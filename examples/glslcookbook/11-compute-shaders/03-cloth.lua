#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local load_texture = require("common.texture").load_texture

local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad, sqrt = math.pi, math.rad, math.sqrt
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 11 - Cloth simulation using compute shader"
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
   projection = glmath.perspective(rad(50.0), w/h, .1, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader programs
local prog, vsh, fsh = gl.make_program({
   vertex = "shaders/ads.vert",
   fragment = "shaders/ads.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, csh = gl.make_program({
   compute = "shaders/cloth.comp",
})
gl.delete_shaders(csh)
local prog2, csh = gl.make_program({
   compute = "shaders/cloth_normal.comp",
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

local uniforms1 = {
   "Gravity",
   "ParticleMass",
   "ParticleInvMass",
   "SpringK",
   "RestLengthHoriz",
   "RestLengthVert",
   "RestLengthDiag",
   "DeltaT",
   "DampingConst",
}

local loc1 = {}
for _,name in ipairs(uniforms1) do loc1[name] = gl.get_uniform_location(prog1, name) end

-- prog2 has no uniform variables

-- Initialize the uniform variables
resize(window, W, H) -- creates projection

local function set_matrices(model, view, projection)
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end


local clothSize = vec2(4.0, 3.0)
local nx, ny = 40, 40 -- compute space size
local nParticles = nx*ny
local dx, dy = clothSize.x/(nx-1), clothSize.y/(ny-1) -- distance between neighbors
local wgx, wgy = nx/10, ny/10 -- no of workgroups in each dimension
local delta_t = 0.000005 -- fixed time interval used in physics updates

gl.use_program(prog)
gl.uniformf(loc["LightPosition"], 0.0, 0.0, 0.0, 1.0)
gl.uniformf(loc["LightIntensity"], 1.0, 1.0, 1.0)
gl.uniformf(loc["Ka"], 0.2, 0.2, 0.2)
gl.uniformf(loc["Kd"], 0.8, 0.8, 0.8)
gl.uniformf(loc["Ks"], 0.2, 0.2, 0.2)
gl.uniformf(loc["Shininess"], 80.0)
gl.use_program(prog1)
gl.uniformf(loc1["DeltaT"], delta_t)
gl.uniformf(loc1["RestLengthHoriz"], dx)
gl.uniformf(loc1["RestLengthVert"], dy)
gl.uniformf(loc1["RestLengthDiag"], sqrt(dx*dx+dy*dy))

gl.active_texture(0)
local texid = load_texture("../media/texture/me_textile.png")
gl.bind_texture_unit(0, texid)
gl.use_program(prog)
gl.uniformi(loc["Tex"], 0)

-- Prepare the initial positions and texcoords of the particles
local initPos, initTc = {}, {}
local transf = translate(0,clothSize.y,0)*rotate(rad(-80.0), 1,0,0)*translate(0,-clothSize.y, 0)
local ds, dt = 1/(nx-1), 1/(ny-1)
local p = vec4(0, 0, 0, 1)
local tc = vec2(0, 0)
local s, t
for j = 0, ny-1 do
   p.y = dy*j
   t = dt*j
   for i = 0, nx-1 do
      p.x = dx*i
      s = ds*i
      table.insert(initPos, transf*p)
      table.insert(initTc, vec2(s, t))
   end
end
initPos = gl.packf(initPos)
initTc = gl.packf(initTc)

-- Prepare the element indices
local restart_index= 0xffffff
local indices = {}
for row=0, ny-2 do -- every row is one triangle strip
   for col=0, nx-1 do
      table.insert(indices, (row+1)*nx+col)
      table.insert(indices, (row  )*nx+col)
   end
   table.insert(indices, restart_index)
end
local count = #indices
indices = gl.packui(indices)
gl.enable('primitive restart')
gl.primitive_restart_index(restart_index)

-- Prepare the initial velocities of the particles
local v0 = gl.packf(vec4(0, 0, 0, 0))
local initVel = string.rep(v0, nParticles)

-- Set up buffers and the SSBOs
local A, B = 1, 2
local bufsz = nParticles*4*gl.sizeof('float')
-- The buffers for positions
local posBufs = {gl.gen_buffers(2)}
gl.bind_buffer_base('shader storage', 0, posBufs[A])
gl.buffer_data('shader storage', initPos, 'dynamic draw')
gl.bind_buffer_base('shader storage', 1, posBufs[B])
gl.buffer_data('shader storage', bufsz, 'dynamic draw')
-- Velocities
local velBufs = {gl.gen_buffers(2)}
gl.bind_buffer_base('shader storage', 2, velBufs[A])
gl.buffer_data('shader storage', initVel, 'dynamic copy')
gl.bind_buffer_base('shader storage', 3, velBufs[B])
gl.buffer_data('shader storage', bufsz, 'dynamic copy')
-- Normal buffer
local normBuf = gl.gen_buffers(1)
gl.bind_buffer_base('shader storage', 4, normBuf)
gl.buffer_data('shader storage', bufsz, 'dynamic copy')
-- Element indices
local elBuf = gl.gen_buffers(1)
gl.bind_buffer('element array', elBuf)
gl.buffer_data('element array', indices, 'dynamic copy')
-- Texture coordinates
local tcBuf = gl.gen_buffers(1)
gl.bind_buffer('array', tcBuf)
gl.buffer_data('array', initTc, 'static draw')

-- Set up the VAOs
local clothVao = {gl.gen_vertex_arrays(2)}
for i = 1, 2 do
   gl.bind_vertex_array(clothVao[i]) -- i = A or B
   gl.bind_buffer('array', posBufs[i])
   gl.vertex_attrib_pointer(0, 4, 'float', false, 0, 0)
   gl.enable_vertex_attrib_array(0)
   gl.bind_buffer('array', normBuf)
   gl.vertex_attrib_pointer(1, 4, 'float', false, 0, 0)
   gl.enable_vertex_attrib_array(1)
   gl.bind_buffer('array', tcBuf)
   gl.vertex_attrib_pointer(2, 2, 'float', false, 0, 0)
   gl.enable_vertex_attrib_array(2)
   gl.bind_buffer('element array', elBuf)
   gl.unbind_vertex_array(0)
end

-- Event loop -----------------------------------------------------------------

print("Press space to toggle animation on/off")

local model = mat4()
local view = glmath.look_at(vec3(3,2,5), vec3(2,1,0), vec3(0,1,0))
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

   gl.use_program(prog1)
   for i=1, 1000 do 
      gl.dispatch_compute(wgx, wgy, 1)
      gl.memory_barrier('shader storage')
      -- Swap buffers
      A, B = B, A
      gl.bind_buffer_base('shader storage', 0, posBufs[A])
      gl.bind_buffer_base('shader storage', 1, posBufs[B])
      gl.bind_buffer_base('shader storage', 2, velBufs[A])
      gl.bind_buffer_base('shader storage', 3, velBufs[B])
   end

   -- Compute the normals
   gl.use_program(prog2)
   gl.dispatch_compute(wgx, wgy, 1)
   gl.memory_barrier('shader storage')

   -- Draw the scene
   gl.use_program(prog)
   gl.clear_color(.5, .5, .5, 1)
   gl.clear('color', 'depth')
   set_matrices(model, view, projection)
   gl.bind_vertex_array(clothVao[A])
   gl.draw_elements('triangle strip', count, 'uint', 0)
   gl.unbind_vertex_array()

   glfw.swap_buffers(window)
end

