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
local vec3, vec4, mat4 = glmath.vec3, glmath.vec4, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local transpose = glmath.transpose
local clamp, mix = glmath.clamp, glmath.mix
local perspective = glmath.perspective
local rad, sin, cos = math.rad, math.sin, math.cos
local min, max, sqrt = math.min, math.max, math.sqrt

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 5.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local lightPos = vec3(2.0, 4.0, -2.0)
local lightColor = vec3(0.2, 0.2, 0.7)

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
local prog1 = make_program("9.ssao_geometry.vert", "9.ssao_geometry.frag") -- shaderGeometryPass
local prog2 = make_program("9.ssao.vert", "9.ssao_lighting.frag") -- shaderLightingPass
local prog3 = make_program("9.ssao.vert", "9.ssao.frag") -- shaderSSAO
local prog4 = make_program("9.ssao.vert", "9.ssao_blur.frag") -- shaderSSAOBlur
make_program = nil

-- configure g-buffer framebuffer -------------------------------------------
local gBuffer = gl.new_framebuffer('draw read')
-- position color buffer
local gPosition = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb16f', 'rgb', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', gPosition, 0)
-- normal color buffer
local gNormal = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb16f', 'rgb', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 1', '2d', gNormal, 0)
-- color + specular color buffer
local gAlbedo = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb', 'rgb', 'ubyte', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 2', '2d', gAlbedo, 0)
-- tell OpenGL which color attachments we'll use (of this framebuffer) for rendering 
gl.draw_buffers({'color attachment 0', 'color attachment 1', 'color attachment 2'})
-- create and attach depth buffer (renderbuffer)
local rboDepth = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', SCR_WIDTH, SCR_HEIGHT)
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', rboDepth)
-- finally check if framebuffer is complete
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
gl.unbind_framebuffer('draw read')

-- also create framebuffer to hold SSAO processing stage 
local ssaoFBO = gl.new_framebuffer('draw read')
-- SSAO color buffer
local ssaoColorBuffer = gl.new_texture('2d')
gl.texture_image('2d', 0, 'red', 'rgb', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', ssaoColorBuffer, 0)
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
-- and blur stage
local ssaoBlurFBO = gl.new_framebuffer('draw read')
local ssaoColorBufferBlur= gl.new_texture('2d')
gl.texture_image('2d', 0, 'red', 'rgb', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', ssaoColorBufferBlur, 0)
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
gl.unbind_framebuffer('draw read')

-- load models
local nanosuit = new_model("../resources/objects/nanosuit/nanosuit.obj")

local cube = new_cube()
local quad = new_quad()

-- generate sample kernel
math.randomseed(os.time())
local ssaoKernel = {}
for i=1,64 do
   local sample = vec3(math.random()*2-1, math.random()*2-1, math.random()):normalize()
   sample = sample * math.random()
   local scale = (i-1)/64
   -- scale samples s.t. they're more aligned to center of kernel
   scale = mix(0.1, 1.0, scale*scale) -- lerp
   ssaoKernel[i] = sample*scale
end

-- generate noise texture
local ssaoNoise = {}
for i=1,16 do
   local noise = vec3(math.random()*2-1, math.random()*2-1, 0) -- rotate around z-axis (in tangent space)
   ssaoNoise[i] = noise
end
local noiseTexture = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb32f', 'rgb', 'float', gl.packf(ssaoNoise), 4, 4)
gl.texture_parameter('2d', 'min filter', 'nearest');
gl.texture_parameter('2d', 'mag filter', 'nearest');
gl.texture_parameter('2d', 'wrap s', 'repeat')
gl.texture_parameter('2d', 'wrap t', 'repeat')

-- get the locations of the uniforms:
local loc1 = {}
local uniforms = { "projection", "view", "model", "invertedNormals"}
gl.use_program(prog1)
for _, name in ipairs(uniforms) do loc1[name]=gl.get_uniform_location(prog1, name) end

local loc2 = {}
local uniforms = { "gPosition", "gNormal", "gAlbedo", "ssao", 
                  "light.Position", "light.Color", "light.Linear", "light.Quadratic" }
gl.use_program(prog2)
for _, name in ipairs(uniforms) do loc2[name]=gl.get_uniform_location(prog2, name) end
gl.uniformi(loc2.gPosition, 0)
gl.uniformi(loc2.gNormal, 1)
gl.uniformi(loc2.gAlbedo, 2)
gl.uniformi(loc2.ssao, 3)

local loc3 = {}
local uniforms = { "gPosition", "gNormal", "texNoise", "projection" }
for i=1, #ssaoKernel do table.insert(uniforms, "samples["..(i-1).."]") end
gl.use_program(prog3)
for _, name in ipairs(uniforms) do loc3[name]=gl.get_uniform_location(prog3, name) end
gl.uniformi(loc3.gPosition, 0)
gl.uniformi(loc3.gNormal, 1)
gl.uniformi(loc3.texNoise, 2)

local loc4 = {}
local uniforms = { "ssaoInput" }
gl.use_program(prog4)
for _, name in ipairs(uniforms) do loc4[name]=gl.get_uniform_location(prog4, name) end
gl.uniformi(loc4.ssaoInput, 0)

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
   gl.clear_color(0.0, 0.0, 0.0, 1.0)
   gl.clear('color', 'depth')
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 50.0)
   local view = camera:view()
   gl.use_program(prog1)
   gl.uniform_matrix4f(loc1.projection, true, projection)
   gl.uniform_matrix4f(loc1.view, true, view)
   -- room cube
   gl.uniform_matrix4f(loc1.model, true, translate(0.0, 7.0, 0.0)*scale(7.5))
   gl.uniformb(loc1.invertedNormals, true) -- invert normals as we're inside the cube
   cube:draw()
   gl.uniformb(loc1.invertedNormals, false)
   -- nanosuit model on the floor
   local model = translate(0.0, 0.0, 5.0)*rotate(rad(-90.0), 1, 0, 0)*scale(0.5)
   gl.uniform_matrix4f(loc1.model, true, model)
   nanosuit:draw(prog1)
   gl.unbind_framebuffer('draw read')

   -- 2. generate SSAO texture
   gl.bind_framebuffer('draw read', ssaoFBO)
   gl.clear('color')
   gl.use_program(prog3)
   -- Send kernel + rotation 
   for i, sample in ipairs(ssaoKernel) do
      gl.uniformf(loc3["samples["..(i-1).."]"], sample)
   end
   gl.uniform_matrix4f(loc3.projection, true, projection)
   gl.active_texture(0)
   gl.bind_texture('2d', gPosition)
   gl.active_texture(1)
   gl.bind_texture('2d', gNormal)
   gl.active_texture(2)
   gl.bind_texture('2d', noiseTexture)
   quad:draw()
   gl.unbind_framebuffer('draw read')

   -- 3. blur SSAO texture to remove noise
   gl.bind_framebuffer('draw read', ssaoBlurFBO)
   gl.clear('color')
   gl.use_program(prog4)
   gl.active_texture(0)
   gl.bind_texture('2d', ssaoColorBuffer)
   quad:draw()
   gl.unbind_framebuffer('draw read')

   -- 4. lighting pass: traditional deferred Blinn-Phong lighting with added
   -- screen-space ambient occlusion
   gl.clear('color', 'depth')
   gl.use_program(prog2)
   -- send light relevant uniforms
   local lightPosView = vec3(view*vec4(lightPos.x, lightPos.y, lightPos.z, 1.0))
   gl.uniformf(loc2["light.Position"], lightPosView)
   gl.uniformf(loc2["light.Color"], lightColor)
   -- Update attenuation parameters
   local constant = 1.0 -- note that we don't send this to the shader, 
                        -- we assume it is always 1.0 (in our case)
   local linear, quadratic = 0.09, 0.032
   gl.uniformf(loc2["light.Linear"], linear)
   gl.uniformf(loc2["light.Quadratic"], quadratic)
   gl.active_texture(0)
   gl.bind_texture('2d', gPosition)
   gl.active_texture(1)
   gl.bind_texture('2d', gNormal)
   gl.active_texture(2)
   gl.bind_texture('2d', gAlbedo)
   gl.active_texture(3) -- add extra SSAO texture to lighting pass
   gl.bind_texture('2d', ssaoColorBufferBlur)
   quad:draw()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

