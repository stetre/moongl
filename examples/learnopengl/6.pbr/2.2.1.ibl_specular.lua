#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local mi = require("moonimage")
local new_camera = require("common.camera")
local new_sphere = require("common.sphere")
local new_cube = require("common.cube")
local new_quad = require("common.quad")

-- A few shortcuts:
local vec3, mat4 = glmath.vec3, glmath.mat4
local rotate, translate, scale = glmath.rotate, glmath.translate, glmath.scale
local transpose = glmath.transpose
local clamp = glmath.clamp
local perspective, look_at = glmath.perspective, glmath.look_at
local rad, sin, cos = math.rad, math.sin, math.cos

local SCR_WIDTH, SCR_HEIGHT = 1280, 720
-- camera:
local camera = new_camera(vec3(0.0, 0.0, 3.0))
local last_x, last_y = SCR_WIDTH/2, SCR_HEIGHT/2 -- initially at the center
local first_mouse = true
-- lighting info
local lightPositions = {
   vec3(-10.0,  10.0, 10.0),
   vec3( 10.0,  10.0, 10.0),
   vec3(-10.0, -10.0, 10.0),
   vec3( 10.0, -10.0, 10.0),
}
local lightColors = {
   vec3(300.0, 300.0, 300.0),
   vec3(300.0, 300.0, 300.0),
   vec3(300.0, 300.0, 300.0),
   vec3(300.0, 300.0, 300.0)
}
local nrRows, nrColumns, spacing = 7, 7, 2.5

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
glfw.window_hint('samples', 4)
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local function make_program(vshader, fshader)
   local prog, vsh, fsh = gl.make_program(
      {vertex="shaders/"..vshader, fragment="shaders/"..fshader})
   gl.delete_shaders(vsh, fsh)
   return prog
end

local prog1 = make_program("2.2.1.pbr.vert", "2.2.1.pbr.frag") -- pbrShader
local prog2 = make_program("2.2.1.cubemap.vert", "2.2.1.equirectangular_to_cubemap.frag") -- equirectangularToCubemapShader
local prog3 = make_program("2.2.1.background.vert", "2.2.1.background.frag") -- backgroundShader
local prog4 = make_program("2.2.1.cubemap.vert", "2.2.1.irradiance_convolution.frag") -- irradianceShader
local prog5 = make_program("2.2.1.cubemap.vert", "2.2.1.prefilter.frag") -- prefilterShader
local prog6 = make_program("2.2.1.brdf.vert", "2.2.1.brdf.frag") -- brdfShader
make_program = nil

-- get the locations of the uniforms:
local loc1 = {}
local uniforms = { "projection", "view", "model", "camPos",
                  "ao", "albedo", "metallic", "roughness", "irradianceMap",
                  "prefilterMap", "brdfLUT" }
for i=1,#lightPositions do
   table.insert(uniforms, "lightPositions["..(i-1).."]")
   table.insert(uniforms, "lightColors["..(i-1).."]")
end
gl.use_program(prog1)
for _, name in ipairs(uniforms) do loc1[name]=gl.get_uniform_location(prog1, name) end
gl.uniformf(loc1.albedo, 0.5, 0.0, 0.0)
gl.uniformf(loc1.ao, 1.0)
gl.uniformi(loc1.irradianceMap, 0)
gl.uniformi(loc1.prefilterMap, 1)
gl.uniformi(loc1.brdfLUT, 2)

local loc2 = {}
local uniforms = { "projection", "view", "equirectangularMap" }
gl.use_program(prog2)
for _, name in ipairs(uniforms) do loc2[name]=gl.get_uniform_location(prog2, name) end

local loc3 = {}
local uniforms = { "projection", "view", "environmentMap" }
gl.use_program(prog3)
for _, name in ipairs(uniforms) do loc3[name]=gl.get_uniform_location(prog3, name) end

local loc4 = {}
local uniforms = { "projection", "view", "environmentMap" }
gl.use_program(prog4)
for _, name in ipairs(uniforms) do loc4[name]=gl.get_uniform_location(prog4, name) end

local loc5 = {}
local uniforms = { "projection", "view", "environmentMap", "roughness" }
gl.use_program(prog5)
for _, name in ipairs(uniforms) do loc5[name]=gl.get_uniform_location(prog5, name) end

local cube = new_cube()
local sphere = new_sphere()
local quad = new_quad()

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
gl.depth_func('lequal') -- set depth function to less than AND equal for skybox depth trick.
gl.enable('texture cube map seamless') -- enable seamless cubemap sampling for lower mip levels in the pre-filter map.


-- pbr: setup framebuffer
local captureFBO = gl.new_framebuffer('draw read')
local captureRBO = gl.new_renderbuffer('renderbuffer')
gl.renderbuffer_storage('renderbuffer', 'depth component24', 512, 512)
gl.framebuffer_renderbuffer('draw read', 'depth attachment', 'renderbuffer', captureRBO)
-- pbr: load the HDR environment map (note how we specify the texture's data value to be float)
mi.flip_vertically_on_load(true)
local data, width, height, channels = mi.load("../resources/textures/hdr/newport_loft.hdr", 'rgb', 'f')
local hdrTexture = gl.new_texture('2d')
gl.texture_image('2d', 0, 'rgb16f', 'rgb', 'float', data, width, height)
gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
data = nil

-- pbr: setup cubemap to render to and attach to framebuffer
local envCubemap = gl.new_texture('cube map')
gl.texture_image('cube map positive x', 0, 'rgb16f', 'rgb', 'float', nil, 512, 512)
gl.texture_image('cube map negative x', 0, 'rgb16f', 'rgb', 'float', nil, 512, 512)
gl.texture_image('cube map positive y', 0, 'rgb16f', 'rgb', 'float', nil, 512, 512)
gl.texture_image('cube map negative y', 0, 'rgb16f', 'rgb', 'float', nil, 512, 512)
gl.texture_image('cube map positive z', 0, 'rgb16f', 'rgb', 'float', nil, 512, 512)
gl.texture_image('cube map negative z', 0, 'rgb16f', 'rgb', 'float', nil, 512, 512)
gl.texture_parameter('cube map', 'wrap s', 'clamp to edge');
gl.texture_parameter('cube map', 'wrap t', 'clamp to edge');
gl.texture_parameter('cube map', 'wrap r', 'clamp to edge');
-- enable pre-filter mipmap sampling (combatting visible dots artifact):
gl.texture_parameter('cube map', 'min filter', 'linear mipmap linear'); 
gl.texture_parameter('cube map', 'mag filter', 'linear');

-- pbr: set up projection and view matrices for capturing data onto the 6 cubemap face directions
local captureProjection = perspective(rad(90.0), 1.0, 0.1, 10.0)
local captureViews = {
   look_at(vec3(0.0, 0.0, 0.0), vec3( 1.0,  0.0,  0.0), vec3(0.0, -1.0,  0.0)),
   look_at(vec3(0.0, 0.0, 0.0), vec3(-1.0,  0.0,  0.0), vec3(0.0, -1.0,  0.0)),
   look_at(vec3(0.0, 0.0, 0.0), vec3( 0.0,  1.0,  0.0), vec3(0.0,  0.0,  1.0)),
   look_at(vec3(0.0, 0.0, 0.0), vec3( 0.0, -1.0,  0.0), vec3(0.0,  0.0, -1.0)),
   look_at(vec3(0.0, 0.0, 0.0), vec3( 0.0,  0.0,  1.0), vec3(0.0, -1.0,  0.0)),
   look_at(vec3(0.0, 0.0, 0.0), vec3( 0.0,  0.0, -1.0), vec3(0.0, -1.0,  0.0)),
}

-- pbr: convert HDR equirectangular environment map to cubemap equivalent
gl.use_program(prog2)
gl.uniformi(loc2.equirectangularMap, 0)
gl.uniform_matrix4f(loc2.projection, true, captureProjection)
gl.active_texture(0)
gl.bind_texture('2d', hdrTexture)
gl.viewport(0, 0, 512, 512) -- don't forget to configure the viewport to the capture dimensions.
gl.bind_framebuffer('draw read', captureFBO)
local targets = {
   'cube map positive x',
   'cube map negative x', 
   'cube map positive y', 
   'cube map negative y', 
   'cube map positive z', 
   'cube map negative z',
}
for i, target in ipairs(targets) do
   gl.uniform_matrix4f(loc2.view, true, captureViews[i])
   gl.framebuffer_texture_2d('draw read', 'color attachment 0', target, envCubemap, 0)
   gl.clear('color', 'depth')
   cube:draw()
end
gl.unbind_framebuffer('draw read')

-- then let OpenGL generate mipmaps from first mip face (combatting visible dots artifact)
gl.bind_texture('cube map', envCubemap)
gl.generate_mipmap('cube map')


-- pbr: create an irradiance cubemap, and re-scale capture FBO to irradiance scale.
local irradianceMap = gl.new_texture('cube map')
gl.texture_image('cube map positive x', 0, 'rgb16f', 'rgb', 'float', nil, 32, 32)
gl.texture_image('cube map negative x', 0, 'rgb16f', 'rgb', 'float', nil, 32, 32)
gl.texture_image('cube map positive y', 0, 'rgb16f', 'rgb', 'float', nil, 32, 32)
gl.texture_image('cube map negative y', 0, 'rgb16f', 'rgb', 'float', nil, 32, 32)
gl.texture_image('cube map positive z', 0, 'rgb16f', 'rgb', 'float', nil, 32, 32)
gl.texture_image('cube map negative z', 0, 'rgb16f', 'rgb', 'float', nil, 32, 32)
gl.texture_parameter('cube map', 'wrap s', 'clamp to edge')
gl.texture_parameter('cube map', 'wrap t', 'clamp to edge')
gl.texture_parameter('cube map', 'wrap r', 'clamp to edge')
gl.texture_parameter('cube map', 'min filter', 'linear')
gl.texture_parameter('cube map', 'mag filter', 'linear')
gl.bind_framebuffer('draw read', captureFBO)
gl.bind_renderbuffer('renderbuffer', captureRBO)
gl.renderbuffer_storage('renderbuffer', 'depth component24', 32, 32)

-- pbr: solve diffuse integral by convolution to create an irradiance (cube)map.
gl.use_program(prog4)
gl.uniformi(loc4.environmentMap, 0)
gl.uniform_matrix4f(loc4.projection, true, captureProjection)
gl.active_texture(0)
gl.bind_texture('cube map', envCubemap)
gl.viewport(0, 0, 32, 32) -- don't forget to configure the viewport to the capture dimensions.
gl.bind_framebuffer('draw read', captureFBO)
for i, target in ipairs(targets) do
   gl.uniform_matrix4f(loc4.view, true, captureViews[i])
   gl.framebuffer_texture_2d('draw read', 'color attachment 0', target, irradianceMap, 0)
   gl.clear('color', 'depth')
   cube:draw()
end
gl.unbind_framebuffer('draw read')

-- pbr: create a pre-filter cubemap, and re-scale capture FBO to pre-filter scale.
local prefilterMap = gl.new_texture('cube map')
gl.texture_image('cube map positive x', 0, 'rgb16f', 'rgb', 'float', nil, 128, 128)
gl.texture_image('cube map negative x', 0, 'rgb16f', 'rgb', 'float', nil, 128, 128)
gl.texture_image('cube map positive y', 0, 'rgb16f', 'rgb', 'float', nil, 128, 128)
gl.texture_image('cube map negative y', 0, 'rgb16f', 'rgb', 'float', nil, 128, 128)
gl.texture_image('cube map positive z', 0, 'rgb16f', 'rgb', 'float', nil, 128, 128)
gl.texture_image('cube map negative z', 0, 'rgb16f', 'rgb', 'float', nil, 128, 128)
gl.texture_parameter('cube map', 'wrap s', 'clamp to edge')
gl.texture_parameter('cube map', 'wrap t', 'clamp to edge')
gl.texture_parameter('cube map', 'wrap r', 'clamp to edge')
gl.texture_parameter('cube map', 'min filter', 'linear mipmap linear') -- be sure to set minifcation filter to mip_linear 
gl.texture_parameter('cube map', 'mag filter', 'linear')
-- generate mipmaps for the cubemap so OpenGL automatically allocates the required memory.
gl.generate_mipmap('cube map')

-- pbr: run a quasi monte-carlo simulation on the environment lighting to create a prefilter (cube)map.
gl.use_program(prog5)
gl.uniformi(loc5.environmentMap, 0)
gl.uniform_matrix4f(loc5.projection, true, captureProjection)
gl.active_texture(0)
gl.bind_texture('cube map', envCubemap)
gl.bind_framebuffer('draw read', captureFBO)
local maxMipLevels = 5
for mip = 0, maxMipLevels-1 do
   -- resize framebuffer according to mip-level size.
   local mipWidth  = 128 * math.pow(0.5, mip)
   local mipHeight = 128 * math.pow(0.5, mip)
   gl.bind_renderbuffer('renderbuffer', captureRBO)
   gl.renderbuffer_storage('renderbuffer', 'depth component24', mipWidth, mipHeight)
   gl.viewport(0, 0, mipWidth, mipHeight)
   local roughness = mip/(maxMipLevels - 1)
   gl.uniformf(loc5.roughness, roughness)
   for i, target in ipairs(targets) do
      gl.uniform_matrix4f(loc5.view, true, captureViews[i])
      gl.framebuffer_texture_2d('draw read', 'color attachment 0', target, prefilterMap, mip)
      gl.clear('color', 'depth')
      cube:draw()
   end
end
gl.unbind_framebuffer('draw read')

-- pbr: generate a 2D LUT from the BRDF equations used.
local brdfLUTTexture = gl.new_texture('2d')
-- pre-allocate enough memory for the LUT texture.
gl.texture_image('2d', 0, 'rg16f', 'rg', 'float', nil, 512, 512)
-- be sure to set wrapping mode to'clamp to edge' 
gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
gl.texture_parameter('2d', 'min filter', 'linear')
gl.texture_parameter('2d', 'mag filter', 'linear')
-- then re-configure capture framebuffer object and render screen-space quad with BRDF shader.
gl.bind_framebuffer('draw read', captureFBO)
gl.bind_renderbuffer('renderbuffer', captureRBO)
gl.renderbuffer_storage('renderbuffer', 'depth component24', 512, 512)
gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', brdfLUTTexture, 0)
gl.viewport(0, 0, 512, 512)
gl.use_program(prog6)
gl.clear('color', 'depth')
quad:draw()
gl.unbind_framebuffer('draw read')

-- initialize static shader uniforms before rendering
local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
gl.use_program(prog1)
gl.uniform_matrix4f(loc1.projection, true, projection)
gl.use_program(prog3)
gl.uniform_matrix4f(loc3.projection, true, projection)

-- then before rendering, configure the viewport to the original framebuffer's screen dimensions
local scrWidth, scrHeight = glfw.get_framebuffer_size(window)
gl.viewport(0, 0, scrWidth, scrHeight)

local last_frame_time = 0.0 -- last frame time

local function keypressed(x) return glfw.get_key(window, x)=='press' end
local function keyreleased(x) return glfw.get_key(window, x)=='release' end

local animate = false

-- render loop
print("Press 'space' to toggle moving lights")
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
   if keypressed('space') then animate = not animate end

   -- render scene, supplying the convoluted irradiance map to the final shader.
   gl.clear_color(0.2, 0.3, 0.3, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog1)
   local view = camera:view()
   gl.uniform_matrix4f(loc1.view, true, view)
   gl.uniformf(loc1.camPos, camera.position)

   -- bind pre-computed IBL data
   gl.active_texture(0)
   gl.bind_texture('cube map', irradianceMap)
   gl.active_texture(1)
   gl.bind_texture('cube map', prefilterMap)
   gl.active_texture(2)
   gl.bind_texture('2d', brdfLUTTexture)

   -- render rows*column number of spheres with material properties defined by textures
   -- (they all have the same material properties)
   for row=0, nrRows-1 do
      gl.uniformf(loc1.metallic, row/nrRows)
      for col=0, nrColumns-1 do
         -- we clamp the roughness to 0.025 - 1.0 as perfectly smooth surfaces
         -- (roughness of 0.0) tend to look a bit off on direct lighting.
         gl.uniformf(loc1.roughness, clamp(col/nrColumns, 0.05, 1.0))
         local model = translate((col-(nrColumns/2))*spacing, (row-(nrRows/2))*spacing, -2.0)
         gl.uniform_matrix4f(loc1.model, true, model)
         sphere:draw()
      end
   end

   -- render light source (simply re-render sphere at light positions)
   -- this looks a bit off as we use the same shader, but it'll make their positions obvious and 
   -- keeps the codeprint small.
   for i=1,#lightPositions do
      local newPos = lightPositions[i]
      if animate then newPos.x = newPos.x + sin(5*t)*5 end
      gl.uniformf(loc1["lightPositions["..(i-1).."]"], newPos)
      gl.uniformf(loc1["lightColors["..(i-1).."]"], lightColors[i])
      gl.uniform_matrix4f(loc1.model, true, translate(newPos)*scale(0.5))
      sphere:draw()
   end

   -- render skybox (render as last to prevent overdraw)
   gl.use_program(prog3)
   gl.uniform_matrix4f(loc3.view, true, view)
   gl.active_texture(0)
   gl.bind_texture('cube map', envCubemap)
   --gl.bind_texture('cube map', irradianceMap) -- display irradiance map
   cube:draw()

   --[[ render BRDF map to screen
   gl.use_program(prog6)
   quad:draw()
   --]]
   
   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end

