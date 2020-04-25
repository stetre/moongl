#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local random = require("common.random")
local texture = require("common.texture")
local new_grid = require("common.grid")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local mix, clamp = glmath.mix, glmath.clamp
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 10 - Particle system with kinematic model"
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
local prog, vsh, fsh = gl.make_program('vertex', "shaders/particles.vert",
                                       'fragment', "shaders/particles.frag")
gl.delete_shaders(vsh, fsh)
local prog1, vsh, fsh = gl.make_program('vertex', "shaders/flat.vert",
                                       'fragment', "shaders/flat.frag")
gl.delete_shaders(vsh, fsh)

-- Get the locations of the uniform variables
local uniforms = {
   "Time",
   "Gravity",
   "ParticleTex",
   "ParticleSize",
   "ParticleLifetime",
   "EmitterPos",
   "Proj",
   "MV",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

local uniforms1 = {
   "Color",
   "Proj",
   "MV",
}

local loc1 = {}
for _,name in ipairs(uniforms1) do loc1[name] = gl.get_uniform_location(prog1, name) end

-- Initialize the uniform variables
resize(window, W, H) -- creates projection

-- Generate the meshes
local grid = new_grid()

-- Load the particle texture
gl.active_texture(0)
local texid = texture.load_texture("../media/texture/bluewater.png")
gl.bind_texture_unit(0, texid)

local particleLifetime = 5.5
local nParticles = 8000
local emitterPos = vec3(1, 0, 0)
local emitterDir = vec3(-1, 2, 0)

gl.use_program(prog)
gl.uniformi(loc["ParticleTex"], 0)
gl.uniformf(loc["ParticleLifetime"], particleLifetime)
gl.uniformf(loc["ParticleSize"], 0.05)
gl.uniformf(loc["Gravity"], 0.0, -0.2, 0.0)
gl.uniformf(loc["EmitterPos"], emitterPos)

gl.use_program(prog1)
gl.uniformf(loc1["Color"], 0.4, 0.4, 0.4, 1.0)

-- Generate the buffers for initial velocity and start (birth) time ---------------

local function arbitrary_basis(dir) 
-- Returns a rotation matrix (mat3) that rotates the y-axis to be parallel to dir (vec3).
   local u, v, n
   local v = vec3(dir):normalize()
   local n = vec3(1,0,0) % v
   -- if v is parallel to the x-axis, use the y-axis instead
   if n:norm() < 0.00001 then n = vec3(0,1,0) % v end
   n:normalize()
   local u = (v % n):normalize()
   local rot =mat3(u.x, v.x, n.x, u.y, v.y, n.y, u.z, v.z, n.z) -- rot*{0,1,0}' = {v.x,v.y,v.z}'
   return rot
end

-- Generate the random initial velocities and start times
local emitterBasis = arbitrary_basis(emitterDir)
local rate = particleLifetime/nParticles
local vdata, tdata = {}, {}
local v, theta, phi, speed
for i = 1, nParticles do
   theta = mix(0.0, pi/20.0, random.uniform())
   phi = mix(0.0, 2*pi, random.uniform())
   v = vec3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi))
   speed = mix(1.25,1.5, random.uniform())
   v = speed * (emitterBasis * v):normalize()
   table.insert(vdata, v)
   table.insert(tdata, rate*(i-1))
end

local vao = gl.new_vertex_array()
local initVel = gl.new_buffer('array') -- Initial velocity buffer
gl.buffer_data('array', gl.packf(vdata), 'static draw')
gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0) -- VertexInitVel
local startTime = gl.new_buffer('array') -- Start time buffer
gl.buffer_data('array', gl.packf(tdata), 'static draw')
gl.vertex_attrib_pointer(1, 1, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(1) -- VertexBirthTime
gl.vertex_attrib_divisor(0,1)
gl.vertex_attrib_divisor(1,1)
gl.unbind_vertex_array()

-- Event loop -----------------------------------------------------------------

local model = mat4()
local view = glmath.look_at(vec3(3.0*cos(angle),1.5,3.0*sin(angle)), vec3(0,1.5,0), vec3(0,1,0))

print("Press space to toggle animation on/off")

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

   gl.enable('blend')
   gl.blend_func('src alpha', 'one minus src alpha')
   gl.enable('depth test')
   gl.clear_color(.1, .1, .1, 1)
   gl.clear('color', 'depth')

   gl.use_program(prog1)
   gl.uniform_matrix4f(loc1["MV"], true, view*model)
   gl.uniform_matrix4f(loc1["Proj"], true, projection)
   grid:render()

   gl.depth_mask(false)
   gl.use_program(prog)
   if animate then
      time = time+dt
      gl.uniformf(loc["Time"], time) 
   end
   gl.uniform_matrix4f(loc["MV"], true, view*model)
   gl.uniform_matrix4f(loc["Proj"], true, projection)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6, nParticles)
   gl.unbind_vertex_array()
   gl.depth_mask(true)

   glfw.swap_buffers(window)
end

