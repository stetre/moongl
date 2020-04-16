#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local new_objmesh = require("common.objmesh")
local load_texture = require("common.texture").load_texture

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 8 - Ambient occlusion from a texture"
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

local projection = mat4()
local function resize(window, w, h)
   W, H = w, h
   gl.viewport(0, 0, w, h)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program({vertex="shaders/ao.vert", 
                                       fragment="shaders/ao.frag"})
gl.delete_shaders(vsh, fsh)

-- Get the locations of the uniform variables
local uniforms = {
   "Light.Position",
   "Light.Intensity",
   "AOTex",
   "DiffTex",
   "ModelViewMatrix",
   "NormalMatrix",
   "MVP",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

-- Initialize the uniform variables
resize(window, W, H)

local function set_matrices(model, view, projection)
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
end

gl.use_program(prog)
gl.uniformf(loc["Light.Position"], 0.0, 0.0, 0.0, 1.0) -- camera coords
gl.uniformf(loc["Light.Intensity"], 1.0, 1.0, 1.0)

-- Generate the meshes
local mesh = new_objmesh("../media/bs_ears.obj", {add_tangents=true})

-- Create the textures

gl.active_texture(0)
local tex0 = load_texture("../media/texture/ao_ears.png")
gl.uniformi(loc["AOTex"], 0)
gl.bind_texture_unit(0, tex0)

gl.active_texture(1)
local tex1 = load_texture("../media/texture/ogre_diffuse.png")
gl.uniformi(loc["DiffTex"], 1)
gl.bind_texture_unit(1, tex1)

-- Event loop -----------------------------------------------------------------

gl.enable('depth test')
gl.clear_color(.5, .5, .5, 1)

local c = 2.25
local projection = glmath.ortho(-0.4*c, 0.4*c, -0.3*c, 0.3*c, 0.1, 100.0)
local model = mat4()

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

   gl.use_program(prog)
   gl.clear('color', 'depth')
   local view = glmath.look_at(vec3(3*cos(angle), 0, 3*sin(angle)), vec3(0, 0, 0), vec3(0, 1, 0))
   set_matrices(model, view, projection)
   mesh:render()
   gl.finish()

   glfw.swap_buffers(window)
end

