#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 11 - Simple particle simulation using compute shader"
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
   projection = glmath.perspective(rad(50.0), w/h, 1.0, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader programs
local prog, vsh, fsh = gl.make_program({
   vertex = "shaders/particles.vert",
   fragment = "shaders/particles.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, csh = gl.make_program({
   compute = "shaders/particles.comp",
})
gl.delete_shaders(csh)

-- Get the locations of the uniform variables
local uniforms = {
   "Color",
-- These are pruned by the compiler because Position is not used in the fragment shader:
-- "ModelViewMatrix",
-- "NormalMatrix",
   "MVP",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

-- Get the locations of the uniform variables
local uniforms1 = {
   "Gravity1",
   "Gravity2",
   "BlackHolePos1",
   "BlackHolePos2",
-- "ParticleMass", -- not used
   "ParticleInvMass",
   "DeltaT",
   "MaxDist",
}

local loc1 = {}
for _,name in ipairs(uniforms1) do loc1[name] = gl.get_uniform_location(prog1, name) end

-- Initialize the uniform variables
resize(window, W, H) -- creates projection

local function set_matrices(model, view, projection)
   local mv = view * model
--[[
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
--]]
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end

local nx, ny, nz = 100, 100, 100
local nParticles = nx*ny*nz
local bh1, bh2 = vec4(5,0,0,1), vec4(-5,0,0,1) -- black hole positions

-- Prepare the initial positions of the particles (this will take a while...)
local initPos = {}
local dx, dy, dz = 2/(nx-1), 2/(ny-1), 2/(nz-1)
-- We want to center the particles at (0,0,0)
local transf = translate(-1,-1,-1)
local p = vec4(0, 0, 0, 1)
for i=0, nx-1 do
   p.x = dx*i
   for j=0, ny-1 do
      p.y = dy*j
      for k=0, nz-1 do
         p.z = dz*k
         table.insert(initPos, transf*p)
      end
   end
end
initPos = gl.packf(initPos)

-- Prepare the initial velocities of the particles
local v0 = gl.packf(vec4(0, 0, 0, 0))
local initVel = string.rep(v0, nParticles)

-- Create and initialize the buffers for positions and velocities
local posBuf, velBuf = gl.gen_buffers(2)
gl.bind_buffer_base('shader storage', 0, posBuf)
gl.buffer_data('shader storage', initPos, 'dynamic draw')
gl.bind_buffer_base('shader storage', 1, velBuf)
gl.buffer_data('shader storage', initVel, 'dynamic copy')
-- Set up the VAO for the particles
local vao = gl.new_vertex_array()
gl.bind_buffer('array', posBuf)
gl.vertex_attrib_pointer(0, 4, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0)
gl.unbind_vertex_array()
-- Set up the VAO (and buffer) for the black holes
local bh_vao = gl.new_vertex_array()
local bh_vbo = gl.new_buffer('array')
local data = gl.packf({ bh1.x, bh1.y, bh1.z, bh1.w, bh2.x, bh2.y, bh2.z, bh2.w })
gl.buffer_data('array', data, 'dynamic draw')
gl.vertex_attrib_pointer(0, 4, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0)
gl.unbind_vertex_array()

-- Event loop -----------------------------------------------------------------

print("Press space to toggle animation on/off")

local model = mat4()
local view = glmath.look_at(vec3(2,0,20), vec3(0,0,0), vec3(0,1,0))
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

   -- Rotate the attractors ("black holes")
   local rot = rotate(rad(angle), 0,0,1)
   local att1 = vec3(rot*bh1)
   local att2 = vec3(rot*bh2)
   -- Execute the compute shader
   gl.use_program(prog1)
   gl.uniformf(loc1["BlackHolePos1"], att1)
   gl.uniformf(loc1["BlackHolePos2"], att2)
   gl.dispatch_compute(nParticles/1000, 1, 1)
   gl.memory_barrier('shader storage')

   -- Draw the scene
   -- gl.enable('depth test')
   gl.enable('blend')
   gl.blend_func('src alpha', 'one minus src alpha')
   gl.clear_color(1, 1, 1, 1)
   gl.use_program(prog)
   gl.clear('color', 'depth')
   set_matrices(model, view, projection)
   -- Draw the particles
   gl.point_size(1.0)
   gl.uniformf(loc["Color"], 0, 0, 0, 0.2)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('points',0, nParticles)
   gl.unbind_vertex_array()
   -- Draw the attractors
   gl.point_size(5.0)
   gl.bind_buffer('array', bh_vbo)
   gl.buffer_sub_data('array', 0, gl.packf({att1.x, att1.y, att1.z, 1, att2.x, att2.y, att2.z, 1}))
   gl.uniformf(loc["Color"], 1, 1, 0, 1)
   gl.bind_vertex_array(bh_vao)
   gl.draw_arrays('points', 0, 2)
   gl.unbind_vertex_array()

   glfw.swap_buffers(window)
end


