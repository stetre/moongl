#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local ft = require("moonfreetype")

-- A few shortcuts:
local vec2 = glmath.vec2

local SCR_WIDTH, SCR_HEIGHT = 800, 600

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader program ---------------------------------
local prog, vsh, fsh = gl.make_program({
   vertex = "shaders/2.text.vert",
   fragment = "shaders/2.text.frag"
})
gl.delete_shaders(vsh, fsh)
gl.use_program(prog)

local uniforms = {"textColor", "projection"}
local loc = {}
for _, name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

local projection
local function framebuffer_size_callback(window, w, h)
   gl.viewport(0, 0, w, h)
   SCR_WIDTH, SCR_HEIGHT = w, h
   projection = glmath.ortho(0, SCR_WIDTH, 0, SCR_HEIGHT)
end
glfw.set_framebuffer_size_callback(window, framebuffer_size_callback)
framebuffer_size_callback(window, SCR_WIDTH, SCR_HEIGHT) -- to set projection

-- configure VAO/VBO for texture quads
local vao = gl.new_vertex_array()
local vbo = gl.new_buffer('array')
gl.buffer_data('array', gl.sizeof('float')*6*4, 'dynamic draw')
gl.enable_vertex_attrib_array(0)
gl.vertex_attrib_pointer(0, 4, 'float', false, 4*gl.sizeof('float'), 0)
gl.unbind_buffer('array')
gl.unbind_vertex_array()

-- Inizialize and load the FreeType library
local ftlib = ft.init_freetype()
-- Load the font face and set the desired glyph size
local face = ft.new_face(ftlib, "../resources/fonts/Antonio-Bold.ttf")
face:set_pixel_sizes(0, 48)
-- disable OpenGL byte-alignment restriction
gl.pixel_store('unpack alignment', 1)
-- Load the first 128 ASCII characters
local char = {}
for c = 0, 127 do
   -- load glyph
   face:load_char(c, ft.LOAD_RENDER)
   local glyph = face:glyph()
   local bitmap = glyph.bitmap
   -- Generate texture and set its options
   local texid = gl.new_texture('2d')
   gl.texture_image('2d', 0, 'red', 'red', 'ubyte', bitmap.buffer, bitmap.width, bitmap.rows)
   gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
   gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'mag filter', 'linear')
   -- store for later use
   char[c] = {
      texid = texid,                           -- texture id
      size = vec2(bitmap.width, bitmap.rows),  -- glyph size
      bearing = vec2(bitmap.left, bitmap.top), -- offset from baseline to left/top of glyph
      advance = glyph.advance.x,               -- horizontal offset to advance to next glyph
   }
   gl.unbind_texture('2d')
end
-- We're done with FreeType
face:done()
ftlib:done()


local function render_text(text, x, y, scale, color)
   gl.uniformf(loc["textColor"], color)   
   gl.active_texture(0)
   gl.bind_vertex_array(vao)
   for i=1, #text do
      local c = text:byte(i) -- numeric code for the i-th character in text
      local ch = char[c] -- info for the character
      local xpos = x + ch.bearing.x*scale
      local ypos = y - (ch.size.y -ch.bearing.y)*scale
      local w = ch.size.x*scale
      local h = ch.size.y*scale
      -- Update the contents of vbo with the positions and texture coordinates of
      -- the quad vertices, and render the quad with this character's texture
      gl.bind_buffer('array', vbo)
      gl.buffer_sub_data('array', 0, gl.pack('float', {
        -- position           texcoords
        xpos,     ypos + h,   0.0, 0.0,
        xpos,     ypos,       0.0, 1.0,
        xpos + w, ypos,       1.0, 1.0,
        xpos,     ypos + h,   0.0, 0.0,
        xpos + w, ypos,       1.0, 1.0,
        xpos + w, ypos + h,   1.0, 0.0,
      }))
      gl.unbind_buffer('array')
      gl.bind_texture('2d', ch.texid)
      gl.draw_arrays('triangles', 0, 6)
      -- advance x position for the next glyph (if any)
      x = x + (ch.advance  >> 6)*scale -- = x +ch.advance/64*scale
   end
   gl.unbind_vertex_array()
   gl.unbind_texture('2d')
end

-- configure global opengl state
gl.enable('cull face')
gl.enable('blend')
gl.blend_func('src alpha', 'one minus src alpha')

-- render loop
while not glfw.window_should_close(window) do
   -- process input
   if glfw.get_key(window, 'escape') == 'press' then
      glfw.set_window_should_close(window, true)
   end

   gl.clear_color(0.2, 0.3, 0.3, 1.0)
   gl.clear('color')
   gl.uniform_matrix4f(loc["projection"], true, projection)
   render_text("This is sample text", 25.0, 25.0, 1.0, {0.5, 0.8, 0.2})
   render_text("(C) LearnOpenGL.com", 540.0, 570.0, 0.5, {0.3, 0.7, 0.9})

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

