
## Environment setup for MoonXXX modules

### Ubuntu

Install Lua:

```sh
$ sudo apt-get install libreadline-dev
$ wget https://www.lua.org/ftp/lua-5.3.2.tar.gz
$ tar -zxpvf lua-5.3.2.tar.gz
$ cd lua-5.3.2
lua-5.3.2$ make linux
lua-5.3.2$ sudo make install
```

Install libraries:

```sh
$ sudo apt-get install libfltk1.3-dev   # needed by MoonFLTK
$ sudo apt-get install libglfw3-dev     # needed by MoonGLFW
$ sudo apt-get install freeglut3-dev    # needed by MoonGLUT
$ sudo apt-get install libglew-dev      # needed by MoonGL
$ sudo apt-get install libassimp-dev    # needed by MoonAssimp
$ sudo apt-get install libfreetype6-dev # needed by MoonFreeType
```

### Windows, with MSYS2/MinGW-w64

Download the [MSYS2 installer](https://msys2.github.io/) and
follow the instructions from the download page.

From the MSYS2 MinGW-w64 Win32 or Win64 shell:

```sh
$ pacman -S make tar git 
$ pacman -S ${MINGW_PACKAGE_PREFIX}-gcc
$ pacman -S ${MINGW_PACKAGE_PREFIX}-lua
```

Assuming MSYS2 is installed in _C:\msys32_, append the following path
to the PATH environment variable:
- _C:\msys32\mingw32\bin_   (corresponding to _/mingw32/bin_ under MSYS2, for 32-bit), or
- _C:\msys32\mingw64\bin_   (corresponding to _/mingw64/bin_ under MSYS2, for 64-bit).

(To edit PATH, right click My Computer -> Properties -> Advanced ->  Environment variables).

Install libraries:

```sh
$ pacman -S ${MINGW_PACKAGE_PREFIX}-fltk        # needed by MoonFLTK
$ pacman -S ${MINGW_PACKAGE_PREFIX}-glfw        # needed by MoonGLFW
$ pacman -S ${MINGW_PACKAGE_PREFIX}-freeglut    # needed by MoonGLUT
$ pacman -S ${MINGW_PACKAGE_PREFIX}-glew        # needed by MoonGL
$ pacman -S ${MINGW_PACKAGE_PREFIX}-assimp      # needed by MoonAssimp
$ pacman -S ${MINGW_PACKAGE_PREFIX}-freetype    # needed by MoonFreeType
```

