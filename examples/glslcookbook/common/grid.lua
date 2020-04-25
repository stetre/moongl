-- Drawable grid
local gl = require("moongl")

local function generate(size, ndivs)
   local size2 = size / 2.0
   local divisionSize = size / ndivs;
   local positions = {}
   for row = 0, ndivs do
      local z = (row*divisionSize)-size2
      table.insert(positions, {-size2, 0, z})
      table.insert(positions, { size2, 0, z})
   end
   for col = 0, ndivs do
      local x = (col*divisionSize)-size2
      table.insert(positions, {x, 0, -size2})
      table.insert(positions, {x, 0,  size2})
   end
   local nverts = 4*(ndivs+1)
   -- Convert data to binary strings:
   return gl.pack('float', positions), #positions --nverts
end

-------------------------------------------------------------------------------
local function new(size, ndivs)
   local positions, nverts = generate(size or 10.0, ndivs or 10)
   
   -- Create and populate the buffers
   local p_vbo = gl.new_buffer('array')
   gl.buffer_data('array', positions, 'static draw')

   -- Create the vertex array object and populate it
   local vao = gl.new_vertex_array()
   gl.enable_vertex_attrib_array(0) -- position
   gl.bind_buffer('array', p_vbo)
   gl.vertex_attrib_pointer(0, 3, 'float', false, 0, 0)
   gl.unbind_vertex_array()

   return setmetatable({}, {
      __index = {
      ------------------------------------------------
      vao = function(self) return vao end,
      positions = function(self) return positions end,
      ------------------------------------------------
      render = function(self)
         gl.bind_vertex_array(vao)
         gl.draw_arrays('lines', 0, nverts)
         gl.unbind_vertex_array()
      end,
      ------------------------------------------------
      delete = function(self)
         if vao then
            gl.delete_vertex_arrays(vao)
            gl.delete_buffers(p_vbo)
            vao, positions, indices = nil
         end
      end,
      ------------------------------------------------
      },
      __gc = function(self) self:delete() end,
   })
end

return new

