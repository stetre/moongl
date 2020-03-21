-- Renders a 1x1 3D cube in NDC.
local gl = require("moongl")

return function()
   local vertices = {
         -- back face
        -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, -- bottom-left
         1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, -- top-right
         1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 0.0, -- bottom-right         
         1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, -- top-right
        -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, -- bottom-left
        -1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 1.0, -- top-left
        -- front face
        -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, -- bottom-left
         1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 0.0, -- bottom-right
         1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, -- top-right
         1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, -- top-right
        -1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 1.0, -- top-left
        -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, -- bottom-left
        -- left face
        -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, -- top-right
        -1.0,  1.0, -1.0, -1.0,  0.0,  0.0, 1.0, 1.0, -- top-left
        -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-left
        -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-left
        -1.0, -1.0,  1.0, -1.0,  0.0,  0.0, 0.0, 0.0, -- bottom-right
        -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, -- top-right
        -- right face
         1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, -- top-left
         1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-right
         1.0,  1.0, -1.0,  1.0,  0.0,  0.0, 1.0, 1.0, -- top-right         
         1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, -- bottom-right
         1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, -- top-left
         1.0, -1.0,  1.0,  1.0,  0.0,  0.0, 0.0, 0.0, -- bottom-left     
        -- bottom face
        -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, -- top-right
         1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 1.0, 1.0, -- top-left
         1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, -- bottom-left
         1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, -- bottom-left
        -1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 0.0, 0.0, -- bottom-right
        -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, -- top-right
        -- top face
        -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, -- top-left
         1.0,  1.0 , 1.0,  0.0,  1.0,  0.0, 1.0, 0.0, -- bottom-right
         1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 1.0, 1.0, -- top-right     
         1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 1.0, 0.0, -- bottom-right
        -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, -- top-left
        -1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 0.0, 0.0  -- bottom-left        
   }
   local vao = gl.new_vertex_array()
   local vbo = gl.new_buffer('array')
   gl.buffer_data('array', gl.packf(vertices), 'static draw')
   -- link vertex attributes
   gl.bind_vertex_array(vao)
   gl.enable_vertex_attrib_array(0)
   gl.vertex_attrib_pointer(0, 3, 'float', false, 8*gl.sizeof('float'), 0)
   gl.enable_vertex_attrib_array(1)
   gl.vertex_attrib_pointer(1, 3, 'float', false, 8*gl.sizeof('float'), 3*gl.sizeof('float'))
   gl.enable_vertex_attrib_array(2)
   gl.vertex_attrib_pointer(2, 2, 'float', false, 8*gl.sizeof('float'), 6*gl.sizeof('float'))
   gl.bind_buffer('array', 0)
   gl.unbind_vertex_array()

   return setmetatable({}, {
      __index = {
         draw = function(cube) 
            gl.bind_vertex_array(vao)
            gl.draw_arrays('triangles', 0, 36)
            gl.unbind_vertex_array()
         end,
         delete = function(cube)
            if not vao then return end
            gl.delete_vertex_array(vao)
            gl.delete_buffers(vbo)
            vao, vbo = nil
         end,
      },
      __gc = function(cube) cube:delete() end,
   })
end

