-- Texture utilities
local gl = require("moongl")
local glmath = require("moonglmath")
local mi = require("moonimage")

-------------------------------------------------------------------------------
local function load_texture(filename)
   mi.flip_vertically_on_load(true)
   local data, width, height = mi.load(filename, 'rgba')
   --print(#data, width, height, width*height*4, filename)
   local texid = gl.new_texture('2d')
   gl.texture_storage('2d', 1, 'rgba8', width, height)
   gl.texture_sub_image('2d', 0, 'rgba', 'ubyte', data, 0, 0, width, height)
   gl.texture_parameter('2d', 'mag filter', 'linear')
   gl.texture_parameter('2d', 'min filter', 'nearest')
   gl.unbind_texture('2d')
   return texid, width, height
end

local SUFFIX = { "posx", "negx", "posy", "negy", "posz", "negz" }
local TARGET = { 'cube map positive x', 'cube map negative x',
                 'cube map positive y', 'cube map negative y',
                 'cube map positive z', 'cube map negative z' }


-------------------------------------------------------------------------------
local function load_cube_map(basename, extension)
   local extension = estension or "png"
   local texid = gl.new_texture('cube map')
   mi.flip_vertically_on_load(false)
   local data, width, height
   for i=1,6 do
      local filename = basename .."_"..SUFFIX[i].."."..extension
      data, width, height = mi.load(filename, 'rgba')
      if i == 1 then -- Allocate immutable storage for the whole cube map texture
         gl.texture_storage('cube map', 1, 'rgba8', width, height)
      end
      gl.texture_sub_image(TARGET[i], 0, 'rgba', 'ubyte', data, 0, 0, width, height)
   end
   gl.texture_parameter('cube map', 'mag filter', 'linear')
   gl.texture_parameter('cube map', 'min filter', 'nearest')
   gl.texture_parameter('cube map', 'wrap s', 'clamp to edge')
   gl.texture_parameter('cube map', 'wrap t', 'clamp to edge')
   gl.texture_parameter('cube map', 'wrap r', 'clamp to edge')
   gl.unbind_texture('cube map')
   return texid, width, height
end


-------------------------------------------------------------------------------
local function load_hdr_cube_map(basename)
   local texid = gl.new_texture('cube map')
-- mi.flip_vertically_on_load(true)
   local data, width, height
   for i=1,6 do
      local filename = basename .."_"..SUFFIX[i]..".hdr"
      data, width, height = mi.load(filename, 'rgb', 'f')
      if i == 1 then -- Allocate immutable storage for the whole cube map texture
         gl.texture_storage('cube map', 1, 'rgb32f', width, height)
      end
      gl.texture_sub_image(TARGET[i], 0, 'rgb', 'float', data, 0, 0, width, height)
   end
   gl.texture_parameter('cube map', 'mag filter', 'linear')
   gl.texture_parameter('cube map', 'min filter', 'nearest')
   gl.texture_parameter('cube map', 'wrap s', 'clamp to edge')
   gl.texture_parameter('cube map', 'wrap t', 'clamp to edge')
   gl.texture_parameter('cube map', 'wrap r', 'clamp to edge')
   gl.unbind_texture('cube map')
   return texid, width, height
end


-------------------------------------------------------------------------------
local perlin = mi.perlin
local clamp = glmath.clamp
local floor = math.floor

local function noise_2d(base_freq, persistence, width, height, periodic)
   local base_freq = base_freq or 4
   local persistence = persistence or 0.5
   local w = width or 128
   local h = height or 128
   local data = {}  -- size = w*h*4
   for row = 0, h-1 do
      for col = 0, w-1 do
         local x = col/(w-1)
         local y = row/(h-1)
         local sum = 0.0
         local freq = base_freq
         local persist = persistence
         local wrap = periodic and freq or nil
         for oct = 0, 3 do
            sum = sum + perlin(x*freq, y*freq, 0, wrap, wrap)
            -- Move to the range [0, 1] and convert to a 0-255 color component
            local val = floor(clamp((sum + 1)/2, 0.0, 1.0) * 255)
            -- Store in texture data
            data[(row*w + col)*4 + 1 + oct] = val
            freq = freq * 2
            persist = persist * persistence
         end
      end
   end
   -- assert(#data, w*h*4)

   -- Store in a texture
   local texid = gl.new_texture('2d')
   gl.texture_storage('2d', 1, 'rgba8', w, h)
   gl.texture_sub_image('2d', 0, 'rgba', 'ubyte', gl.pack('ubyte', data), 0, 0, w, h)
   gl.texture_parameter('2d', 'mag filter', 'linear')
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'wrap s', 'repeat')
   gl.texture_parameter('2d', 'wrap t', 'repeat')
   return texid
end

local function noise_2d_periodic(base_freq, persistence, width, height)
   return noise_2d(base_freq, persistence, width, height, true)
end

return {
   load_texture = load_texture,
   load_hdr_cube_map = load_hdr_cube_map,
   load_cube_map = load_cube_map,
   noise_2d = noise_2d,
   noise_2d_periodic = noise_2d_periodic,
}

