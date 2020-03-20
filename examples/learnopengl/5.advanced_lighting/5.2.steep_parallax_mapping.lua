#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_texture = require("common.texture")

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
   vertex="shaders/5.2.parallax_mapping.vert",
   fragment="shaders/5.2.parallax_mapping.frag",
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

-- renders a 1x1 quad in NDC with manually calculated tangent vectors
local quad_vao, quad_vbo
local function render_quad()
   if not quad_vao then
      -- positions
      local pos1 = vec3(-1.0,  1.0, 0.0)
      local pos2 = vec3(-1.0, -1.0, 0.0)
      local pos3 = vec3( 1.0, -1.0, 0.0)
      local pos4 = vec3( 1.0,  1.0, 0.0)
      -- texture coordinates
      local uv1 = vec2(0.0, 1.0)
      local uv2 = vec2(0.0, 0.0)
      local uv3 = vec2(1.0, 0.0)  
      local uv4 = vec2(1.0, 1.0)
      -- normal vector
      local nm = vec3(0.0, 0.0, 1.0)
      -- calculate tangent/bitangent vectors of both triangles
      local edge1 = pos2 - pos1
      local edge2 = pos3 - pos1
      local deltaUV1 = uv2 - uv1
      local deltaUV2 = uv3 - uv1
      local f = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y)
      local tangent1 = vec3(f*(deltaUV2.y * edge1.x - deltaUV1.y * edge2.x),
                            f*(deltaUV2.y * edge1.y - deltaUV1.y * edge2.y),
                            f*(deltaUV2.y * edge1.z - deltaUV1.y * edge2.z)):normalize()
      local bitangent1 = vec3(f*(-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x),
                              f*(-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y),
                              f*(-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z)):normalize()

      local edge1 = pos3 - pos1
      local edge2 = pos4 - pos1
      local deltaUV1 = uv3 - uv1
      local deltaUV2 = uv4 - uv1
      local f = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y)
      local tangent2 = vec3(f*(deltaUV2.y * edge1.x - deltaUV1.y * edge2.x),
                            f*(deltaUV2.y * edge1.y - deltaUV1.y * edge2.y),
                            f*(deltaUV2.y * edge1.z - deltaUV1.y * edge2.z)):normalize()
      local bitangent2 = vec3(f*(-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x),
                              f*(-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y),
                              f*(-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z)):normalize()

      local quad_vertices = {
         pos1, nm, uv1, tangent1, bitangent1,
         pos2, nm, uv2, tangent1, bitangent1,
         pos3, nm, uv3, tangent1, bitangent1,
         pos1, nm, uv1, tangent2, bitangent2,
         pos3, nm, uv3, tangent2, bitangent2,
         pos4, nm, uv4, tangent2, bitangent2,
      }
      -- configure plane VAO
      quad_vao = gl.new_vertex_array()
      quad_vbo = gl.new_buffer('array')
      gl.buffer_data('array', gl.packf(quad_vertices), 'static draw')
      gl.enable_vertex_attrib_array(0)
      gl.vertex_attrib_pointer(0, 3, 'float', false, 14*gl.sizeof('float'), 0)
      gl.enable_vertex_attrib_array(1)
      gl.vertex_attrib_pointer(1, 3, 'float', false, 14*gl.sizeof('float'), 3*gl.sizeof('float'))
      gl.enable_vertex_attrib_array(2)
      gl.vertex_attrib_pointer(2, 2, 'float', false, 14*gl.sizeof('float'), 6*gl.sizeof('float'))
      gl.enable_vertex_attrib_array(3)
      gl.vertex_attrib_pointer(3, 3, 'float', false, 14*gl.sizeof('float'), 8*gl.sizeof('float'))
      gl.enable_vertex_attrib_array(4)
      gl.vertex_attrib_pointer(4, 3, 'float', false, 14*gl.sizeof('float'), 11*gl.sizeof('float'))
   end
   gl.bind_vertex_array(quad_vao)
   gl.draw_arrays('triangles', 0, 6)
   gl.unbind_vertex_array()
end

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
   render_quad()

   -- render light source (simply re-renders a smaller plane at the light's position
   -- for debugging/visualization)
   gl.uniform_matrix4f(loc.model, true, translate(light_pos)*scale(0.1))
   render_quad()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

gl.delete_vertex_arrays(plane_vao)
gl.delete_buffers(plane_vbo)


