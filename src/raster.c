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

ENUM_STRINGS(PolygonModeFaceStrings) = {
    "front and back",
    NULL
};
ENUM_CODES(PolygonModeFaceCodes) = {
    GL_FRONT_AND_BACK
};
ENUM_T(PolygonModeFaceEnum, PolygonModeFaceStrings, PolygonModeFaceCodes)
#define CheckPolygonModeFace(L, arg) enumCheck((L), (arg), &PolygonModeFaceEnum)
#define PushPolygonModeFace(L, code) enumPush((L), (code), &PolygonModeFaceEnum)

ENUM_STRINGS(PolygonModeModeStrings) = {
    "point",
    "line",
    "fill",
    NULL
};
ENUM_CODES(PolygonModeModeCodes) = {
    GL_POINT,
    GL_LINE,
    GL_FILL
};
ENUM_T(PolygonModeModeEnum, PolygonModeModeStrings, PolygonModeModeCodes)
#define CheckPolygonModeMode(L, arg) enumCheck((L), (arg), &PolygonModeModeEnum)
#define PushPolygonModeMode(L, code) enumPush((L), (code), &PolygonModeModeEnum)

enum_t *enumPolygonModeMode(void)
    { return &PolygonModeModeEnum; }

ENUM_STRINGS(FrontFaceModeStrings) = {
    "ccw",
    "cw",
    NULL
};
ENUM_CODES(FrontFaceModeCodes) = {
    GL_CCW,
    GL_CW
};
ENUM_T(FrontFaceModeEnum, FrontFaceModeStrings, FrontFaceModeCodes)
#define CheckFrontFaceMode(L, arg) enumCheck((L), (arg), &FrontFaceModeEnum)
#define PushFrontFaceMode(L, code) enumPush((L), (code), &FrontFaceModeEnum)

enum_t *enumFrontFaceMode(void)
    { return &FrontFaceModeEnum; }

ENUM_STRINGS(CullFaceModeStrings) = {
    "front",
    "back",
    "front and back",
    NULL
};
ENUM_CODES(CullFaceModeCodes) = {
    GL_FRONT,
    GL_BACK,
    GL_FRONT_AND_BACK
};
ENUM_T(CullFaceModeEnum, CullFaceModeStrings, CullFaceModeCodes)
#define CheckCullFaceMode(L, arg) enumCheck((L), (arg), &CullFaceModeEnum)
#define PushCullFaceMode(L, code) enumPush((L), (code), &CullFaceModeEnum)

enum_t *enumCullFaceMode(void)
    { return &CullFaceModeEnum; }


ENUM_STRINGS(MultisamplePnameStrings) = {
    "sample position",
    NULL
};
ENUM_CODES(MultisamplePnameCodes) = {
    GL_SAMPLE_POSITION
};
ENUM_T(MultisamplePnameEnum, MultisamplePnameStrings, MultisamplePnameCodes)
#define CheckMultisamplePname(L, arg) enumCheck((L), (arg), &MultisamplePnameEnum)
#define PushMultisamplePname(L, code) enumPush((L), (code), &MultisamplePnameEnum)

ENUM_STRINGS(PnameStrings) = {
    "fade threshold size",
    "sprite coord origin",
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_POINT_FADE_THRESHOLD_SIZE,
    GL_POINT_SPRITE_COORD_ORIGIN
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)

ENUM_STRINGS(OriginStrings) = {
    "lower left",
    "upper left",
    NULL
};
ENUM_CODES(OriginCodes) = {
    GL_LOWER_LEFT,
    GL_UPPER_LEFT
};
ENUM_T(OriginEnum, OriginStrings, OriginCodes)
#define CheckOrigin(L, arg) enumCheck((L), (arg), &OriginEnum)
#define PushOrigin(L, code) enumPush((L), (code), &OriginEnum)

enum_t *enumOrigin(void)
    { return &OriginEnum; }


static int PointParameter(lua_State *L)
    {
    GLenum pname = CheckPname(L, 1);
    switch(pname)
        {
        case GL_POINT_FADE_THRESHOLD_SIZE: glPointParameterf(pname, luaL_checknumber(L, 2));
                                            break;
        case GL_POINT_SPRITE_COORD_ORIGIN: glPointParameteri(pname, CheckOrigin(L, 2)); 
                                            break;
        default: 
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    CheckError(L);
    return 0;
    }

FLOAT_FUNC(PointSize)
FLOAT_FUNC(LineWidth)
FLOAT_FUNC(MinSampleShading)

static int GetMultisample(lua_State *L)
    {
    GLenum pname = CheckMultisamplePname(L, 1);
    switch(pname)
        {
        case GL_SAMPLE_POSITION:
                {
                GLfloat val[2];
                GLuint index = luaL_checkinteger(L, 2);
                glGetMultisamplefv(pname,index,val);
                CheckError(L);
                lua_pushnumber(L, val[0]);
                lua_pushnumber(L, val[1]);
                return 2;
                }
        default: 
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }


static int CullFace(lua_State *L)
    {
    GLenum mode = CheckCullFaceMode(L, 1);
    glCullFace(mode);
    CheckError(L);
    return 0;
    }

static int FrontFace(lua_State *L)
    {
    GLenum mode = CheckFrontFaceMode(L, 1);
    glFrontFace(mode);
    CheckError(L);
    return 0;
    }

static int PolygonMode(lua_State *L)
    {
    GLenum face = CheckPolygonModeFace(L, 1);
    GLenum mode = CheckPolygonModeMode(L, 2);
    glPolygonMode(face, mode);
    CheckError(L);
    return 0;
    }

FLOAT2_FUNC(PolygonOffset)

static const struct luaL_Reg Functions[] = 
    {
        { "min_sample_shading", MinSampleShading },
        { "point_parameter", PointParameter },
        { "point_size", PointSize },
        { "line_width", LineWidth },
        { "get_multisample", GetMultisample },
        { "cull_face", CullFace },
        { "front_face", FrontFace },
        { "polygon_mode", PolygonMode },
        { "polygon_offset", PolygonOffset },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_raster(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

