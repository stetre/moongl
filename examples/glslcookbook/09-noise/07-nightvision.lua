#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local new_plane = require("common.plane")
local new_torus = require("common.torus")
local new_teapot = require("common.teapot")
local new_quad = require("common.quad")
local texture = require("common.texture")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 9 - Night vision effect"
local W, H = 800, 600

-- GLFW/GL initializations
glfw.version_hint(4, 6, 'core')
glfw.window_hint('opengl forward compat', true)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local angle, speed = pi/4, pi/8 -- rad, rad/s
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
   projection = glmath.perspective(rad(60.0), w/h, 0.3, 100.0)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program('vertex', "shaders/nightvision.vert",
                                       'fragment', "shaders/nightvision.frag")
gl.delete_shaders(vsh, fsh)
gl.use_program(prog)

-- Get the locations of the uniform variables
local uniforms = {
   "Width",
   "Height",
   "Radius",
   "Light.Intensity",
   "Light.Position",
   "Material.Ka",
   "Material.Kd",
   "Material.Ks",
   "Material.Shininess",
   "ModelViewMatrix",
   "NormalMatrix",
   "MVP",
   "RenderTex",
   "NoiseTex",
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


-- Generate the meshes
local plane = new_plane(50, 50, 1, 1)
local teapot = new_teapot(14)
local torus = new_torus(0.7*1.5, 0.3*1.5, 50,50)
local quad = new_quad()

-- Setup the fbo ----------------------------
local fbo = gl.new_framebuffer('draw read')
-- Create the texture object
local render_tex = gl.new_texture('2d')
gl.texture_storage('2d', 1, 'rgba8', W, H)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
-- Bind the texture to the FBO
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', render_tex, 0)
-- Create the depth buffer
local depthBuf = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', W, H)
-- Bind the depth buffer to the FBO
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', depthBuf);
-- Set the targets for the fragment output variables
gl.draw_buffers('color attachment 0')
-- Unbind the framebuffer, and revert to default framebuffer
gl.unbind_framebuffer('draw read')

-- Create the noise texture
local noise_tex = texture.noise_2d_periodic(200.0, 0.5, 512, 512)
gl.active_texture(1)
gl.bind_texture('2d', noise_tex)
gl.use_program(prog)
gl.uniformi(loc["RenderTex"], 0)
gl.uniformi(loc["NoiseTex"], 1)

-- Get the subroutine indexes
local pass1 = gl.get_subroutine_index(prog, 'fragment', "pass1")
local pass2 = gl.get_subroutine_index(prog, 'fragment', "pass2")

gl.uniformi(loc["Width"], W)
gl.uniformi(loc["Height"], H)
gl.uniformf(loc["Radius"], W/3.5)
gl.uniformf(loc["Light.Intensity"], 1.0,1.0,1.0)
gl.uniformf(loc["Light.Position"], 0.0,0.0,0.0,1.0)

-- Event loop -----------------------------------------------------------------

print("Press space to toggle animation on/off")

local model
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

   -- Pass 1 ---------------------------------------------
   gl.bind_framebuffer('draw read', fbo)
   gl.clear('color', 'depth')
   gl.enable('depth test')
   gl.uniform_subroutines('fragment', pass1)

   local view = glmath.look_at(vec3(7*cos(angle),4.0,7*sin(angle)), vec3(0,0,0), vec3(0,1,0))

   set_material(vec3(0.1, 0.1, 0.1), vec3(0.9, 0.9, 0.9), vec3(0.95, 0.95, 0.95), 100.0)
   local model = translate(0.0,0.0,0.0)*rotate(rad(-90), 1,0,0)
   set_matrices(model, view, projection)
   teapot:render()

   set_material(vec3(0.1, 0.1, 0.1), vec3(0.4, 0.4, 0.4), vec3(0, 0, 0), 1.0)
   model = translate(0.0,-0.75,0.0)
   set_matrices(model, view, projection)
   plane:render()

   set_material(vec3(0.1, 0.1, 0.1), vec3(0.9, 0.5, 0.2), vec3(0.95, 0.95, 0.95), 100.0)
   model = translate(1.0,1.0,3.0)*rotate(rad(90), 1,0,0)
   set_matrices(model, view, projection)
   torus:render()

   gl.flush()

   -- Pass 2 ---------------------------------------------
   gl.unbind_framebuffer('draw read')
   gl.active_texture(0)
   gl.bind_texture('2d', render_tex)
   gl.disable('depth test')
   gl.clear('color')
   gl.uniform_subroutines('fragment', pass2)
   set_matrices(mat4(), mat4(), mat4())
   -- Render the full-screen quad
   quad:render()

   glfw.swap_buffers(window)
end

