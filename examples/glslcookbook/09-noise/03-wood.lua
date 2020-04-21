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

local TITLE = "Chapter 9 - Wood grain effect"
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
local prog, vsh, fsh = gl.make_program({vertex="shaders/wood.vert", 
                                       fragment="shaders/wood.frag"})
gl.delete_shaders(vsh, fsh)

local uniforms = {
   "MVP",
   "NoiseTex",
   "DarkWoodColor",
   "LightWoodColor",
   "Slice",
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
local tc = {
   0.0, 0.0,
   1.0, 0.0,
   1.0, 1.0,
   0.0, 0.0,
   1.0, 1.0,
   0.0, 1.0
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
local noise_tex = texture.noise_2d()
gl.active_texture(0)
gl.bind_texture('2d', noise_tex)
gl.use_program(prog)
gl.uniformi(loc["NoiseTex"], 0)
--gl.uniformf(loc["DarkWoodColor"],  .8, .4, .1 ,1.0)
--gl.uniformf(loc["LightWoodColor"], .9, .6, .2 ,1.0)

local slice = rotate(rad(10), 1, 0, 0)*rotate(rad(-20), 0,0,1)
              *scale(40.0, 40.0, 1.0)*translate(-0.35, -0.5, 2.0)
gl.uniform_matrix4f(loc["Slice"], true, slice)

-- Event loop -----------------------------------------------------------------

gl.enable('depth test')
gl.clear_color(.5, .5, .5, 1)

local view, model, projection = mat4(), mat4(), mat4()
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

