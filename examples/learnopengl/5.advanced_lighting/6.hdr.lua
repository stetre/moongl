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
local min, max = math.min, math.max

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 5.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local lightPositions = {
   vec3( 0.0,  0.0, 49.5), -- back light
   vec3(-1.4, -1.9, 9.0),
   vec3( 0.0, -1.8, 4.0),
   vec3( 0.8, -1.7, 6.0),
}
-- colors
local lightColors = {
   vec3(200.0, 200.0, 200.0),
   vec3(0.1, 0.0, 0.0),
   vec3(0.0, 0.0, 0.2),
   vec3(0.0, 0.1, 0.0),
}

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local prog, vsh, fsh = gl.make_program({
   vertex="shaders/6.lighting.vert",
   fragment="shaders/6.lighting.frag",
})
gl.delete_shaders(vsh, fsh)
local prog1, vsh, fsh = gl.make_program({
   vertex="shaders/6.hdr.vert",
   fragment="shaders/6.hdr.frag",
})
gl.delete_shaders(vsh, fsh)


-- configure floating point framebuffer -------------------------------------
-- create floating point color buffer
local colorBuffer = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgba16f', 'rgba', 'float', nil, SCR_WIDTH, SCR_HEIGHT)
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
-- create depth buffer (renderbuffer)
local rboDepth = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component', SCR_WIDTH, SCR_HEIGHT)
-- attach buffers
local hdrFBO = gl.new_framebuffer('draw read')
gl.bind_framebuffer('draw read', hdrFBO)
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', colorBuffer, 0)
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', rboDepth)
assert(gl.check_framebuffer_status('draw read')=='complete', "Framebuffer not complete!")
gl.unbind_framebuffer('draw read', 0)

-- load textures
-- note that we're loading the texture as an SRGB texture:
local wood_texture = new_texture("../resources/textures/wood.png", true) 

-- get the locations of the uniforms:
local loc = {} -- holds the locations for prog (indexed by the uniform variables names)
local uniforms = -- names of prog's uniform variables
   { "projection", "view", "model", --[["viewPos",--]] "diffuseTexture", "inverse_normals" }
for i=1,#lightPositions do table.insert(uniforms, "lights["..(i-1).."].Position") end
for i=1,#lightColors do table.insert(uniforms, "lights["..(i-1).."].Color") end
gl.use_program(prog)
for _, name in ipairs(uniforms) do loc[name]=gl.get_uniform_location(prog, name) end
gl.uniformi(loc.diffuseTexture, 0)

local loc1 = {} -- holds the locations for prog1 (indexed by the uniform variables names)
local uniforms = -- names of prog1's uniform variables
   { "hdr", "hdrBuffer", "exposure" }
gl.use_program(prog1)
for _, name in ipairs(uniforms) do loc1[name]=gl.get_uniform_location(prog1, name) end
gl.uniformi(loc1.hdrBuffer, 0)

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
local hdr, hdr_key_pressed = true, false
local exposure = 1.0

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end


local cube_vao, cube_vbo
local function render_cube()
-- renders a 1x1 3D cube in NDC.
   if not cube_vao then -- initialize
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
      gl.enable_vertex_attrib_array(0)
      gl.vertex_attrib_pointer(0, 3, 'float', false, 8*gl.sizeof('float'), 0)
      gl.enable_vertex_attrib_array(1)
      gl.vertex_attrib_pointer(1, 3, 'float', false, 8*gl.sizeof('float'), 3*gl.sizeof('float'))
      gl.enable_vertex_attrib_array(2)
      gl.vertex_attrib_pointer(2, 2, 'float', false, 8*gl.sizeof('float'), 6*gl.sizeof('float'))
      gl.bind_buffer('array', 0)
      gl.unbind_vertex_array()
   end
   -- render Cube
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
      gl.vertex_attrib_pointer(1, 2, 'float', false, 5*gl.sizeof('float'), 3*gl.sizeof('float'))
   end
   gl.bind_vertex_array(quad_vao)
   gl.draw_arrays('triangle strip', 0, 4)
   gl.bind_vertex_array(0)
end

-- render loop
print("Press 'space' to toggle hdr")
print("Press Q or E to decrease/increase exposure")
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
   if keypressed('space') and not hdr_key_pressed then
      hdr = not hdr
      hdr_key_pressed = true
   end
   if keyreleased('space') then hdr_key_pressed = false end
   if keypressed('q') then exposure = max(exposure-0.001, 0.0) end
   if keypressed('e') then exposure = exposure+0.001 end
   glfw.set_window_title(window,string.format("LearnOpenGL - hdr %s (exposure=%.3f)",
      (hdr and "enabled" or "disabled"), exposure))

   -- render
   -- 1. render scene into floating point framebuffer
   gl.bind_framebuffer('draw read', hdrFBO)
   gl.clear_color(0.1, 0.1, 0.1, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   gl.uniform_matrix4f(loc.projection, true, projection)
   gl.uniform_matrix4f(loc.view, true, camera:view())
   gl.active_texture(0)
   gl.bind_texture('2d', wood_texture)
   -- set lighting uniforms
   for i = 0, #lightPositions-1 do
      gl.uniformf(loc["lights["..(i).."].Position"], lightPositions[i+1])
      gl.uniformf(loc["lights["..(i).."].Color"], lightColors[i+1])
   end
   -- gl.uniformf(loc.viewPos, camera.position) -- unused in the shader, thus pruned
   -- render tunnel
   gl.uniform_matrix4f(loc.model, true, translate(0.0, 0.0, 25.0)*scale(2.5, 2.5, 27.5))
   gl.uniformb(loc.inverse_normals, true)
   render_cube()
   -- 2. now render floating point color buffer to 2D quad and tonemap HDR colors
   -- to default framebuffer's (clamped) color range
   gl.unbind_framebuffer('draw read')
   gl.clear('color', 'depth')
   gl.use_program(prog1)
   gl.active_texture(0)
   gl.bind_texture('2d', colorBuffer)
   gl.uniformb(loc1.hdr, hdr)
   gl.uniformf(loc1.exposure, exposure)
   render_quad()

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

gl.delete_vertex_arrays(cube_vao, quad_vao)
gl.delete_buffers(cube_vbo, quad_vbo)

