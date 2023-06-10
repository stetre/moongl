#!/usr/bin/env lua
-- Drawing a textured fullscreen-quad (useful for post-processing).
local gl = require("moongl")
local glfw = require("moonglfw")
local mi = require("moonimage")

local vertexshader = [[
#version 330 core
layout (location = 0) in vec2 VertexPos;
layout (location = 1) in vec2 VertexTexCoord;
out vec2 TexCoord;
void main()
   {
    gl_Position = vec4(VertexPos.xy, 0.0, 1.0);
    TexCoord = VertexTexCoord;
   }
]]

local fragmentshader = [[
#version 330 core
in vec2 TexCoord;
out vec4 Color;
uniform sampler2D Tex;
void main()
   {
   // ... filtering goes here ...
   Color = texture(Tex, TexCoord);
   }
]]

local W, H = 800, 600

glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(W, H, "Fullscreen Textured Quad")
glfw.make_context_current(window)
gl.init()

glfw.set_framebuffer_size_callback(window, function (window, width, height)
    gl.viewport(0, 0, width, height)
end)

local prog, vsh, fsh = gl.make_program_s({vertex=vertexshader, fragment=fragmentshader})
gl.delete_shaders(vsh, fsh)

local vertices = {
-- positions  -- texture coords
   1,  1,      1.0, 1.0, -- top right
   1, -1,      1.0, 0.0, -- bottom right
  -1, -1,      0.0, 0.0, -- bottom left
  -1,  1,      0.0, 1.0, -- top left 
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
gl.vertex_attrib_pointer(0, 3, 'float', false, 4*gl.sizeof('float'), 0)
gl.enable_vertex_attrib_array(0)
-- texture coords attribute
gl.vertex_attrib_pointer(1, 2, 'float', false, 4*gl.sizeof('float'), 2*gl.sizeof('float'))
gl.enable_vertex_attrib_array(1)
gl.unbind_buffer('array')
gl.unbind_vertex_array() 

-- load and create a texture --------------------------------------------------
local texture = gl.gen_textures() 
gl.bind_texture('2d', texture)
gl.texture_parameter('2d', 'wrap s', 'repeat')
gl.texture_parameter('2d', 'wrap t', 'repeat')
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
mi.flip_vertically_on_load(true)
local data, w, h, channels = mi.load("sunflowers.jpg")
gl.texture_image('2d', 0, 'rgb', 'rgb', 'ubyte', data, w, h)
data, w, h, nchannels = nil -- we don't need these any more

while not glfw.window_should_close(window) do
   if glfw.get_key(window, 'escape') == 'press' then
       glfw.set_window_should_close(window, true)
   end
   gl.clear_color(0.2, 0.3, 0.3, 1.0)
   gl.clear('color')
   gl.bind_texture('2d', texture)
   gl.use_program(prog)
   gl.bind_vertex_array(vao)
   gl.draw_elements('triangles', 6, 'uint', 0)
   gl.unbind_vertex_array()
   glfw.swap_buffers(window)
   glfw.poll_events()
end

