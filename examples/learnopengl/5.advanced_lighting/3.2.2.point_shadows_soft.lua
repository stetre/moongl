#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_texture = require("common.texture")
local new_cube = require("common.cube")

-- A few shortcuts:
local vec3, mat4 = glmath.vec3, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local transpose = glmath.transpose
local clamp = glmath.clamp
local perspective, ortho, look_at = glmath.perspective, glmath.ortho, glmath.look_at
local rad, sin, cos = math.rad, math.sin, math.cos

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 3.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local light_pos = vec3(0.0, 0.0, 0.0)

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
gl.delete_shaders(vsh, fsh)
local prog, vsh, fsh = gl.make_program({
   vertex="shaders/3.2.2.point_shadows.vert",
   fragment="shaders/3.2.2.point_shadows.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, vsh, fsh, gsh = gl.make_program({
   vertex="shaders/3.2.2.point_shadows_depth.vert",
   fragment="shaders/3.2.2.point_shadows_depth.frag",
   geometry="shaders/3.2.2.point_shadows_depth.geom",
})
gl.delete_shaders(vsh, fsh, gsh)

-- load textures
local wood_texture = new_texture("../resources/textures/wood.png")

local cube = new_cube()

-- configure depth map FBO
local SHADOW_WIDTH, SHADOW_HEIGHT = 1024, 1024
-- create depth cubemap texture
local depth_cube_map = gl.new_texture('cube map')
local function f(target)
      gl.texture_image(target, 0, 'depth component', 'depth component', 'float',
         nil, SHADOW_WIDTH, SHADOW_HEIGHT)
end
f('cube map positive x')
f('cube map negative x')
f('cube map positive y')
f('cube map negative y')
f('cube map positive z')
f('cube map negative z')
f = nil
gl.texture_parameter('cube map', 'min filter', 'nearest')
gl.texture_parameter('cube map', 'mag filter', 'nearest')
gl.texture_parameter('cube map', 'wrap s', 'clamp to edge')
gl.texture_parameter('cube map', 'wrap t', 'clamp to edge')
gl.texture_parameter('cube map', 'wrap r', 'clamp to edge')
local fbo = gl.new_framebuffer('draw read')
gl.framebuffer_texture('draw read', 'depth attachment', depth_cube_map, 0)
gl.draw_buffer('none')
gl.read_buffer('none')
gl.bind_framebuffer('draw read', 0)

-- get the locations of the uniforms:
local loc = {}
local uniforms = { "model", "view", "projection", "reverse_normals", "diffuseTexture",
                  "depthMap", "viewPos", "lightPos", "far_plane", "shadows" }
gl.use_program(prog)
for _, name in ipairs(uniforms) do loc[name]=gl.get_uniform_location(prog, name) end
gl.uniformi(loc.diffuseTexture, 0)
gl.uniformi(loc.depthMap, 1)
local loc1 = {}
local uniforms1 = { "lightPos", "model", "far_plane" }
for i=0, 5 do table.insert(uniforms1, "shadowMatrices["..(i).."]") end
gl.use_program(prog1)
for _, name in ipairs(uniforms1) do loc1[name]=gl.get_uniform_location(prog1, name) end

glfw.set_framebuffer_size_callback(window, function (window, w, h)
   gl.viewport(0, 0, w, h)
   SCR_WIDTH, SCR_HEIGHT = w, h
end)

glfw.set_cursor_pos_callback(window, function(window, xpos, ypos)
   -- whenever the mouse moves, this callback is called
   if first_mouse then
      last_x, last_y = xpos, ypos
      first_mouse = false
   end
   local xoffset = xpos - last_x
   local yoffset = last_y - ypos -- reversed since y-coordinates go from bottom to top
   last_x, last_y = xpos, ypos
   camera:process_mouse(xoffset, yoffset, true)
end)

local function render_scene(prog, loc)
-- renders the 3D scene
    -- room cube
    -- We disable culling here since we render 'inside' the cube instead of the usual
    -- 'outside' which throws off the normal culling methods.
    -- The reverse_normals uniform is a small little hack to invert normals when drawing
    -- cube from the inside so lighting still works
    gl.disable('cull face')
    if loc.reverse_normals then gl.uniformb(loc.reverse_normals, true) end
    gl.uniform_matrix4f(loc.model, true, scale(5))
    cube:draw()
    if loc.reverse_normals then gl.uniformb(loc.reverse_normals, false) end
    gl.enable('cull face')
    -- cubes
    gl.uniform_matrix4f(loc.model, true, translate(4.0, -3.5, 0.0)*scale(0.5))
    cube:draw()
    gl.uniform_matrix4f(loc.model, true, translate(2.0, 3.0, 1.0)*scale(0.75))
    cube:draw()
    gl.uniform_matrix4f(loc.model, true, translate(-3.0, -1.0, 0.0)*scale(0.5))
    cube:draw()
    gl.uniform_matrix4f(loc.model, true, translate(-1.5, 1.0, 1.5)*scale(0.5))
    cube:draw()
    gl.uniform_matrix4f(loc.model, true, translate(-1.5, 2.0, -3.0)*
               rotate(rad(60.0), vec3(1.0, 0.0, 1.0):normalize())*scale(0.75))
    cube:draw()
end

-- tell GLFW to capture our mouse:
glfw.set_input_mode(window, 'cursor', 'disabled')

-- configure global opengl state
gl.enable('depth test')
gl.enable('cull face')

local last_frame_time = 0.0 -- last frame time
local shadows, shadows_key_pressed = false, false

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

print("Press space to toggle shadows")

-- render loop
while not glfw.window_should_close(window) do
   local t = glfw.get_time()
   local dt = t - last_frame_time
   last_frame_time = t

   -- process input
   if keypressed('escape') then glfw.set_window_should_close(window, true) end
   -- camera movement controlled either by WASD keys or arrow keys:
   if keypressed('w') or keypressed('up') then camera:process_keyboard('forward', dt) end
   if keypressed('a') or keypressed('left') then camera:process_keyboard('left', dt) end
   if keypressed('s') or keypressed('down') then camera:process_keyboard('backward', dt) end
   if keypressed('d') or keypressed('right') then camera:process_keyboard('right', dt) end
   if keypressed('space') and not shadows_key_pressed then
      shadows = not shadows
      shadows_key_pressed = true
   end
   if keyreleased('space') then shadows_key_pressed = false end

   -- move light position over time
   light_pos.z = sin(t*0.5)*3.0


   -- 0. create depth cubemap transformation matrices
   local near_plane, far_plane = 1.0, 25.0
   local shadowProj = perspective(rad(90.0), SHADOW_WIDTH/SHADOW_HEIGHT, near_plane, far_plane)
   local shadowTransforms = {
      shadowProj*look_at(light_pos, light_pos+vec3( 1.0,  0.0,  0.0), vec3(0.0, -1.0,  0.0)),
      shadowProj*look_at(light_pos, light_pos + vec3(-1.0,  0.0,  0.0), vec3(0.0, -1.0,  0.0)),
      shadowProj*look_at(light_pos, light_pos + vec3( 0.0,  1.0,  0.0), vec3(0.0,  0.0,  1.0)),
      shadowProj*look_at(light_pos, light_pos + vec3( 0.0, -1.0,  0.0), vec3(0.0,  0.0, -1.0)),
      shadowProj*look_at(light_pos, light_pos + vec3( 0.0,  0.0,  1.0), vec3(0.0, -1.0,  0.0)),
      shadowProj*look_at(light_pos, light_pos + vec3( 0.0,  0.0, -1.0), vec3(0.0, -1.0,  0.0)),
   }

   -- 1. render scene to depth cubemap
   gl.viewport(0, 0, SHADOW_WIDTH, SHADOW_HEIGHT)
   gl.bind_framebuffer('draw read', fbo)
   gl.clear('depth')
   gl.use_program(prog1)
   for i = 0, 5 do
      gl.uniform_matrix4f(loc1["shadowMatrices["..(i).."]"], true, shadowTransforms[i+1])
   end
   gl.uniformf(loc1.far_plane, far_plane)
   gl.uniformf(loc1.lightPos, light_pos)
   render_scene(prog1, loc1)
   gl.unbind_framebuffer('draw read')

   -- 2. render scene as normal 
   gl.viewport(0, 0, SCR_WIDTH, SCR_HEIGHT)
   gl.clear_color(0.1, 0.1, 0.1, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   gl.uniform_matrix4f(loc.projection, true, projection)
   gl.uniform_matrix4f(loc.view, true, camera:view())
   -- set lighting uniforms
   gl.uniformf(loc.lightPos, light_pos)
   gl.uniformf(loc.viewPos, camera.position)
   gl.uniformb(loc.shadows, shadows) -- enable/disable shadows by pressing 'SPACE'
   gl.uniformf(loc.far_plane, far_plane)
   gl.active_texture(0)
   gl.bind_texture('2d', wood_texture)
   gl.active_texture(1)
   gl.bind_texture('cube map', depth_cube_map)
   render_scene(prog, loc)

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

gl.delete_vertex_arrays(plane_vao)
gl.delete_buffers(plane_vbo)


