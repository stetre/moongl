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

ENUM_STRINGS(FuncStrings) = {
    "never",
    "always",
    "less",
    "greater",
    "equal",
    "lequal",
    "gequal",
    "notequal",
    NULL
};
ENUM_CODES(FuncCodes) = {
    GL_NEVER,
    GL_ALWAYS,
    GL_LESS,
    GL_GREATER,
    GL_EQUAL,
    GL_LEQUAL,
    GL_GEQUAL,
    GL_NOTEQUAL,
};
ENUM_T(FuncEnum, FuncStrings, FuncCodes)
#define CheckFunc(L, arg) enumCheck((L), (arg), &FuncEnum)
#define PushFunc(L, code) enumPush((L), (code), &FuncEnum)

enum_t *enumStencilFunc(void)
    { return &FuncEnum; }

ENUM_STRINGS(FaceStrings) = {
    "front",
    "back",
    "front and back",
    NULL
};
ENUM_CODES(FaceCodes) = {
    GL_FRONT,
    GL_BACK,
    GL_FRONT_AND_BACK,
};
ENUM_T(FaceEnum, FaceStrings, FaceCodes)
#define CheckFace(L, arg) enumCheck((L), (arg), &FaceEnum)
#define PushFace(L, code) enumPush((L), (code), &FaceEnum)

ENUM_STRINGS(ActionStrings) = {
    "keep",
    "zero", 
    "replace", 
    "incr", 
    "incr wrap", 
    "decr", 
    "decr wrap",
    "invert",
    NULL
};
ENUM_CODES(ActionCodes) = {
    GL_KEEP,
    GL_ZERO, 
    GL_REPLACE, 
    GL_INCR, 
    GL_INCR_WRAP, 
    GL_DECR, 
    GL_DECR_WRAP,
    GL_INVERT
};
ENUM_T(ActionEnum, ActionStrings, ActionCodes)
#define CheckAction(L, arg) enumCheck((L), (arg), &ActionEnum)
#define PushAction(L, code) enumPush((L), (code), &ActionEnum)

enum_t *enumStencilOp(void)
    { return &ActionEnum; }

ENUM_STRINGS(ModeStrings) = {
    "min", 
    "max",
    "add", 
    "subtract", 
    "reverse subtract",
    NULL
};
ENUM_CODES(ModeCodes) = {
    GL_MIN, 
    GL_MAX,
    GL_FUNC_ADD, 
    GL_FUNC_SUBTRACT, 
    GL_FUNC_REVERSE_SUBTRACT,
};
ENUM_T(ModeEnum, ModeStrings, ModeCodes)
#define CheckMode(L, arg) enumCheck((L), (arg), &ModeEnum)
#define PushMode(L, code) enumPush((L), (code), &ModeEnum)

enum_t *enumBlendMode(void)
    { return &ModeEnum; }

ENUM_STRINGS(FactorStrings) = {
    "zero",
    "one",
    "src color",
    "one minus src color",
    "dst color",
    "one minus dst color",
    "src alpha",
    "one minus src alpha",
    "dst alpha",
    "one minus dst alpha",
    "constant color",
    "one minus constant color",
    "constant alpha",
    "one minus constant alpha",
    "src alpha saturate",
    "src1 color",
    "one minus src1 color",
    "src1 alpha", 
    "one minus src1 alpha",
    NULL
};
ENUM_CODES(FactorCodes) = {
    GL_ZERO,
    GL_ONE,
    GL_SRC_COLOR,
    GL_ONE_MINUS_SRC_COLOR,
    GL_DST_COLOR,
    GL_ONE_MINUS_DST_COLOR,
    GL_SRC_ALPHA,
    GL_ONE_MINUS_SRC_ALPHA,
    GL_DST_ALPHA,
    GL_ONE_MINUS_DST_ALPHA,
    GL_CONSTANT_COLOR,
    GL_ONE_MINUS_CONSTANT_COLOR,
    GL_CONSTANT_ALPHA,
    GL_ONE_MINUS_CONSTANT_ALPHA,
    GL_SRC_ALPHA_SATURATE,
    GL_SRC1_COLOR,
    GL_ONE_MINUS_SRC1_COLOR,
    GL_SRC1_ALPHA, 
    GL_ONE_MINUS_SRC1_ALPHA,
};
ENUM_T(FactorEnum, FactorStrings, FactorCodes)
#define CheckFactor(L, arg) enumCheck((L), (arg), &FactorEnum)
#define PushFactor(L, code) enumPush((L), (code), &FactorEnum)

enum_t *enumBlendFactor(void)
    { return &FactorEnum; }

ENUM_STRINGS(OpStrings) = {
    "clear", 
    "and", 
    "and reverse", 
    "copy",
    "and inverted", 
    "noop", 
    "xor", 
    "or", 
    "nor", 
    "equiv", 
    "or reverse", 
    "invert", 
    "copy inverted", 
    "or inverted",
    "nand", 
    "set", 
    NULL
};
ENUM_CODES(OpCodes) = {
    GL_CLEAR, 
    GL_AND, 
    GL_AND_REVERSE, 
    GL_COPY,
    GL_AND_INVERTED, 
    GL_NOOP, 
    GL_XOR, 
    GL_OR, 
    GL_NOR, 
    GL_EQUIV, 
    GL_OR_REVERSE, 
    GL_INVERT, 
    GL_COPY_INVERTED, 
    GL_OR_INVERTED,
    GL_NAND, 
    GL_SET, 
};
ENUM_T(OpEnum, OpStrings, OpCodes)
#define CheckOp(L, arg) enumCheck((L), (arg), &OpEnum)
#define PushOp(L, code) enumPush((L), (code), &OpEnum)

enum_t *enumLogicOp(void)
    { return &OpEnum; }

static int Scissor(lua_State *L)
    {
    GLint x, y;
    GLsizei width, height;
    GLint v[4];
    GLint index;
    if(lua_isinteger(L, 5))
        {
        v[0] = luaL_checkinteger(L, 1);
        v[1] = luaL_checkinteger(L, 2);
        v[2] = luaL_checkinteger(L, 3);
        v[3] = luaL_checkinteger(L, 4);
        index = luaL_checkinteger(L, 5);
        glScissorIndexedv(index, v);
        }
    else
        {
        x = luaL_checkinteger(L, 1);
        y = luaL_checkinteger(L, 2);
        width = luaL_checkinteger(L, 3);
        height = luaL_checkinteger(L, 4);
        glScissor(x, y, width, height);
        }
    CheckError(L);
    return 0;
    }


static int ScissorArray(lua_State *L)
/* scissor_array(first, x1, x2, w1, h1, x2, y2, ...) */
    {
    int i, arg;
    GLsizei count;
    GLint *v;
    GLuint first = luaL_checkinteger(L, 1);
    count = 0;
    arg = 2;
    while(!lua_isnoneornil(L, arg++))
        luaL_checkinteger(L, arg);

    count = arg - 2;
    if((arg < 6) || ((count % 4)!=0))
        return luaL_error(L, NARGS_ERROR);
    v = (GLint*)Malloc(L, count*sizeof(GLint));
    i = 0;
    arg = 2;
    while(i < count)
        v[i++] = lua_tointeger(L, arg++);
    glScissorArrayv(first, count/4, v);
    Free(L, v);
    CheckError(L);
    return 0;
    }

static int SampleCoverage(lua_State *L)
    {
    GLfloat value = luaL_checknumber(L, 1);
    GLboolean invert = checkboolean(L, 2);
    glSampleCoverage(value, invert);
    CheckError(L);
    return 0;
    }

static int SampleMask(lua_State *L)
    {
    GLuint maskNumber = luaL_checkinteger(L, 1);
    GLbitfield mask = luaL_checkinteger(L, 2);
    glSampleMaski(maskNumber, mask);
    CheckError(L);
    return 0;
    }

static int StencilFunc(lua_State *L)
    {
    GLenum face;
    GLenum func = CheckFunc(L, 1);
    GLint ref = luaL_checkinteger(L, 2);
    GLuint mask = luaL_checkinteger(L, 3);
    if(lua_isstring(L, 4))
        {
        face = CheckFace(L, 4);
        glStencilFuncSeparate(face, func, ref, mask);
        }
    else
        glStencilFunc(func, ref, mask);
    CheckError(L);
    return 0;
    }

static int StencilOp(lua_State *L)
    {
    GLenum face;
    GLenum sfail = CheckAction(L, 1);
    GLenum dpfail = CheckAction(L, 2);
    GLenum dppass = CheckAction(L, 3);
    if(lua_isstring(L, 4))
        {
        face = CheckFace(L, 4);
        glStencilOpSeparate(face, sfail, dpfail, dppass);
        }
    else
        glStencilOp(sfail, dpfail, dppass);
    CheckError(L);
    return 0;
    }

static int DepthFunc(lua_State *L)
    {
    GLenum func = CheckFunc(L, 1);
    glDepthFunc(func);
    CheckError(L);
    return 0;
    }

static int BlendEquation(lua_State *L)
    {
    GLuint buf;
    GLenum mode, alpha;

    if(lua_isinteger(L, 1))
        {
        buf = luaL_checkinteger(L, 1);
        mode = CheckMode(L, 2);
        if(lua_isstring(L, 3))
            {
            alpha = CheckMode(L,3);
            glBlendEquationSeparatei(buf, mode, alpha);
            }
        else
            glBlendEquationi(buf, mode);
        }
    else
        {
        mode = CheckMode(L, 1);
        if(lua_isstring(L, 2))
            {
            alpha = CheckMode(L,2);
            glBlendEquationSeparate(mode, alpha);
            }
        else
            glBlendEquation(mode);
        }
    CheckError(L);
    return 0;
    }


static int BlendFunc(lua_State *L)
    {
    GLuint buf;
    GLenum sfactor, dfactor, sfactorAlpha, dfactorAlpha;
    if(lua_isinteger(L, 1))
        {
        buf = luaL_checkinteger(L, 1);
        sfactor = CheckFactor(L, 2);
        dfactor = CheckFactor(L, 3);
        if(lua_isstring(L, 4))
            {
            sfactorAlpha = CheckFactor(L, 4);
            dfactorAlpha = CheckFactor(L, 5);
            glBlendFuncSeparatei(buf, sfactor, dfactor, sfactorAlpha, dfactorAlpha);
            }
        else
            glBlendFunci(buf, sfactor, dfactor);
        }
    else
        {
        sfactor = CheckFactor(L, 1);
        dfactor = CheckFactor(L, 2);
        if(lua_isstring(L, 3))
            {
            sfactorAlpha = CheckFactor(L, 3);
            dfactorAlpha = CheckFactor(L, 4);
            glBlendFuncSeparate(sfactor, dfactor, sfactorAlpha, dfactorAlpha);
            }
        else
            glBlendFunc(sfactor, dfactor);
        }
    CheckError(L);
    return 0;
    }


static int BlendColor(lua_State *L)
    {
    GLfloat r = luaL_checknumber(L, 1);
    GLfloat g = luaL_checknumber(L, 2);
    GLfloat b = luaL_checknumber(L, 3);
    GLfloat a = luaL_checknumber(L, 4);
    glBlendColor(r, g, b, a);
    CheckError(L);
    return 0;
    }

static int LogicOp(lua_State *L)
    {
    GLenum opcode = CheckOp(L, 1);
    glLogicOp(opcode);
    CheckError(L);
    return 0;
    }

static const struct luaL_Reg Functions[] = 
    {
        { "scissor", Scissor },
        { "scissor_array", ScissorArray },
        { "sample_coverage", SampleCoverage },
        { "sample_mask", SampleMask },
        { "stencil_func", StencilFunc },
        { "stencil_op", StencilOp },
        { "depth_func", DepthFunc },
        { "blend_equation", BlendEquation },
        { "blend_func", BlendFunc },
        { "blend_color", BlendColor },
        { "logic_op", LogicOp },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_perfragment(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

