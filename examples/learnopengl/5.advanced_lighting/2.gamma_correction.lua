#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_texture = require("common.texture")

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
-- lighting info
local lightPositions = {
   vec3(-3.0, 0.0, 0.0),
   vec3(-1.0, 0.0, 0.0),
   vec3 (1.0, 0.0, 0.0),
   vec3 (3.0, 0.0, 0.0)
}
local lightColors = {
   vec3(0.25, 0.25, 0.25),
   vec3(0.50, 0.50, 0.50),
   vec3(0.75, 0.75, 0.75),
   vec3(1.00, 1.00, 1.00)
}

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local prog, vsh, fsh = gl.make_program({
   vertex="shaders/2.gamma_correction.vert",
   fragment="shaders/2.gamma_correction.frag",
})
gl.delete_shaders(vsh, fsh)

-- set up vertex data (and buffer(s)) and configure vertex attributes ----------
local plane_vertices = {
   -- positions            -- normals         -- texcoords
   10.0, -0.5,  10.0,  0.0, 1.0, 0.0,  10.0,  0.0,
  -10.0, -0.5,  10.0,  0.0, 1.0, 0.0,   0.0,  0.0,
  -10.0, -0.5, -10.0,  0.0, 1.0, 0.0,   0.0, 10.0,

   10.0, -0.5,  10.0,  0.0, 1.0, 0.0,  10.0,  0.0,
  -10.0, -0.5, -10.0,  0.0, 1.0, 0.0,   0.0, 10.0,
   10.0, -0.5, -10.0,  0.0, 1.0, 0.0,  10.0, 10.0
}
-- plane VAO
local plane_vao = gl.new_vertex_array()
local plane_vbo = gl.new_buffer('array')
gl.buffer_data('array', gl.packf(plane_vertices), 'static draw')
gl.enable_vertex_attrib_array(0)
gl.vertex_attrib_pointer(0, 3, 'float', false, 8*gl.sizeof('float'), 0)
gl.enable_vertex_attrib_array(1)
gl.vertex_attrib_pointer(1, 3, 'float', false, 8*gl.sizeof('float'), 3*gl.sizeof('float'))
gl.enable_vertex_attrib_array(2)
gl.vertex_attrib_pointer(2, 2, 'float', false, 8*gl.sizeof('float'), 6*gl.sizeof('float'))
gl.unbind_vertex_array()

-- load textures
local floor_texture = new_texture("../resources/textures/wood.png", false)
local floor_texture_gammacorrected = new_texture("../resources/textures/wood.png", true)

-- get the locations of the uniforms:
local loc = {} -- holds the locations for prog (indexed by the uniform variables names)
local uniforms = -- names of prog's uniform variables
   { "projection", "view", "viewPos", "floorTexture", "gamma" }
for i=1,#lightPositions do table.insert(uniforms, "lightPositions["..(i-1).."]") end
for i=1,#lightColors do table.insert(uniforms, "lightColors["..(i-1).."]") end
gl.use_program(prog)
for _, name in ipairs(uniforms) do loc[name]=gl.get_uniform_location(prog, name) end

gl.uniformi(loc.floorTexture, 0)

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
gl.enable('blend')
gl.blend_func('src alpha', 'one minus src alpha')

local last_frame_time = 0.0 -- last frame time
local gamma, gamma_key_pressed = false, false

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

-- render loop
print("Press 'space' to toggle gamma correction")
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
   if keypressed('space') and not gamma_key_pressed then
      gamma = not gamma
      gamma_key_pressed = true
   end
   if keyreleased('space') then gamma_key_pressed = false end
   glfw.set_window_title(window, "LearnOpenGL - gamma correction "..(gamma and "enabled" or "disabled"))

   -- render
   gl.clear_color(0.1, 0.1, 0.1, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   gl.uniform_matrix4f(loc.projection, true, projection)
   gl.uniform_matrix4f(loc.view, true, camera:view())
   -- set light uniforms
   for i=1,4 do
      gl.uniformf(loc["lightPositions["..(i-1).."]"], lightPositions[i])
      gl.uniformf(loc["lightColors["..(i-1).."]"], lightColors[i])

   end
   gl.uniformf(loc.viewPos, camera.position)
   gl.uniformi(loc.gamma, gamma and 1 or 0)
   -- floor
   gl.bind_vertex_array(plane_vao)
   gl.active_texture(0)
   gl.bind_texture('2d', gamma and floor_texture_gammacorrected or floor_texture)
   gl.draw_arrays('triangles', 0, 6)

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

gl.delete_vertex_arrays(plane_vao)
gl.delete_buffers(plane_vbo)
gl.delete_program(prog)

