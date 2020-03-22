#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local new_cube = require("common.cube")
local new_texture = require("common.texture")

local rad = math.rad
local vec3 = glmath.vec3

-- settings
local SCR_WIDTH, SCR_HEIGHT = 800, 600

-- process all input: query GLFW whether relevant keys are pressed/released
-- this frame and react accordingly

-- glfw: initialize and configure
glfw.window_hint('context version major', 3)
glfw.window_hint('context version minor', 3)
glfw.window_hint('opengl profile', 'core')
glfw.window_hint('opengl debug context', true) -- comment this line in a release build! 

-- glfw window creation
local window = glfw.create_window(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL")
glfw.make_context_current(window)
gl.init() -- this loads all OpenGL function pointers
glfw.set_framebuffer_size_callback(window, function(window, width, height)
    gl.viewport(0, 0, width, height)
end)

-- enable OpenGL debug context if context allows for debug context
local flags = { gl.get('context flags') }
for _, flag in ipairs(flags) do flags[flag]=true end
if flags.debug then
   gl.enable('debug output')
   gl.enable('debug output synchronous') -- makes sure errors are displayed synchronously
   gl.debug_message_callback(function (source, type, id, severity, message)
      -- ignore these non-significant error codes:
      if id == 131169 or id == 131185 or id == 131218 or id == 131204 then return end
      print("---------------------------")
      print("Debug message", source, type, id, severity, message)
   end)
   gl.debug_message_control("don't care", "don't care", "don't care", true)
end

-- configure global opengl state
gl.enable('depth test')
gl.enable('cull face')

local prog, vsh, fsh = gl.make_program({
   vertex="shaders/1.debugging.vert", fragment="shaders/1.debugging.frag"})
gl.delete_shaders(vsh, fsh)

local cube = new_cube()
local texture = new_texture("../resources/textures/wood.png")

local loc = {}
local uniforms = { "projection", "model", "tex" }
for _,name in ipairs(uniforms) do loc[name] = gl.get_uniform_location(prog, name) end

-- set up projection matrix
local projection = glmath.perspective(rad(45.0), SCR_WIDTH/SCR_HEIGHT, 0.1, 10.0)
-- The following calls will cause errors because we didn't call gl.use_program().
-- Notice that MoonGL automatically checks the returned error code when calling
-- OpenGL functions, and raises a Lua error() on failure, so here we wrap them in
-- pcall(), just to continue after the error (we should nonetheless see the errors
-- via the debug message callback):
pcall(gl.uniform_matrix4f, loc.projection, true, projection)
pcall(gl.uniformi, loc.tex, 0)

-- render loop
while not glfw.window_should_close(window) do
   -- process input
   if glfw.get_key(window, 'escape') == 'press' then
       glfw.set_window_should_close(window, true)
   end

   -- render
   gl.clear_color(0.0, 0.0, 0.0, 1.0)
   gl.clear('color', 'depth')
   gl.use_program(prog)

   local rotationSpeed = 10.0
   local angle = glfw.get_time() * rotationSpeed
   local model = glmath.translate(0.0, 0.0, -2.5)*
                  glmath.rotate(rad(angle), vec3(1.0, 1.0, 1.0):normalize())
   gl.uniform_matrix4f(loc.model, true, model)

   gl.bind_texture('2d', texture)
   cube:draw()

   glfw.swap_buffers(window)
   glfw.poll_events()
end

