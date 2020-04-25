-- Random utilities
local glmath = require("moonglmath")

local random = math.random
local randomseed = math.randomseed
local pi = math.pi
local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local vec3 = glmath.vec3

local function uniform_hemisphere()
   local x1, x2 = random(), random()
   local s = sqrt(1.0- x1*x1)
   local pi2x2 = 2*pi*x2
   return vec3(cos(pi2x2)*s, sin(pi2x2)*s, x1)
end

local function uniform_circle()
   local x = random()
   local pi2x = 2*pi*x
   return vec3(cos(pi2x), sin(pi2x), 0)
end

local function shuffle(t) 
-- Shuffles the elements of table t (in place) so that each ordering has the same probability
-- Rfr: https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_modern_algorithm
   local n = #t
   local j
   for i = 1, n-1 do
      j = random(i, n) -- random integer s.t. i <= j < n+1
      t[i], t[j] = t[j], t[i]
   end
end

return {
   seed = randomseed,
   uniform = random,
   uniform_hemisphere = uniform_hemisphere,
   uniform_circle = uniform_circle,
   shuffle = shuffle,
}

