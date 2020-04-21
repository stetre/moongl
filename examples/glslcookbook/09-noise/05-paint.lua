#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local texture = require("common.texture")
local new_teapot = require("common.teapot")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 9 - Paint spatters on a teapot"
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
   projection = glmath.perspective(rad(55), W/H, 0.3, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program({vertex="shaders/paint.vert", 
                                       fragment="shaders/paint.frag"})
gl.delete_shaders(vsh, fsh)

local uniforms = {
   "ModelViewMatrix",
   "NormalMatrix",
   "MVP",
   "NoiseTex",
   "Light.Position",
   "Light.Intensity",
   "Material.Kd",
   "Material.Ks",
   "Material.Shininess",
}
local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

local function set_matrices(model, view, projection)
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end

resize(window, W, H)

-- Create the noise texture
local noise_tex = texture.noise_2d(32.0)
gl.active_texture(0)
gl.bind_texture('2d', noise_tex)
gl.use_program(prog)
gl.uniformi(loc["NoiseTex"], 0)

-- set other uniforms
gl.uniformf(loc["Light.Intensity"], 1.0,1.0,1.0)
gl.uniformf(loc["Light.Position"], 0.0,0.0,0.0,1.0)
gl.uniformf(loc["Material.Kd"], 0.7, 0.5, 0.3)
gl.uniformf(loc["Material.Ks"], 1.0, 1.0, 1.0)
gl.uniformf(loc["Material.Shininess"], 100.0);

local view = glmath.look_at(0.85*vec3(0.0,5.0,6.0), vec3(0.0,0.0,-3.0), vec3(0.0,1.0,0.0))
local model = rotate(rad(-15.0), 0,1,0)*rotate(rad(-90.0), 1,0,0)

-- Create the teapot mesh
local teapot = new_teapot(14)

-- Event loop -----------------------------------------------------------------

gl.enable('depth test')
gl.clear_color(.1, .1, .1, 1)

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

   gl.use_program(prog)
   gl.clear('color', 'depth')
   set_matrices(model, view, projection)
   teapot:render()
   gl.finish()

   glfw.swap_buffers(window)
end

