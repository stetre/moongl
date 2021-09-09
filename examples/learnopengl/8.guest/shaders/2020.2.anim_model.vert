#version 430 core

layout(location = 0) in vec3 pos;
layout(location = 1) in vec3 norm;
layout(location = 2) in vec2 tex;
layout(location = 5) in uvec4 boneIds; 
layout(location = 6) in vec4 weights;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

const uint MAX_BONES = 100;
uniform mat4 bone_transforms[MAX_BONES];

out vec2 TexCoords;

void main()
	{
    vec4 position = vec4(0.0f);
    for(int i = 0 ; i < 4 ; i++)
    	{
		if(weights[i] == 0.0) continue;
        position += weights[i] * bone_transforms[boneIds[i]] * vec4(pos,1.0f) ;
        //vec3 normal = mat3(bone_transforms[boneIds[i]]) * norm;
   		}
    gl_Position =  projection * view * model * position;
    TexCoords = tex;
	}
