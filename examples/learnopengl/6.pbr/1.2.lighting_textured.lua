#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_camera = require("common.camera")
local new_texture = require("common.texture")
local new_sphere = require("common.sphere")

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
   vec3(0.0, 0.0, 10.0),
}
local lightColors = {
   vec3(150.0, 150.0, 150.0),
}
local nrRows, nrColumns, spacing = 7, 7, 2.5

-- glfw inits and window creation ---------------------------------------------
glfw.version_hint(3, 3, 'core')
glfw.window_hint('samples', 4)
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers

-- build, compile, and link our shader programs --------------------------------
local prog, vsh, fsh = gl.make_program({
   vertex="shaders/1.2.pbr.vert",
   fragment="shaders/1.2.pbr.frag",
})
gl.delete_shaders(vsh, fsh)

-- get the locations of the uniforms:
local loc = {}
local uniforms = { "projection", "view", "model", "camPos",
                  "aoMap", "albedoMap", "metallicMap", "roughnessMap", "normalMap" }
for i=1,#lightPositions do
   table.insert(uniforms, "lightPositions["..(i-1).."]")
   table.insert(uniforms, "lightColors["..(i-1).."]")
end
gl.use_program(prog)
for _, name in ipairs(uniforms) do loc[name]=gl.get_uniform_location(prog, name) end
gl.uniformi(loc.albedoMap, 0)
gl.uniformi(loc.normalMap, 1)
gl.uniformi(loc.metallicMap, 2)
gl.uniformi(loc.roughnessMap, 3)
gl.uniformi(loc.aoMap, 4)

-- load PBR material textures
local albedo = new_texture("../resources/textures/pbr/rusted_iron/albedo.png")
local normal = new_texture("../resources/textures/pbr/rusted_iron/normal.png")
local metallic = new_texture("../resources/textures/pbr/rusted_iron/metallic.png")
local roughness = new_texture("../resources/textures/pbr/rusted_iron/roughness.png")
local ao = new_texture("../resources/textures/pbr/rusted_iron/ao.png")

local sphere = new_sphere()

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

   -- render
   gl.clear_color(0.1, 0.1, 0.1, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog)
   local projection = perspective(rad(camera.zoom), SCR_WIDTH/SCR_HEIGHT, 0.1, 100.0)
   gl.uniform_matrix4f(loc.projection, true, projection)
   gl.uniform_matrix4f(loc.view, true, camera:view())
   gl.uniformf(loc.camPos, camera.position)

   gl.active_texture(0)
   gl.bind_texture('2d', albedo)
   gl.active_texture(1)
   gl.bind_texture('2d', normal)
   gl.active_texture(2)
   gl.bind_texture('2d', metallic)
   gl.active_texture(3)
   gl.bind_texture('2d', roughness)
   gl.active_texture(4)
   gl.bind_texture('2d', ao)
   
   -- render rows*column number of spheres with material properties defined by textures
   -- (they all have the same material properties)
   for row=0,nrRows-1 do 
      for col=0, nrColumns-1 do 
         local model = translate((col-(nrColumns/2))*spacing, (row-(nrRows/2))*spacing, 0.0)
         gl.uniform_matrix4f(loc.model, true, model)
         sphere:draw()
      end
   end

   -- render light source (simply re-render sphere at light positions)
   -- this looks a bit off as we use the same shader, but it'll make their positions obvious and 
   -- keeps the codeprint small.
   for i=1,#lightPositions do
      local newPos = lightPositions[i]
      if animate then newPos.x = newPos.x + sin(5*t)*5 end
      gl.uniformf(loc["lightPositions["..(i-1).."]"], newPos)
      gl.uniformf(loc["lightColors["..(i-1).."]"], lightColors[i])
      gl.uniform_matrix4f(loc.model, true, translate(newPos)*scale(0.5))
      sphere:draw()
   end

   -- swap buffers and poll IO events
   glfw.swap_buffers(window)
   glfw.poll_events()
end


