#!/usr/bin/env lua
local gl = require("moongl")
local glfw = require("moonglfw")
local mi = require("moonimage")
-- Attribute-less generation of a fullscreen-quad with texture coordinates.
-- The vertex shader generates the vertices of a triangle that covers the whole
-- screen, as in the image below (the (-1,-1)...(1,1) square is the viewport).
-- See https://stackoverflow.com/questions/2588875/whats-the-best-way-to-draw-a-fullscreen-quad-in-opengl-3-2/59739538#59739538
--
--  (-1,3)
--     |\
--     |  \
--     |    \                
--     |-----(1,1)           (the [-1,1] quad).
--     |     |  \
--     |_____|____\
--  (-1,-1)       (3,-1)
--

local vertexshader = [[
#version 330 core
out vec2 TexCoords;
void main()
   {
   vec2 vertices[3]=vec2[3](vec2(-1,-1), vec2(3,-1), vec2(-1,3));
   gl_Position = vec4(vertices[gl_VertexID], 0.0, 1.0);
   TexCoords = 0.5 * gl_Position.xy + vec2(0.5);
   }
]]

local fragmentshader = [[
#version 330 core
in vec2 TexCoords;
out vec4 Color;
uniform sampler2D Tex;
void main()
   {
   // ... filtering goes here ...
   Color = texture(Tex, TexCoords);
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

-- Empty vao: vertices and texcoords are generated in the vertex shader based on gl_VertexID
local vao = gl.gen_vertex_arrays()
gl.unbind_vertex_array() 

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
   gl.bind_texture('2d', texture)
   gl.use_program(prog)
   gl.bind_vertex_array(vao)
   gl.draw_arrays('triangles', 0, 3)
   gl.unbind_vertex_array()
   glfw.swap_buffers(window)
   glfw.poll_events()
end

