#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local new_cube = require("common.cube")

local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 11 - Mandelbrot set with compute shader"
local W, H = 800, 600

-- GLFW/GL initializations
glfw.version_hint(4, 6, 'core')
glfw.window_hint('opengl forward compat', true)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local angle, speed = pi/2, pi/3 -- rad, rad/s
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
   projection = glmath.perspective(rad(60.0), w/h, .3, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader programs
local prog, vsh, fsh = gl.make_program({
   vertex = "shaders/ads.vert",
   fragment = "shaders/ads.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, csh = gl.make_program({
   compute = "shaders/mandelbrot.comp",
})
gl.delete_shaders(csh)


-- Get the locations of the uniform variables
local uniforms = {
   "LightPosition",
   "LightIntensity",
   "Ka",
   "Kd",
   "Ks",
   "Shininess",
   "Tex",
   "ModelViewMatrix",
   "NormalMatrix",
   "MVP",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

-- Get the locations of the uniform variables
local uniforms1 = {
   "ColorImg",
   "CompWindow",
   "Width",
   "Height",
}

local loc1 = {}
for _,name in ipairs(uniforms1) do loc1[name] = gl.get_uniform_location(prog1, name) end

-- Initialize the uniform variables
resize(window, W, H) -- creates projection

local function set_matrices(model, view, projection)
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end

gl.use_program(prog)
gl.uniformf(loc["LightPosition"], 0.0,0.0,0.0,1.0)
gl.uniformf(loc["LightIntensity"], 1.0, 1.0, 1.0)
gl.uniformf(loc["Ka"], .2, .2, .2)
gl.uniformf(loc["Kd"], .8, .8, .8)
gl.uniformf(loc["Ks"], .2, .2, .2)
gl.uniformf(loc["Shininess"], 80.0)

local cheight = 1.0
local function set_window()
   gl.use_program(prog1)
   local ar = 1.0
   local cwidth = cheight * ar
   local center = vec2(0.001643721971153, 0.822467633298876)
   local bbox = {center.x - cwidth/2.0, center.y - cheight/2.0, 
                 center.x + cwidth/2.0, center.y + cheight/2.0}
   gl.uniformf(loc1["CompWindow"], bbox)
end
set_window()

-- Generate the mesh
local cube = new_cube(cheight)

-- The buffer for the colors, as an image texture
gl.active_texture(0)
local imgTex = gl.new_texture('2d')
gl.texture_storage('2d', 1, 'rgba8', 256, 256)
gl.bind_image_texture(0, imgTex, 0, false, 0, 'read write', 'rgba8')


-- Event loop -----------------------------------------------------------------

print("Press space to toggle animation on/off")

local linspeed = 200.0
local model = mat4()
local view = glmath.look_at(vec3(1, 1.25, 1.25), vec3(0,0,0), vec3(0,1,0))
--local view = glmath.look_at(vec3(0,0,2), vec3(0,0,0), vec3(0,1,0))
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
      local dy = cheight / H
      cheight =cheight - dt * linspeed * dy
      set_window()
   end

   gl.use_program(prog1)
   gl.dispatch_compute(256/32, 256/32, 1)
   gl.memory_barrier('shader image access')
   gl.enable('depth test')
   gl.clear('color', 'depth')
   gl.use_program(prog)
   local model = glmath.rotate(angle, 0, 1, 0)
   set_matrices(model, view, projection)
   cube:render()

   glfw.swap_buffers(window)
end
