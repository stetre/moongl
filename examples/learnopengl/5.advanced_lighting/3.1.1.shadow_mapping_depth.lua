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
local perspective, ortho, look_at = glmath.perspective, glmath.ortho, glmath.look_at
local rad, sin, cos = math.rad, math.sin, math.cos

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 3.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local light_pos = vec3(-2.0, 4.0, -1.0)

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local prog, vsh, fsh = gl.make_program({ -- simpleDepthShader
   vertex="shaders/3.1.1.shadow_mapping_depth.vert",
   fragment="shaders/3.1.1.shadow_mapping_depth.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, vsh, fsh = gl.make_program({ -- debugDepthQuad
   vertex="shaders/3.1.1.debug_quad.vert",
   fragment="shaders/3.1.1.debug_quad_depth.frag",
})
gl.delete_shaders(vsh, fsh)

-- set up vertex data (and buffer(s)) and configure vertex attributes ----------
local plane_vertices = {
   -- positions            -- normals         -- texcoords
   25.0, -0.5,  25.0,  0.0, 1.0, 0.0,  25.0,  0.0,
  -25.0, -0.5,  25.0,  0.0, 1.0, 0.0,   0.0,  0.0,
  -25.0, -0.5, -25.0,  0.0, 1.0, 0.0,   0.0, 25.0,

   25.0, -0.5,  25.0,  0.0, 1.0, 0.0,  25.0,  0.0,
  -25.0, -0.5, -25.0,  0.0, 1.0, 0.0,   0.0, 25.0,
   25.0, -0.5, -25.0,  0.0, 1.0, 0.0,  25.0, 10.0
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
local wood_texture = new_texture("../resources/textures/wood.png")

-- configure depth map FBO
local SHADOW_WIDTH, SHADOW_HEIGHT = 1024, 1024
-- create depth texture
local depth_map = gl.new_texture('2d')
gl.texture_image('2d', 0, 'depth component', 'depth component', 'float', nil, SHADOW_WIDTH, SHADOW_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'nearest')
gl.texture_parameter('2d', 'mag filter', 'nearest')
gl.texture_parameter('2d', 'wrap s', 'repeat')
gl.texture_parameter('2d', 'wrap t', 'repeat')
local fbo = gl.new_framebuffer('draw read')
gl.framebuffer_texture_2d('draw read', 'depth attachment', '2d', depth_map, 0)
gl.draw_buffer('none')
gl.read_buffer('none')
gl.bind_framebuffer('draw read', 0)

-- get the locations of the uniforms:
local loc = {}
local uniforms = { "model", "lightSpaceMatrix" }
gl.use_program(prog)
for _, name in ipairs(uniforms) do loc[name]=gl.get_uniform_location(prog, name) end
local loc1 = {}
local uniforms1 = { "depthMap", "use_ortho", "near_plane", "far_plane" }
gl.use_program(prog1)
for _, name in ipairs(uniforms1) do loc1[name]=gl.get_uniform_location(prog1, name) end
-- Note: 'use_ortho' was added to avoid pruning of unused uniform variables 'near_plane'
-- and 'far_plane' when LinearizeDepth() was commented out in fragment shader
gl.uniformb(loc1.use_ortho, true)
gl.uniformi(loc1.depthMap, 0)

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

-- renders a 1x1 3D cube in NDC.
local cube_vao, cube_vbo
local function render_cube()
   -- initialize (if necessary)
   if not cube_vao then
      local vertices = {
         -- back face
        -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, -- bottom-left
         1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, -- top-right
         1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 0.0, -- bottom-right         
         1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, -- top-right
        -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, -- bottom-left
        -1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 1.0, -- top-left
        -- front face
        -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, -- bottom-left
         1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 0.0, -- bottom-right
         1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, -- top-right
         1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, -- top-right
        -1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 1.0, -- top-left
        -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, -- bottom-left
        -- left face
        -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, -- top-right
        -1.0,  1.0, -1.0, -1.0,  0.0,  0.0, 1.0, 1.0, -- top-left
        -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-left
        -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-left
        -1.0, -1.0,  1.0, -1.0,  0.0,  0.0, 0.0, 0.0, -- bottom-right
        -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, -- top-right
        -- right face
         1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, -- top-left
         1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-right
         1.0,  1.0, -1.0,  1.0,  0.0,  0.0, 1.0, 1.0, -- top-right         
         1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-right
         1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, -- top-left
         1.0, -1.0,  1.0,  1.0,  0.0,  0.0, 0.0, 0.0, -- bottom-left     
        -- bottom face
        -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, -- top-right
         1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 1.0, 1.0, -- top-left
         1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, -- bottom-left
         1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, -- bottom-left
        -1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 0.0, 0.0, -- bottom-right
        -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, -- top-right
        -- top face
        -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, -- top-left
         1.0,  1.0 , 1.0,  0.0,  1.0,  0.0, 1.0, 0.0, -- bottom-right
         1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 1.0, 1.0, -- top-right     
         1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 1.0, 0.0, -- bottom-right
        -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, -- top-left
        -1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 0.0, 0.0  -- bottom-left        
      }
      cube_vao = gl.new_vertex_array()
      cube_vbo = gl.new_buffer('array')
      gl.buffer_data('array', gl.packf(vertices), 'static draw')
      -- link vertex attributes
      gl.bind_vertex_array(cube_vao)
      gl.enable_vertex_attrib_array(0)
      gl.vertex_attrib_pointer(0, 3, 'float', false, 8*gl.sizeof('float'), 0)
      gl.enable_vertex_attrib_array(1)
      gl.vertex_attrib_pointer(1, 3, 'float', false, 8*gl.sizeof('float'), 3*gl.sizeof('float'))
      gl.enable_vertex_attrib_array(2)
      gl.vertex_attrib_pointer(2, 2, 'float', false, 8*gl.sizeof('float'), 6*gl.sizeof('float'))
      gl.bind_buffer('array', 0)
      gl.unbind_vertex_array()
   end
   -- render cube
   gl.bind_vertex_array(cube_vao)
   gl.draw_arrays('triangles', 0, 36)
   gl.unbind_vertex_array()
end

local quad_vao, quad_vbo
local function render_quad()
-- renders a 1x1 XY quad in NDC
    if not quad_vao then
      local vertices = {
         -- positions        -- texture Coords
        -1.0,  1.0, 0.0, 0.0, 1.0,
        -1.0, -1.0, 0.0, 0.0, 0.0,
         1.0,  1.0, 0.0, 1.0, 1.0,
         1.0, -1.0, 0.0, 1.0, 0.0,
      }
      -- setup plane VAO
      quad_vao = gl.new_vertex_array()
      quad_vbo = gl.new_buffer('array')
      gl.buffer_data('array', gl.packf(vertices), 'static draw')
      gl.enable_vertex_attrib_array(0)
      gl.vertex_attrib_pointer(0, 3, 'float', false, 5*gl.sizeof('float'), 0)
      gl.enable_vertex_attrib_array(1)
      gl.vertex_attrib_pointer(1, 2, 'float', false, 5*gl.sizeof('float'), 3 * gl.sizeof('float'))
   end
   gl.bind_vertex_array(quad_vao)
   gl.draw_arrays('triangle strip', 0, 4)
   gl.bind_vertex_array(0)
end

-- tell GLFW to capture our mouse:
glfw.set_input_mode(window, 'cursor', 'disabled')

-- configure global opengl state
gl.enable('depth test')

local last_frame_time = 0.0 -- last frame time

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

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

   -- render
   gl.clear_color(0.1, 0.1, 0.1, 1.0)

   -- 1. render depth of scene to texture (from light's perspective)
   local near_plane, far_plane = 1.0, 7.5
   local lightProjection = ortho(-10.0, 10.0, -10.0, 10.0, near_plane, far_plane)
   local lightView = look_at(light_pos, vec3(0, 0, 0), vec3(0, 1, 0))
   -- render scene from light's point of view
   gl.use_program(prog)
   gl.uniform_matrix4f(loc.lightSpaceMatrix, true, lightProjection*lightView)
   gl.viewport(0, 0, SHADOW_WIDTH, SHADOW_HEIGHT)
   gl.bind_framebuffer('draw read', fbo)
   gl.clear('depth')
   gl.active_texture(0)
   gl.bind_texture('2d', wood_texture)
   -- floor
   gl.uniform_matrix4f(loc.model, true, mat4())
   gl.bind_vertex_array(plane_vao)
   gl.draw_arrays('triangles', 0, 6)
   -- cubes
   gl.uniform_matrix4f(loc.model, true, translate(0.0, 1.5, 0.0)*scale(0.5))
   render_cube()
   gl.uniform_matrix4f(loc.model, true, translate(2.0, 0.0, 1.0)*scale(0.5))
   render_cube()
   local model = translate(-1.0, 0.0, 2.0)*rotate(rad(60.0), vec3(1.0, 0.0, 1.0):normalize())
                  *scale(0.25)
   gl.uniform_matrix4f(loc.model, true, model)
   render_cube()
   gl.unbind_framebuffer('draw read')

   -- reset viewport
   gl.viewport(0, 0, SCR_WIDTH, SCR_HEIGHT)
   gl.clear('color', 'depth')

   -- render Depth map to quad for visual debugging
   gl.use_program(prog1)
   gl.uniformf(loc1.near_plane, near_plane)
   gl.uniformf(loc1.far_plane, far_plane)
   gl.active_texture(0)
   gl.bind_texture('2d', depth_map)
   render_quad()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

gl.delete_vertex_arrays(plane_vao, cube_vao, quad_vao)
gl.delete_buffers(plane_vbo, cube_vbo, quad_vbo)

