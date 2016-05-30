
## How to install MoonGL

### On Ubuntu

Install Lua as described in the installation instructions for 
[MoonFLTK](https://github.com/stetre/moonfltk/).

Install GLEW:

```sh
$ sudo apt-get install libglew-dev
```

Download MoonGL's [latest release](https://github.com/stetre/moongl/releases)
(e.g. moongl-0.1.tar.gz).

```sh
$ tar -zxpvf moongl-0.1.tar.gz
$ cd moongl-0.1
moongl-0.1$ make
moongl-0.1$ sudo make install
```

### On Windows with MSYS2/MinGW

Set up the MSYS2/MinGW environment and install Lua as described in the installation 
instructions for [MoonFLTK](https://github.com/stetre/moonfltk/).

Install GLEW:

```sh
$ pacman -S mingw-w64-i686-glew      # (32-bit)
$ pacman -S mingw-w64-x86_64-glew    # (64-bit)
```

Download MoonGL's [latest release](https://github.com/stetre/moongl/releases)
(e.g. moongl-0.1.tar.gz).

```sh
$ tar -zxpvf moongl-0.1.tar.gz
$ cd moongl-0.1
moongl-0.1$ make platform=mingw
moongl-0.1$ make install platform=mingw
```

