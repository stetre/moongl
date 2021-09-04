#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")

-- A few shortcuts:
local vec3 = glmath.vec3
local rad = math.rad

local SCR_WIDTH, SCR_HEIGHT = 800, 600
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 5.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local light_pos = vec3(0.5, 1.0, 0.3)

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(4, 2, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local function make_program(vshader, fshader)
   local prog, vsh, fsh = gl.make_program({vertex="shaders/"..vshader, fragment="shaders/"..fshader})
   gl.delete_shaders(vsh, fsh)
   return prog
end

local prog1 = make_program("2020.1.solid.vert", "2020.1.solid.frag") -- 
local prog2 = make_program("2020.1.transparent.vert", "2020.1.transparent.frag") -- 
local prog3 = make_program("2020.1.composite.vert", "2020.1.composite.frag") -- 
local prog4 = make_program("2020.1.screen.vert", "2020.1.screen.frag") -- 
make_program=nil

-- get the locations of the uniforms:
local loc1, loc2 = {}, {} -- uniform locations from prog1 and prog2, indexed by uniform name
local uniforms = -- names of uniform variables
   { "mvp", "color" }
for _, name in ipairs(uniforms) do loc1[name]=gl.get_uniform_location(prog1, name) end
for _, name in ipairs(uniforms) do loc2[name]=gl.get_uniform_location(prog2, name) end

-- setup the vao for the quad --------------------------------------------------
local vertices = {
      -- positions      texcoords   
      -1.0, -1.0, 0.0,  0.0, 0.0,
       1.0, -1.0, 0.0,  1.0, 0.0,
       1.0,  1.0, 0.0,  1.0, 1.0,
       1.0,  1.0, 0.0,  1.0, 1.0,
      -1.0,  1.0, 0.0,  0.0, 1.0,
      -1.0, -1.0, 0.0,  0.0, 0.0,
}
local vao = gl.new_vertex_array()
local vbo = gl.new_buffer('array')
gl.buffer_data('array', gl.packf(vertices), 'static draw')
gl.enable_vertex_attrib_array(0) -- position
gl.vertex_attrib_pointer(0, 3, 'float', false, 5*gl.sizeof('float'), 0)
gl.enable_vertex_attrib_array(1) -- texcoords
gl.vertex_attrib_pointer(1, 2, 'float', false, 5*gl.sizeof('float'), 3*gl.sizeof('float'))
gl.unbind_vertex_array()

-- setup the opaque framebuffer ------------------------------------------------
local opaque_tex = gl.new_texture('2d') -- color attachment
gl.texture_image('2d', 0, 'rgba16f', 'rgba', 'half float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
gl.unbind_texture('2d')

local depth_tex = gl.new_texture('2d') -- depth attachment
gl.texture_image('2d', 0, 'depth component', 'depth component', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.unbind_texture('2d')

local opaque_fbo = gl.new_framebuffer('draw read')
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', opaque_tex, 0)
gl.framebuffer_texture_2d('draw read', 'depth attachment', '2d', depth_tex, 0)
assert(gl.check_framebuffer_status('draw read')=='complete', "framebuffer not complete!")
gl.unbind_framebuffer('draw read')

-- setup the transparent framebuffer -------------------------------------------
local accum_tex = gl.new_texture('2d') -- color attachment 0
gl.texture_image('2d', 0, 'rgba16f', 'rgba', 'half float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
gl.unbind_texture('2d')

local reveal_tex = gl.new_texture('2d') -- color attachment 1
gl.texture_image('2d', 0, 'r8', 'red', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
gl.unbind_texture('2d')

local transparent_fbo = gl.new_framebuffer('draw read')
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', accum_tex, 0)
gl.framebuffer_texture_2d('draw read', 'color attachment 1', '2d', reveal_tex, 0)
gl.framebuffer_texture_2d('draw read', 'depth attachment', '2d', depth_tex, 0)
gl.draw_buffers({ 'color attachment 0', 'color attachment 1'})
assert(gl.check_framebuffer_status('draw read')=='complete', "framebuffer not complete!")
gl.unbind_framebuffer('draw read')


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

glfw.set_scroll_callback(window, function(window, xoffset, yoffset)
   -- whenever the mouse scroll wheel scrolls, this callback is called
   camera:process_scroll(yoffset)
end)

-- tell GLFW to capture our mouse:
glfw.set_input_mode(window, 'cursor', 'disabled')

-- set up transformation matrices
local function calculate_model_matrix(position, rotation, scale)
   local rotation = rotation or vec3(0.0, 0.0, 0.0)
   local scale = scale or vec3(1.0, 1.0, 1.0)
   return glmath.translate(position)
                 *glmath.rotate_x(rad(rotation.x))
                 *glmath.rotate_y(rad(rotation.y))
                 *glmath.rotate_z(rad(rotation.z))
                 *glmath.scale(scale)
end
local red_model = calculate_model_matrix(vec3(.8, 0.0, 0.0))
local green_model = calculate_model_matrix(vec3(-.5, 0.0, 1.0))
local blue_model = calculate_model_matrix(vec3(0.0, 0.0, 2.0))


local last_frame_time = 0.0 -- last frame time

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

-- render loop
while not glfw.window_should_close(window) do
   -- per-frame time logic
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

   -- camera matrices
   local projection = glmath.perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   local view = camera:view()
   local vp = projection * view

   -- Pass 1: draw solid objects to opaque_fbo
   gl.enable('depth test')
   gl.depth_func('less')
   gl.depth_mask(true)
   gl.disable('blend')  
   gl.clear_color(0, 0, 0, 0)
   gl.bind_framebuffer('draw read', opaque_fbo)
   gl.clear('color', 'depth')
   gl.use_program(prog1)
   -- draw red quad
   gl.uniform_matrix4f(loc1["mvp"], true, vp*red_model)
   gl.uniformf(loc1["color"], 1.0, 0.0, 0.0)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6)

   -- Pass 2: draw transparent objects to transparent_fbo
   gl.depth_mask(false) -- disable writing to depth buffer
   gl.enable('blend')   
   gl.blend_func(0, 'one', 'one')
   gl.blend_func(1, 'zero', 'one minus src color')
   gl.blend_equation('add')
   gl.bind_framebuffer('draw read', transparent_fbo)
   gl.clear_buffer('color', 0, 0.0, 0.0, 0.0, 0.0)
   gl.clear_buffer('color', 1, 1.0, 1.0, 1.0, 1.0)
   gl.use_program(prog2)
   -- draw green quad
   gl.uniform_matrix4f(loc2["mvp"], true, vp*green_model)
   gl.uniformf(loc2["color"], 0.0, 1.0, 0.0, 0.5)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6)
   -- draw blue quad
   gl.uniform_matrix4f(loc2["mvp"], true, vp*blue_model)
   gl.uniformf(loc2["color"], 0.0, 0.0, 1.0, 0.5)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6)

   -- Pass 3: draw composite image to opaque_fbo
   gl.depth_func('always')
   gl.enable('blend')
   gl.blend_func('src alpha', 'one minus src alpha')
   gl.bind_framebuffer('draw read', opaque_fbo)
   gl.use_program(prog3)
   -- draw screen quad
   gl.active_texture(0) -- see layout binding in shader
   gl.bind_texture('2d', accum_tex)
   gl.active_texture(1)
   gl.bind_texture('2d', reveal_tex)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6)

   -- Pass 4 (final): draw to default framebuffer
   gl.disable('depth test')
   gl.depth_mask(true) -- enable depth writes so gl.clear won't ignore clearing the depth buffer
   gl.disable('blend')
   gl.bind_framebuffer('draw read', 0) -- bind backbuffer of default double framebuffer
   gl.clear_color(0, 0, 0, 0)
   gl.clear('color', 'depth', 'stencil')
   gl.use_program(prog4)
   -- draw final screen quad
   gl.active_texture(0)
   gl.bind_texture('2d', opaque_tex)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 6)

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

-- optional: de-allocate all resources once they've outlived their purpose:
gl.delete_vertex_arrays(vao)
gl.delete_buffers(vbo)
gl.delete_textures(opaque_tex, depth_tex, accum_tex, reveal_tex)
gl.delete_framebuffers(opaque_fbo, transparent_fbo)
gl.delete_programs(prog1, prog2, prog3, prog4)


