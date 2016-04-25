##MoonGL: Lua bindings for OpenGL

MoonGL is a Lua binding library for [OpenGL](https://www.opengl.org/).

It runs on GNU/Linux and requires 
[Lua](http://www.lua.org/) (>=5.3), 
[OpenGL](https://www.opengl.org/) (>=3.3), and
[GLEW](http://glew.sourceforge.net/).


_Authored by:_ _[Stefano Trettel](https://www.linkedin.com/in/stetre)_

[![Lua logo](./doc/powered-by-lua.gif)](http://www.lua.org/)

#### License

MIT/X11 license (same as Lua). See [LICENSE](./LICENSE).

#### Documentation, Getting and installing, etc.

See the [Reference Manual](https://stetre.github.io/moongl/doc/index.html).

#### Example

Below is an "Hello, World!" example, using [MoonGLFW](https://github.com/stetre/moonglfw) 
as [windowing library](#see-also).

Other examples can be found in the **examples/** directory contained in the release package.

```lua
-- Script: hello.lua

gl = require("moongl")
glfw = require("moonglfw")

glfw.window_hint('context version major', 3)
glfw.window_hint('context version minor', 3)
glfw.window_hint('opengl profile', 'core')

window = glfw.create_window(600, 400, "Hello, World!")
glfw.make_context_current(window)
gl.init() -- this is actually glewInit()

function reshape(_, w, h) 
   print("window reshaped to "..w.."x"..h)
   gl.viewport(0, 0, w, h)
end

glfw.set_window_size_callback(window, reshape)

while not glfw.window_should_close(window) do
   glfw.poll_events()
   -- ... rendering code goes here ...
   gl.clear_color(1.0, 0.5, 0.2, 1.0) -- GLFW orange
   gl.clear("color", "depth")
   glfw.swap_buffers(window)
end
```

The script can be executed at the shell prompt with the standard Lua interpreter:

```shell
$ lua hello.lua
```

#### See also

The following libraries may be used in conjunction with MoonGL, but they do not
depend on it (and viceversa): 

* Windowing:
[MoonFLTK](https://github.com/stetre/moonfltk),
[MoonGLFW](https://github.com/stetre/moonglfw),
[MoonGLUT](https://github.com/stetre/moonglut).

* Math:
[MoonGLMATH](https://github.com/stetre/moonglmath).

* Image and model loading:
[MoonAssimp](https://github.com/stetre/moonassimp),
[MoonSOIL](https://github.com/stetre/moonsoil).

* Audio:
[LuaJACK](https://github.com/stetre/luajack).

