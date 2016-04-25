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

static int CreateProgram(lua_State *L)
    {
    GLuint ref;
    check_init_called(L);
    ref = glCreateProgram();
    CheckError(L);
    lua_pushinteger(L, ref);
    return 1;
    }

UINT2_FUNC(AttachShader)
UINT2_FUNC(DetachShader)
UINT_FUNC(UseProgram)
UINT_FUNC(ValidateProgram)
UINT_FUNC(DeleteProgram)
IS_FUNC(Program)

static int DeletePrograms(lua_State *L) /* NONGL */
    {
    int arg = 1;
    GLuint prog;
    while(!lua_isnone(L, arg))
        {
        prog = luaL_checkinteger(L, arg++);
        glDeleteProgram(prog);
        CheckError(L);
        }
    return 0;
    }



static int LinkProgram(lua_State *L)
/* link_program(program [, check]) */
    {
    char *buf;
    GLint ok, bufsz;
    int check = lua_toboolean(L, 2);

    GLuint program = luaL_checkinteger(L, 1);
    glLinkProgram(program);
    CheckError(L);

    if(check)
        {
        glGetProgramiv(program, GL_LINK_STATUS, &ok);
        if(!ok)
            {
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufsz);
            CheckError(L);
            buf = (char*)Malloc(L, bufsz*sizeof(char));
            glGetProgramInfoLog(program, bufsz, NULL, buf);
            CheckErrorFree(L, buf);
            lua_pushfstring(L, "program link error: %s",buf);
            Free(L, buf);
            return lua_error(L);
            }   
        }
    return 0;
    }

static int GetProgramInfoLog(lua_State *L)
    {
    char *buf;
    GLint bufsz;
    GLuint program = luaL_checkinteger(L, 1);

    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufsz);
    CheckError(L);
    if(bufsz==0) return 0;
    buf = (char*)Malloc(L, bufsz*sizeof(char));
    glGetProgramInfoLog(program, bufsz, NULL, buf);
    CheckErrorFree(L, buf);
    lua_pushstring(L, buf);
    Free(L, buf);
    return 1;
    }

static int GetAttachedShaders(lua_State *L)
    {
    GLuint *shaders;
    GLsizei i, count;
    GLuint program = luaL_checkinteger(L, 1);

    glGetProgramiv(program, GL_ATTACHED_SHADERS, &count);
    CheckError(L);
    if(count==0) return 0;
    shaders = (GLuint*)Malloc(L, count*sizeof(GLuint));
    glGetAttachedShaders(program, count, NULL, shaders);
    CheckErrorFree(L, shaders);
    for(i=0; i<count; i++)
        lua_pushinteger(L, shaders[i]);
    Free(L, shaders);
    return count;
    }

/*------------------------------------------------------------------------------*
 | program_parameter()                                                          |
 *------------------------------------------------------------------------------*/

ENUM_STRINGS(PPnameStrings) = {
    "separable",
    "binary retrievable hint",
    NULL
};
ENUM_CODES(PPnameCodes) = {
    GL_PROGRAM_SEPARABLE,
    GL_PROGRAM_BINARY_RETRIEVABLE_HINT,
};
ENUM_T(PPnameEnum, PPnameStrings, PPnameCodes)
#define CheckPPname(L, arg) enumCheck((L), (arg), &PPnameEnum)
#define PushPPname(L, code) enumPush((L), (code), &PPnameEnum)

static int ProgramParameter(lua_State *L)
    {
    GLuint program = luaL_checkinteger(L, 1);
    GLenum pname = CheckPPname(L, 2);
    GLint value = checkboolean(L, 3);
    glProgramParameteri(program, pname, value);
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | get_program()                                                                |
 *------------------------------------------------------------------------------*/

ENUM_STRINGS(PnameStrings) = {
    "active atomic counter buffers",
    "active attributes",
    "active attribute max length",
    "active uniforms",
    "active uniform blocks",
    "active uniform block max name length",
    "active uniform max length",
    "attached shaders",
    "validate status",
    "compute work group size",
    "delete status",
    "geometry input type",
    "geometry output type",
    "geometry shader invocations",
    "geometry vertices out",
    "info log length",
    "link status",
    "program separable",
    "program binary retrievable hint",
    "tess control output vertices",
    "tess gen mode",
    "tess gen spacing",
    "tess gen vertex order",
    "tess gen point mode",
    "program binary length",
    "transform feedback buffer mode",
    "transform feedback varyings",
    "transform feedback varying max length",
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_ACTIVE_ATOMIC_COUNTER_BUFFERS,
    GL_ACTIVE_ATTRIBUTES,
    GL_ACTIVE_ATTRIBUTE_MAX_LENGTH,
    GL_ACTIVE_UNIFORMS,
    GL_ACTIVE_UNIFORM_BLOCKS,
    GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH,
    GL_ACTIVE_UNIFORM_MAX_LENGTH,
    GL_ATTACHED_SHADERS,
    GL_VALIDATE_STATUS,
    GL_COMPUTE_WORK_GROUP_SIZE,
    GL_DELETE_STATUS,
    GL_GEOMETRY_INPUT_TYPE,
    GL_GEOMETRY_OUTPUT_TYPE,
    GL_GEOMETRY_SHADER_INVOCATIONS,
    GL_GEOMETRY_VERTICES_OUT,
    GL_INFO_LOG_LENGTH,
    GL_LINK_STATUS,
    GL_PROGRAM_SEPARABLE,
    GL_PROGRAM_BINARY_RETRIEVABLE_HINT,
    GL_TESS_CONTROL_OUTPUT_VERTICES,
    GL_TESS_GEN_MODE,
    GL_TESS_GEN_SPACING,
    GL_TESS_GEN_VERTEX_ORDER,
    GL_TESS_GEN_POINT_MODE,
    GL_PROGRAM_BINARY_LENGTH,
    GL_TRANSFORM_FEEDBACK_BUFFER_MODE,
    GL_TRANSFORM_FEEDBACK_VARYINGS,
    GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH,
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)

ENUM_STRINGS(GeometryInputTypeStrings) = {
    "points",
    "lines",
    "lines adjacency",
    "triangles",
    "triangles adjacency",
    NULL
};
ENUM_CODES(GeometryInputTypeCodes) = {
    GL_POINTS,
    GL_LINES,
    GL_LINES_ADJACENCY,
    GL_TRIANGLES,
    GL_TRIANGLES_ADJACENCY,
};
ENUM_T(GeometryInputTypeEnum, GeometryInputTypeStrings, GeometryInputTypeCodes)
#define CheckGeometryInputType(L, arg) enumCheck((L), (arg), &GeometryInputTypeEnum)
#define PushGeometryInputType(L, code) enumPush((L), (code), &GeometryInputTypeEnum)

ENUM_STRINGS(GeometryOutputTypeStrings) = {
    "points",
    "line strip",
    "triangle",
    NULL
};
ENUM_CODES(GeometryOutputTypeCodes) = {
    GL_POINTS,
    GL_LINE_STRIP,
    GL_TRIANGLE_STRIP,
};
ENUM_T(GeometryOutputTypeEnum, GeometryOutputTypeStrings, GeometryOutputTypeCodes)
#define CheckGeometryOutputType(L, arg) enumCheck((L), (arg), &GeometryOutputTypeEnum)
#define PushGeometryOutputType(L, code) enumPush((L), (code), &GeometryOutputTypeEnum)

ENUM_STRINGS(TessGenModeStrings) = {
    "quads",
    "triangles",
    "isolines",
    NULL
};
ENUM_CODES(TessGenModeCodes) = {
    GL_QUADS,
    GL_TRIANGLES,
    GL_ISOLINES,
};
ENUM_T(TessGenModeEnum, TessGenModeStrings, TessGenModeCodes)
#define CheckTessGenMode(L, arg) enumCheck((L), (arg), &TessGenModeEnum)
#define PushTessGenMode(L, code) enumPush((L), (code), &TessGenModeEnum)

ENUM_STRINGS(GenSpacingStrings) = {
    "equal",
    "fractional even",
    "fractional odd",
    NULL
};
ENUM_CODES(GenSpacingCodes) = {
    GL_EQUAL,
    GL_FRACTIONAL_EVEN,
    GL_FRACTIONAL_ODD,
};
ENUM_T(GenSpacingEnum, GenSpacingStrings, GenSpacingCodes)
#define CheckGenSpacing(L, arg) enumCheck((L), (arg), &GenSpacingEnum)
#define PushGenSpacing(L, code) enumPush((L), (code), &GenSpacingEnum)

ENUM_STRINGS(GenVertexOrderStrings) = {
    "ccw",
    "cw",
    NULL
};
ENUM_CODES(GenVertexOrderCodes) = {
    GL_CCW,
    GL_CW,
};
ENUM_T(GenVertexOrderEnum, GenVertexOrderStrings, GenVertexOrderCodes)
#define CheckGenVertexOrder(L, arg) enumCheck((L), (arg), &GenVertexOrderEnum)
#define PushGenVertexOrder(L, code) enumPush((L), (code), &GenVertexOrderEnum)

ENUM_STRINGS(BufferModeStrings) = {
    "separate attribs",
    "interleaved attribs",
    NULL
};
ENUM_CODES(BufferModeCodes) = {
    GL_SEPARATE_ATTRIBS,
    GL_INTERLEAVED_ATTRIBS,
};
ENUM_T(BufferModeEnum, BufferModeStrings, BufferModeCodes)
#define CheckBufferMode(L, arg) enumCheck((L), (arg), &BufferModeEnum)
#define PushBufferMode(L, code) enumPush((L), (code), &BufferModeEnum)

enum_t *enumBufferMode(void)
    { return &BufferModeEnum; }

static int GetBoolean(lua_State *L, GLuint program, GLenum pname)
    {
    GLint params; 
    glGetProgramiv(program, pname, &params);
    CheckError(L);
    lua_pushboolean(L, params == GL_TRUE); 
    return 1;
    }

GLint programGet(lua_State *L, GLuint program, GLenum pname)
    {
    GLint params; 
    glGetProgramiv(program, pname, &params);
    CheckError(L);
    return params;
    }

static int GetInteger(lua_State *L, GLuint program, GLenum pname)
    {
    GLint params; 
    glGetProgramiv(program, pname, &params);
    CheckError(L);
    lua_pushinteger(L, params); 
    return 1;
    }

static int GetInteger3(lua_State *L, GLuint program, GLenum pname)
    {
    GLint params[3]; 
    glGetProgramiv(program, pname, params);
    CheckError(L);
    lua_pushinteger(L, params[0]); 
    lua_pushinteger(L, params[1]); 
    lua_pushinteger(L, params[2]); 
    return 3;
    }

static int GetEnum(lua_State *L, GLuint program, GLenum pname, enum_t *e)
    {
    GLint params;
    glGetProgramiv(program, pname, &params);
    CheckError(L);
    return enumPush(L, params, e);
    }

static int GetProgram(lua_State *L)
    {
#define BOOLEAN return GetBoolean(L, program, pname);
#define INTEGER return GetInteger(L, program, pname);
#define INTEGER3 return GetInteger3(L, program, pname);
#define ENUM(e) return GetEnum(L, program, pname, e);
    GLuint program = luaL_checkinteger(L, 1);
    GLenum pname = CheckPname(L, 2);
    switch(pname)
        {
        case GL_ACTIVE_ATOMIC_COUNTER_BUFFERS: INTEGER
        case GL_ACTIVE_ATTRIBUTES: INTEGER
        case GL_ACTIVE_ATTRIBUTE_MAX_LENGTH: INTEGER
        case GL_ACTIVE_UNIFORMS: INTEGER
        case GL_ACTIVE_UNIFORM_BLOCKS: INTEGER
        case GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH: INTEGER
        case GL_ACTIVE_UNIFORM_MAX_LENGTH: INTEGER
        case GL_ATTACHED_SHADERS: INTEGER
        case GL_VALIDATE_STATUS: BOOLEAN
        case GL_COMPUTE_WORK_GROUP_SIZE: INTEGER3
        case GL_DELETE_STATUS: BOOLEAN
        case GL_GEOMETRY_INPUT_TYPE: ENUM(&GeometryInputTypeEnum)
        case GL_GEOMETRY_OUTPUT_TYPE:  ENUM(&GeometryOutputTypeEnum)
        case GL_GEOMETRY_SHADER_INVOCATIONS: INTEGER
        case GL_GEOMETRY_VERTICES_OUT: INTEGER
        case GL_INFO_LOG_LENGTH: INTEGER
        case GL_LINK_STATUS: BOOLEAN
        case GL_PROGRAM_SEPARABLE: BOOLEAN
        case GL_PROGRAM_BINARY_RETRIEVABLE_HINT: BOOLEAN
        case GL_TESS_CONTROL_OUTPUT_VERTICES: INTEGER
        case GL_TESS_GEN_MODE: ENUM(&TessGenModeEnum)
        case GL_TESS_GEN_SPACING: ENUM(&GenSpacingEnum)
        case GL_TESS_GEN_VERTEX_ORDER: ENUM(&GenVertexOrderEnum)
        case GL_TESS_GEN_POINT_MODE: BOOLEAN
        case GL_PROGRAM_BINARY_LENGTH: INTEGER
        case GL_TRANSFORM_FEEDBACK_BUFFER_MODE: ENUM(&BufferModeEnum)
        case GL_TRANSFORM_FEEDBACK_VARYINGS: INTEGER
        case GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH: INTEGER
        default: return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
#undef ENUM
#undef BOOLEAN
#undef INTEGER
#undef INTEGER3
    }

/*------------------------------------------------------------------------------*
 | Binary                                                                       |
 *------------------------------------------------------------------------------*/

static int GetProgramBinary(lua_State *L)
/* get_program_binary(program)
 * -> format, binary  (or nil)
 */
    {
    GLsizei length;
    GLenum format;
    void *binary;
    GLuint program = luaL_checkinteger(L, 1);
    GLsizei bufsz = programGet(L, program, GL_PROGRAM_BINARY_LENGTH);
    if(bufsz==0)
        return 0;   
    binary = Malloc(L, bufsz);
    glGetProgramBinary(program, bufsz, &length, &format, binary);
    CheckErrorFree(L, binary);
    if(length==0)
        return 0;
    lua_pushinteger(L, format);
    lua_pushlstring(L, (char*)binary, length);
    Free(L, binary);
    return 2;
    }

static int ProgramBinary(lua_State *L)
/* program_binary(program, format, binary)
 */
    {
    size_t length;
    GLuint program = luaL_checkinteger(L, 1);
    GLenum format = luaL_checkinteger(L, 2);
    const void *binary = luaL_checklstring(L, 3, &length);
    glProgramBinary(program, format, binary, (GLsizei)length);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "create_program", CreateProgram },
        { "attach_shader", AttachShader },
        { "detach_shader", DetachShader },
        { "link_program", LinkProgram },
        { "use_program", UseProgram },
        { "validate_program", ValidateProgram },
        { "delete_program", DeleteProgram },
        { "delete_programs", DeletePrograms },
        { "is_program", IsProgram },
        { "get_program_info_log", GetProgramInfoLog },
        { "get_attached_shaders", GetAttachedShaders },
        { "get_program", GetProgram },
        { "program_parameter", ProgramParameter },
        { "get_program_binary", GetProgramBinary },
        { "program_binary", ProgramBinary },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_program(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

