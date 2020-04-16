#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local load_texture = require("common.texture").load_texture
local new_plane = require("common.plane")
local new_objmesh = require("common.objmesh")

local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local pi, rad = math.pi, math.rad
local sin, cos = math.sin, math.cos
local exp, log, sqrt = math.exp, math.log, math.sqrt
local fmt = string.format

local TITLE = "Chapter 8 - Shadow Volumes using geometry shader"
local W, H = 800, 600

-- GLFW/GL initializations
glfw.version_hint(4, 6, 'core')
glfw.window_hint('opengl forward compat', true)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local angle, speed = 0, pi/8 -- rad, rad/s
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

-- The shader for the volumes
local prog1, vsh, gsh, fsh = gl.make_program({
         vertex="shaders/shadowvolume-vol.vert", 
         geometry="shaders/shadowvolume-vol.geom",
         fragment="shaders/shadowvolume-vol.frag",
      })
gl.delete_shaders(vsh, gsh, fsh)
-- The shader for rendering and compositing
local prog2, vsh, fsh = gl.make_program({
         vertex="shaders/shadowvolume-render.vert", 
         fragment="shaders/shadowvolume-render.frag",
      })
gl.delete_shaders(vsh, fsh)
-- The final composite shader
local prog3, vsh, fsh = gl.make_program({
         vertex="shaders/shadowvolume-comp.vert", 
         fragment="shaders/shadowvolume-comp.frag",
      })
gl.delete_shaders(vsh, fsh)

-- Get the locations of the uniform variables
local uniforms1 = {
   "ModelViewMatrix",
-- "NormalMatrix", -- pruned out
   "ProjMatrix",
   "LightPosition",
}

local uniforms2 = {
   "ModelViewMatrix",
   "ProjMatrix",
   "NormalMatrix",
   "LightPosition",
   "LightIntensity",
   "Kd",
   "Ks",
   "Ka",
   "Shininess",
   "Tex",
}

local uniforms3 = {
   "ModelViewMatrix",
   "ProjMatrix",
   "DiffSpecTex",
}

local loc1 = {}
for _,name in ipairs(uniforms1) do loc1[name] = gl.get_uniform_location(prog1, name) end
local loc2 = {}
for _,name in ipairs(uniforms2) do loc2[name] = gl.get_uniform_location(prog2, name) end
local loc3 = {}
for _,name in ipairs(uniforms3) do loc3[name] = gl.get_uniform_location(prog3, name) end
local locs = {} -- prog->loc map
locs[prog1]=loc1
locs[prog2]=loc2
locs[prog3]=loc3

-- Initialize the uniform variables
resize(window, W, H)

local function set_matrices(prog, model, view, projection)
   local loc = locs[prog]
   local mv = view * model
   local normal_mv = mat3(mv):inv():transpose()
   gl.uniform_matrix4f(loc["ModelViewMatrix"], true, mv)
   gl.uniform_matrix4f(loc["ProjMatrix"], true, projection)
   if loc["NormalMatrix"] then
      gl.uniform_matrix3f(loc["NormalMatrix"], true, normal_mv)
   end
end

local function set_material(ka, kd, ks, shininess)
   gl.uniformf(loc2["Ka"], ka)
   gl.uniformf(loc2["Ks"], ks)
   gl.uniformf(loc2["Kd"], kd)
   gl.uniformf(loc2["Shininess"], shininess)
end

gl.use_program(prog2)
gl.uniformf(loc2["LightIntensity"], 1.0, 1.0, 1.0)

-- Generate the meshes
local plane = new_plane(10, 10, 2, 2, 5, 5)
local spot = new_objmesh("../media/spot/spot_triangulated.obj", {adjacency=true})

-- Set up a  VAO for the full-screen quad
local verts = gl.packf({ -1.0, -1.0, 0.0, 1.0, -1.0, 0.0,  1.0, 1.0, 0.0, -1.0, 1.0, 0.0 })
local quad_vao = gl.new_vertex_array()
local quad_vbo = gl.new_buffer('array')
gl.buffer_data('array', verts, 'static draw')
gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
gl.enable_vertex_attrib_array(0)  -- Vertex position
gl.unbind_vertex_array()

-- Setup the fbo ----------------------------
-- The FBO has one texture for the diffuse + specular components.
-- The depth buffer
local depthBuf = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', W, H)
-- The ambient buffer
local ambBuf = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'rgba', W, H)
-- The diffuse+specular component
gl.active_texture(0)
local diffSpecTex = gl.new_texture('2d')
gl.texture_storage('2d', 1, 'rgba8', W, H)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
-- Create and set up the FBO
local colorDepthFBO = gl.new_framebuffer('draw read')
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', depthBuf)
gl.framebuffer_renderbuffer('draw read', 'color attachment 0', 'renderbuffer', ambBuf)
gl.framebuffer_texture_2d('draw read', 'color attachment 1', '2d', diffSpecTex, 0)
gl.draw_buffers({'color attachment 0', 'color attachment 1'})
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer is not complete.\n")
gl.unbind_framebuffer('draw read')

--Load textures
gl.active_texture(2)
local spotTex = load_texture("../media/spot/spot_texture.png")
local brickTex = load_texture("../media/texture/brick1.jpg")
gl.use_program(prog2)
gl.uniformi(loc2["Tex"], 2)
gl.use_program(prog3)
gl.uniformi(loc3["DiffSpecTex"], 0)


-- Event loop -----------------------------------------------------------------

local lightPos

local function draw_scene(prog, view, projection)
   if prog == prog2 then
      gl.active_texture(2)
      gl.bind_texture('2d', spotTex)
      local color = vec3(1.0, 1.0, 1.0)
      set_material(color*0.1, color, vec3(.9, .9, .9), 150.0)
   end
   local model
   model = translate(-2.3,1.0,0.2)*rotate(rad(180.0),0,1,0)*scale(1.5)
   set_matrices(prog, model, view, projection)
   spot:render()

   model = translate(2.5,1.0,-1.2)*rotate(rad(180.0),0,1,0)*scale(1.5)
   set_matrices(prog, model, view, projection)
   spot:render()

   model = translate(0.5,1.0,2.7)*rotate(rad(180.0),0,1,0)*scale(1.5)
   set_matrices(prog, model, view, projection)
   spot:render()

   if prog == prog2 then
      gl.active_texture(2)
      gl.bind_texture('2d', brickTex)
      local color = vec3(.5, .5, .5)
      set_material(vec3(.1, .1, .1), color, vec3(0, 0, 0), 1.0)
      model = mat4()
      set_matrices(prog, model, view, projection)
      plane.render()
      model = translate(-5.0,5.0,0.0)*rotate(rad(90.0),1,0,0)*rotate(rad(-90.0),0,0,1)
      set_matrices(prog, model, view, projection)
      plane.render()
      model = translate(0.0,5.0,-5.0)*rotate(rad(90.0),1,0,0)
      set_matrices(prog, model, view, projection)
      plane.render()
   end
end

print("Press space to toggle animation on/off")

local t0 = glfw.now()

gl.enable('depth test')
gl.clear_color(.5, .5, .5, 1)
gl.clear_stencil(0)

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
   if animate or not lightPos then
      lightPos = vec4(5*cos(angle)*7.5, 5*1.5, 5*sin(angle)*7.5, 1.0)  -- World coords
   end

   -- Pass1 -------------------------------------------------------------------
   -- Just renders the geometry normally with shading. 
   -- The ambient component is rendered to one buffer, and the diffuse and specular
   -- components are written to a texture.
   gl.depth_mask(true)
   gl.disable('stencil test')
   gl.enable('depth test')
   local projection = glmath.perspective(rad(50.0), W/H, 0.5, 1000000) -- infinite perspective
   local view = glmath.look_at(vec3(5.0, 5.0, 5.0), vec3(0,2,0), vec3(0,1,0))
   gl.use_program(prog2)
   gl.uniformf(loc2["LightPosition"], view * lightPos)
   gl.bind_framebuffer('draw read', colorDepthFBO)
   gl.clear('depth', 'color')
   draw_scene(prog2, view, projection)
   gl.flush()

   -- Pass2 -------------------------------------------------------------------
   -- This is the pass that generates the shadow volumes using the geometry shader
   gl.use_program(prog1)
   gl.uniformf(loc1["LightPosition"], view * lightPos)

   -- Copy the depth and color buffers from the FBO into the default FBO
   -- The color buffer should contain the ambient component.
   gl.bind_framebuffer('read', colorDepthFBO)
   gl.unbind_framebuffer('draw')
   gl.blit_framebuffer(0,0,W-1,H-1,0,0,W-1,H-1, 'nearest', 'depth', 'color')
   -- Disable writing to the color buffer and depth buffer
   gl.color_mask(false, false, false, false)
   gl.depth_mask(false)

   -- Re-bind to the default framebuffer
   gl.unbind_framebuffer('draw read')

   -- Set up the stencil test so that it always succeeds, increments for front faces,
   -- and decrements for back faces.
   gl.clear('stencil')
   gl.enable('stencil test')
   gl.stencil_func('always', 0, 0xffff)
   gl.stencil_op('keep', 'keep', 'incr wrap', 'front')
   gl.stencil_op('keep', 'keep', 'decr wrap', 'back')
   -- Draw only the shadow casters
   draw_scene(prog1, view, projection)
   -- Enable writing to the color buffer
   gl.color_mask(true, true, true, true)
   gl.flush()

   -- Pass3 -------------------------------------------------------------------
   -- In this pass, we read the diffuse and specular component from a texture
   -- and combine it with the ambient component if the stencil test succeeds.
   -- We don't need the depth test
   gl.disable('depth test')
   -- We want to just sum the ambient component and the diffuse + specular
   -- when the stencil test succeeds, so we'll use this simple blend function.
   gl.enable('blend')
   gl.blend_func('one','one')
   -- We want to only render those pixels that have a stencil value equal to zero.
   gl.stencil_func('equal', 0, 0xffff)
   gl.stencil_op('keep', 'keep', 'keep')
   gl.use_program(prog3)
   -- Just draw a screen filling quad
   set_matrices(prog3, mat4(), mat4(), mat4())
   gl.bind_vertex_array(quad_vao)
   gl.draw_arrays('triangle fan', 0, 4)
   gl.unbind_vertex_array(0)
   -- Restore some state
   gl.disable('blend')
   gl.enable('depth test')

   glfw.swap_buffers(window)
end

