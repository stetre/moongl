#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_texture = require("common.texture")
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

local SCR_WIDTH, SCR_HEIGHT = 800, 600
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 5.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
-- positions
local lightPositions = {
   vec3( 0.0, 0.5,  1.5),
   vec3(-4.0, 0.5, -3.0),
   vec3( 3.0, 0.5,  1.0),
   vec3(-.8,  2.4, -1.0),
}
-- colors
local lightColors = {
   vec3(5.0,   5.0,  5.0),
   vec3(10.0,  0.0,  0.0),
   vec3(0.0,   0.0,  15.0),
   vec3(0.0,   5.0,  0.0),
}

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
local prog1 = make_program("7.bloom.vert", "7.bloom.frag")              -- shader
local prog2 = make_program("7.bloom.vert", "7.light_box.frag")          -- shaderLight
local prog3 = make_program("7.blur.vert", "7.blur.frag")                -- shaderBlur
local prog4 = make_program("7.bloom_final.vert", "7.bloom_final.frag")  -- shaderBloomFinal
make_program=nil

-- configure floating point framebuffers ------------------------------------

local hdrFBO = gl.new_framebuffer('draw read')
 -- create 2 floating point color buffers (1 for normal rendering, other for brightness treshold values)
local colorBuffers = { gl.gen_textures(2)}
for i, tex in ipairs(colorBuffers) do
   gl.bind_texture('2d', tex)
   gl.texture_image('2d', 0, 'rgba16f', 'rgba', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'mag filter', 'linear')
   -- we clamp to the edge as the blur filter would otherwise sample repeated texture values!
   gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
   gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
   -- attach texture to framebuffer
   gl.framebuffer_texture_2d('draw read', 'color attachment '..(i-1), '2d', tex, 0)
end

-- create and attach depth buffer (renderbuffer)
local rboDepth = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', SCR_WIDTH, SCR_HEIGHT)
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', rboDepth)
-- tell OpenGL which color attachments we'll use (of this framebuffer) for rendering 
gl.draw_buffers({ 'color attachment 0',  'color attachment 1' })
-- finally check if framebuffer is complete
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
gl.unbind_framebuffer('draw read')

-- ping-pong-framebuffer for blurring
local pingpongFBO = {gl.gen_framebuffers(2)}
local pingpongColorbuffers = {gl.gen_textures(2)}
for i=1, 2 do
   gl.bind_framebuffer('draw read', pingpongFBO[i])
   gl.bind_texture('2d', pingpongColorbuffers[i])
   gl.texture_image('2d', 0, 'rgba16f', 'rgba', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'mag filter', 'linear')
   -- we clamp to the edge as the blur filter would otherwise sample repeated texture values!
   gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
   gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
   gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', pingpongColorbuffers[i], 0)
   -- also check if framebuffers are complete (no need for depth buffer)
   assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
end

-- load textures
-- note that we're loading the texture as an SRGB texture:
local wood_texture = new_texture("../resources/textures/wood.png", true) 
local container_texture = new_texture("../resources/textures/container2.png", true) 

local cube = new_cube()
local quad = new_quad()

-- get the locations of the uniforms:
local loc1 = {}
local uniforms = { "projection", "view", "model", "diffuseTexture" }
for i=1,#lightPositions do table.insert(uniforms, "lights["..(i-1).."].Position") end
for i=1,#lightColors do table.insert(uniforms, "lights["..(i-1).."].Color") end
gl.use_program(prog1)
for _, name in ipairs(uniforms) do loc1[name]=gl.get_uniform_location(prog1, name) end
gl.uniformi(loc1.diffuseTexture, 0)

local loc2 = {}
local uniforms = { "projection", "view", "model", "lightColor" }
gl.use_program(prog2)
for _, name in ipairs(uniforms) do loc2[name]=gl.get_uniform_location(prog2, name) end

local loc3 = {}
local uniforms = { "image", "horizontal" }
gl.use_program(prog3)
for _, name in ipairs(uniforms) do loc3[name]=gl.get_uniform_location(prog3, name) end
gl.uniformi(loc3.image, 0)

local loc4 = {}
local uniforms = { "scene", "bloom", "bloomBlur", "exposure" }
gl.use_program(prog4)
for _, name in ipairs(uniforms) do loc4[name]=gl.get_uniform_location(prog4, name) end
gl.uniformi(loc4.scene, 0)
gl.uniformi(loc4.bloomBlur, 1)

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
local bloom, bloom_key_pressed = true, false
local exposure = 1.0

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

-- render loop
print("Press 'space' to toggle bloom")
print("Press Q or E to decrease/increase exposure")
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
   if keypressed('space') and not bloom_key_pressed then
      bloom = not bloom
      bloom_key_pressed = true
   end
   if keyreleased('space') then bloom_key_pressed = false end
   if keypressed('q') then exposure = max(exposure-0.001, 0.0) end
   if keypressed('e') then exposure = exposure+0.001 end
   glfw.set_window_title(window,string.format("LearnOpenGL - bloom %s (exposure=%.3f)",
      (bloom and "enabled" or "disabled"), exposure))

   -- 1. render scene into floating point framebuffer
   gl.bind_framebuffer('draw read', hdrFBO)
   gl.clear_color(0.0, 0.0, 0.0, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog1)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   local view = camera:view()
   gl.uniform_matrix4f(loc1.projection, true, projection)
   gl.uniform_matrix4f(loc1.view, true, view)
   gl.active_texture(0)
   gl.bind_texture('2d', wood_texture)
   -- set lighting uniforms
   for i=0,#lightPositions-1 do
      gl.uniformf(loc1["lights["..(i).."].Position"], lightPositions[i+1])
      gl.uniformf(loc1["lights["..(i).."].Color"], lightColors[i+1])
   end
   -- create one large cube that acts as the floor
   gl.uniform_matrix4f(loc1.model, true, translate(0.0, -1.0, 0.0)*scale(12.5, 0.5, 12.5))
   cube:draw()
   -- then create multiple cubes as the scenery
   gl.bind_texture('2d', container_texture);
   gl.uniform_matrix4f(loc1.model, true, translate(0.0, 1.5, 0.0)*scale(0.5))
   cube:draw()
   gl.uniform_matrix4f(loc1.model, true, translate(2.0, 0.0, 1.0)*scale(0.5))
   cube:draw()
   gl.uniform_matrix4f(loc1.model, true, translate(-1.0, -1.0, 2.0)*
                        rotate(rad(60.0), vec3(1.0, 0.0, 1.0):normalize()))
   cube:draw()
   gl.uniform_matrix4f(loc1.model, true, translate(0.0, 2.7, 4.0)*
                        rotate(rad(23.0), vec3(1.0, 0.0, 1.0):normalize())*scale(1.25))
   cube:draw()
   gl.uniform_matrix4f(loc1.model, true, translate(-2.0, 1.0, -3.0)*
                     rotate(rad(124.0), vec3(1.0, 0.0, 1.0):normalize()))
   cube:draw()
   gl.uniform_matrix4f(loc1.model, true, translate(-3.0, 0.0, 0.0)*scale(0.5))
   cube:draw()

   -- finally show all the light sources as bright cubes
   gl.use_program(prog2)
   gl.uniform_matrix4f(loc2.projection, true, projection)
   gl.uniform_matrix4f(loc2.view, true, view)
   for i=0,#lightPositions-1 do
      gl.uniform_matrix4f(loc2.model, true, translate(lightPositions[i+1])*scale(0.25))
      gl.uniformf(loc2.lightColor, lightColors[i+1])
      cube:draw()
   end

   -- 2. blur bright fragments with two-pass Gaussian Blur 
   gl.unbind_framebuffer('draw read')
   gl.use_program(prog3)
   local horizontal = true
   local amount = 10
   for i=1,amount do
      gl.bind_framebuffer('draw read', pingpongFBO[horizontal and 2 or 1])
      gl.uniformb(loc3.horizontal, horizontal)
      -- bind texture of other framebuffer (or scene if first iteration):
      gl.bind_texture('2d', i==1 and colorBuffers[2] or (pingpongColorbuffers[horizontal and 1 or 2]))
      quad:draw()
      horizontal = not horizontal
   end

   -- 3. now render floating point color buffer to 2D quad and tonemap HDR colors to
   -- default framebuffer's (clamped) color range
   gl.unbind_framebuffer('draw read')
   gl.clear('color', 'depth')
   gl.use_program(prog4)
   gl.active_texture(0)
   gl.bind_texture('2d', colorBuffers[1])
   gl.active_texture(1)
   gl.bind_texture('2d', pingpongColorbuffers[horizontal and 1 or 2])
   gl.uniformb(loc4.bloom, bloom)
   gl.uniformf(loc4.exposure, exposure)
   quad:draw()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

