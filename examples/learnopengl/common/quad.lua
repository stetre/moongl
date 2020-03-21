local gl = require("moongl")
local glmath = require("moonglmath")

local vec2, vec3 = glmath.vec2, glmath.vec3

local function quad_notangents()
-- Renders a 1x1 XY quad in NDC
   local vertices = {
      -- positions    texture Coords
     -1.0,  1.0, 0.0, 0.0, 1.0,
     -1.0, -1.0, 0.0, 0.0, 0.0,
      1.0,  1.0, 0.0, 1.0, 1.0,
      1.0, -1.0, 0.0, 1.0, 0.0,
   }
   local vao = gl.new_vertex_array()
   local vbo = gl.new_buffer('array')
   gl.buffer_data('array', gl.packf(vertices), 'static draw')
   gl.enable_vertex_attrib_array(0)
   gl.vertex_attrib_pointer(0, 3, 'float', false, 5*gl.sizeof('float'), 0)
   gl.enable_vertex_attrib_array(1)
   gl.vertex_attrib_pointer(1, 2, 'float', false, 5*gl.sizeof('float'), 3 * gl.sizeof('float'))

   return setmetatable({}, {
      __index = {
         draw = function(quad) 
            gl.bind_vertex_array(vao)
            gl.draw_arrays('triangle strip', 0, 4)
            gl.unbind_vertex_array()
         end,
         delete = function(quad)
            if not vao then return end
            gl.delete_vertex_array(vao)
            gl.delete_buffers(vbo)
            vao, vbo = nil
         end,
      },
      __gc = function(quad) quad:delete() end,
   })
end


local function quad_withtangents()
-- Renders a 1x1 quad in NDC with manually calculated tangent vectors
   -- positions
   local pos1 = vec3(-1.0,  1.0, 0.0)
   local pos2 = vec3(-1.0, -1.0, 0.0)
   local pos3 = vec3( 1.0, -1.0, 0.0)
   local pos4 = vec3( 1.0,  1.0, 0.0)
   -- texture coordinates
   local uv1 = vec2(0.0, 1.0)
   local uv2 = vec2(0.0, 0.0)
   local uv3 = vec2(1.0, 0.0)  
   local uv4 = vec2(1.0, 1.0)
   -- normal vector
   local nm = vec3(0.0, 0.0, 1.0)
   -- calculate tangent/bitangent vectors of both triangles
   local edge1 = pos2 - pos1
   local edge2 = pos3 - pos1
   local deltaUV1 = uv2 - uv1
   local deltaUV2 = uv3 - uv1
   local f = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y)
   local tangent1 = vec3(f*(deltaUV2.y * edge1.x - deltaUV1.y * edge2.x),
                            f*(deltaUV2.y * edge1.y - deltaUV1.y * edge2.y),
                            f*(deltaUV2.y * edge1.z - deltaUV1.y * edge2.z)):normalize()
   local bitangent1 = vec3(f*(-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x),
                              f*(-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y),
                              f*(-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z)):normalize()

   local edge1 = pos3 - pos1
   local edge2 = pos4 - pos1
   local deltaUV1 = uv3 - uv1
   local deltaUV2 = uv4 - uv1
   local f = 1.0 / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y)
   local tangent2 = vec3(f*(deltaUV2.y * edge1.x - deltaUV1.y * edge2.x),
                            f*(deltaUV2.y * edge1.y - deltaUV1.y * edge2.y),
                            f*(deltaUV2.y * edge1.z - deltaUV1.y * edge2.z)):normalize()
   local bitangent2 = vec3(f*(-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x),
                              f*(-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y),
                              f*(-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z)):normalize()

   local vertices = {
         pos1, nm, uv1, tangent1, bitangent1,
         pos2, nm, uv2, tangent1, bitangent1,
         pos3, nm, uv3, tangent1, bitangent1,
         pos1, nm, uv1, tangent2, bitangent2,
         pos3, nm, uv3, tangent2, bitangent2,
         pos4, nm, uv4, tangent2, bitangent2,
   }
   -- configure plane VAO
   local vao = gl.new_vertex_array()
   local vbo = gl.new_buffer('array')
   gl.buffer_data('array', gl.packf(vertices), 'static draw')
   gl.enable_vertex_attrib_array(0)
   gl.vertex_attrib_pointer(0, 3, 'float', false, 14*gl.sizeof('float'), 0)
   gl.enable_vertex_attrib_array(1)
   gl.vertex_attrib_pointer(1, 3, 'float', false, 14*gl.sizeof('float'), 3*gl.sizeof('float'))
   gl.enable_vertex_attrib_array(2)
   gl.vertex_attrib_pointer(2, 2, 'float', false, 14*gl.sizeof('float'), 6*gl.sizeof('float'))
   gl.enable_vertex_attrib_array(3)
   gl.vertex_attrib_pointer(3, 3, 'float', false, 14*gl.sizeof('float'), 8*gl.sizeof('float'))
   gl.enable_vertex_attrib_array(4)
   gl.vertex_attrib_pointer(4, 3, 'float', false, 14*gl.sizeof('float'), 11*gl.sizeof('float'))
   gl.unbind_vertex_array()

   return setmetatable({}, {
      __index = {
         draw = function(quad) 
            gl.bind_vertex_array(vao)
            gl.draw_arrays('triangles', 0, 6)
            gl.unbind_vertex_array()
         end,
         delete = function(quad)
            if not vao then return end
            gl.delete_vertex_array(vao)
            gl.delete_buffers(vbo)
            vao, vbo = nil
         end,
      },
      __gc = function(quad) quad:delete() end,
   })
end

return function(withtangents)
   if withtangents then
      return quad_withtangents()
   else
      return quad_notangents()
   end
end
