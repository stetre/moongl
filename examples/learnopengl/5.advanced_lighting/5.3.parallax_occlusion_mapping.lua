#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_texture = require("common.texture")
local new_quad = require("common.quad")

-- A few shortcuts:
local vec2, vec3, mat4 = glmath.vec2, glmath.vec3, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local transpose = glmath.transpose
local clamp = glmath.clamp
local perspective = glmath.perspective
local rad, sin, cos = math.rad, math.sin, math.cos
local min, max = math.min, math.max

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 3.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local light_pos = vec3(0.5, 1.0, 0.3)

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local prog, vsh, fsh = gl.make_program({
   vertex="shaders/5.3.parallax_mapping.vert",
   fragment="shaders/5.3.parallax_mapping.frag",
})
gl.delete_shaders(vsh, fsh)

-- load textures
local diffuse_map = new_texture("../resources/textures/brickwall.jpg")
local normal_map  = new_texture("../resources/textures/brickwall_normal.jpg")

local diffuse_map, normal_map, height_map
if arg[1] == "toy" then
   diffuse_map = new_texture("../resources/textures/toy_box_diffuse.png")
   normal_map = new_texture("../resources/textures/toy_box_normal.png")
   height_map = new_texture("../resources/textures/toy_box_disp.png")
else -- bricks
   diffuse_map = new_texture("../resources/textures/bricks2.jpg")
   normal_map  = new_texture("../resources/textures/bricks2_normal.jpg")
   height_map  = new_texture("../resources/textures/bricks2_disp.jpg")
end

local quad = new_quad(true)

-- get the locations of the uniforms:
local loc = {} -- holds the locations for prog (indexed by the uniform variables names)
local uniforms = -- names of prog's uniform variables
   { "projection", "view", "model", "viewPos", "lightPos", "diffuseMap", "normalMap",
     "depthMap", "heightScale" }
gl.use_program(prog)
for _, name in ipairs(uniforms) do loc[name]=gl.get_uniform_location(prog, name) end
gl.uniformi(loc.diffuseMap, 0)
gl.uniformi(loc.normalMap, 1)
gl.uniformi(loc.depthMap, 2)

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

-- tell GLFW to capture our mouse:
glfw.set_input_mode(window, 'cursor', 'disabled')

-- configure global opengl state
gl.enable('depth test')

local last_frame_time = 0.0 -- last frame time
local height_scale = 0.1

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

print("Press Q or E to decrease/increase height scale")

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
   if keypressed('q') then height_scale = max(height_scale - 0.0005, 0.0) end
   if keypressed('e') then height_scale = min(height_scale + 0.0005, 1.0) end
   glfw.set_window_title(window, "LearnOpenGL - height scale = ".. height_scale)

   -- render
   gl.clear_color(0.1, 0.1, 0.1, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   gl.uniform_matrix4f(loc.projection, true, projection)
   gl.uniform_matrix4f(loc.view, true, camera:view())

   -- render parallax-mapped quad
   -- rotate the quad to show parallax mapping from multiple directions:
   gl.uniform_matrix4f(loc.model, true, rotate(rad(-10*t), vec3(1, 0, 1):normalize()))
   gl.uniformf(loc.viewPos, camera.position)
   gl.uniformf(loc.lightPos, light_pos)
   gl.uniformf(loc.heightScale, height_scale)
   gl.active_texture(0)
   gl.bind_texture('2d', diffuse_map)
   gl.active_texture(1)
   gl.bind_texture('2d', normal_map)
   gl.active_texture(2)
   gl.bind_texture('2d', height_map)
   quad:draw()

   -- render light source (simply re-renders a smaller plane at the light's position
   -- for debugging/visualization)
   gl.uniform_matrix4f(loc.model, true, translate(light_pos)*scale(0.1))
   quad:draw()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

gl.delete_vertex_arrays(plane_vao)
gl.delete_buffers(plane_vbo)
gl.delete_program(prog)


