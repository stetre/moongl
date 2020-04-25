#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local new_plane = require("common.plane")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 10 - A plane wave displacement animation"
local W, H = 800, 600

-- GLFW/GL initializations
glfw.version_hint(4, 6, 'core')
glfw.window_hint('opengl forward compat', true)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local angle, speed = pi/2, pi/8 -- rad, rad/s
local animate = true

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
   projection = glmath.perspective(rad(60), w/h, 0.3, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program('vertex', "shaders/wave.vert",
                                       'fragment', "shaders/wave.frag")
gl.delete_shaders(vsh, fsh)
gl.use_program(prog)

-- Get the locations of the uniform variables
local uniforms = {
   "Time",
   "Light.Intensity",
   "Light.Position",
   "Material.Ka",
   "Material.Kd",
   "Material.Ks",
   "Material.Shininess",
   "ModelViewMatrix",
   "NormalMatrix",
   "MVP",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

-- Initialize the uniform variables
resize(window, W, H) -- creates projection

local function set_matrices(model, view, projection)
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end

local function set_material(ka, kd, ks, shininess)
   gl.uniformf(loc["Material.Ka"], ka)
   gl.uniformf(loc["Material.Kd"], kd)
   gl.uniformf(loc["Material.Ks"], ks)
   gl.uniformf(loc["Material.Shininess"], shininess)
end


gl.uniformf(loc["Light.Intensity"], 1, 1, 1)
gl.uniformf(loc["Light.Position"], 0, 0, 0, 1)

-- Generate the meshes
local plane = new_plane(13.0, 10.0, 200, 200)

-- Event loop -----------------------------------------------------------------

local view = glmath.look_at(vec3(10*cos(angle), 4, 10*sin(angle)), vec3(0,0,0), vec3(0,1,0))

print("Press space to toggle animation on/off")

local model
local t0 = glfw.now()
local time = 0

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

   gl.enable('depth test')
   gl.clear_color(.5, .5, .5, 1)
   gl.clear('color', 'depth')
   gl.use_program(prog)

   if animate then
      -- we could use t here, but then the animation would 'jump' when
      -- toggled off and then on
      time = time+dt
      gl.uniformf(loc["Time"], time) 
   end

   local model = rotate(rad(-10), 0, 0, 1)*rotate(rad(50), 1, 0, 0)
   set_matrices(model, view, projection)
   set_material({0.2, 0.2, 0.2}, {0.9, 0.5, 0.3}, {0.8, 0.8, 0.8}, 100.0)
   plane:render()

   glfw.swap_buffers(window)
end

