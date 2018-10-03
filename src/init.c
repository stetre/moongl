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

static int Initialized = 0;

int check_init_called(lua_State *L)
/* Guard against a missing call of gl.init() (we get a SEGV if we call
 * some GL functions before calling glewInit(), so check) */
    {
    if(!Initialized)
        return luaL_error(L, "missing gl.init() call");
    return 0;
    }

static int Init(lua_State *L)
    {
    GLenum err;
#if 0
    if(lua_isboolean(L, 1))
        glewExperimental = (lua_toboolean(L,1)) ? GL_TRUE : GL_FALSE;
#endif
    /* See:
     * http://stackoverflow.com/questions/8302625/segmentation-fault-at-glgenvertexarrays-1-vao
     * http://glew.sourceforge.net/basic.html ('Experimental drivers')
     */
    glewExperimental = GL_TRUE;
    if((err = glewInit()) != GLEW_OK)
        return luaL_error(L, "glewInit error: %s", glewGetErrorString(err));
    glGetError(); /* just to be sure... */
    Initialized = 1;
    return 0;
    }

static int IsSupported(lua_State *L)
    {
    const char *what = luaL_checkstring(L, 1);
    lua_pushboolean(L, glewIsSupported(what));
    CheckError(L);
    return 1;
    }

#if 0
static int GetExtension(lua_State *L)
    {
    const char *what = luaL_checkstring(L, 1);
    lua_pushboolean(L, glewGetExtension(what));
    CheckError(L);
    return 1;
    }
#endif

static int Versions(lua_State *L)
    {
    int n = 0;
#ifdef GL_VERSION_1_0
    lua_pushstring(L, "GL_VERSION_1_0"); n++;
#endif /* GL_VERSION_1_0 */
#ifdef GL_VERSION_1_1
    lua_pushstring(L, "GL_VERSION_1_1"); n++;
#endif /* GL_VERSION_1_1 */
#ifdef GL_VERSION_1_2
    lua_pushstring(L, "GL_VERSION_1_2"); n++;
#endif /* GL_VERSION_1_2 */
#ifdef GL_VERSION_1_3
    lua_pushstring(L, "GL_VERSION_1_3"); n++;
#endif /* GL_VERSION_1_3 */
#ifdef GL_VERSION_1_4
    lua_pushstring(L, "GL_VERSION_1_4"); n++;
#endif /* GL_VERSION_1_4 */
#ifdef GL_VERSION_1_5
    lua_pushstring(L, "GL_VERSION_1_5"); n++;
#endif /* GL_VERSION_1_5 */
#ifdef GL_VERSION_2_0
    lua_pushstring(L, "GL_VERSION_2_0"); n++;
#endif /* GL_VERSION_2_0 */
#ifdef GL_VERSION_2_1
    lua_pushstring(L, "GL_VERSION_2_1"); n++;
#endif /* GL_VERSION_2_1 */
#ifdef GL_VERSION_3_0
    lua_pushstring(L, "GL_VERSION_3_0"); n++;
#endif /* GL_VERSION_3_0 */
#ifdef GL_VERSION_3_1
    lua_pushstring(L, "GL_VERSION_3_1"); n++;
#endif /* GL_VERSION_3_1 */
#ifdef GL_VERSION_3_2
    lua_pushstring(L, "GL_VERSION_3_2"); n++;
#endif /* GL_VERSION_3_2 */
#ifdef GL_VERSION_3_3
    lua_pushstring(L, "GL_VERSION_3_3"); n++;
#endif /* GL_VERSION_3_3 */
#ifdef GL_VERSION_4_0
    lua_pushstring(L, "GL_VERSION_4_0"); n++;
#endif /* GL_VERSION_4_0 */
#ifdef GL_VERSION_4_1
    lua_pushstring(L, "GL_VERSION_4_1"); n++;
#endif /* GL_VERSION_4_1 */
#ifdef GL_VERSION_4_2
    lua_pushstring(L, "GL_VERSION_4_2"); n++;
#endif /* GL_VERSION_4_2 */
#ifdef GL_VERSION_4_3
    lua_pushstring(L, "GL_VERSION_4_3"); n++;
#endif /* GL_VERSION_4_3 */
#ifdef GL_VERSION_4_4
    lua_pushstring(L, "GL_VERSION_4_4"); n++;
#endif /* GL_VERSION_4_4 */
#ifdef GL_VERSION_4_5
    lua_pushstring(L, "GL_VERSION_4_5"); n++;
#endif /* GL_VERSION_4_5 */
#ifdef GL_VERSION_4_6
    lua_pushstring(L, "GL_VERSION_4_6"); n++;
#endif /* GL_VERSION_4_6 */
    return n;
    }

static const struct luaL_Reg Functions[] = 
    {
        { "init", Init },
        { "is_supported", IsSupported },
/*       { "get_extension", GetExtension },  for glew version < 1.3.0 only */
        { "versions", Versions },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_init(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }


