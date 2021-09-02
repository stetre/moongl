#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")

-- A few shortcuts:
local vec3, mat4 = glmath.vec3, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local transpose = glmath.transpose
local clamp = glmath.clamp
local perspective = glmath.perspective
local rad, sin, cos = math.rad, math.sin, math.cos

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 3.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
glfw.window_hint('samples', 8)
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local prog, vsh, fsh = gl.make_program({
   vertex="shaders/11.1.anti_aliasing.vert",
   fragment="shaders/11.1.anti_aliasing.frag",
})
gl.delete_shaders(vsh, fsh)

-- set up vertex data (and buffer(s)) and configure vertex attributes
local cube_vertices = {
   -- positions       
  -0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5,  0.5, -0.5,
   0.5,  0.5, -0.5,
  -0.5,  0.5, -0.5,
  -0.5, -0.5, -0.5,

  -0.5, -0.5,  0.5,
   0.5, -0.5,  0.5,
   0.5,  0.5,  0.5,
   0.5,  0.5,  0.5,
  -0.5,  0.5,  0.5,
  -0.5, -0.5,  0.5,

  -0.5,  0.5,  0.5,
  -0.5,  0.5, -0.5,
  -0.5, -0.5, -0.5,
  -0.5, -0.5, -0.5,
  -0.5, -0.5,  0.5,
  -0.5,  0.5,  0.5,

   0.5,  0.5,  0.5,
   0.5,  0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5,  0.5,
   0.5,  0.5,  0.5,

  -0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5,  0.5,
   0.5, -0.5,  0.5,
  -0.5, -0.5,  0.5,
  -0.5, -0.5, -0.5,

  -0.5,  0.5, -0.5,
   0.5,  0.5, -0.5,
   0.5,  0.5,  0.5,
   0.5,  0.5,  0.5,
  -0.5,  0.5,  0.5,
  -0.5,  0.5, -0.5
}

-- setup cube VAO
local cube_vao = gl.new_vertex_array()
local cube_vbo = gl.new_buffer('array')
gl.buffer_data('array', gl.packf(cube_vertices), 'static draw')
gl.enable_vertex_attrib_array(0)
gl.vertex_attrib_pointer(0, 3, 'float', false, 3*gl.sizeof('float'), 0)

-- get the locations of the uniforms:
local loc = {} -- holds the locations for prog (indexed by the uniform variables names)
gl.use_program(prog)
loc.model = gl.get_uniform_location(prog, "model")
loc.view = gl.get_uniform_location(prog, "view")
loc.projection = gl.get_uniform_location(prog, "projection")

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
gl.enable('multisample') -- it's usually enabled by default, but just to be sure...

local last_frame_time = 0.0 -- last frame time

local function keypressed(x) return glfw.get_key(window, x)=='press' end

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

   gl.clear_color(.1, .1, .1, 1.0)
   gl.clear('color', 'depth')
   -- set transformation matrices      
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 1.0, 1000.0)
   gl.use_program(prog)
   gl.uniform_matrix4f(loc.projection, true, projection)
   gl.uniform_matrix4f(loc.view, true, camera:view())
   gl.uniform_matrix4f(loc.model, true, mat4())
   gl.bind_vertex_array(cube_vao)
   gl.draw_arrays('triangles', 0, 36)

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

