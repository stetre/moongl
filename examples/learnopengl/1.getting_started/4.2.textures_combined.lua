#!/usr/bin/env lua
local gl = require("moongl")
local glfw = require("moonglfw")
local mi = require("moonimage")

local SCR_WIDTH, SCR_HEIGHT = 800, 600

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers
glfw.set_framebuffer_size_callback(window, function (window, width, height)
    gl.viewport(0, 0, width, height)
end)

-- build, compile, and link our shader program ---------------------------------
local prog, vsh, fsh = gl.make_program({vertex="shaders/4.2.texture.vert",
                                         fragment="shaders/4.2.texture.frag"})
gl.delete_shaders(vsh, fsh)

-- set up vertex data (and buffer(s)) and configure vertex attributes ---------
local vertices = {
   -- positions      -- colors        -- texture coords
   0.5,  0.5, 0.0,   1.0, 0.0, 0.0,   1.0, 1.0, -- top right
   0.5, -0.5, 0.0,   0.0, 1.0, 0.0,   1.0, 0.0, -- bottom right
  -0.5, -0.5, 0.0,   0.0, 0.0, 1.0,   0.0, 0.0, -- bottom left
  -0.5,  0.5, 0.0,   1.0, 1.0, 0.0,   0.0, 1.0,  -- top left 
}
local indices = {  
   0, 1, 3, -- first triangle
   1, 2, 3  -- second triangle
}
 
local vao = gl.gen_vertex_arrays()
local vbo, ebo = gl.gen_buffers(2)
gl.bind_vertex_array(vao)
gl.bind_buffer('array', vbo)
gl.buffer_data('array', gl.pack('float', vertices), 'static draw')
gl.bind_buffer('element array', ebo)
gl.buffer_data('element array', gl.pack('uint', indices), 'static draw')
-- position attribute
gl.vertex_attrib_pointer(0, 3, 'float', false, 8*gl.sizeof('float'), 0)
gl.enable_vertex_attrib_array(0)
-- color attribute
gl.vertex_attrib_pointer(1, 3, 'float', false, 8*gl.sizeof('float'), 3*gl.sizeof('float'))
gl.enable_vertex_attrib_array(1) -- color
-- texture coords attribute
gl.vertex_attrib_pointer(2, 2, 'float', false, 8*gl.sizeof('float'), 6*gl.sizeof('float'))
gl.enable_vertex_attrib_array(2)
gl.unbind_buffer('array')
gl.unbind_vertex_array() 

-- load and create 2 textures -------------------------------------------------
mi.flip_vertically_on_load(true) -- flip loaded images on the y-axis
-- (This is because in stored images the origin is usually on the top-left
-- corner, so the y-axis goes from top to bottom.)

local texture1 = gl.gen_textures() 
gl.bind_texture('2d', texture1)
gl.texture_parameter('2d', 'wrap s', 'repeat')
gl.texture_parameter('2d', 'wrap t', 'repeat')
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
local data, w, h, channels = mi.load("../resources/textures/container.jpg")
-- print(#data, w, h, channels, #channels*w*h)
gl.texture_image('2d', 0, 'rgb', 'rgb', 'ubyte', data, w, h)
gl.generate_mipmap('2d')

local texture2 = gl.gen_textures() 
gl.bind_texture('2d', texture2)
gl.texture_parameter('2d', 'wrap s', 'repeat')
gl.texture_parameter('2d', 'wrap t', 'repeat')
gl.texture_parameter('2d', 'min filter', 'linear mipmap linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
local data, w, h, channels = mi.load("../resources/textures/awesomeface.png")
-- print(#data, w, h, channels, #channels*w*h)
-- Note that the awesomeface.png has transparency and thus an alpha channel, 
-- so make sure to tell OpenGL the data format is RGBA
gl.texture_image('2d', 0, 'rgba', 'rgba', 'ubyte', data, w, h)
gl.generate_mipmap('2d')
data, w, h, nchannels = nil -- we don't need these any more

-- tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
gl.use_program(prog) -- don't forget to activate/use the shader before setting uniforms!
gl.uniformi(gl.get_uniform_location(prog, "texture1"), 0)
gl.uniformi(gl.get_uniform_location(prog, "texture2"), 1)

-- render loop
while not glfw.window_should_close(window) do
   -- process input
   if glfw.get_key(window, 'escape') == 'press' then
       glfw.set_window_should_close(window, true)
   end

   -- render
   gl.clear_color(0.2, 0.3, 0.3, 1.0)
   gl.clear('color')
   -- bind textures on corresponding texture units, and draw
   gl.active_texture(0)
   gl.bind_texture('2d', texture1)
   gl.active_texture(1)
   gl.bind_texture('2d', texture2)
   gl.use_program(prog)
   gl.bind_vertex_array(vao)
   gl.draw_elements('triangles', 6, 'uint', 0)
   gl.unbind_vertex_array()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

-- optional: de-allocate all resources once they've outlived their purpose:
gl.delete_vertex_arrays(vao)
gl.delete_buffers(vbo, ebo)
gl.delete_program(prog)
