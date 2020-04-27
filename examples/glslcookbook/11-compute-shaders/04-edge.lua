#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local load_texture = require("common.texture").load_texture
local new_plane = require("common.plane")
local new_torus = require("common.torus")
local new_teapot = require("common.teapot")
local new_quad = require("common.quad")

local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad, sqrt = math.pi, math.rad, math.sqrt
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 11 - Edge detection filter using compute shader"
local W, H = 800, 600

-- GLFW/GL initializations
glfw.version_hint(4, 6, 'core')
glfw.window_hint('opengl forward compat', true)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local angle, speed = pi/4, pi/4 -- rad, rad/s
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
   vertex = "shaders/edge.vert",
   fragment = "shaders/edge.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, csh = gl.make_program({
   compute = "shaders/edge.comp",
})
gl.delete_shaders(csh)

-- Get the locations of the uniform variables
local uniforms = {
   "Light.Position",
   "Light.Intensity",
   "Material.Ka",
   "Material.Kd",
   "Material.Ks",
   "Material.Shininess",
   "EdgeTex",
   "ModelViewMatrix",
   "NormalMatrix",
   "MVP",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

local uniforms1 = {
   "EdgeThreshold",
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

local function set_material(ka, kd, ks, shininess)
   gl.uniformf(loc["Material.Ka"], ka)
   gl.uniformf(loc["Material.Kd"], kd)
   gl.uniformf(loc["Material.Ks"], ks)
   gl.uniformf(loc["Material.Shininess"], shininess)
end

-- Generate the meshes
local plane = new_plane(50.0, 50.0, 1, 1)
local teapot = new_teapot(14)
local torus = new_torus(0.7 * 1.5, 0.3 * 1.5, 50,50)
local quad = new_quad()

-- Set up the subroutine indexes
gl.use_program(prog)
local pass1 = gl.get_subroutine_index(prog, 'fragment', "pass1")
local pass2 = gl.get_subroutine_index(prog, 'fragment', "pass2")

gl.uniformf(loc["Light.Intensity"], 1.0, 1.0, 1.0)
gl.uniformf(loc["Light.Position"], 0.0, 0.0, 0.0, 1.0)

-- Set up the FBO
-- Generate and bind the framebuffer
local fbo = gl.new_framebuffer('draw read')
-- Create the texture object
local renderTex = gl.new_texture('2d')
gl.texture_storage('2d', 1, 'rgba8', W, H)
gl.bind_image_texture(0, renderTex, 0, false, 0, 'read write', 'rgba8')
gl.active_texture(0)  -- Use texture unit 0
local edgeTex = gl.new_texture('2d')
gl.texture_storage('2d', 1, 'rgba8', W, H)
gl.bind_image_texture(1, edgeTex, 0, false, 0, 'read write', 'rgba8')
-- Bind the texture to the FBO
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', renderTex, 0)
-- Create the depth buffer
local depthBuf = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', W, H)
-- Bind the depth buffer to the FBO
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', depthBuf)
-- Set the targets for the fragment output variables
gl.draw_buffers(1, {'color attachment 0'})
-- Unbind the framebuffer, and revert to default framebuffer
gl.unbind_framebuffer('draw read')

-- Event loop -----------------------------------------------------------------

print("Press space to toggle animation on/off")

local t0 = glfw.now()

gl.enable('depth test')
gl.clear_color(0, 0, 0, 1)

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

   -- Pass 1: draw the scene to fbo ----------------------------
   gl.use_program(prog)
   gl.bind_framebuffer('draw read', fbo)
   gl.clear('color', 'depth')
   gl.uniform_subroutines('fragment', pass1)
   local view = glmath.look_at(vec3(7*cos(angle), 4.0, 7*sin(angle)), vec3(0,0,0), vec3(0,1,0))

   set_material({0.1, 0.1, 0.1}, {0.9, 0.9, 0.9}, {0.95, 0.95, 0.95}, 100.0)
   local model = translate(0.0,0.0,0.0)*rotate(rad(-90), 1,0,0)
   set_matrices(model, view, projection)
   teapot:render()

   set_material({0.1, 0.1, 0.1}, {0.4, 0.4, 0.4}, {0, 0, 0}, 1.0)
   model = translate(0.0,-0.75,0.0)
   set_matrices(model, view, projection)
   plane:render()

   set_material({0.1, 0.1, 0.1}, {0.9, 0.5, 0.2}, {0.95, 0.95, 0.95}, 100.0)
   model = translate(1.0,1.0,3.0)*rotate(rad(90), 1, 0, 0)
   set_matrices(model, view, projection)
   torus:render()

   -- Compute pass: detect the edges ---------------------------
   gl.use_program(prog1)
   gl.dispatch_compute(W/25, H/25, 1)
   gl.memory_barrier('shader image access')

   -- Pass 2: draw edges ---------------------------------------
   gl.use_program(prog)
   gl.bind_framebuffer('draw read', 0)
   gl.clear('color', 'depth')
   gl.uniform_subroutines('fragment', pass2)
   set_matrices(mat4(), mat4(), mat4())
   -- Render the full-screen quad
   quad:render()

   glfw.swap_buffers(window)
end

