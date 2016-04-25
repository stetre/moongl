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

ENUM_STRINGS(HintTargetStrings) = {
    "line smooth",
    "polygon smooth",
    "texture compression",
    "fragment shader derivative",
    NULL
};
ENUM_CODES(HintTargetCodes) = {
    GL_LINE_SMOOTH_HINT,
    GL_POLYGON_SMOOTH_HINT,
    GL_TEXTURE_COMPRESSION_HINT,
    GL_FRAGMENT_SHADER_DERIVATIVE_HINT,
};
ENUM_T(HintTargetEnum, HintTargetStrings, HintTargetCodes)
#define CheckHintTarget(L, arg) enumCheck((L), (arg), &HintTargetEnum)
#define PushHintTarget(L, code) enumPush((L), (code), &HintTargetEnum)

ENUM_STRINGS(HintModeStrings) = {
    "fastest",
    "nicest",
    "don't care",
    NULL
};
ENUM_CODES(HintModeCodes) = {
    GL_FASTEST,
    GL_NICEST,
    GL_DONT_CARE,
};
ENUM_T(HintModeEnum, HintModeStrings, HintModeCodes)
#define CheckHintMode(L, arg) enumCheck((L), (arg), &HintModeEnum)
#define PushHintMode(L, code) enumPush((L), (code), &HintModeEnum)

enum_t *enumHintMode(void)
    { return &HintModeEnum; }

static int Hint(lua_State *L)
    {
    GLenum target = CheckHintTarget(L, 1);
    GLenum mode = CheckHintMode(L, 2);
    glHint(target, mode);
    CheckError(L);
    return 0;
    }

static const struct luaL_Reg Functions[] = 
    {
        { "hint", Hint },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_hint(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }


