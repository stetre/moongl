/* The MIT License (MIT)
 *
 * Copyright (c) 2016 Stefano Trettel
 *
 * Software repository: MoonGL, https://github.com/stetre/moongl
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "internal.h"

ENUM_STRINGS(InterfaceStrings) = {
    "uniform",
    "uniform block",
    "atomic counter buffer",
    "program input",
    "program output",
    "vertex subroutine",
    "tess control subroutine",
    "tess evaluation subroutine",
    "geometry subroutine",
    "fragment subroutine",
    "compute subroutine",
    "vertex subroutine uniform",
    "tess control subroutine uniform",
    "tess evaluation subroutine uniform",
    "geometry subroutine uniform",
    "fragment subroutine uniform",
    "compute subroutine uniform",
    "transform feedback varying",
    "buffer variable",
    "shader storage block",
    "transform feedback buffer",
    NULL
};
ENUM_CODES(InterfaceCodes) = {
    GL_UNIFORM,
    GL_UNIFORM_BLOCK,
    GL_ATOMIC_COUNTER_BUFFER,
    GL_PROGRAM_INPUT,
    GL_PROGRAM_OUTPUT,
    GL_VERTEX_SUBROUTINE,
    GL_TESS_CONTROL_SUBROUTINE,
    GL_TESS_EVALUATION_SUBROUTINE,
    GL_GEOMETRY_SUBROUTINE,
    GL_FRAGMENT_SUBROUTINE,
    GL_COMPUTE_SUBROUTINE,
    GL_VERTEX_SUBROUTINE_UNIFORM,
    GL_TESS_CONTROL_SUBROUTINE_UNIFORM,
    GL_TESS_EVALUATION_SUBROUTINE_UNIFORM,
    GL_GEOMETRY_SUBROUTINE_UNIFORM,
    GL_FRAGMENT_SUBROUTINE_UNIFORM,
    GL_COMPUTE_SUBROUTINE_UNIFORM,
    GL_TRANSFORM_FEEDBACK_VARYING,
    GL_BUFFER_VARIABLE,
    GL_SHADER_STORAGE_BLOCK,
    GL_TRANSFORM_FEEDBACK_BUFFER,
};
ENUM_T(InterfaceEnum, InterfaceStrings, InterfaceCodes)
#define CheckInterface(L, arg) enumCheck((L), (arg), &InterfaceEnum)
#define PushInterface(L, code) enumPush((L), (code), &InterfaceEnum)

ENUM_STRINGS(PnameStrings) = {
    "active resources",
    "max name length",
    "max num active variables",
    "max num compatible subroutines",
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_ACTIVE_RESOURCES,
    GL_MAX_NAME_LENGTH,
    GL_MAX_NUM_ACTIVE_VARIABLES,
    GL_MAX_NUM_COMPATIBLE_SUBROUTINES,
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)

ENUM_STRINGS(PropertyStrings) = {
    "active variables",
    "array size",
    "array stride",
    "atomic counter buffer index",
    "block index",
    "buffer binding", 
    "buffer data size",
    "is per patch",
    "is row major",
    "location",
    "location component",
    "location index",
    "matrix stride",
    "name length",
    "num active variables",
    "offset",
    "referenced by vertex shader",
    "referenced by tess control shader",
    "referenced by tess evaluation shader",
    "referenced by geometry shader",
    "referenced by fragment shader", 
    "referenced by compute shader", 
    "top level array size",
    "top level array stride",
    "transform feedback buffer index",
    "transform feedback buffer stride",
    "type",
    NULL
};
ENUM_CODES(PropertyCodes) = {
    GL_ACTIVE_VARIABLES,
    GL_ARRAY_SIZE,
    GL_ARRAY_STRIDE,
    GL_ATOMIC_COUNTER_BUFFER_INDEX,
    GL_BLOCK_INDEX,
    GL_BUFFER_BINDING, 
    GL_BUFFER_DATA_SIZE,
    GL_IS_PER_PATCH,
    GL_IS_ROW_MAJOR,
    GL_LOCATION,
    GL_LOCATION_COMPONENT,
    GL_LOCATION_INDEX,
    GL_MATRIX_STRIDE,
    GL_NAME_LENGTH,
    GL_NUM_ACTIVE_VARIABLES,
    GL_OFFSET,
    GL_REFERENCED_BY_VERTEX_SHADER,
    GL_REFERENCED_BY_TESS_CONTROL_SHADER,
    GL_REFERENCED_BY_TESS_EVALUATION_SHADER,
    GL_REFERENCED_BY_GEOMETRY_SHADER,
    GL_REFERENCED_BY_FRAGMENT_SHADER, 
    GL_REFERENCED_BY_COMPUTE_SHADER, 
    GL_TOP_LEVEL_ARRAY_SIZE,
    GL_TOP_LEVEL_ARRAY_STRIDE,
    GL_TRANSFORM_FEEDBACK_BUFFER_INDEX,
    GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE,
    GL_TYPE,
};
ENUM_T(PropertyEnum, PropertyStrings, PropertyCodes)
#define CheckProperty(L, arg) enumCheck((L), (arg), &PropertyEnum)
#define PushProperty(L, code) enumPush((L), (code), &PropertyEnum)


static GLint GetParam(lua_State *L, GLuint prog, GLenum itf, GLenum pname)
    {
    GLint param;    
    glGetProgramInterfaceiv(prog, itf, pname, &param);
    CheckError(L);
    return param;
    }

#define GetMaxNameLength(L, prog, itf) \
    GetParam((L), (prog), (itf), (GL_MAX_NAME_LENGTH))
#define GetNumActiveVariables(L, prog, itf) \
    GetParam((L), (prog), (itf), (GL_MAX_NUM_ACTIVE_VARIABLES))

static int GetInt(lua_State *L, GLuint prog, GLenum itf, GLenum pname)
    {
    GLint param;    
    glGetProgramInterfaceiv(prog, itf, pname, &param);
    CheckError(L);
    lua_pushinteger(L, param);
    return 1;
    }


static int GetProgramInterface(lua_State *L)
    {
    GLuint prog = luaL_checkinteger(L, 1);
    GLenum itf = CheckInterface(L, 2);
    GLenum pname = CheckPname(L, 3);
    switch(pname)
        {
        case GL_ACTIVE_RESOURCES: return GetInt(L, prog, itf, pname);
        case GL_MAX_NAME_LENGTH: return GetInt(L, prog, itf, pname);
        case GL_MAX_NUM_ACTIVE_VARIABLES: return GetInt(L, prog, itf, pname);
        case GL_MAX_NUM_COMPATIBLE_SUBROUTINES: return GetInt(L, prog, itf, pname);
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }

static int GetProgramResourceIndex(lua_State *L)
    {
    GLuint prog = luaL_checkinteger(L, 1);
    GLenum itf = CheckInterface(L, 2);
    const char *name = luaL_checkstring(L, 3);
    GLuint index = glGetProgramResourceIndex(prog, itf, name);
    CheckError(L);
    lua_pushinteger(L, index);
    return 1;
    }

static int GetProgramResourceName(lua_State *L)
    {
    GLsizei length;
    char *name;
    GLuint prog = luaL_checkinteger(L, 1);
    GLenum itf = CheckInterface(L, 2);
    GLuint index = luaL_checkinteger(L, 3);
    GLsizei bufsz = GetMaxNameLength(L, prog, itf);
    name = (char*)Malloc(L, bufsz*sizeof(char));
    glGetProgramResourceName(prog, itf, index, bufsz, &length, name);
    CheckErrorFree(L, name);
    lua_pushstring(L, name);
    Free(L, name);
    return 1;
    }

static int GetProgramResourceLocation(lua_State *L)
    {
    GLuint prog = luaL_checkinteger(L, 1);
    GLenum itf = CheckInterface(L, 2);
    const char *name = luaL_checkstring(L, 3);
    GLint loc = glGetProgramResourceLocation(prog, itf, name);
    CheckError(L);
    lua_pushinteger(L, loc);
    return 1;
    }

static int GetProgramResourceLocationIndex(lua_State *L)
    {
    GLuint prog = luaL_checkinteger(L, 1);
    GLenum itf = CheckInterface(L, 2);
    const char *name = luaL_checkstring(L, 3);
    GLint index = glGetProgramResourceLocationIndex(prog, itf, name);
    CheckError(L);
    lua_pushinteger(L, index);
    return 1;
    }

/*------------------------------------------------------------------------------*
 | Get properties                                                               |
 *------------------------------------------------------------------------------*/

static int GetPropInt(lua_State *L, GLuint prog, GLenum itf, GLuint index, GLenum prop)
    {
    GLsizei length;
    GLint param;
    glGetProgramResourceiv(prog, itf, index, 1, &prop, 1, &length, &param);
    CheckError(L);
    lua_pushinteger(L, param);
    return 1;
    }

static int GetPropBoolean(lua_State *L, GLuint prog, GLenum itf, GLuint index, GLenum prop)
    {
    GLsizei length;
    GLint param;
    glGetProgramResourceiv(prog, itf, index, 1, &prop, 1, &length, &param);
    CheckError(L);
    lua_pushboolean(L, param);
    return 1;
    }


static int GetActiveVariables(lua_State *L, GLuint prog, GLenum itf, GLuint index, GLenum prop)
    {
    GLsizei length, i;
    GLint *params;
    GLsizei n = GetNumActiveVariables(L, prog, itf);
    params = (GLint*)Malloc(L, n*sizeof(GLint));
    glGetProgramResourceiv(prog, itf, index, 1, &prop, n, &length, params);
    CheckErrorFree(L, params);
    for(i=0; i<n; i++)
        lua_pushinteger(L, params[i]);
    Free(L, params);
    return n;
    }

static int GetPropType(lua_State *L, GLuint prog, GLenum itf, GLuint index, GLenum prop)
    {
    GLsizei length;
    GLint param;
    glGetProgramResourceiv(prog, itf, index, 1, &prop, 1, &length, &param);
    CheckError(L);
    pushglsltype(L, param);
    return 1;
    }

static int GetProgramResource(lua_State *L)
    {
    GLuint prog = luaL_checkinteger(L, 1);
    GLenum itf = CheckInterface(L, 2);
    GLuint index = luaL_checkinteger(L, 3);
    GLenum prop = CheckProperty(L, 4);
    switch(prop)
        {
        case GL_ACTIVE_VARIABLES: return GetActiveVariables(L, prog, itf, index, prop);
        case GL_ARRAY_SIZE: return GetPropInt(L, prog, itf, index, prop);
        case GL_ARRAY_STRIDE: return GetPropInt(L, prog, itf, index, prop);
        case GL_ATOMIC_COUNTER_BUFFER_INDEX: return GetPropInt(L, prog, itf, index, prop);
        case GL_BLOCK_INDEX: return GetPropInt(L, prog, itf, index, prop);
        case GL_BUFFER_BINDING: return GetPropInt(L, prog, itf, index, prop);
        case GL_BUFFER_DATA_SIZE: return GetPropInt(L, prog, itf, index, prop);
        case GL_IS_PER_PATCH: return GetPropBoolean(L, prog, itf, index, prop);
        case GL_IS_ROW_MAJOR: return GetPropBoolean(L, prog, itf, index, prop);
        case GL_LOCATION: return GetPropInt(L, prog, itf, index, prop);
        case GL_LOCATION_COMPONENT: return GetPropInt(L, prog, itf, index, prop);
        case GL_LOCATION_INDEX: return GetPropInt(L, prog, itf, index, prop);
        case GL_MATRIX_STRIDE: return GetPropInt(L, prog, itf, index, prop);
        case GL_NAME_LENGTH: return GetPropInt(L, prog, itf, index, prop);
        case GL_NUM_ACTIVE_VARIABLES: return GetPropInt(L, prog, itf, index, prop);
        case GL_OFFSET: return GetPropInt(L, prog, itf, index, prop);
        case GL_REFERENCED_BY_VERTEX_SHADER: return GetPropInt(L, prog, itf, index, prop);
        case GL_REFERENCED_BY_TESS_CONTROL_SHADER: return GetPropInt(L, prog, itf, index, prop);
        case GL_REFERENCED_BY_TESS_EVALUATION_SHADER: return GetPropInt(L, prog, itf, index, prop);
        case GL_REFERENCED_BY_GEOMETRY_SHADER: return GetPropInt(L, prog, itf, index, prop);
        case GL_REFERENCED_BY_FRAGMENT_SHADER:  return GetPropInt(L, prog, itf, index, prop);
        case GL_REFERENCED_BY_COMPUTE_SHADER:  return GetPropInt(L, prog, itf, index, prop);
        case GL_TOP_LEVEL_ARRAY_SIZE: return GetPropInt(L, prog, itf, index, prop);
        case GL_TOP_LEVEL_ARRAY_STRIDE: return GetPropInt(L, prog, itf, index, prop);
        case GL_TRANSFORM_FEEDBACK_BUFFER_INDEX: return GetPropInt(L, prog, itf, index, prop);
        case GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE: return GetPropInt(L, prog, itf, index, prop);
        case GL_TYPE: return GetPropType(L, prog, itf, index, prop);
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "get_program_interface", GetProgramInterface },
        { "get_program_resource_index", GetProgramResourceIndex },
        { "get_program_resource_name", GetProgramResourceName },
        { "get_program_resource", GetProgramResource },
        { "get_program_resource_location", GetProgramResourceLocation },
        { "get_program_resource_location_index", GetProgramResourceLocationIndex },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_proginterface(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

