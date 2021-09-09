-- ASSIMP-based model loader, with support for skeletal animation
package.path = package.path..";../?.lua"
local gl = require("moongl")
local glmath = require("moonglmath")
local ai = require("moonassimp")
local new_mesh = require("common.mesh")
local new_texture = require("common.texture")
local vec3, mat4, quat = glmath.vec3, glmath.mat4, glmath.quat

-------------------------------------------------------------------------------
-- Bone object
-------------------------------------------------------------------------------

local function new_bone(name, id, offset_matrix, nodeanim)
   local name = name       -- (string)
   local id = id           -- (integer, 1-based)
   local offset_matrix = mat4(offset_matrix)
   local positions, rotations, scales = {}, {}, {}

   for _, key in ipairs(nodeanim:position_keys()) do
      table.insert(positions, {value = vec3(table.unpack(key.value)), tstamp = key.time})
   end
   
   for _, key in ipairs(nodeanim:rotation_keys()) do
      table.insert(rotations, {value = quat(table.unpack(key.value)):normalize(), tstamp = key.time})
   end
      
   for _, key in ipairs(nodeanim:scaling_keys()) do
      table.insert(scales, {value = vec3(table.unpack(key.value)), tstamp = key.time})
   end

   local function mix_factor(last_tstamp, next_tstamp, t)
      return (t - last_tstamp)/(next_tstamp - last_tstamp)
   end

   local function find_keys(what, t)
      -- returns the indices of the two keys to interpolate at animation time t
      for i=2, #what do
         if t < what[i].tstamp then return i-1, i end
      end
      assert(false)
   end

   local function translation(t)
      -- returns the translation matrix at animation time t
      if #positions==1 then return glmath.translate(positions[1].value) end
      local i1, i2 = find_keys(positions, t)
      local p0, p1 = positions[i1], positions[i2]
      local s = mix_factor(p0.tstamp, p1.tstamp, t)
      return glmath.translate(glmath.mix(p0.value, p1.value, s))
   end

   local function rotation(t)
      -- returns the rotation matrix at animation time t
      if #rotations==1 then return (rotations[1].value):mat4() end
      local i1, i2 = find_keys(rotations, t)
      local q0, q1 = rotations[i1], rotations[i2]
      local s = mix_factor(q0.tstamp, q1.tstamp, t)
      return (glmath.slerp(q0.value, q1.value, s):normalize()):mat4()
   end

   local function scaling(t)
      -- returns the scaling matrix at animation time t
      if #scales==1 then return glmath.scale(scales[1].value) end
      local i1, i2 = find_keys(scales, t)
      local s0, s1 = scales[i1], scales[i2]
      local s = mix_factor(s0.tstamp, s1.tstamp, t)
      return glmath.scale(glmath.mix(s0.value, s1.value, s))
   end

   return setmetatable({}, {
      __index = {
         ------------------------------------------------------
         name = function(bone) return name end,
         id = function(bone) return id end,
         offset_matrix = function(bone) return mat4(offset_matrix) end,
         update = function(bone, t) -- returns the local transform for animation time t
            return translation(t)*rotation(t)*scaling(t)
         end,
         ------------------------------------------------------
         delete = function(bone) end,
      },
      __gc = function(bone) bone:delete() end,
   })
end

-------------------------------------------------------------------------------
-- Model
-------------------------------------------------------------------------------

local Directory = "???"
local TexturesLoaded = {} -- contains already loaded textures (to avoid loading them twice or more)
local Meshes = {} -- the meshes that compose the model
local BoneInfo = {} -- temporary bone information, indexed by name
local BoneCount = 0
local Nodes = {}        -- {{node name, parent name}} (root's parent name = root name)
local Transforms = {}   -- node name to node transform (mat4)

local function load_material_textures(textures, material, texturetype, name)
-- Checks all material textures of a given type and loads the textures if they're not loaded yet.
-- Note: We adopt the following convention for sampler names in the shaders:
-- each diffuse texture should be named as 'texture_diffuseN' where N is a sequential number
-- ranging from 1 to MAX_SAMPLER_NUMBER. The same applies to the other texture types:
-- diffuse  -> texture_diffuseN
-- specular -> texture_specularN
-- normal   -> texture_normalN
-- height   -> texture_heightN
   for i = 1, material:texture_count(texturetype) do
      local path = material:texture_path(texturetype, i)
      local tex = TexturesLoaded[path]
      if not tex then -- not already loaded
         tex = {}
         tex.name = name
         tex.id = new_texture(Directory..path)
         TexturesLoaded[path] = tex
      end
      table.insert(textures, {name=tex.name, id=tex.id, path=Directory..path})
      -- print("material texture", tex.id, tex.name, tex.path)
   end
end

local function process_mesh(aimesh)
   local vertices, indices, textures = {}, {}, {} -- data to fill

   -- We assume that the models we use have only one set of texture coordinates:
   local has_texcoords = aimesh:has_texture_coords(1)
   local num_vertices = aimesh:num_vertices()

   for i=1, num_vertices do
      local position = {aimesh:position(i)}
      local normal = aimesh:has_normals() and {aimesh:normal(i)} or {0, 0, 0}
      local tangent = {aimesh:tangent(i)}
      local bitangent = {aimesh:bitangent(i)}
      local u, v
      if has_texcoords then u, v = aimesh:texture_coords(1, i) else u, v = 0.0, 0.0 end
      local texcoords = {u, v}
      table.insert(vertices, {position, normal, texcoords, tangent, bitangent})
   end

   -- read bone data
   local boneids, boneweights = {}, {}
   for i=1, num_vertices do
      table.insert(boneids, { })
      table.insert(boneweights, { })
   end
   for i=1, aimesh:num_bones() do
      local aibone = aimesh:bone(i)
      local name = aibone:name()
      local info = BoneInfo[name]
      local id
      if not info then -- create a new BoneInfo entry
         id = BoneCount + 1
         BoneCount = id
         BoneInfo[name] = { id=id, offset_matrix=mat4(aibone:offset_matrix()), name=name }
      end
      -- add the bone to the boneids and boneweights entries for the vertices it affects
      for _, w in ipairs(aibone:ordered_weights()) do
         local ids, weights = boneids[w.vertex], boneweights[w.vertex]
         if #ids < 4 then
            table.insert(ids, id-1) -- 0-based, since it's vertex data
            table.insert(weights, w.weight)
         else
            -- print("warning: vertex affected by more than 4 bones")
         end
      end
    end
    -- if a vertex is affected that less than 4 bones, pad with zero-weighted bones
    for i = 1, num_vertices do
      local ids, weights = boneids[i], boneweights[i]
      while #ids < 4 do
         table.insert(ids, 0)
         table.insert(weights, 0.0)
      end
   end

   indices = aimesh:all_indices(true) -- zero-based indices

   local material = aimesh:material()
   load_material_textures(textures, material, 'diffuse', 'texture_diffuse')
   load_material_textures(textures, material, 'specular', 'texture_specular')
   load_material_textures(textures, material, 'height', 'texture_normal')
   load_material_textures(textures, material, 'ambient', 'texture_height')
   return new_mesh(vertices, indices, textures, boneids, boneweights)
end

local function process_node(node, parent_name)
-- Processes each individual mesh located at the node and repeats recursively
-- on its children nodes (if any).
   for _, mesh in ipairs(node:meshes()) do 
      table.insert(Meshes, process_mesh(mesh))
   end
   local name = node:name()
   Transforms[name] = mat4(node:transformation())
   -- insert children in Nodes so that they always come after their parent
   for _, child in ipairs(node:children()) do table.insert(Nodes, {child:name(), name}) end
   for _, child in ipairs(node:children()) do process_node(child, name) end
end

local DEFAULT_AI_FLAGS = ai.Process_Triangulate
                       --| ai.Process_FlipUVs
                       | ai.Process_GenSmoothNormals
                       | ai.Process_CalcTangentSpace

return function(path, options)
-- Constructor, expects a filepath to a 3D model.
   local aiflags = DEFAULT_AI_FLAGS
   if options then -- optional table with the following fields (also optional):
      aiflags = options.aiflags or aiflags  -- use this to override the default assimp flags
   end

   local scene = assert(ai.import_file(path, aiflags))
   assert((scene:flags() & ai.SCENE_FLAGS_INCOMPLETE)==0, "scene is incomplete")
   assert(scene:num_meshes() == 1)
   -- this module is just a starting point example so it's a bit limited:
   -- it only supports models that have a single mesh
   assert(scene:num_animations() >= 1)
   local root = assert(scene:root_node(), "missing root node")
   Directory = string.match(path, '(.*/)')

   local root_name = root:name()
   table.insert(Nodes, {root_name, root_name})
   process_node(root, root_name)

   -- read animation data and create bone objects
   local animation = scene:animation(1)
   local duration = animation:duration()
   local ticks_per_second = animation:ticks_per_second()
   local global_transform = mat4(root:transformation())
   local global_inverse_transform = global_transform^-1
   local bones_by_name, bones_by_id = {}, {}
   for _, nodeanim in ipairs(animation:node_anims()) do
      local name = nodeanim:node_name()
      local info = BoneInfo[name]
      assert(info, "unknown bone '"..name.."'")
      local bone = new_bone(name, info.id, info.offset_matrix, nodeanim)
      bones_by_name[name] = bone
      bones_by_id[info.id] = bone
   end

   -- Save information in closure, and cleanup data that is no more needed:
   local num_bones = #bones_by_id
   local meshes = Meshes
   local nodes, transforms = Nodes, Transforms
   Meshes, TexturesLoaded, Nodes, Transforms, BoneInfo = {}, {}, {}, {}, {}
   ai.release_import(scene)

   return setmetatable({}, {
      __index = {
         draw = function(model, prog)
            for _, mesh in ipairs(meshes) do mesh:draw(prog) end
         end,

         meshes = function(model) return meshes end,

         num_bones = function(model) return num_bones end,
         duration = function(model) return duration end,
         ticks_per_second = function(model) return ticks_per_second end,

         bone_transforms = function(model, t)
         -- returns the list of bone transforms, ordered by id, for animation time t
            local ret = {}
            local parent_transforms = {}, {}
            parent_transforms[root_name] = mat4(global_transform)
            for i = 2, #nodes do -- skip root
               local node = nodes[i]
               local name, parent_name = node[1], node[2]
               local parent_transform = parent_transforms[parent_name]
               local bone = bones_by_name[name]
               local m
               if bone then
                  m = parent_transform * bone:update(t)
                  ret[bone:id()] = global_inverse_transform * m * bone:offset_matrix()
               else
                  m = parent_transform * transforms[name]
               end
               parent_transforms[name] = m
            end
            assert(#ret == num_bones) -- paranoia
            return ret
         end,

         delete = function(model)   
            if not meshes then return end
            for _, mesh in ipairs(meshes) do mesh:delete(prog) end
            meshes = nil
         end,
         },
      __gc = function(model) model:delete() end
   })
end

