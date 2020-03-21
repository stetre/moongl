#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_model = require("common.model")
local new_cube = require("common.cube")
local new_quad = require("common.quad")

-- A few shortcuts:
local vec3, mat4 = glmath.vec3, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local transpose = glmath.transpose
local clamp = glmath.clamp
local perspective = glmath.perspective
local rad, sin, cos = math.rad, math.sin, math.cos
local min, max = math.min, math.max

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 5.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local NR_LIGHTS = 32
local lightPositions = {}
local lightColors = {}
math.randomseed(os.time())
for i=1, NR_LIGHTS do
   -- calculate slightly random offsets
   lightPositions[i] = vec3(math.random()*6-3, math.random()*6-4, math.random()*6-3)
   -- also calculate random color (components between 0.5 and 1.0)
   lightColors[i] = vec3(math.random()*.5+.5, math.random()*.5+.5, math.random()*.5+.5)
end

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local function make_program(vshader, fshader)
   local prog, vsh, fsh = gl.make_program(
      {vertex="shaders/"..vshader, fragment="shaders/"..fshader})
   gl.delete_shaders(vsh, fsh)
   return prog
end
local prog1 = make_program("8.1.g_buffer.vert", "8.1.g_buffer.frag")
local prog2 = make_program("8.1.deferred_shading.vert", "8.1.deferred_shading.frag")
local prog3 = make_program("8.1.deferred_light_box.vert", "8.1.deferred_light_box.frag")
make_program = nil

-- configure g-buffer framebuffer -------------------------------------------
local gBuffer = gl.new_framebuffer('draw read')
-- position color buffer
local gPosition = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb16f', 'rgb', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', gPosition, 0)
-- normal color buffer
local gNormal = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb16f', 'rgb', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 1', '2d', gNormal, 0)
-- color + specular color buffer
local gAlbedoSpec = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgba', 'rgba', 'ubyte', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 2', '2d', gAlbedoSpec, 0)
-- tell OpenGL which color attachments we'll use (of this framebuffer) for rendering 
gl.draw_buffers({'color attachment 0', 'color attachment 1', 'color attachment 2'})
-- create and attach depth buffer (renderbuffer)
local rboDepth = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', SCR_WIDTH, SCR_HEIGHT)
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', rboDepth)
-- finally check if framebuffer is complete
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
gl.unbind_framebuffer('draw read')

-- load models
local nanosuit = new_model("../resources/objects/nanosuit/nanosuit.obj")
local objectPositions = {
   vec3(-3.0,  -3.0, -3.0),
   vec3( 0.0,  -3.0, -3.0),
   vec3( 3.0,  -3.0, -3.0),
   vec3(-3.0,  -3.0,  0.0),
   vec3( 0.0,  -3.0,  0.0),
   vec3( 3.0,  -3.0,  0.0),
   vec3(-3.0,  -3.0,  3.0),
   vec3( 0.0,  -3.0,  3.0),
   vec3( 3.0,  -3.0,  3.0),
}

local cube = new_cube()
local quad = new_quad()

-- get the locations of the uniforms:
local loc1 = {}
local uniforms = { "projection", "view", "model" }
gl.use_program(prog1)
for _, name in ipairs(uniforms) do loc1[name]=gl.get_uniform_location(prog1, name) end

local loc2 = {}
local uniforms = { "gPosition", "gNormal", "gAlbedoSpec", "viewPos" }
gl.use_program(prog2)
for i=1, NR_LIGHTS do
   table.insert(uniforms, "lights["..(i-1).."].Position")
   table.insert(uniforms, "lights["..(i-1).."].Color")
   table.insert(uniforms, "lights["..(i-1).."].Linear")
   table.insert(uniforms, "lights["..(i-1).."].Quadratic")
end
for _, name in ipairs(uniforms) do loc2[name]=gl.get_uniform_location(prog2, name) end
gl.uniformi(loc2.gPosition, 0)
gl.uniformi(loc2.gNormal, 1)
gl.uniformi(loc2.gAlbedoSpec, 2)

local loc3 = {}
local uniforms = { "projection", "view", "model", "lightColor" }
gl.use_program(prog3)
for _, name in ipairs(uniforms) do loc3[name]=gl.get_uniform_location(prog3, name) end

glfw.set_framebuffer_size_callback(window, function (window, w, h)
   gl.viewport(0, 0, w, h)
   SCR_WIDTH, SCR_HEIGHT = w, h
end)

glfw.set_cursor_pos_callback(window, function(window, xpos, ypos)
   -- whenever the mouse moves, this callback is called
   if first_mouse then
      last_x, last_y = xpos, ypos
      first_mouse = false
   end
   local xoffset = xpos - last_x
   local yoffset = last_y - ypos -- reversed since y-coordinates go from bottom to top
   last_x, last_y = xpos, ypos
   camera:process_mouse(xoffset, yoffset, true)
end)

-- tell GLFW to capture our mouse:
glfw.set_input_mode(window, 'cursor', 'disabled')

-- configure global opengl state
gl.enable('depth test')

local last_frame_time = 0.0 -- last frame time

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

-- render loop
while not glfw.window_should_close(window) do
   local t = glfw.get_time()
   local dt = t - last_frame_time
   last_frame_time = t

   -- process input
   if keypressed('escape') then glfw.set_window_should_close(window, true) end
   -- camera movement controlled either by WASD keys or arrow keys:
   if keypressed('w') or keypressed('up') then camera:process_keyboard('forward', dt) end
   if keypressed('a') or keypressed('left') then camera:process_keyboard('left', dt) end
   if keypressed('s') or keypressed('down') then camera:process_keyboard('backward', dt) end
   if keypressed('d') or keypressed('right') then camera:process_keyboard('right', dt) end

   -- 1. geometry pass: render scene's geometry/color data into gbuffer
   gl.bind_framebuffer('draw read', gBuffer)
   gl.clear_color(0.1, 0.1, 0.1, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog1)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   local view = camera:view()
   gl.uniform_matrix4f(loc1.projection, true, projection)
   gl.uniform_matrix4f(loc1.view, true, view)
   for _, pos in ipairs(objectPositions) do
      gl.uniform_matrix4f(loc1.model, true, translate(pos)*scale(0.25))
      nanosuit:draw(prog1)
   end
   gl.unbind_framebuffer('draw read')

   -- 2. lighting pass: calculate lighting by iterating over a screen filled quad
   -- pixel-by-pixel using the gbuffer's content.
   gl.clear('color', 'depth')
   gl.use_program(prog2)
   gl.active_texture(0)
   gl.bind_texture('2d', gPosition)
   gl.active_texture(1)
   gl.bind_texture('2d', gNormal)
   gl.active_texture(2)
   gl.bind_texture('2d', gAlbedoSpec)
   -- send light relevant uniforms
   for i = 1, NR_LIGHTS do
      gl.uniformf(loc2["lights["..(i-1).."].Position"], lightPositions[i])
      gl.uniformf(loc2["lights["..(i-1).."].Color"], lightColors[i])
      -- update attenuation parameters and calculate radius
      -- local constant = 1.0 -- note that we don't send this to the shader, 
                           -- we assume it is always 1.0 (in our case)
      gl.uniformf(loc2["lights["..(i-1).."].Linear"], 0.7)
      gl.uniformf(loc2["lights["..(i-1).."].Quadratic"], 1.8)
   end
   gl.uniformf(loc2.viewPos, camera.position)
   -- finally render quad
   quad:draw()

   -- 2.5. copy content of geometry's depth buffer to default framebuffer's depth buffer
   gl.bind_framebuffer('read', gBuffer)
   gl.unbind_framebuffer('draw') -- write to default framebuffer
   -- blit to default framebuffer. Note that this may or may not work as the internal
   -- formats of both the FBO and default framebuffer have to match. The internal formats
   -- are implementation defined. This works on all of my systems, but if it doesn't on
   -- yours you'll likely have to write to the depth buffer in another shader stage (or
   -- somehow see to match the default framebuffer's internal format with the FBO's
   -- internal format).
   gl.blit_framebuffer(0, 0, SCR_WIDTH, SCR_HEIGHT, 0, 0, SCR_WIDTH, SCR_HEIGHT, 'nearest', 'depth')
   gl.unbind_framebuffer('draw read')

   -- 3. render lights on top of scene
   gl.use_program(prog3)
   gl.uniform_matrix4f(loc3.projection, true, projection)
   gl.uniform_matrix4f(loc3.view, true, view)
   for i = 1, NR_LIGHTS do
      gl.uniform_matrix4f(loc3.model, true, translate(lightPositions[i])*scale(0.125))
      gl.uniformf(loc3.lightColor, lightColors[i])
      cube:draw()
   end

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

