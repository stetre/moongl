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

local TITLE = "Chapter 10 - Particle system with dynamic model (using transform feedback)"
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


-- Create the shader programs -------------------------------------------
-- Note that here we cannot use the make_program() utility for the transform
-- feedback program, because we must specify the xfb variables before linking.
local function readsource(filename)
   local file = assert(io.open(filename, 'r'))
   local s = file:read('a')
   file:close()
   return s
end
local prog = gl.create_program()
local vsh = gl.create_shader('vertex')
gl.shader_source(vsh, readsource("shaders/transfeedback.vert"))
gl.compile_shader(vsh, true)
gl.attach_shader(prog, vsh)
local fsh = gl.create_shader('fragment')
gl.shader_source(fsh, readsource("shaders/transfeedback.frag"))
gl.compile_shader(fsh, true)
gl.attach_shader(prog, fsh)
-- Specify the transform feedback variables (must be done before linking the program)
gl.transform_feedback_varyings(prog, 'separate attribs', "Position", "Velocity", "Age")
gl.link_program(prog, true)
gl.delete_shaders(vsh, fsh)
-- Here we can use make_program() ...
local prog1, vsh, fsh = gl.make_program('vertex', "shaders/flat.vert",
                                       'fragment', "shaders/flat.frag")
gl.delete_shaders(vsh, fsh)


-- Get the locations of the uniform variables
local uniforms = {
   "Pass",
   "DeltaT",
   "Accel",
   "RandomTex",
   "ParticleTex",
   "ParticleSize",
   "ParticleLifetime",
   "Emitter",
   "EmitterBasis",
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

local particleLifetime = 6.0
local nParticles = 4000
local emitterPos = vec3(1, 0, 0)
local emitterDir = vec3(-1, 2, 0)

-- Load the particle texture
gl.active_texture(0)
local texid = texture.load_texture("../media/texture/bluewater.png")
gl.bind_texture_unit(0, texid)
-- Load the random texture
gl.active_texture(1)
local texid = texture.random_1d(nParticles*3)
gl.bind_texture_unit(1, texid)

gl.use_program(prog)
gl.uniformi(loc["ParticleTex"], 0)
gl.uniformi(loc["RandomTex"], 1)
gl.uniformf(loc["ParticleLifetime"], particleLifetime)
gl.uniformf(loc["ParticleSize"], 0.05)
gl.uniformf(loc["Accel"], 0.0, -0.5, 0.0)
gl.uniformf(loc["Emitter"], emitterPos)
gl.uniform_matrix3f(loc["EmitterBasis"], true, arbitrary_basis(emitterDir))

gl.use_program(prog1)
gl.uniformf(loc1["Color"], 0.3, 0.3, 0.3, 1.0)

-- Generate the buffers for initial velocity and start (birth) time ---------------

-- Generate the initial start times
local rate = particleLifetime/nParticles
local tdata = {}
for i = 1, nParticles do
   table.insert(tdata, rate*(i-1-nParticles))
end

-- Generate the buffers
local posBuf = {gl.gen_buffers(2)} -- position buffers
local velBuf = {gl.gen_buffers(2)} -- velocity buffers
local ageBuf = {gl.gen_buffers(2)} -- age buffers

local A, B = 1, 2
-- Allocate space for all buffers
local size = nParticles*3*gl.sizeof('float')
gl.bind_buffer('array', posBuf[A])
gl.buffer_data('array', size, 'dynamic copy')
gl.bind_buffer('array', posBuf[B])
gl.buffer_data('array', size, 'dynamic copy')
gl.bind_buffer('array', velBuf[A])
gl.buffer_data('array', size, 'dynamic copy')
gl.bind_buffer('array', velBuf[B])
gl.buffer_data('array', size, 'dynamic copy')
gl.bind_buffer('array', ageBuf[A])
gl.buffer_data('array', size/3, 'dynamic copy')
gl.bind_buffer('array', ageBuf[B])
gl.buffer_data('array', size/3, 'dynamic copy')

gl.bind_buffer('array', ageBuf[A])
gl.buffer_sub_data('array', 0, gl.packf(tdata))
gl.unbind_buffer('array')
tdata = nil

-- Create vertex arrays for each set of buffers
local vao = {gl.gen_vertex_arrays(2)}
-- Set up vao 1
gl.bind_vertex_array(vao[A])
gl.bind_buffer('array', posBuf[A])
gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0)
gl.bind_buffer('array', velBuf[A])
gl.vertex_attrib_pointer(1, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(1)
gl.bind_buffer('array', ageBuf[A])
gl.vertex_attrib_pointer(2, 1, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(2)
-- Set up vao 2
gl.bind_vertex_array(vao[B])
gl.bind_buffer('array', posBuf[B])
gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0)
gl.bind_buffer('array', velBuf[B])
gl.vertex_attrib_pointer(1, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(1)
gl.bind_buffer('array', ageBuf[B])
gl.vertex_attrib_pointer(2, 1, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(2)
gl.unbind_vertex_array()

-- Setup the trabnsform feedback objects
local xfbo = {gl.gen_transform_feedbacks(2)}
-- Transform feedback 0
gl.bind_transform_feedback('transform feedback', xfbo[A])
gl.bind_buffer_base('transform feedback', 0, posBuf[A])
gl.bind_buffer_base('transform feedback', 1, velBuf[A])
gl.bind_buffer_base('transform feedback', 2, ageBuf[A])
-- Transform feedback 1
gl.bind_transform_feedback('transform feedback', xfbo[B])
gl.bind_buffer_base('transform feedback', 0, posBuf[B])
gl.bind_buffer_base('transform feedback', 1, velBuf[B])
gl.bind_buffer_base('transform feedback', 2, ageBuf[B])
gl.unbind_transform_feedback('transform feedback')

-- Event loop -----------------------------------------------------------------

local model = mat4()
local view = glmath.look_at(vec3(4.0*cos(angle),1.5,4.0*sin(angle)), vec3(0,1.5,0), vec3(0,1,0))

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

   gl.enable('blend')
   gl.blend_func('src alpha', 'one minus src alpha')
   gl.enable('depth test')
   gl.clear_color(.1, .1, .1, 1)
   gl.clear('color', 'depth')

   gl.use_program(prog1)
   gl.uniform_matrix4f(loc1["MV"], true, view*model)
   gl.uniform_matrix4f(loc1["Proj"], true, projection)
   grid:render()

   gl.use_program(prog)
   gl.uniformf(loc["DeltaT"], animate and dt or 0)

   -- Update pass
   gl.uniformi(loc["Pass"], 1)
   gl.enable('rasterizer discard')
   gl.bind_transform_feedback('transform feedback', xfbo[B])
   gl.begin_transform_feedback('points')
   gl.bind_vertex_array(vao[A])
   gl.vertex_attrib_divisor(0,0)
   gl.vertex_attrib_divisor(1,0)
   gl.vertex_attrib_divisor(2,0)
   gl.draw_arrays('points', 0, nParticles)
   gl.unbind_vertex_array()
   gl.end_transform_feedback()
   gl.disable('rasterizer discard')

    -- Render pass
   gl.uniformi(loc["Pass"], 2)
   gl.uniform_matrix4f(loc["MV"], true, view*model)
   gl.uniform_matrix4f(loc["Proj"], true, projection)

   gl.depth_mask(false)
   gl.bind_vertex_array(vao[B])
   gl.vertex_attrib_divisor(0,1)
   gl.vertex_attrib_divisor(1,1)
   gl.vertex_attrib_divisor(2,1)
   gl.draw_arrays('triangles', 0, 6, nParticles)
   gl.unbind_vertex_array()
   gl.depth_mask(true)

   -- Swap buffers
   A, B = B, A

   glfw.swap_buffers(window)
end

