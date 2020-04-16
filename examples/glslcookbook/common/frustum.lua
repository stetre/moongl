-- Drawable frustum
local gl = require("moongl")
local glmath = require("moonglmath")

local vec3, mat4 = glmath.vec3, glmath.mat4
local perspective, translate = glmath.perspective, glmath.translate
local rad, tan = math.rad, math.tan

local function new(pos, at, up, fovy, ar, near, far)
   local pos = pos and vec3(pos) or vec3(0, 0, 1)
   local at = at and vec3(at) or vec3(0, 0, 0)
   local up = up and vec3(up) or vec3(0, 1, 0)
   local fovy = fovy or 50.0
   local ar = ar or 1.0
   local near = near or 0.5
   local far = far or 100.0

   local n, u, v
   local view, inverse_view, projection
   local position

   local indices = gl.pack('uint', {
      0, 5, 0, 6, 0, 7, 0, 8, -- sides
      1, 2, 2, 3, 3, 4, 4, 1, -- near plane
      5, 6, 6, 7, 7, 8, 8, 5, -- far plane
   })
   local count =#indices/gl.sizeof('uint')

   local vao, p_vbo, ebo

   local function orient(pos_, at_, up_)
      pos, at, up = pos_, at_, up_
      n = (pos - at):normalize()
      u = (up % n):normalize()
      v = (n % u):normalize()
      local rot = mat4(u.x, u.y, u.z, 0, 
                       v.x, v.y, v.z, 0, 
                       n.x, n.y, n.z, 0, 
                         0,  0,   0,  1)
      view = rot*translate(-pos)
      inverse_view = translate(pos)*rot:transpose()
   end

   local function set_perspective(fovy_, ar_, near_, far_)
      fovy, ar, near, far = fovy_, ar_, near_, far_
      local dy = near*tan(rad(fovy)/2)
      local dx = ar*dy
      local fdy = far*tan(rad(fovy)/2)
      local fdx = ar*fdy
      positions = gl.pack('float', {
           0,    0,    0, 
          dx,   dy, -near,
         -dx,   dy, -near, 
         -dx,  -dy, -near,
          dx,  -dy, -near,
         fdx,  fdy,  -far, 
        -fdx,  fdy,  -far, 
        -fdx, -fdy,  -far, 
         fdx, -fdy,  -far,
      })
      if vao then
         gl.delete_vertex_arrays(vao)
         gl.delete_buffers(p_vbo, ebo)
      end
      -- (Re)Create the vertex array object and populate it
      vao = gl.new_vertex_array()
      p_vbo = gl.new_buffer('array')
      gl.buffer_data('array', positions, 'static draw')
      gl.enable_vertex_attrib_array(0) -- position
      gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
      ebo = gl.new_buffer('element array')
      gl.buffer_data('element array', indices, 'static draw')
      gl.unbind_vertex_array()
   end

   orient(pos, at, up)
   set_perspective(fovy, ar, near, far)

   return setmetatable({}, {
      __index = {
      ------------------------------------------------
      vao = function(self) return vao end,
      positions = function(self) return positions end,
      indices = function(self) return indices end,
      set_perspective = function(self, ...) set_perspective(...) end,
      orient = function(self, ...) orient(...) end,
      view = function(self) return mat4(view) end,
      inverse_view = function(self) return mat4(inverse_view) end,
      projection = function(self) return perspective(rad(fovy), ar, near, far) end,
      origin = function(self) return vec3(pos) end,
      ------------------------------------------------
      render = function(self)
         gl.bind_vertex_array(vao)
         gl.draw_elements('lines', count, 'uint', 0)
         gl.unbind_vertex_array()
      end,
      ------------------------------------------------
      delete = function(self)
         if vao then
            gl.delete_vertex_arrays(vao)
            gl.delete_buffers(p_vbo, ebo)
            vao, positions, indices = nil
         end
      end,
      ------------------------------------------------
      },
      __gc = function(self) self:delete() end,
   })
end

return new

