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

ENUM_STRINGS(SourceStrings) = {
    "don't care",
    "api",
    "shader compiler",
    "window system",
    "third party",
    "application",
    "other",
    NULL
};
ENUM_CODES(SourceCodes) = {
    GL_DONT_CARE,
    GL_DEBUG_SOURCE_API,
    GL_DEBUG_SOURCE_SHADER_COMPILER,
    GL_DEBUG_SOURCE_WINDOW_SYSTEM,
    GL_DEBUG_SOURCE_THIRD_PARTY,
    GL_DEBUG_SOURCE_APPLICATION,
    GL_DEBUG_SOURCE_OTHER,
};
ENUM_T(SourceEnum, SourceStrings, SourceCodes)
#define CheckSource(L, arg) enumCheck((L), (arg), &SourceEnum)
#define PushSource(L, code) enumPush((L), (code), &SourceEnum)

ENUM_STRINGS(TypeStrings) = {
    "don't care",
    "error",
    "deprecated behavior",
    "undefined behavior",
    "performance",
    "portability",
    "marker",
    "push group",
    "pop group",
    "other",
    NULL
};
ENUM_CODES(TypeCodes) = {
    GL_DONT_CARE,
    GL_DEBUG_TYPE_ERROR,
    GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR,
    GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR,
    GL_DEBUG_TYPE_PERFORMANCE,
    GL_DEBUG_TYPE_PORTABILITY,
    GL_DEBUG_TYPE_MARKER,
    GL_DEBUG_TYPE_PUSH_GROUP,
    GL_DEBUG_TYPE_POP_GROUP,
    GL_DEBUG_TYPE_OTHER,
};
ENUM_T(TypeEnum, TypeStrings, TypeCodes)
#define CheckType(L, arg) enumCheck((L), (arg), &TypeEnum)
#define PushType(L, code) enumPush((L), (code), &TypeEnum)

ENUM_STRINGS(SeverityStrings) = {
    "don't care",
    "high",
    "medium",
    "low",
    "notification",
    NULL
};
ENUM_CODES(SeverityCodes) = {
    GL_DONT_CARE,
    GL_DEBUG_SEVERITY_HIGH,
    GL_DEBUG_SEVERITY_MEDIUM,
    GL_DEBUG_SEVERITY_LOW,
    GL_DEBUG_SEVERITY_NOTIFICATION,
};
ENUM_T(SeverityEnum, SeverityStrings, SeverityCodes)
#define CheckSeverity(L, arg) enumCheck((L), (arg), &SeverityEnum)
#define PushSeverity(L, code) enumPush((L), (code), &SeverityEnum)


ENUM_STRINGS(IdentifierStrings) = {
    "buffer", 
    "framebuffer",
    "renderbuffer", 
    "program pipeline", 
    "program", 
    "query", 
    "sampler", 
    "shader", 
    "texture", 
    "transform feedback", 
    "vertex array", 
    NULL
};
ENUM_CODES(IdentifierCodes) = {
    GL_BUFFER, 
    GL_FRAMEBUFFER,
    GL_RENDERBUFFER, 
    GL_PROGRAM_PIPELINE, 
    GL_PROGRAM, 
    GL_QUERY, 
    GL_SAMPLER, 
    GL_SHADER, 
    GL_TEXTURE, 
    GL_TRANSFORM_FEEDBACK, 
    GL_VERTEX_ARRAY, 
};
ENUM_T(IdentifierEnum, IdentifierStrings, IdentifierCodes)
#define CheckIdentifier(L, arg) enumCheck((L), (arg), &IdentifierEnum)
#define PushIdentifier(L, code) enumPush((L), (code), &IdentifierEnum)


/*------------------------------------------------------------------------------*
 | Debug Callback                                                               |
 *------------------------------------------------------------------------------*/

#define CALLBACK "moongl_debug_callback" /* callback name in the Lua registry */

static void Callback(GLenum source, GLenum type, GLuint id, GLenum severity,
            GLsizei length, const GLchar *message, void *userParam)
    {
#define L ((lua_State*)userParam)
    /* Retrieve the callback */
    lua_getfield(L, LUA_REGISTRYINDEX, CALLBACK);
    /* push arguments */
    PushSource(L, source);
    PushType(L, type);
    lua_pushinteger(L, id);
    PushSeverity(L, severity);
    lua_pushlstring(L, message, length);
    /* Execute the callback */
    lua_call(L, 5, 0);
#undef L
    }

static int DebugMessageCallback(lua_State *L)
/* debug_message_callback(func) 
 * func(source, type, id, severity, message)
 */
    {
    if(!lua_isfunction(L, 1))
        return luaL_argerror(L, 1, "function expected");
    lua_pushvalue(L, 1);
    lua_setfield(L, LUA_REGISTRYINDEX, CALLBACK);
    glDebugMessageCallback(Callback, (void*)L);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Debug Control                                                                |
 *------------------------------------------------------------------------------*/

static int DebugMessageControl(lua_State *L)
/* debug_message_control(source, type, severity, enabled [, id1, ... ]) */
    {
    GLsizei arg, i, count;
    GLuint *ids;
    GLenum source = CheckSource(L, 1);
    GLenum type = CheckType(L, 2);
    GLenum severity = CheckSeverity(L, 3);
    GLboolean enabled = checkboolean(L, 4);
    arg = 5;
    while(!lua_isnoneornil(L, arg))
        luaL_checkinteger(L, arg++);
    if(arg == 5) /* no ids */
        glDebugMessageControl(source, type, severity, 0, NULL, enabled);
    else
        {
        count = arg - 5;
        ids = (GLuint*)Malloc(L, count*sizeof(GLuint));
        arg = 5;
        for(i=0; i<count; i++)
            ids[i] = lua_tointeger(L, arg++);
        glDebugMessageControl(source, type, severity, count, ids, enabled);
        Free(L,ids);
        }
    CheckError(L);
    return 0;
    }

static int DebugMessageInsert(lua_State *L)
    {
    size_t length;
    GLenum source = CheckSource(L, 1);
    GLenum type = CheckType(L, 2);
    GLenum severity = CheckSeverity(L, 3);
    GLuint id = luaL_checkinteger(L, 4);
    const GLchar *message = luaL_checklstring(L, 5, &length);
    glDebugMessageInsert(source, type, id, severity, (GLsizei)length, message);
    CheckError(L);
    return 0;
    }

static int PushDebugGroup(lua_State *L)
    {
    size_t length;
    GLenum source = CheckSource(L, 1);
    GLuint id = luaL_checkinteger(L, 2);
    const GLchar *message = luaL_checklstring(L, 3, &length);
    glPushDebugGroup(source, id, (GLsizei)length, message);
    CheckError(L);
    return 0;
    }

VOID_FUNC(PopDebugGroup)

static int ObjectLabel(lua_State *L)
    {
    size_t length;
    GLenum identifier = CheckIdentifier(L, 1);
    GLuint name = luaL_checkinteger(L, 2);
    const GLchar *label= luaL_checklstring(L, 3, &length);
    glObjectLabel(identifier, name, (GLsizei)length, label);
    CheckError(L);
    return 0;
    }

//void glObjectPtrLabel(const void *ptr, GLsizei length, const GLchar *label);
static int ObjectPtrLabel(lua_State *L) //@@
    {
    NOT_AVAILABLE;
    CheckError(L);
    return 0;
    }

#define MaxLabelLength(L) getSizei((L), GL_MAX_LABEL_LENGTH)
#define DebugLoggedMessages(L) getSizei((L), GL_DEBUG_LOGGED_MESSAGES)
#define MaxDebugMessageLength(L) getSizei((L), GL_MAX_DEBUG_MESSAGE_LENGTH)
#define MaxDebugLoggedMessages(L) getSizei((L), GL_MAX_DEBUG_LOGGED_MESSAGES)

//GLuint glGetDebugMessageLog(GLuint count, GLsizei bufSize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);
static int GetDebugMessageLog(lua_State *L) //@@
    {
    NOT_AVAILABLE;
    CheckError(L);
    return 0;
    }

static int GetObjectLabel(lua_State *L)
    {
    GLsizei length, bufsz = MaxLabelLength(L);
    GLenum identifier = CheckIdentifier(L, 1);
    GLuint name = luaL_checkinteger(L, 2);
    GLchar *label = (GLchar*)Malloc(L, bufsz*sizeof(GLchar));
    glGetObjectLabel(identifier, name, bufsz, &length, label);
    CheckErrorFree(L, label);
    lua_pushlstring(L, label, length);
    Free(L, label);
    return 1;
    }

//void glGetObjectPtrLabel(const void *ptr, GLsizei bufSize, GLsizei *length, GLchar *label);
static int GetObjectPtrLabel(lua_State *L) //@@
    {
    NOT_AVAILABLE;
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "debug_message_callback", DebugMessageCallback },
        { "debug_message_control", DebugMessageControl },
        { "debug_message_insert", DebugMessageInsert },
        { "push_debug_group", PushDebugGroup },
        { "pop_debug_group", PopDebugGroup },
        { "object_label", ObjectLabel },
        { "object_ptr_label", ObjectPtrLabel },
        { "get_debug_message_log", GetDebugMessageLog },
        { "get_object_label", GetObjectLabel },
        { "get_object_ptr_label", GetObjectPtrLabel },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_debug(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

