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

/*------------------------------------------------------------------------------*
 | Misc utilities                                                               |
 *------------------------------------------------------------------------------*/

int noprintf(const char *fmt, ...) 
    { (void)fmt; return 0; }

int notavailable(lua_State *L, ...) 
    { 
    GLuint major, minor;
    major = getUint(L, GL_MAJOR_VERSION);
    minor = getUint(L, GL_MINOR_VERSION);
    return luaL_error(L, 
        "function not available in this OpenGL version (v%d.%d)", major, minor); 
    }


GLboolean checkboolean(lua_State *L, int arg)
    {
    if(!lua_isboolean(L, arg))
        return (GLboolean)luaL_argerror(L, arg, "boolean expected");
    return lua_toboolean(L, arg) ? GL_TRUE : GL_FALSE;
    }

GLboolean optboolean(lua_State *L, int arg, GLboolean d)
    {
    if(!lua_isboolean(L, arg))
        return d;
    return lua_toboolean(L, arg) ? GL_TRUE : GL_FALSE;
    }


int checkoption_hint(lua_State *L, int arg, const char *def, const char *const lst[])
/* Variant of luaL_checkoption(), with an added hint in the error message */
    {
    const char *hint = NULL;
    const char *name = (def) ? luaL_optstring(L, arg, def) : luaL_checkstring(L, arg);
    int i;
    for (i=0; lst[i]; i++)
        if (strcmp(lst[i], name) == 0)  return i;

    if(lua_checkstack(L, i*2))
        {
        for(i=0; lst[i]; i++)
            {
            lua_pushfstring(L, "'%s'", lst[i]);
            lua_pushstring(L, "|");
            }
        i = i*2;
        if(i>0)
            {
            lua_pop(L, 1); /* the last separator */
            lua_concat(L, i-1);
            hint = lua_tostring(L, -1); 
            }
        }
    if(hint)
        return luaL_argerror(L, arg, lua_pushfstring(L, 
                    "invalid option '%s', valid options are: %s", name, hint));
    return luaL_argerror(L, arg, lua_pushfstring(L, "invalid option '%s'", name));
    }

int isoption(lua_State *L, int arg, const char *const lst[])
/* Variant of luaL_checkoption(), checks only and returns a boolean */
    {
    int i;
    const char *name;

    if(!lua_isstring(L, arg)) return 0;
    name = lua_tostring(L, arg);
    for (i=0; lst[i]; i++)
        if (strcmp(lst[i], name) == 0)  return 1;
    return 0;
    }


