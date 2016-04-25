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


ENUM_STRINGS(CapStrings) = {
    "blend",
    "clip distance 0",
    "clip distance 1",
    "clip distance 2",
    "clip distance 3",
    "clip distance 4",
    "clip distance 5",
    "clip distance 6",
    "clip distance 7",
    "color logic op",
    "cull face",
    "debug output",
    "debug output synchronous",
    "depth clamp",
    "depth test",
    "dither",
    "framebuffer srgb",
    "line smooth",
    "multisample",
    "polygon offset fill",
    "polygon offset line",
    "polygon offset point",
    "polygon smooth",
    "primitive restart",
    "primitive restart fixed index",
    "rasterizer discard",
    "sample alpha to coverage",
    "sample alpha to one",
    "sample coverage",
    "sample shading",
    "sample mask",
    "scissor test",
    "stencil test",
    "texture cube map seamless",
    "program point size",
    NULL
};
ENUM_CODES(CapCodes) = {
    GL_BLEND,
    GL_CLIP_DISTANCE0,
    GL_CLIP_DISTANCE1,
    GL_CLIP_DISTANCE2,
    GL_CLIP_DISTANCE3,
    GL_CLIP_DISTANCE4,
    GL_CLIP_DISTANCE5,
    GL_CLIP_DISTANCE6,
    GL_CLIP_DISTANCE7,
    GL_COLOR_LOGIC_OP,
    GL_CULL_FACE,
    GL_DEBUG_OUTPUT,
    GL_DEBUG_OUTPUT_SYNCHRONOUS,
    GL_DEPTH_CLAMP,
    GL_DEPTH_TEST,
    GL_DITHER,
    GL_FRAMEBUFFER_SRGB,
    GL_LINE_SMOOTH,
    GL_MULTISAMPLE,
    GL_POLYGON_OFFSET_FILL,
    GL_POLYGON_OFFSET_LINE,
    GL_POLYGON_OFFSET_POINT,
    GL_POLYGON_SMOOTH,
    GL_PRIMITIVE_RESTART,
    GL_PRIMITIVE_RESTART_FIXED_INDEX,
    GL_RASTERIZER_DISCARD,
    GL_SAMPLE_ALPHA_TO_COVERAGE,
    GL_SAMPLE_ALPHA_TO_ONE,
    GL_SAMPLE_COVERAGE,
    GL_SAMPLE_SHADING,
    GL_SAMPLE_MASK,
    GL_SCISSOR_TEST,
    GL_STENCIL_TEST,
    GL_TEXTURE_CUBE_MAP_SEAMLESS,
    GL_PROGRAM_POINT_SIZE
};

ENUM_T(CapEnum, CapStrings, CapCodes)
#define CheckCap(L, arg) enumCheck((L), (arg), &CapEnum)
#define PushCap(L, code) enumPush((L), (code), &CapEnum)

static int Enable(lua_State *L)
    {
    GLenum cap = CheckCap(L, 1);
    int indexed = lua_isinteger(L, 2);
    if(indexed)
        glEnablei(cap, lua_tointeger(L, 2));
    else
        glEnable(cap);
    CheckError(L);
    return 0;
    }

static int Disable(lua_State *L)
    {
    GLenum cap = CheckCap(L, 1);
    int indexed = lua_isinteger(L, 2);
    if(indexed)
        glDisablei(cap, lua_tointeger(L, 2));
    else
        glDisable(cap);
    CheckError(L);
    return 0;
    }

static int IsEnabled(lua_State *L)
    {
    GLboolean res;
    GLenum cap = CheckCap(L, 1);
    int indexed = lua_isinteger(L, 2);
    if(indexed)
        res = glIsEnabledi(cap, lua_tointeger(L, 2));
    else
        res = glIsEnabled(cap);
    CheckError(L);
    lua_pushboolean(L, res);
    return 1;
    }

static const struct luaL_Reg Functions[] = 
    {
        { "enable", Enable },
        { "disable", Disable },
        { "is_enabled", IsEnabled },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_capabilities(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

