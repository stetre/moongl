#!/usr/bin/env lua
-- MoonGL example: hello-sdl2.lua
local sdl = require("moonsdl2")
local gl = require "moongl" -- OpenGL bindings

sdl.init()

sdl.gl_set_context_version(3, 3, 'core')

local window = sdl.create_window("Hello, OpenGL!", nil, nil, 600, 400, 
               sdl.WINDOW_OPENGL|sdl.WINDOW_RESIZABLE|sdl.WINDOW_SHOWN)

local glcontext = sdl.gl_create_context(window)
glcontext:make_current(window)

gl.init() -- this is actually glewInit()

local quit = false
while not quit do
   e = sdl.poll_event()
   if e then
      if e.type == 'quit' or (e.type =='keydown' and e.name == 'Escape')  then
         quit = true
      elseif e.type == 'windowevent' and e.event == 'resized' then
         local w, h = e.data1, e.data2
         print("window reshaped to "..w.."x"..h)
         gl.viewport(0, 0, w, h)
      end
   end
   -- ... rendering code goes here ...
   gl.clear_color(0.24, 0.33, 0.42, 1.0)
   gl.clear("color", "depth")
   sdl.gl_swap_window(window)
end

