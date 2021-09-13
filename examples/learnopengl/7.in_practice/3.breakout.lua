#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local mi = require("moonimage")
local ft = require("moonfreetype")
local sf = require("moonsndfile")
local al = require("moonal")

-- A few shortcuts:
local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local scale, translate, rotate = glmath.scale, glmath.translate, glmath.rotate
local clamp = glmath.clamp
local random, abs = math.random, math.abs

math.randomseed(os.time())

local SCREEN_W, SCREEN_H = 800, 600 -- do not change, the game is coded with these in mind

glfw.version_hint(3, 3, 'core')
glfw.window_hint('resizable', false)
local window = glfw.create_window(SCREEN_W, SCREEN_H, "Breakout (Lua port)")
glfw.make_context_current(window)
gl.init()

-------------------------------------------------------------------------------
-- Utilities for creating programs and quads
-------------------------------------------------------------------------------

local function create_program(what, uniforms)
-- Create a shader programs and gets the locations of its uniform variables
   local path = "shaders/3."..what
   local prog, vsh, fsh = gl.make_program({vertex= path..".vert", fragment=path..".frag"})
   gl.delete_shaders(vsh, fsh)
   local loc = {}
   if uniforms then
      for _, name in ipairs(uniforms) do
         loc[name]=gl.get_uniform_location(prog, name)
      end
   end
   gl.use_program(prog)
   return prog, loc
end

local function create_quad_vao(vertices)
   local vertices = vertices or {
   -- position  texcoords
      0.0, 1.0, 0.0, 1.0,
      1.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 0.0, 
      0.0, 1.0, 0.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 0.0, 1.0, 0.0,
   }
   local vao = gl.new_vertex_array()
   local vbo = gl.new_buffer('array')
   gl.buffer_data('array', gl.packf(vertices), 'static draw')
   gl.enable_vertex_attrib_array(0) -- position and texcoords, packed in a vec4
   gl.vertex_attrib_pointer(0, 4, 'float', false, 0, 0)
   gl.unbind_buffer('array')
   gl.unbind_vertex_array()
   return vao, vbo
end

local function delete_quad_vao(vao, vbo)
   if vao then
      gl.delete_buffers(vbo)
      gl.delete_vertex_arrays(vao)
   end
end

-------------------------------------------------------------------------------
-- Texture2d
-------------------------------------------------------------------------------

local function NewTexture2d(arg1, alpha, wrap_s, wrap_t, filt_min, filt_mag)
   local filename, width, height -- arg1 = filename or {width, heigth}
   if type(arg1) == 'string' then filename = arg1
   else width, height = arg1[1], arg1[2]
   end
   local format = alpha and 'rgba' or 'rgb' -- format of texture object and of loaded image
   local wrap_s = wrap_s or 'repeat'     -- wrap mode on S axis
   local wrap_t = wrap_t or 'repeat'     -- wrap mode on T axis
   local filt_min = filt_min or 'linear' -- filter mode for minification
   local filt_mag = filt_mag or 'linear' -- filter mode for magnification
   local id = gl.new_texture('2d')
   if filename then -- load image from texture
      local data, w, h = mi.load(filename, format)
      gl.texture_image('2d', 0, format, format, 'ubyte', data, w, h)
   else -- empty texture
      gl.texture_image('2d', 0, format, format, 'ubyte', nil, width, height)
   end
   gl.texture_parameter('2d', 'wrap s', wrap_s)
   gl.texture_parameter('2d', 'wrap r', wrap_t)
   gl.texture_parameter('2d', 'min filter', filt_min)
   gl.texture_parameter('2d', 'mag filter', filt_mag)
   gl.unbind_texture('2d')

   return setmetatable({}, {
      __index = {
         id = function(texture) return id end,
         bind = function(texture) gl.bind_texture('2d', id) end,
      },
      __gc = function(texture) 
         if not id then return end
         gl.delete_textures(id)
         id = nil
      end,
   })
end

-------------------------------------------------------------------------------
-- GameObject (duck type, rfr. https://en.wikipedia.org/wiki/Duck_typing)
-------------------------------------------------------------------------------
-- A GameObject is any table that has the following fields:
-- obj.pos        vec2        position of the object (screen pixels)
-- obj.size       vec2        size (pixels)
-- obj.vel        vec2        velocity (pixels/s)
-- obj.color      vec3        RGB color
-- obj.rot        float       rotation angle (radians)
-- obj.texture    Texture2d

-------------------------------------------------------------------------------
-- SpriteRenderer
-------------------------------------------------------------------------------

local function NewSpriteRenderer(projection)
   local prog, loc = create_program("sprite", { "sprite", "projection", "model", "spriteColor"})
   gl.uniformi(loc.sprite, 0) -- sampler
   gl.uniform_matrix4f(loc.projection, true, projection)
   local vao, vbo = create_quad_vao()
   return setmetatable({}, {
      __index = {
         draw = function(renderer, obj) -- obj=GameObject
            local sx, sy = table.unpack(obj.size)
            local model = translate(obj.pos.x, obj.pos.y, 0)
                         *translate(0.5*sx, 0.5*sy, 0) -- move origin to quad center
                         *rotate(obj.rot, 0, 0, 1)
                         *translate(-0.5*sx, -0.5*sy, 0) -- move origin back
                         *scale(sx, sy, 1.0)
            gl.use_program(prog)
            gl.uniform_matrix4f(loc.model, true, model)
            gl.uniformf(loc.spriteColor, obj.color)
            gl.active_texture(0)
            obj.texture:bind()
            gl.bind_vertex_array(vao)
            gl.draw_arrays('triangles', 0, 6)
            gl.unbind_vertex_array()
         end,
      },
      __gc = function(renderer)
         if not prog then return end
         gl.delete_program(prog)
         delete_quad_vao(vao, vbo)
         prog, vao, vbo = nil
      end,
   })
end

-------------------------------------------------------------------------------
-- Collision detection
-------------------------------------------------------------------------------
local COMPASS = { up=vec2(0,1), down=vec2(0,-1), right=vec2(1,0), left=vec2(-1,0) }

local function vector_direction(target)
-- Calculates which direction the vec2 target is facing
   local max = 0
   local best_match = "up"
   for dir, v in pairs(COMPASS) do
      local dot_product = target * v
      if dot_product > max then
         max, best_match = dot_product, dir
      end
   end
   return best_match -- returns one among 'up', 'down', 'right', and 'left'
end

local function check_ball_collision(ball, obj)
-- Checks if the given ball and GameObject obj collide (circle-AABB collision).
-- Returns false if they don't collide, otherwise returns (true, dir, distance),
-- where dir is the collision direction ('up'|'down'|'left'|'right'), and
-- distance is a vec2 from the ball center to the closest point on the object's AABB.
   local ball_center = ball.pos + vec2(ball.radius, ball.radius)
   local aabb_half_extents = obj.size/2
   local aabb_center = obj.pos + aabb_half_extents
   local center_to_center = ball_center - aabb_center 
   -- Point on the box that is closest to the circle:
   local closest = aabb_center + clamp(center_to_center, -aabb_half_extents, aabb_half_extents)
   local distance = closest - ball_center
   if distance:norm() >= ball.radius then return false end -- no collision
   return true, vector_direction(distance), distance
end

local function check_collision(obj1, obj2)
-- Checks if the two given GameObject collide (AABB-AABB collision).
   local pos1, size1 = obj1.pos, obj1.size
   local pos2, size2 = obj2.pos, obj2.size
   return pos1.x + size1.x >= pos2.x and
          pos2.x + size2.x >= pos1.x and
          pos1.y + size1.y >= pos2.y and
          pos2.y + size2.y >= pos1.y
end

-------------------------------------------------------------------------------
-- Player
-------------------------------------------------------------------------------

local function NewPlayer(pos, size, vel, texture, color) -- GameObject
   local player = {}
   player.texture = texture
   player.rot = 0
   local function reset(pos, size, vel, color)
      player.pos = vec2(pos)
      player.vel = vec2(vel)
      player.size = vec2(size)   
      player.color = vec3(color)
   end
   reset(pos, size, vel, color)
   return setmetatable(player, {
      __index = {
         reset = function(player, pos, size, vel, color)
            reset(pos, size, vel, color)
         end,
      },
--    __gc = function(player) end,
   })
end

-------------------------------------------------------------------------------
-- Ball
-------------------------------------------------------------------------------

local function NewBall(pos, radius, vel, color, texture) -- GameObject
   local ball = {}
   ball.texture = texture
   ball.radius = radius
   ball.rot = 0
   ball.size = vec2(radius*2, radius*2)
   local function reset( pos, vel, color)
      ball.pos = vec2(pos)
      ball.vel = vec2(vel)
      ball.color = vec3(color)
      ball.stuck, ball.sticky, ball.passthrough = true, false, false
   end
   reset(pos, vel, color)

   return setmetatable(ball, {
      __index = {
         reset = function(ball, pos, vel, color)
            reset(pos, vel, color)
         end,
         move = function(ball, dt)
         -- moves the ball, keeping it constrained within the window bounds (except bottom edge)
            if not ball.stuck then
               ball.pos = ball.pos + ball.vel*dt
               local pos, vel, size = ball.pos, ball.vel, ball.size
               if pos.x <= 0.0 then -- ball beyond left edge
                  vel.x = -vel.x
                  pos.x = 0.0
               elseif pos.x + size.x >= SCREEN_W then -- ball beyond right edge
                  vel.x = -vel.x
                  pos.x = SCREEN_W - size.x
               end
               if pos.y <= 0.0 then -- ball beyond top edge
                  vel.y = -vel.y
                  pos.y = 0.0
               end
            end
         end,
      },
--    __gc = function(ball) end,
   })
end

-------------------------------------------------------------------------------
-- PowerUp
-------------------------------------------------------------------------------

local function NewPowerUp(powerup_type, color, duration, pos, texture) -- GameObject
   local powerup = { }
   powerup[powerup_type] = true
   powerup.color = vec3(color)
   powerup.duration = duration -- seconds
   powerup.pos = vec2(pos)
   powerup.size = vec2(60, 20)
   powerup.vel = vec2(0, 150) -- velocity when spawned
   powerup.rot = 0
   powerup.texture = texture
   powerup.destroyed = false
   powerup.active = false
   return setmetatable(powerup, {
      __index = {
      },
--    __gc = function(powerup) end,
   })
end

-------------------------------------------------------------------------------
-- Brick
-------------------------------------------------------------------------------

local function NewBrick(pos, size, texture, color, solid) -- GameObject
   local brick = {}
   brick.pos = vec2(pos)   
   brick.size = vec2(size) 
   brick.rot = 0
   brick.color = vec3(color)
   brick.solid = solid
   brick.texture = texture
   return setmetatable(brick, {
      __index = {
      },
--    __gc = function(brick) end,
   })
end

-------------------------------------------------------------------------------
-- Level
-------------------------------------------------------------------------------
-- Holds all Tiles as part of a Breakout level

local Solid_texture, Nonsolid_texture -- Texture2d, shared by all the bricks
local BRICK_COLOR = {
   [1] = vec3(0.8, 0.8, 0.7), -- solid brick
   [2] = vec3(0.2, 0.6, 1.0),
   [3] = vec3(0.0, 0.7, 0.0),
   [4] = vec3(0.8, 0.8, 0.4),
   [5] = vec3(1.0, 0.5, 0.0),
}

local function NewLevel(description)
-- One nice thing about Lua is that it is by itself a description language, so we
-- can describe a level simply with a table without the need for a dedicated parser.
-- Here 'description' is a table containing nrows tables of ncols numbers each.
-- That is, an nrows x ncols matrix defining a grid that covers the top half of the
-- screen. Each matrix element determines what goes in the corresponding position:
-- 0: no tile, 1: a solid tile, 2..5: a non solid tile of the given BRICK_COLOR.
   if not Solid_texture then -- create textures, shared by all bricks
      Solid_texture = NewTexture2d("../resources/textures/block_solid.png", false)
      Nonsolid_texture = NewTexture2d("../resources/textures/block.png", false)
   end
   local nrows, ncols = #description, #description[1]
   local w, h = SCREEN_W/ncols, SCREEN_H/2/nrows
   local bricks = {} -- iterate with pairs, because there will be gaps
   local num_bricks = 0 -- number of non-solid bricks
   for i = 1, nrows do
      for j = 1, ncols do
         local k = description[i][j]
         if k > 0 then -- skip empty positions
            local pos = vec2(w*(j-1), h*(i-1))
            local size = vec2(w, h)
            local texture = k==1 and Solid_texture or Nonsolid_texture
            local color = BRICK_COLOR[k] or vec3(1, 1, 1)
            local solid = k==1
            if not solid then num_bricks = num_bricks +1 end
            table.insert(bricks, NewBrick(pos, size, texture, color, solid))
         end
      end
   end
   return setmetatable({}, {
      __index = {
         bricks = function(level) return bricks end,
         destroy_brick = function(level, i) 
            if not bricks[i].solid then num_bricks = num_bricks-1 end
            bricks[i]=nil
         end,
         is_completed = function(level) return num_bricks == 0 end,
      },
--    __gc = function(level) end,
   })
end

-------------------------------------------------------------------------------
-- ParticleGenerator
-------------------------------------------------------------------------------
-- Renders a large number of particles by repeatedly spawning and updating 
-- particles and killing them after a given amount of time.

local function NewParticleGenerator(projection, texture, amount)
   local prog, loc = create_program("particle", { "sprite", "projection", "offset", "color"})
   gl.uniformi(loc.sprite, 0) -- sampler
   gl.uniform_matrix4f(loc.projection, true, projection)
   local texture = texture -- Texture2d
   local amount = amount   -- integer
   local vao, vbo = create_quad_vao()
   local particles, unused_particles = {}, {}
   -- create amount particles
   for i = 1, amount do
      local p = {pos=vec2(), vel=vec2(), color=vec4(1, 1, 1, 1), life=0.0}
      table.insert(particles, p)
      table.insert(unused_particles, p)
   end

   local function respawn_particle(object, offset)
      local p = unused_particles[#unused_particles]
      if p then 
         unused_particles[#unused_particles]=nil
      else -- override the first one (amount should be increased if this case happens often)
         p = p[1]
      end
      local r = (random()*100 -50)/10
      p.pos = object.pos + offset + vec2(r, r)
      p.vel = object.vel*0.1
      p.life = 1.0
      local c = 0.5 * (1 + random())
      p.color = vec4(c, c, c, 1)
   end

   return setmetatable({}, {
      __index = {
         update = function(generator, dt, object, newparticles, offset)
            local offset = offset and vec2(offset) or vec2(0, 0)
            -- add new particles
            for i=1, newparticles do respawn_particle(object, offset) end
            -- update particle's state
            for _, p in ipairs(particles) do
               if p.life > 0.0 then -- alive & kicking
                  p.life = p.life - dt
                  if p.life <= 0.0 then
                     table.insert(unused_particles, p)
                  else
                     p.pos = p.pos - p.vel*dt
                     p.color.a = p.color.a -2.5*dt
                  end
               end
            end
         end,
         draw = function(generator)
            -- use additive blending to give it a 'glow' effect
            gl.blend_func('src alpha', 'one')
            gl.use_program(prog)
            texture:bind()
            gl.bind_vertex_array(vao)
            for _, p in ipairs(particles) do
               if p.life > 0.0 then
                  gl.uniformf(loc.offset, p.pos)
                  gl.uniformf(loc.color, p.color)
                  gl.draw_arrays('triangles', 0, 6)
               end
            end
            gl.unbind_vertex_array(0)
            -- don't forget to reset to default blending mode
            gl.blend_func('src alpha', 'one minus src alpha')
         end,
      },
      __gc = function(generator)
         if not prog then return end
         gl.delete_program(prog)
         delete_quad_vao(vao, vbo)
         prog, vao, vbo = nil
      end,
   })
end

-------------------------------------------------------------------------------
-- Effects
-------------------------------------------------------------------------------
-- Post-processing effects (consuse, chaos, shake).

local function NewEffects()
   local effects = { confuse=false, chaos=false, shake=false }
   local w, h = SCREEN_W, SCREEN_H
   local uniforms = {
      "scene", "time", "offsets", 
      "confuse", "chaos", "shake", 
      "edge_kernel", "blur_kernel"
   }
   local prog, loc = create_program("post_processing", uniforms)
   -- initialize a few uniform variables that never change afterwards
   gl.use_program(prog)
   gl.uniformi(loc.scene, 0) -- sampler
   local offset = 1/300
   local offsets = {
     -offset,  offset,  -- top-left
         0.0,  offset,  -- top-center
      offset,  offset,  -- top-right
     -offset,     0.0,  -- center-left
         0.0,     0.0,  -- center-center
      offset,     0.0,  -- center - right
     -offset, -offset,  -- bottom-left
         0.0, -offset,  -- bottom-center
      offset, -offset,  -- bottom-right    
   }
   gl.uniformfv(loc.offsets, 9, offsets)
   local edge_kernel = {
      -1, -1, -1,
      -1,  8, -1,
      -1, -1, -1,
   }
   gl.uniformiv(loc.edge_kernel, 9, edge_kernel)
   local blur_kernel = {
      1/16, 2/16, 1/16,
      2/16, 4/16, 2/16,
      1/16, 2/16, 1/16,
   }
   gl.uniformfv(loc.blur_kernel, 9, blur_kernel)

   local msfbo = gl.new_framebuffer('draw read')   -- multisampled FBO
   local rbo = gl.new_renderbuffer('renderbuffer') -- color buffer for msfbo
   gl.renderbuffer_storage_multisample('renderbuffer', 4, 'rgb', w, h)
   gl.framebuffer_renderbuffer('draw read', 'color attachment 0', 'renderbuffer', rbo)
   assert(gl.check_framebuffer_status('draw read')=='complete', "failed to initialize msfbo")
   local texture = NewTexture2d({w, h})
   local fbo = gl.new_framebuffer('draw read')  -- FBO to blit multisampled color buffer to
   gl.framebuffer_texture_2d('draw read', 'color attachment 0', '2d', texture:id(), 0)
   assert(gl.check_framebuffer_status('draw read')=='complete', "failed to initialize fbo")
   gl.unbind_framebuffer('draw read')

   -- initialize quad for rendering postprocessing texture
   local vao, vbo = create_quad_vao({
      -- pos         tex
      -1.0, -1.0, 0.0, 0.0,
       1.0,  1.0, 1.0, 1.0,
      -1.0,  1.0, 0.0, 1.0,
      -1.0, -1.0, 0.0, 0.0,
       1.0, -1.0, 1.0, 0.0,
       1.0,  1.0, 1.0, 1.0,
   })

   return setmetatable(effects, {
      __index = {
         begin_render = function(effects)
         -- call this called before rendering the game, to redirect the output to the msfbo
            gl.bind_framebuffer('draw read', msfbo)
            gl.clear_color(0, 0, 0, 1)
            gl.clear('color')
         end,
         end_render = function(effects, t) 
         -- call this after rendering the game
             -- resolve multisampled color-buffer into intermediate FBO to store to texture
            gl.bind_framebuffer('read', msfbo)
            gl.bind_framebuffer('draw', fbo)
            gl.blit_framebuffer(0, 0, w, h, 0, 0, w, h, 'nearest', 'color')
            -- revert to default framebuffer
            gl.unbind_framebuffer('draw read')
            gl.use_program(prog)
            gl.uniformf(loc.time, t)
            gl.uniformb(loc.confuse, effects.confuse)
            gl.uniformb(loc.chaos, effects.chaos)
            gl.uniformb(loc.shake, effects.shake)
            -- render textured quad
            gl.active_texture(0)
            texture:bind()
            gl.bind_vertex_array(vao)
            gl.draw_arrays('triangles', 0, 6)
            gl.unbind_vertex_array()
         end,
      },
      __gc = function(effects)
         if not msfbo then return end
         gl.delete_framebuffers(msfbo, fbo)
         gl.delete_renderbuffers(rbo)
         texture = nil
         gl.delete_buffers(vbo)
         gl.delete_vertex_arrays(vao)
         msfbo, rbo, fbo, vao, vbo, texture = nil
      end,
   })
end

-------------------------------------------------------------------------------
-- TextRenderer
-------------------------------------------------------------------------------
-- Renders text displayed by a font loaded using the FreeType library. A single
-- font is loaded, processed into a list of Character items for later rendering.

local function NewTextRenderer(projection)
   local prog, loc = create_program("text_2d", { "projection", "text", "textColor" })
   gl.use_program(prog)
   gl.uniformi(loc.text, 0) -- sampler
   gl.uniform_matrix4f(loc.projection, true, projection)
   -- create vao for textured quads
   local vao = gl.new_vertex_array()
   local vbo = gl.new_buffer('array')
   gl.buffer_data('array', gl.sizeof('float')*6*4, 'dynamic draw')
   gl.enable_vertex_attrib_array(0) -- position and texcoords, packed in a vec4
   gl.vertex_attrib_pointer(0, 4, 'float', false, 0, 0)
   gl.unbind_buffer('array')
   gl.unbind_vertex_array()
   gl.pixel_store('unpack alignment', 1) -- disable OpenGL byte-alignment restriction
   local char = {}
   local hby, size

   local function load_font(filename, font_size)
      -- Loads the givent font and pre-compiles a list of characters
      -- Initialize and load the FreeType library
      local ftlib = ft.init_freetype()
      -- load the font face and set the desired glyph size
      local face = ft.new_face(ftlib, filename)
      face:set_pixel_sizes(0, font_size)
      -- first clear the previously loaded characters
      for _, ch in pairs(char) do gl.delete_texture(ch.texid) end
      char = {}
      -- Pre-load the first 128 ASCII characters
      for c = 0, 127 do 
         -- Load glyph
         face:load_char(c, ft.LOAD_RENDER)
         local glyph = face:glyph()
         local bitmap = glyph.bitmap
         -- Generate texture and set texture options
         local texid = gl.new_texture('2d')
         gl.texture_image('2d', 0, 'red', 'red', 'ubyte', bitmap.buffer, bitmap.width, bitmap.rows)
         gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
         gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
         gl.texture_parameter('2d', 'min filter', 'linear')
         gl.texture_parameter('2d', 'mag filter', 'linear')
         -- Store character info for later use
         char[c] = {
            texid = texid,
            size = vec2(bitmap.width, bitmap.rows), -- glyph size
            bearing = vec2(bitmap.left, bitmap.top), -- offset from baseline to left/top of glyph
            advance = glyph.advance.x -- horizontal offset to advance to next glyph
         }
      end
      gl.unbind_texture('2d')
      face:done()
      ftlib:done()
      hby = char[string.byte('H')].bearing.y
      size = font_size
   end

   local function render(text, x, y, scale, color)
      gl.use_program(prog)
      gl.enable('blend')
      gl.blend_func('src alpha', 'one minus src alpha')
      gl.uniformf(loc.textColor, color)
      gl.bind_vertex_array(vao)
      gl.active_texture(0)
      for i = 1, #text do
         local c = text:byte(i)  -- numeric code for the i-th character
         local ch = char[c] -- info for the character
         local xpos = x + ch.bearing.x*scale
         local ypos = y + (hby - ch.bearing.y)*scale
         local w = ch.size.x * scale
         local h = ch.size.y * scale
         -- Update the vbo, and render the quad textured with this character's texture.
         gl.bind_buffer('array', vbo)
         gl.buffer_sub_data('array', 0, gl.packf({
            { xpos,     ypos + h,   0.0, 1.0 },
            { xpos + w, ypos,       1.0, 0.0 },
            { xpos,     ypos,       0.0, 0.0 },
            { xpos,     ypos + h,   0.0, 1.0 },
            { xpos + w, ypos + h,   1.0, 1.0 },
            { xpos + w, ypos,       1.0, 0.0 }
         }))
         gl.unbind_buffer('array')
         gl.bind_texture('2d', ch.texid)
         gl.draw_arrays('triangles', 0, 6)
         -- Advance x position for the next glyph, if any
         x = x + (ch.advance >> 6) * scale -- = x + ch.advance/64 *scale
      end
      gl.unbind_vertex_array()
      gl.unbind_texture('2d')
   end

   return setmetatable({}, {
      __index = {
         load_font = function(renderer, filename, font_size)
            load_font(filename, font_size)
         end,
         render = function(renderer, text, x, y, scale, color)
            render(text, x, y, scale, color)
         end,
      },
      __gc = function(renderer)
         if not prog then return end
         for _, ch in pairs(char) do gl.delete_texture(ch.texid) end
         gl.delete_program(prog)
         gl.delete_vertex_arrays(vao)
         gl.delete_buffers(vbo)
         prog, vao, vbo = nil
      end,
   })
end

-------------------------------------------------------------------------------
-- SoundSample 
-------------------------------------------------------------------------------

local SoundDevice = al.open_device()
local SoundContext = al.create_context(SoundDevice)

local function loadsoundfile(filename)
-- Load sound data and metadata from the given sound file.
   local sndfile, info = sf.open(filename, "r")
   local data = sndfile:read('float', info.frames)
   local format
   if info.channels == 1 then format = 'mono float32'
   elseif info.channels == 2 then format = 'stereo float32'
   else error("unexpected number of channels in sound file")
   end
   sf.close(sndfile) -- we don't need it any more
   return data, format, info.samplerate
end

local function NewSoundSample(filename)
-- A SoundSample is an object holding a dedicated OpenAL source, whose buffer
-- is set with the data from the given file.
-- The sample object has methods to play/pause/stop/rewind it.
   local data, format, srate = loadsoundfile(filename)
   local buffer = al.create_buffer(SoundContext)
   al.buffer_data(buffer, format, data, srate)
   local source = al.create_source(SoundContext)
   source:set('buffer', buffer)

   return setmetatable({}, {
      __index = {
         play = function(sample, loop) -- set loop=true to enable looping
            source:set('looping', loop and true or false)
            source:play()
         end,
         stop = function(sample) source:stop() end,
         pause = function (sample) source:pause() end,
         rewind = function (sample) source:rewind() end,
      },
      __gc = function(sample)
         if not sample then return end
        al.delete_source(source)
         al.delete_buffer(buffer)
         source, buffer = nil
      end,
   })
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------

-- Load textures:
local Texture = {}
Texture.background = NewTexture2d("../resources/textures/background.jpg", false)
Texture.face = NewTexture2d("../resources/textures/awesomeface.png", true)
Texture.block = NewTexture2d("../resources/textures/block.png", false)
Texture.block_solid = NewTexture2d("../resources/textures/block_solid.png", false)
Texture.paddle = NewTexture2d("../resources/textures/paddle.png", true)
Texture.particle = NewTexture2d("../resources/textures/particle.png", true)
Texture.powerup_speed = NewTexture2d("../resources/textures/powerup_speed.png", true)
Texture.powerup_sticky = NewTexture2d("../resources/textures/powerup_sticky.png", true)
Texture.powerup_increase = NewTexture2d("../resources/textures/powerup_increase.png", true)
Texture.powerup_confuse = NewTexture2d("../resources/textures/powerup_confuse.png", true)
Texture.powerup_chaos = NewTexture2d("../resources/textures/powerup_chaos.png", true)
Texture.powerup_passthrough = NewTexture2d("../resources/textures/powerup_passthrough.png", true)

-- Load sounds:
-- NOTE: libsndfile does not support mp3 files, we must convert them to wav.
-- The following instructions show how to do it with ffmpeg:
-- $ cd ../resources/audio
-- $ ffmpeg -i breakout.mp3 breakout.wav
-- $ ffmpeg -i bleep.mp3 bleep1.wav
-- (bleep.mp3 and bleep.wav are different sounds, so we rename the former as bleep1 when
-- converting it to avoid overwriting the latter)
local Sound = {}
Sound.breakout = NewSoundSample("../resources/audio/breakout.wav") -- converted breakout.mp3
Sound.bleep = NewSoundSample("../resources/audio/bleep.wav")
Sound.bleep1 = NewSoundSample("../resources/audio/bleep1.wav")     -- converted bleep.mp3
Sound.powerup = NewSoundSample("../resources/audio/powerup.wav")
Sound.solid = NewSoundSample("../resources/audio/solid.wav")
Sound.breakout:play(true)

-- Initial or constant values:
local PLAYER_SIZE = vec2(100, 20)
local PLAYER_VEL = 500
local PLAYER_POS = vec2((SCREEN_W-PLAYER_SIZE.x)/2, SCREEN_H-PLAYER_SIZE.y)
local PLAYER_COLOR = vec3(1, 1, 1)
local BALL_RADIUS = 12.5
local BALL_VEL = vec2(100, -350)
local BALL_POS = PLAYER_POS + vec2(PLAYER_SIZE.x/2-BALL_RADIUS, -BALL_RADIUS*2)
local BALL_COLOR = vec3(1, 1, 1)
local PROJECTION = glmath.ortho(0, SCREEN_W, SCREEN_H, 0, -1, 1)
local BACKGROUND = { -- GameObject
   texture = Texture.background,
   pos = vec2(0.0, 0.0), 
   size = vec2(SCREEN_W, SCREEN_H), 
   rot = 0,
   color = vec3(1, 1, 1),
}
local TEXT_COLOR = vec3(1, 1, 1)

-- Load levels:
local LevelDescriptions = require("./levels")
local Levels = {}
for i, descr in ipairs(LevelDescriptions) do Levels[i] = NewLevel(descr) end

-- Create renderers and game objects:
local Sprite = NewSpriteRenderer(PROJECTION)
local Text = NewTextRenderer(PROJECTION)
Text:load_font("../resources/fonts/OCRAEXT.TTF", 24)
local Particles = NewParticleGenerator(PROJECTION, Texture.particle, 500)
local Effects = NewEffects()
local Player = NewPlayer(PLAYER_POS, PLAYER_SIZE, PLAYER_VEL, Texture.paddle, PLAYER_COLOR)
local Ball = NewBall(BALL_POS, BALL_RADIUS, BALL_VEL, BALL_COLOR, Texture.face)

-- Game state:
local State = 'MENU' -- the current state of the game ('MENU', 'ACTIVE', or 'WIN')
local LevelIndex = 1 -- the current level index in LevelDescriptions
local Level = Levels[1] -- the current level
local Keys, KeysProcessed = {}, {} -- book-keeping for keyboard input
local Lives = 3
local ShakeTime = 0.0
local PowerUps = {} -- iterate with pairs, because there will be gaps

local function reset_level()
   Levels[LevelIndex] = NewLevel(LevelDescriptions[LevelIndex])
   Level = Levels[LevelIndex]
   Lives = 3
   ShakeTime = 0.0
end

local function reset_player()
   Player:reset(PLAYER_POS, PLAYER_SIZE, PLAYER_VEL, PLAYER_COLOR)
   Ball:reset(BALL_POS, BALL_VEL, BALL_COLOR)
   Effects.chaos = false
   Effects.confuse = false
end

local function spawn_powerups(obj)
   local pos = obj.pos
   if random() < 1/75 then -- 1 in 75 chance
      table.insert(PowerUps, NewPowerUp('speed', vec3(.5,.5,1), 0, pos, Texture.powerup_speed))
   end
   if random() < 1/75 then
      table.insert(PowerUps, NewPowerUp('sticky', vec3(1,.5,1), 20, pos, Texture.powerup_sticky))
   end
   if random() < 1/75 then
      table.insert(PowerUps, NewPowerUp('passthrough', vec3(.5,1,.5), 10, pos, Texture.powerup_passthrough))
   end
   if random() < 1/75 then
      table.insert(PowerUps, NewPowerUp('increase', vec3(1,.6,.4), 0, pos, Texture.powerup_increase))
   end
   if random() < 1/15 then -- negative powerups should spawn more often
      table.insert(PowerUps, NewPowerUp('confuse', vec3(1,.3,.3), 15, pos, Texture.powerup_confuse))
   end
   if random() < 1/15 then
      table.insert(PowerUps, NewPowerUp('chaos', vec3(.9,.25,.25), 15, pos, Texture.powerup_chaos))
   end
end

local function activate_powerup(powerup)
   if powerup.speed then
      Ball.vel = Ball.vel*1.2
   elseif powerup.sticky then
      Ball.sticky = true
      Player.color = vec3(1, .5, 1)
   elseif powerup.passthrough then
      Ball.passthrough = true
      Ball.color = vec3(1, .5, .5)
   elseif powerup.increase then
      Player.size.x = Player.size.x + 50
   elseif powerup.confuse then
      if not Effects.chaos then Effects.confuse = true end
   elseif powerup.chaos then
      if not Effects.confuse then Effects.chaos = true end
   end
end

local function do_collisions(dt)
   -- Ball-Brick collisions
   for i, brick in pairs(Level:bricks()) do
      local collide, dir, distance = check_ball_collision(Ball, brick)
      if collide then
         if brick.solid then
            ShakeTime = 0.05
            Effects.shake = true
            Sound.solid:play()
         else -- destroy it
            spawn_powerups(brick)
            Level:destroy_brick(i)
            Sound.bleep1:play()
         end
         -- collision resolution
         if not (Ball.passthrough and not brick.solid) then
            local pos, vel = Ball.pos, Ball.vel
            if dir == 'left' or dir == 'right' then -- horizontal collision
               vel.x = - vel.x -- reverse horizontal velocity
               local penetration = Ball.radius - abs(distance.x)
               if dir == 'left' then
                  pos.x = pos.x + penetration -- move back right
               else
                  pos.x = pos.x - penetration -- move back left
               end
            else -- vertical collision
               vel.y = - vel.y -- reverse vertical velocity
               local penetration = Ball.radius - abs(distance.y)
               if dir == 'up' then
                  pos.y = pos.y - penetration -- move back up
               else
                  pos.y = pos.y + penetration -- move back down
               end
            end 
         end
      end
   end
   -- Player-PowerUp collisions
   for _, powerup in pairs(PowerUps) do
      if not powerup.destroyed then
         powerup.destroyed = powerup.pos.y >= SCREEN_H -- destroy if beyond bottom edge
         if check_collision(Player, powerup) then -- collided with player
            activate_powerup(powerup)
            powerup.destroyed = true
            powerup.active = true
            Sound.powerup:play()
         end
      end
   end
   -- Player-Ball collisions
   if not Ball.stuck then
      local collide, dir, diff = check_ball_collision(Ball, Player)
      if collide and not Ball.stuck then
         -- check where it hit the board, and change velocity based on where it hit the board
         local centerBoard = Player.pos.x + Player.size.x/2
         local distance = (Ball.pos.x + Ball.radius) - centerBoard
         local percentage = distance/(Player.size.x/2)
         -- then move accordingly
         local strength = 2
         local speed = Ball.vel:norm()
         Ball.vel.x = BALL_VEL.x*percentage*strength
         Ball.vel = Ball.vel:normalize() * speed -- keep total speed consistent
         -- fix sticky paddle
         Ball.vel.y = -abs(Ball.vel.y)
         -- if Sticky powerup is activated, also stick ball to paddle once new velocity
         -- vectors were calculated
        Ball.stuck = Ball.sticky
        Sound.bleep:play()
      end
   end
end

local function active_powerup(powerup_type)
-- Checks if a PowerUp of the given type is active
   for _, powerup in pairs(PowerUps) do
      if powerup[powerup_type] and powerup.active then return true end
   end
   return false
end

local function update_powerups(dt)
   for _, powerup in pairs(PowerUps) do
      powerup.pos = powerup.pos + powerup.vel*dt
      if powerup.active then
         powerup.duration = powerup.duration - dt
         if powerup.duration <= 0.0 then
            powerup.active = false -- will be removed from the list later
            if powerup.sticky then
               if not active_powerup('sticky') then
                  Ball.sticky = false
                  Player.color = vec3(PLAYER_COLOR)
               end
            elseif powerup.passthrough then
               if not active_powerup('passthrough') then
                  Ball.passthrough = false
                  Ball.color = vec3(BALL_COLOR)
               end
            elseif powerup.confuse then
               if not active_powerup('confuse') then
                  Effects.confuse = false
               end
            elseif powerup.chaos then 
               if not active_powerup('chaos') then
                  Effects.chaos = false
               end
            end
         end
      end
   end
   -- remove all those that are both destroyed and inactive,
   -- thus either off the map or finished
   for i, powerup in pairs(PowerUps) do
      if powerup.destroyed and not powerup.active then PowerUps[i] = nil end
   end
end

local function update_game_state(dt)
   Ball:move(dt)
   do_collisions()
   local offset = Ball.radius/2
   Particles:update(dt, Ball, 2, vec2(offset, offset))
   update_powerups(dt)
   -- reduce shake time
   if ShakeTime > 0.0 then
      ShakeTime = ShakeTime - dt
      if ShakeTime <= 0.0 then Effects.shake = false end
   end
   -- check loss condition
   if Ball.pos.y >= SCREEN_H then -- ball reached the bottom edge
      Lives = Lives - 1
      if Lives == 0 then -- game over!
         reset_level()
         State = 'MENU'
      end
      reset_player()
   end
   if State == 'ACTIVE' and Level:is_completed() then -- game won!
      reset_player()
      Effects.chaos = true
      State = 'WIN'
   end
end

local function process_input(dt)
   if State == 'MENU' then
      if Keys['enter'] and not KeysProcessed['enter'] then
         State = 'ACTIVE'
         KeysProcessed['enter'] = true
         collectgarbage()
      end
      if Keys['w'] and not KeysProcessed['w'] then
         LevelIndex = LevelIndex==#Levels and 1 or LevelIndex + 1
         Level = Levels[LevelIndex]
         KeysProcessed['w'] = true
      end
      if Keys['s'] and not KeysProcessed['s'] then
         LevelIndex = LevelIndex > 1 and LevelIndex-1 or #Levels
         Level = Levels[LevelIndex]
         KeysProcessed['s'] = true
      end
   end
   if State == 'WIN' then
      if Keys['enter'] then
         KeysProcessed['enter'] = true
         reset_level()
         Effects.chaos = false
         State = 'MENU'
      end
   end
   if State == 'ACTIVE' then
      --  move player, and ball also if it's stuck
      local player_pos = Player.pos
      if Keys['a'] then
         local ds = PLAYER_VEL * dt -- delta space
         if player_pos.x >= 0.0 then
            player_pos.x = player_pos.x - ds
            if Ball.stuck then Ball.pos.x = Ball.pos.x - ds end
         end
      end
      if Keys['d'] then
         local ds = PLAYER_VEL * dt -- delta space
         if player_pos.x <= SCREEN_W - Player.size.x then
            player_pos.x = player_pos.x + ds
            if Ball.stuck then Ball.pos.x = Ball.pos.x + ds end
         end
      end
      if Keys['space'] then
         Ball.stuck = false
      end
   end
end

glfw.set_key_callback(window, function(window, key, scancode, action, shift, control, alt, super)
   if key=='escape' and action=='press' then
      glfw.set_window_should_close(window, true)
   end
   if action == 'press' then
      Keys[key] = true
   elseif action == 'release' then
      Keys[key] = false
      KeysProcessed[key] = false
   end
end)

gl.viewport(0, 0, SCREEN_W, SCREEN_H)
gl.enable('blend')
gl.blend_func('src alpha', 'one minus src alpha')

-- Time variables
local t, dt, last_t = 0.0, 0.0, 0.0 -- current time, delta time, last frame time

collectgarbage()

-- Render loop
while not glfw.window_should_close(window) do
   -- per-frame time logic
   local t = glfw.get_time()
   dt = t - last_t
   last_t = t
   glfw.poll_events()
   process_input(dt)
   update_game_state(dt)
   -- render
   gl.clear_color(0, 0, 0, 1)
   gl.clear('color')
   Effects:begin_render()
      Sprite:draw(BACKGROUND)
      for _, brick in pairs(Level:bricks()) do Sprite:draw(brick) end
      Sprite:draw(Player)
      for _, powerup in pairs(PowerUps) do
         if not powerup.destroyed then Sprite:draw(powerup) end
      end
      Particles:draw()
      Sprite:draw(Ball)
   Effects:end_render(t)
   -- render text (don't include in postprocessing)
   Text:render("Level: "..LevelIndex.." Lives: "..Lives, 5, 5, 1, TEXT_COLOR)
   if State == 'MENU' then 
      Text:render("Press ENTER to start", 250, SCREEN_H/2, 1.0, TEXT_COLOR)
      Text:render("Press W or S to select level", 245, SCREEN_H/2+20, 0.75, TEXT_COLOR)
   end
   if State == 'WIN' then 
      Text:render("You WON!!!", 320, SCREEN_H/2-20, 1.0, vec3(0.0, 1.0, 0.0))
      Text:render("Press ENTER to retry or ESC to quit", 130, SCREEN_H/2, 1.0, vec3(1.0, 1.0, 0.0))
   end
   glfw.swap_buffers(window)
end

