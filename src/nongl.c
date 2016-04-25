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

static int Sizeof(lua_State *L)
/* size = sizeof(type) */
    {
    GLenum type = checktype(L, 1);
    lua_pushinteger(L, sizeoftype(L, type));
    return 1;
    }

static int Flatten_(lua_State *L, int arg)
/* val1, ..., valN = flatten(table) */
    {
    int len, i, top, n=0;

    if(lua_type(L, arg) != LUA_TTABLE)
        return luaL_error(L, "table expected");

    lua_len(L, arg);
    len = lua_tointeger(L, -1);
    lua_pop(L, 1);

    if(len==0) return n;

    luaL_checkstack(L, len, NULL);
    for(i=1; i<=len; i++)
        {
        lua_geti(L, arg, i);
        top = lua_gettop(L);
        if(lua_type(L, top) == LUA_TTABLE)
            {
            n += Flatten_(L, top);
            lua_remove(L, top);
            }
        else n++;
        }
    return n;
    }

static int Flatten(lua_State *L)
    {
    return Flatten_(L, 1);
    }



static size_t CheckValues(lua_State *L, size_t first, int integral)
#define CheckNumbers(L, arg) CheckValues((L), (arg), 0) 
#define CheckIntegers(L, arg) CheckValues((L), (arg), 1) 
    {
    size_t n, arg;

    if(lua_istable(L, first))
        {
        n = (size_t)Flatten_(L, first);
        lua_remove(L, first); /* remove table */
        }
    else if(integral)
        {
        arg = first;
        while(!lua_isnoneornil(L, arg))
            luaL_checkinteger(L, arg++);
        if(arg == first)
            luaL_checkinteger(L, arg); /* raise an error */
        n = arg - first;
        }
    else
        {
        arg = first;
        while(!lua_isnoneornil(L, arg))
            luaL_checknumber(L, arg++);
        if(arg == first)
            luaL_checknumber(L, arg); /* raise an error */
        n = arg - first;
        }
    return n;
    }


#define PACK_NUMBERS(T)                     \
static int Pack##T(lua_State *L)            \
    {                                       \
    size_t n, i, arg, len;                  \
    T *data;                                \
    n = CheckNumbers(L, 2);                 \
    len = n * sizeof(T);                    \
    data = (T*)Malloc(L, len);              \
    arg = 2;                                \
    for(i = 0; i < n; i++)                  \
        data[i] = lua_tonumber(L, arg++);   \
    lua_pushlstring(L, (char*)data, len);   \
    Free(L, data);                          \
    return 1;                               \
    }

#define PACK_INTEGERS(T)                    \
static int Pack##T(lua_State *L)            \
    {                                       \
    size_t n, i, arg, len;                  \
    T *data;                                \
    n = CheckIntegers(L, 2);                \
    len = n * sizeof(T);                    \
    data = (T*)Malloc(L, len);              \
    arg = 2;                                \
    for(i = 0; i < n; i++)                  \
        data[i] = lua_tointeger(L, arg++);  \
    lua_pushlstring(L, (char*)data, len);   \
    Free(L, data);                          \
    return 1;                               \
    }


PACK_NUMBERS(GLfloat)
PACK_NUMBERS(GLdouble)
PACK_INTEGERS(GLbyte)
PACK_INTEGERS(GLubyte)
PACK_INTEGERS(GLint)
PACK_INTEGERS(GLuint)
PACK_INTEGERS(GLshort)
PACK_INTEGERS(GLushort)
PACK_INTEGERS(GLfixed)
PACK_INTEGERS(GLhalf)


static int Pack(lua_State *L)
/* pack(type, val1, val2, ..., valN)
 * pack(type, table)
 * -> bstring
 */
    {
    GLenum type = checktype(L, 1);
    switch(type)
        {
        case GL_UNSIGNED_BYTE_3_3_2:
        case GL_UNSIGNED_BYTE_2_3_3_REV:
        case GL_UNSIGNED_BYTE: return PackGLbyte(L);
        case GL_BYTE:  return PackGLubyte(L);
        case GL_UNSIGNED_SHORT_5_6_5:
        case GL_UNSIGNED_SHORT_5_6_5_REV:
        case GL_UNSIGNED_SHORT_4_4_4_4:
        case GL_UNSIGNED_SHORT_4_4_4_4_REV:
        case GL_UNSIGNED_SHORT_5_5_5_1:
        case GL_UNSIGNED_SHORT_1_5_5_5_REV:
        case GL_UNSIGNED_SHORT:  return PackGLushort(L);
        case GL_SHORT:  return PackGLshort(L);
        case GL_UNSIGNED_INT_8_8_8_8: 
        case GL_UNSIGNED_INT_8_8_8_8_REV: 
        case GL_UNSIGNED_INT_10_10_10_2: 
        case GL_UNSIGNED_INT_2_10_10_10_REV:
        case GL_UNSIGNED_INT_24_8:
        case GL_UNSIGNED_INT_10F_11F_11F_REV:
        case GL_UNSIGNED_INT_5_9_9_9_REV:
        case GL_UNSIGNED_INT: return PackGLuint(L);
        case GL_INT_2_10_10_10_REV:
        case GL_INT:  return PackGLint(L);
        case GL_FIXED: return PackGLfixed(L);
        case GL_HALF_FLOAT:  return PackGLhalf(L);
        case GL_FLOAT:  return PackGLfloat(L);
        case GL_DOUBLE: return PackGLdouble(L);
        case GL_FLOAT_32_UNSIGNED_INT_24_8_REV: //@@ 2*32 bit, see 8.4.4.2
        case GL_NONE:
            return luaL_argerror(L, 1, "invalid type");
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }

    CheckError(L);
    return 0;
    }

#define UNPACK_NUMBERS(T)                   \
static int Unpack##T(lua_State *L, const void* data, size_t len) \
    {                                       \
    size_t n;                               \
    size_t i=0;                             \
    if((len < sizeof(T)) || (len % sizeof(T)) != 0) \
        return luaL_argerror(L, 2, "invalid length");   \
    n = len / sizeof(T);                    \
    for(i = 0; i < n; i++)                  \
        lua_pushnumber(L, ((T*)data)[i]);   \
    return n;                               \
    }

#define UNPACK_INTEGERS(T)                  \
static int Unpack##T(lua_State *L, const void* data, size_t len)            \
    {                                       \
    size_t n;                               \
    size_t i=0;                             \
    if((len < sizeof(T)) || (len % sizeof(T)) != 0) \
        return luaL_argerror(L, 2, "invalid length");   \
    n = len / sizeof(T);                    \
    for(i = 0; i < n; i++)                  \
        lua_pushnumber(L, ((T*)data)[i]);   \
    return n;                               \
    }


UNPACK_NUMBERS(GLfloat)
UNPACK_NUMBERS(GLdouble)
UNPACK_INTEGERS(GLbyte)
UNPACK_INTEGERS(GLubyte)
UNPACK_INTEGERS(GLint)
UNPACK_INTEGERS(GLuint)
UNPACK_INTEGERS(GLshort)
UNPACK_INTEGERS(GLushort)
UNPACK_INTEGERS(GLfixed)
UNPACK_INTEGERS(GLhalf)


static int Unpack(lua_State *L)
/* unpack(type, bstring)
 * -> val1, ..., valN
 */
    {
    size_t len;
    GLenum type = checktype(L, 1);
    const void *data = luaL_checklstring(L, 2, &len);
    switch(type)
        {
        case GL_UNSIGNED_BYTE_3_3_2:
        case GL_UNSIGNED_BYTE_2_3_3_REV:
        case GL_UNSIGNED_BYTE: return UnpackGLbyte(L, data, len);
        case GL_BYTE:  return UnpackGLubyte(L, data, len);
        case GL_UNSIGNED_SHORT_5_6_5:
        case GL_UNSIGNED_SHORT_5_6_5_REV:
        case GL_UNSIGNED_SHORT_4_4_4_4:
        case GL_UNSIGNED_SHORT_4_4_4_4_REV:
        case GL_UNSIGNED_SHORT_5_5_5_1:
        case GL_UNSIGNED_SHORT_1_5_5_5_REV:
        case GL_UNSIGNED_SHORT:  return UnpackGLushort(L, data, len);
        case GL_SHORT:  return UnpackGLshort(L, data, len);
        case GL_UNSIGNED_INT_8_8_8_8: 
        case GL_UNSIGNED_INT_8_8_8_8_REV: 
        case GL_UNSIGNED_INT_10_10_10_2: 
        case GL_UNSIGNED_INT_2_10_10_10_REV:
        case GL_UNSIGNED_INT_24_8:
        case GL_UNSIGNED_INT_10F_11F_11F_REV:
        case GL_UNSIGNED_INT_5_9_9_9_REV:
        case GL_UNSIGNED_INT: return UnpackGLuint(L, data, len);
        case GL_INT_2_10_10_10_REV:
        case GL_INT:  return UnpackGLint(L, data, len);
        case GL_FIXED: return UnpackGLfixed(L, data, len);
        case GL_HALF_FLOAT:  return UnpackGLhalf(L, data, len);
        case GL_FLOAT:  return UnpackGLfloat(L, data, len);
        case GL_DOUBLE: return UnpackGLdouble(L, data, len);
        case GL_FLOAT_32_UNSIGNED_INT_24_8_REV: //@@ 2*32 bit, see 8.4.4.2
        case GL_NONE:
            return luaL_argerror(L, 1, "invalid type");
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }

    CheckError(L);
    return 0;
    }

static const struct luaL_Reg Functions[] = 
    {
        { "sizeof", Sizeof },
        { "flatten", Flatten },
        { "pack", Pack },
        { "unpack", Unpack },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_nongl(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

