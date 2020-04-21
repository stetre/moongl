#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local texture = require("common.texture")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 9 - Raw noise texture"
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

local function resize(window, w, h)
   W, H = w, h
   gl.viewport(0, 0, w, h)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program({vertex="shaders/noisetex.vert", 
                                       fragment="shaders/noisetex.frag"})
gl.delete_shaders(vsh, fsh)

local uniforms = {
   "MVP",
   "NoiseTex",
}
local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

resize(window, W, H)

-- Create the VAO for the quad

local verts = {
   -1.0, -1.0, 0.0,
    1.0, -1.0, 0.0, 
    1.0,  1.0, 0.0,
   -1.0, -1.0, 0.0, 
    1.0,  1.0, 0.0, 
   -1.0,  1.0, 0.0
}
local max = 2.0
local tc = {
   0.0, 0.0,
   max, 0.0,
   max, max,
   0.0, 0.0,
   max, max,
   0.0, max
}

local vao = gl.new_vertex_array()
local vbo1 = gl.new_buffer('array')
gl.buffer_data('array', gl.packf(verts), 'static draw')
gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0)  -- position
local vbo2 = gl.new_buffer('array')
gl.buffer_data('array', gl.packf(tc), 'static draw')
gl.vertex_attrib_pointer(2, 2, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(2)  -- texture coords
gl.unbind_vertex_array()

-- Create the noise texture
local noise_tex = texture.noise_2d_periodic()
--local noise_tex = texture.noise_2d()
gl.active_texture(0)
gl.bind_texture('2d', noise_tex)
gl.use_program(prog)
gl.uniformi(loc["NoiseTex"], 0)

-- Event loop -----------------------------------------------------------------

gl.enable('depth test')
gl.clear_color(1, 1, 1, 1)

local c = .75
local projection = glmath.ortho(-2*c, 2*c, -1.5*c, 1.5*c)
local view, model = mat4(), mat4()
gl.use_program(prog)
gl.uniform_matrix4f(loc["MVP"], true, projection * view * model)

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
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6)
   gl.finish()

   glfw.swap_buffers(window)
end

