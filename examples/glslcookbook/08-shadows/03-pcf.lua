#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local mi = require("moonimage")
local new_plane = require("common.plane")
local new_objmesh = require("common.objmesh")
local new_frustum = require("common.frustum")

local vec3, vec4 = glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log = math.exp, math.log
local fmt = string.format

local TITLE = "Chapter 8 - Blur shadow map edges using percentage-closer-filtering"
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

local projection = mat4()
local function resize(window, w, h)
   W, H = w, h
   gl.viewport(0, 0, w, h)
end

glfw.set_window_size_callback(window, resize)

-- Create the shader program
local prog, vsh, fsh = gl.make_program({vertex="shaders/pcf.vert", 
                                       fragment="shaders/pcf.frag"})
gl.delete_shaders(vsh, fsh)

gl.use_program(prog)
local pass1 = gl.get_subroutine_index(prog, 'fragment', "recordDepth")
local pass2 = gl.get_subroutine_index(prog, 'fragment', "shadeWithShadow")

-- Get the locations of the uniform variables
local uniforms = {
   "Light.Position",
   "Light.Intensity",
   "Material.Kd",
   "Material.Ks",
   "Material.Ka",
   "Material.Shininess",
   "ModelViewMatrix",
   "NormalMatrix",
   "ShadowMatrix",
   "ShadowMap",
   "MVP",
}

local loc = {}
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

-- Initialize the uniform variables
resize(window, W, H)

local lightPV
local function set_matrices(model, view, projection)
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   gl.uniform_matrix4f(loc["MVP"], true, projection * mv)
   gl.uniform_matrix4f(loc["ShadowMatrix"], true, lightPV * model)
end

local function set_material(ka, kd, ks, shininess)
   gl.uniformf(loc["Material.Ka"], ka)
   gl.uniformf(loc["Material.Ks"], ks)
   gl.uniformf(loc["Material.Kd"], kd)
   gl.uniformf(loc["Material.Shininess"], shininess)
end


gl.uniformf(loc["Light.Intensity"], .85, .85, .85)
gl.uniformi(loc["ShadowMap"], 0)

-- Generate the meshes
local plane = new_plane(20, 20, 1, 1)
local mesh = new_objmesh("../media/building.obj")
local frustum = new_frustum()

local shadowBias = mat4(.5, 0, 0, .5,
                         0,.5, 0, .5,
                         0, 0,.5, .5,
                         0, 0, 0,  1)
local lightPos = vec3(-2.5, 2.0, -2.5)  -- World coords
frustum:orient(lightPos, vec3(0,0,0), vec3(0,1,0))
frustum:set_perspective(40.0, 1.0, 0.1, 100.0)
lightPV = shadowBias*frustum:projection()*frustum:view()

-- Setup the fbo ----------------------------
local shadowmap_width, shadowmap_height = 512, 512
-- The depth buffer texture
local depthTex = gl.new_texture('2d')
gl.texture_storage('2d', 1, 'depth component24', shadowmap_width, shadowmap_height)
gl.texture_parameter('2d', 'mag filter', 'linear')
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'wrap s', 'clamp to border')
gl.texture_parameter('2d', 'wrap t', 'clamp to border')
gl.texture_parameter('2d', 'border color', {1.0, 0.0, 0.0, 0.0})
gl.texture_parameter('2d', 'compare mode', 'compare ref to texture')
gl.texture_parameter('2d', 'compare func', 'less')
-- assign the depth buffer texture to texture unit 0
gl.active_texture(0)
gl.bind_texture('2d', depthTex)
-- Create and set up the FBO
local shadowFBO = gl.new_framebuffer('draw read')
gl.framebuffer_texture_2d('draw read', 'depth attachment', '2d', depthTex, 0)
gl.draw_buffers({'none'})
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer is not complete.\n")
gl.unbind_framebuffer('draw read')

local function print_shadow_map()
-- Retrieves the shadow map from the depth buffer and prints it to a png file.
   local w, h = shadowmap_width, shadowmap_height
   local nbytes = w*h*4*gl.sizeof('float')
   local data = gl.get_texture_image('2d', 0, 'depth component', 'float', nbytes)
--[[ easiest way:
   data = mi.reduce_to_u8(data, w, h, 'rgba', 'f')
   mi.write_png("shadowmap.png", w, h, 'rgba', data)
--]]
---[[ prettier way:
   local data = gl.unpack('float', data)
   local bytes = {}
   for i= 0, h-1 do
      for j = 0, w-1 do
         local imgIdx = 4*(i*w + j)
         local bufIdx = (h-i-1)*w + j + 1
         -- This is just to make a more visible image. Scale so that
         -- the range (minVal, 1.0) maps to (0.0, 1.0).  This probably should
         -- be tweaked for different light configurations.
         local minVal = 0.88
         local scale = (data[bufIdx] - minVal)/(1.0 - minVal)
         local val = math.floor(scale * 255)
         table.insert(bytes, {val, val, val, 255})
      end
   end
   local data = gl.pack('ubyte', bytes)
   mi.write_png("shadowmap.png", w, h, 'rgba', data)
--]]
end

-- Event loop -----------------------------------------------------------------

local function draw_scene(view, projection)
   local model = mat4()
   set_matrices(model, view, projection)

   local color = vec3(1.0,0.85,0.55);
   set_material(color*0.1, color, vec3(0,0,0), 1.0)
   mesh:render()

   set_material(vec3(.05, .05, .05), vec3(.25, .25, .25), vec3(0, 0, 0), 1.0)
   plane:render()
end

print("Press space to toggle animation on/off")

local first_iteration = true
local t0 = glfw.now()

angle = 2*pi*0.85

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

   -- Render (pass 1) --------------------------------------
   gl.enable('depth test')
   gl.clear_color(.5, .5, .5, 1)

   gl.use_program(prog)
   -- Pass 1 (shadow map generation)
   gl.bind_framebuffer('draw read', shadowFBO)
   gl.clear('depth')
   gl.viewport(0,0,shadowmap_width,shadowmap_height)
   gl.enable('cull face')
   gl.cull_face('front')
   gl.enable('polygon offset fill')
   gl.polygon_offset(2.5,10.0)
   gl.uniform_subroutines('fragment', pass1)
   draw_scene(frustum:view(), frustum:projection())
   gl.cull_face('back')
   gl.disable('polygon offset fill')
   gl.flush()

   if first_iteration then
      -- print_shadow_map()
      first_iteration = false
   end

   -- Pass 2 (render)
   local cameraPos = vec3(1.8*cos(angle), 0.7, 1.8*sin(angle))
   local view = glmath.look_at(cameraPos, vec3(0,-0.175, 0), vec3(0, 1, 0))
   local light_pos = vec4(frustum:origin())
   light_pos.w = 1
   gl.uniformf(loc["Light.Position"], view*light_pos)
   projection = glmath.perspective(rad(50.0), W/H, 0.1, 100.0)
   gl.unbind_framebuffer('draw read')
   gl.clear('color', 'depth')
   gl.viewport(0,0,W,H)
   gl.uniform_subroutines('fragment', pass2)
   draw_scene(view, projection)

   glfw.swap_buffers(window)
end

