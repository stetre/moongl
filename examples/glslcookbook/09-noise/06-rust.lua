#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local texture = require("common.texture")
local new_teapot = require("common.teapot")
local new_skybox = require("common.skybox")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 9 - Rust effect"
local W, H = 800, 600

-- GLFW/GL initializations
glfw.version_hint(4, 6, 'core')
glfw.window_hint('opengl forward compat', true)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local angle, speed = pi/2, pi/8 -- rad, rad/s
local animate = false

glfw.set_key_callback(window, function(window, key, scancode, action)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   elseif key == 'space' and action == 'press' then
      animate = not animate
   end
end)

local projection
local function resize(window, w, h)
   W, H = w, h
   gl.viewport(0, 0, w, h)
   projection = glmath.perspective(rad(50), W/H, 0.3, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program({vertex="shaders/rust.vert", 
                                       fragment="shaders/rust.frag"})
gl.delete_shaders(vsh, fsh)
local prog1, vsh, fsh = gl.make_program({vertex="shaders/skybox.vert", 
                                       fragment="shaders/skybox.frag"})
gl.delete_shaders(vsh, fsh)

local uniforms = {
   "ModelMatrix",
   "MVP",
   "NoiseTex",
   "CubeMapTex",
   "WorldCameraPosition",
   "MaterialColor",
}

local uniforms1 = {
   "SkyBoxTex",
   "MVP",
}
local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end


local loc1 = {}
for _,name in ipairs(uniforms1) do loc1[name] = gl.get_uniform_location(prog1, name) end

local function set_matrices(model, view, projection)
   local mv = view * model
   gl.uniform_matrix4f(loc["ModelMatrix"], true, model)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end

local function set_matrices1(model, view, projection)
   local mv = view * model
   gl.uniform_matrix4f(loc1["MVP"], true, projection * mv)
end


resize(window, W, H)

-- Create the textures

local cube_tex = texture.load_hdr_cube_map("../media/texture/cube/pisa-hdr/pisa")
local noise_tex = texture.noise_2d(16.0)
gl.active_texture(0)
gl.bind_texture('cube map', cube_tex)
gl.active_texture(1)
gl.bind_texture('2d', noise_tex)

gl.use_program(prog)
gl.uniformi(loc["CubeMapTex"], 0)
gl.uniformi(loc["NoiseTex"], 1)
gl.uniformf(loc["MaterialColor"], 0.7255, 0.255, 0.055, 1.0)

gl.use_program(prog1)
gl.uniformi(loc1["SkyBoxTex"], 1)

-- Create the meshes
local teapot = new_teapot(14)
local sky = new_skybox(100.0)

-- Event loop -----------------------------------------------------------------

gl.enable('depth test')
gl.clear_color(.1, .1, .1, 1)

print("Press space to toggle animation on/off")

local t0 = glfw.now()

while not glfw.window_should_close(window) do
   glfw.poll_events()

   -- Update
   local t = glfw.now()
   local dt = t - t0
   t0 = t
   if animate then
      angle = angle + speed*dt
      if angle >= 2*pi then angle = angle - 2*pi end
   end

   local cameraPos = vec3(7*cos(angle), 2.0, 7*sin(angle))
   local view = glmath.look_at(cameraPos, vec3(0.0,0.0,0.0), vec3(0.0,1.0,0.0))
   local model = translate(0.0,-1.0,0.0)*rotate(rad(-90.0), 1,0,0)

   gl.clear('color', 'depth')

   -- Draw sky
   gl.use_program(prog1)
   set_matrices1(mat4(), view, projection)
   sky:render()

   gl.use_program(prog)
   gl.uniformf(loc["WorldCameraPosition"], cameraPos)
   set_matrices(model, view, projection)
   teapot:render()

   gl.finish()

   glfw.swap_buffers(window)
end

