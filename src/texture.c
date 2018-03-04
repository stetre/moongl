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

ENUM_STRINGS(TargetStrings) = {
    "1d",
    "2d",
    "3d",
    "1d array",
    "2d array",
    "rectangle",
    "cube map",
    "cube map array",
    "2d multisample",
    "2d multisample array",
    "cube map positive x", 
    "cube map positive y", 
    "cube map positive z", 
    "cube map negative x", 
    "cube map negative y", 
    "cube map negative z", 
    "proxy 1d",
    "proxy 2d",
    "proxy 3d",
    "proxy 1d array",
    "proxy 2d array",
    "proxy rectangle",
    "proxy cube map",
    "proxy cube map array",
    "proxy 2d multisample",
    "proxy 2d multisample array",
    "buffer",
    "renderbuffer",
    NULL
};
ENUM_CODES(TargetCodes) = {
    GL_TEXTURE_1D,
    GL_TEXTURE_2D,
    GL_TEXTURE_3D,
    GL_TEXTURE_1D_ARRAY,
    GL_TEXTURE_2D_ARRAY,
    GL_TEXTURE_RECTANGLE,
    GL_TEXTURE_CUBE_MAP,
    GL_TEXTURE_CUBE_MAP_ARRAY,
    GL_TEXTURE_2D_MULTISAMPLE,
    GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
    GL_TEXTURE_CUBE_MAP_POSITIVE_X, 
    GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 
    GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 
    GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 
    GL_PROXY_TEXTURE_1D,
    GL_PROXY_TEXTURE_2D,
    GL_PROXY_TEXTURE_3D,
    GL_PROXY_TEXTURE_1D_ARRAY,
    GL_PROXY_TEXTURE_2D_ARRAY,
    GL_PROXY_TEXTURE_RECTANGLE,
    GL_PROXY_TEXTURE_CUBE_MAP,
    GL_PROXY_TEXTURE_CUBE_MAP_ARRAY,
    GL_PROXY_TEXTURE_2D_MULTISAMPLE,
    GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY,
    GL_TEXTURE_BUFFER,
    GL_RENDERBUFFER, /* for GetInternalFormat() only */
};
ENUM_T(TargetEnum,TargetStrings, TargetCodes)
#define CheckTarget(L, arg) enumCheck((L), (arg), &TargetEnum)
#define CheckTargetOrName(L, arg, dst) enumOrUint((L), (arg), (dst), &TargetEnum, 0)
enum_t *enumTextureTarget(void)
    { return &TargetEnum; }

ENUM_STRINGS(PnameStrings) = {
    "depth stencil mode",
    "base level",
    "compare func",
    "compare mode",
    "lod bias",
    "min filter", 
    "mag filter",
    "min lod",
    "max lod",
    "max level",
    "swizzle r",
    "swizzle g",
    "swizzle b",
    "swizzle a",
    "wrap s",
    "wrap t", 
    "wrap r",
    "border color",
    "swizzle rgba",
    /* get only: */
    "image format compatibility type", 
    "immutable format",
    "immutable levels", 
    "view min level", 
    "view num levels", 
    "view min layer", 
    "view num layers",
    "target", 
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_DEPTH_STENCIL_TEXTURE_MODE,
    GL_TEXTURE_BASE_LEVEL,
    GL_TEXTURE_COMPARE_FUNC,
    GL_TEXTURE_COMPARE_MODE,
    GL_TEXTURE_LOD_BIAS,
    GL_TEXTURE_MIN_FILTER, 
    GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_MIN_LOD,
    GL_TEXTURE_MAX_LOD,
    GL_TEXTURE_MAX_LEVEL,
    GL_TEXTURE_SWIZZLE_R,
    GL_TEXTURE_SWIZZLE_G,
    GL_TEXTURE_SWIZZLE_B,
    GL_TEXTURE_SWIZZLE_A,
    GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T, 
    GL_TEXTURE_WRAP_R,
    GL_TEXTURE_BORDER_COLOR,
    GL_TEXTURE_SWIZZLE_RGBA,
    /* get only: */
    GL_IMAGE_FORMAT_COMPATIBILITY_TYPE, 
    GL_TEXTURE_IMMUTABLE_FORMAT,
    GL_TEXTURE_IMMUTABLE_LEVELS, 
    GL_TEXTURE_VIEW_MIN_LEVEL, 
    GL_TEXTURE_VIEW_NUM_LEVELS, 
    GL_TEXTURE_VIEW_MIN_LAYER, 
    GL_TEXTURE_VIEW_NUM_LAYERS,
    GL_TEXTURE_TARGET
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)

ENUM_STRINGS(DepthStencilStrings) = {
    "depth",
    "stencil",
    NULL
};
ENUM_CODES(DepthStencilCodes) = {
    GL_DEPTH_COMPONENT,
    GL_STENCIL_INDEX
};
ENUM_T(DepthStencilEnum, DepthStencilStrings, DepthStencilCodes)
#define CheckDepthStencil(L, arg) enumCheck((L), (arg), &DepthStencilEnum)
#define PushDepthStencil(L, code) enumPush((L), (code), &DepthStencilEnum)

ENUM_STRINGS(CompareFuncStrings) = {
    "never",
    "less",
    "equal",
    "lequal",
    "greater",
    "notequal",
    "gequal",
    "always",
    NULL
};
ENUM_CODES(CompareFuncCodes) = {
    GL_NEVER,
    GL_LESS,
    GL_EQUAL,
    GL_LEQUAL,
    GL_GREATER,
    GL_NOTEQUAL,
    GL_GEQUAL,
    GL_ALWAYS
};
ENUM_T(CompareFuncEnum, CompareFuncStrings, CompareFuncCodes)
#define CheckCompareFunc(L, arg) enumCheck((L), (arg), &CompareFuncEnum)
#define PushCompareFunc(L, code) enumPush((L), (code), &CompareFuncEnum)
enum_t *enumCompareFunc(void)
    { return &CompareFuncEnum; }

ENUM_STRINGS(CompareModeStrings) = {
    "none",
    "compare ref to texture",
    NULL
};
ENUM_CODES(CompareModeCodes) = {
    GL_NONE,
    GL_COMPARE_REF_TO_TEXTURE
};
ENUM_T(CompareModeEnum, CompareModeStrings, CompareModeCodes)
#define CheckCompareMode(L, arg) enumCheck((L), (arg), &CompareModeEnum)
#define PushCompareMode(L, code) enumPush((L), (code), &CompareModeEnum)
enum_t *enumCompareMode(void)
    { return &CompareModeEnum; }

ENUM_STRINGS(RgbaStrings) = {
    "red",
    "green",
    "blue",
    "alpha",
    "zero",
    "one",
    NULL
};
ENUM_CODES(RgbaCodes) = {
    GL_RED,
    GL_GREEN,
    GL_BLUE,
    GL_ALPHA,
    GL_ZERO,
    GL_ONE
};
ENUM_T(RgbaEnum, RgbaStrings, RgbaCodes)
#define CheckRgba(L, arg) enumCheck((L), (arg), &RgbaEnum)
#define PushRgba(L, code) enumPush((L), (code), &RgbaEnum)

ENUM_STRINGS(WrapStrings) = {
    "clamp to edge",
    "repeat",
    "clamp to border",
    "mirrored repeat",
    "mirror clamp to edge",
    NULL
};
ENUM_CODES(WrapCodes) = {
    GL_CLAMP_TO_EDGE,
    GL_REPEAT,
    GL_CLAMP_TO_BORDER,
    GL_MIRRORED_REPEAT,
    GL_MIRROR_CLAMP_TO_EDGE
};
ENUM_T(WrapEnum, WrapStrings, WrapCodes)
#define CheckWrap(L, arg) enumCheck((L), (arg), &WrapEnum)
#define PushWrap(L, code) enumPush((L), (code), &WrapEnum)
enum_t *enumWrap(void)
    { return &WrapEnum; }

ENUM_STRINGS(MagFilterStrings) = {
    "nearest",
    "linear",
    NULL
};
ENUM_CODES(MagFilterCodes) = {
    GL_NEAREST,
    GL_LINEAR
};
ENUM_T(MagFilterEnum, MagFilterStrings, MagFilterCodes)
#define CheckMagFilter(L, arg) enumCheck((L), (arg), &MagFilterEnum)
#define PushMagFilter(L, code) enumPush((L), (code), &MagFilterEnum)
enum_t *enumMagFilter(void)
    { return &MagFilterEnum; }

ENUM_STRINGS(MinFilterStrings) = {
    "nearest",
    "linear",
    "nearest mipmap nearest",
    "nearest mipmap linear",
    "linear mipmap nearest",
    "linear mipmap linear",
    NULL
};
ENUM_CODES(MinFilterCodes) = {
    GL_NEAREST,
    GL_LINEAR,
    GL_NEAREST_MIPMAP_NEAREST,
    GL_NEAREST_MIPMAP_LINEAR,
    GL_LINEAR_MIPMAP_NEAREST,
    GL_LINEAR_MIPMAP_LINEAR
};
ENUM_T(MinFilterEnum, MinFilterStrings, MinFilterCodes)
#define CheckMinFilter(L, arg) enumCheck((L), (arg), &MinFilterEnum)
#define PushMinFilter(L, code) enumPush((L), (code), &MinFilterEnum)
enum_t *enumMinFilter(void)
    { return &MinFilterEnum; }

ENUM_STRINGS(ImageFormatCTStrings) = {
    "by size",
    "by class",
    "none",
    NULL
};
ENUM_CODES(ImageFormatCTCodes) = {
    GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE,
    GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS,
    GL_NONE
};
ENUM_T(ImageFormatCTEnum, ImageFormatCTStrings, ImageFormatCTCodes)
#define CheckImageFormatCT(L, arg) enumCheck((L), (arg), &ImageFormatCTEnum)
#define PushImageFormatCT(L, code) enumPush((L), (code), &ImageFormatCTEnum)

ENUM_STRINGS(LPnameStrings) = {
    "width",
    "height", 
    "depth",
    "fixed sample locations",
    "internal format",
    "shared size",
    "compressed",
    "compressed image size",
    "samples",
    "buffer offset",
    "buffer size",
    "red size",
    "green size",
    "blue size",
    "alpha size",
    "depth size",
    "red type",
    "green type",
    "blue type",
    "alpha type",
    "depth type",
    NULL
};
ENUM_CODES(LPnameCodes) = {
    GL_TEXTURE_WIDTH,
    GL_TEXTURE_HEIGHT, 
    GL_TEXTURE_DEPTH,
    GL_TEXTURE_FIXED_SAMPLE_LOCATIONS,
    GL_TEXTURE_INTERNAL_FORMAT,
    GL_TEXTURE_SHARED_SIZE,
    GL_TEXTURE_COMPRESSED,
    GL_TEXTURE_COMPRESSED_IMAGE_SIZE,
    GL_TEXTURE_SAMPLES,
    GL_TEXTURE_BUFFER_OFFSET,
    GL_TEXTURE_BUFFER_SIZE,
    GL_TEXTURE_RED_SIZE,
    GL_TEXTURE_GREEN_SIZE,
    GL_TEXTURE_BLUE_SIZE,
    GL_TEXTURE_ALPHA_SIZE,
    GL_TEXTURE_DEPTH_SIZE,
    GL_TEXTURE_RED_TYPE,
    GL_TEXTURE_GREEN_TYPE,
    GL_TEXTURE_BLUE_TYPE,
    GL_TEXTURE_ALPHA_TYPE,
    GL_TEXTURE_DEPTH_TYPE,
};
ENUM_T(LPnameEnum, LPnameStrings, LPnameCodes)
#define CheckLPname(L, arg) enumCheck((L), (arg), &LPnameEnum)
#define PushLPname(L, code) enumPush((L), (code), &LPnameEnum)


/*--------------------------------------------------------------------------*
 | Set parameter                                                            |   
 *--------------------------------------------------------------------------*/

static int SetInt(lua_State *L, GLuint texture, GLenum target, GLenum pname, int arg)
    {
    GLint param = luaL_checkinteger(L, arg);
    if(texture==0)
        glTexParameteri(target, pname, param);
    else 
        glTextureParameteri(texture, pname, param);
    CheckError(L);
    return 0;
    }

static int SetFloat(lua_State *L, GLuint texture, GLenum target, GLenum pname, int arg)
    {
    GLfloat param = luaL_checkinteger(L, arg);
    if(texture==0)
        glTexParameterf(target, pname, param);
    else 
        glTextureParameterf(texture, pname, param);
    CheckError(L);
    return 0;
    }

static int SetColor(lua_State *L, GLuint texture, GLenum target, GLenum pname, int arg)
    {
    GLfloat param[4];
    checkcolor(L, arg, param);
    if(texture==0)
        glTexParameterfv(target, pname, param);
    else 
        glTextureParameterfv(texture, pname, param);
    CheckError(L);
    return 0;
    }

static int SetEnum(lua_State *L, GLuint texture, GLenum target, GLenum pname, int arg, enum_t *e) 
    {
    GLint param = enumCheck(L, arg, e);
    if(texture==0)
        glTexParameteri(target, pname, param);
    else 
        glTextureParameteri(texture, pname, param);
    CheckError(L);
    return 0;
    }

static int SetEnum4(lua_State *L, GLuint texture, GLenum target, GLenum pname, int arg, enum_t *e) 
    {
    GLint param[4];
    param[0] = enumCheck(L, arg++, e);
    param[1] = enumCheck(L, arg++, e);
    param[2] = enumCheck(L, arg++, e);
    param[3] = enumCheck(L, arg++, e);
    if(texture==0)
        glTexParameteriv(target, pname, param);
    else 
        glTextureParameteriv(texture, pname, param);
    CheckError(L);
    return 0;
    }

static int TextureParameter(lua_State *L) 
/* texture_parameter(texture|target, pname, ...) */
    {
    int arg = 1;
    GLenum target, pname;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    pname = CheckPname(L, arg++);
    
    switch(pname)
        {
        case GL_DEPTH_STENCIL_TEXTURE_MODE: 
                return SetEnum(L, texture, target, pname, arg, &DepthStencilEnum);
        case GL_TEXTURE_BASE_LEVEL: 
        case GL_TEXTURE_MAX_LEVEL:  return SetInt(L, texture, target, pname, arg);
        case GL_TEXTURE_BORDER_COLOR:   return SetColor(L, texture, target, pname, arg);
        case GL_TEXTURE_COMPARE_FUNC:
                return SetEnum(L, texture, target, pname, arg, &CompareFuncEnum);
        case GL_TEXTURE_COMPARE_MODE:   
                return SetEnum(L, texture, target, pname, arg, &CompareModeEnum);
        case GL_TEXTURE_LOD_BIAS:
        case GL_TEXTURE_MIN_LOD:
        case GL_TEXTURE_MAX_LOD:   return SetFloat(L, texture, target, pname, arg);
        case GL_TEXTURE_SWIZZLE_R:
        case GL_TEXTURE_SWIZZLE_G:
        case GL_TEXTURE_SWIZZLE_B:
        case GL_TEXTURE_SWIZZLE_A:   
                return SetEnum(L, texture, target, pname, arg, &RgbaEnum);
        case GL_TEXTURE_SWIZZLE_RGBA:   
                return SetEnum4(L, texture, target, pname, arg, &RgbaEnum);
        case GL_TEXTURE_MIN_FILTER:
                return SetEnum(L, texture, target, pname, arg, &MinFilterEnum);
        case GL_TEXTURE_MAG_FILTER:  
                return SetEnum(L, texture, target, pname, arg, &MagFilterEnum);
        case GL_TEXTURE_WRAP_S:
        case GL_TEXTURE_WRAP_T:
        case GL_TEXTURE_WRAP_R:  
                return SetEnum(L, texture, target, pname, arg, &WrapEnum);
        default:
            return luaL_error(L, "cannot set parameter '%s'",  luaL_checkstring(L, arg));
        }
    return 0;
    }

/*--------------------------------------------------------------------------*
 | Get parameter                                                            |   
 *--------------------------------------------------------------------------*/

static int GetInt_(lua_State *L, GLuint texture, GLenum target, GLenum pname, int boolean)
#define GetInt(L,texture,target,pname) GetInt_((L),(texture),(target),(pname),0)
#define GetBoolean(L,texture,target,pname) GetInt_((L),(texture),(target),(pname),1)
    {
    GLint param;
    if(texture==0)
        glGetTexParameteriv(target, pname, &param);
    else
        glGetTextureParameteriv(texture, pname, &param);
    CheckError(L);
    if(boolean)
        lua_pushboolean(L, param); 
    else
        lua_pushinteger(L, param); 
    return 1;
    }

static int GetFloat(lua_State *L, GLuint texture, GLenum target, GLenum pname)
    {
    GLfloat param;
    if(texture==0)
        glGetTexParameterfv(target, pname, &param);
    else
        glGetTextureParameterfv(texture, pname, &param);
    CheckError(L);
    lua_pushnumber(L, param); 
    return 1;
    }

static int GetFloat4(lua_State *L, GLuint texture, GLenum target, GLenum pname)
    {
    GLfloat param[4];
    if(texture==0)
        glGetTexParameterfv(target, pname, param);
    else
        glGetTextureParameterfv(texture, pname, param);
    CheckError(L);
    lua_pushnumber(L, param[0]); 
    lua_pushnumber(L, param[1]); 
    lua_pushnumber(L, param[2]); 
    lua_pushnumber(L, param[3]); 
    return 4;
    }

static int GetEnum(lua_State *L, GLuint texture, GLenum target, GLenum pname, enum_t *e)
    {
    GLint param;
    if(texture==0)
        glGetTexParameteriv(target, pname, &param);
    else
        glGetTextureParameteriv(texture, pname, &param);
    CheckError(L);
    enumPush(L, param, e);
    return 1;
    }

static int GetEnum4(lua_State *L, GLuint texture, GLenum target, GLenum pname, enum_t *e)
    {
    GLint param[4];
    if(texture==0)
        glGetTexParameteriv(target, pname, param);
    else
        glGetTextureParameteriv(texture, pname, param);
    CheckError(L);
    enumPush(L, param[0], e);
    enumPush(L, param[1], e);
    enumPush(L, param[2], e);
    enumPush(L, param[3], e);
    return 4;
    }

static int GetTextureParameter(lua_State *L) 
/* get_texture_parameter(texture|target, pname) */
    {
    GLenum target, pname;
    GLuint texture = CheckTargetOrName(L, 1, &target);
    pname = CheckPname(L, 2);

    switch(pname)
        {
        case GL_DEPTH_STENCIL_TEXTURE_MODE:
                return GetEnum(L, texture, target, pname, &DepthStencilEnum);
        case GL_TEXTURE_BASE_LEVEL: 
        case GL_TEXTURE_MAX_LEVEL:  return GetInt(L, texture, target, pname);

        case GL_TEXTURE_BORDER_COLOR:   return GetFloat4(L, texture, target, pname);
        case GL_TEXTURE_COMPARE_FUNC:
                return GetEnum(L, texture, target, pname, &CompareFuncEnum);
        case GL_TEXTURE_COMPARE_MODE:
                return GetEnum(L, texture, target, pname, &CompareModeEnum);
        case GL_TEXTURE_LOD_BIAS:
        case GL_TEXTURE_MIN_LOD:
        case GL_TEXTURE_MAX_LOD:    return GetFloat(L, texture, target, pname);
        case GL_TEXTURE_SWIZZLE_R:
        case GL_TEXTURE_SWIZZLE_G:
        case GL_TEXTURE_SWIZZLE_B:
        case GL_TEXTURE_SWIZZLE_A:  
                return GetEnum(L, texture, target, pname, &RgbaEnum);
        case GL_TEXTURE_SWIZZLE_RGBA: 
            return GetEnum4(L, texture, target, pname, &RgbaEnum);

        case GL_TEXTURE_MIN_FILTER:
                return GetEnum(L, texture, target, pname, &MinFilterEnum);
        case GL_TEXTURE_MAG_FILTER:
                return GetEnum(L, texture, target, pname, &MagFilterEnum);

        case GL_TEXTURE_WRAP_S:
        case GL_TEXTURE_WRAP_T:
        case GL_TEXTURE_WRAP_R:
                return GetEnum(L, texture, target, pname, &WrapEnum);
        case GL_IMAGE_FORMAT_COMPATIBILITY_TYPE:
                return GetEnum(L, texture, target, pname, &ImageFormatCTEnum);
        case GL_TEXTURE_IMMUTABLE_FORMAT:   return GetBoolean(L, texture, target, pname); 
        case GL_TEXTURE_IMMUTABLE_LEVELS:
        case GL_TEXTURE_VIEW_MIN_LEVEL:
        case GL_TEXTURE_VIEW_NUM_LEVELS:
        case GL_TEXTURE_VIEW_MIN_LAYER:
        case GL_TEXTURE_VIEW_NUM_LAYERS:    return GetInt(L, texture, target, pname);
        case GL_TEXTURE_TARGET:     return GetInt(L, texture, target, pname);
        default:
            {
            const char *name = luaL_checkstring(L, 2);
            return luaL_error(L, "cannot get parameter '%s'", name);
            }
        }
    return 0;
    }

/*--------------------------------------------------------------------------*
 | Get level parameter                                                      |   
 *--------------------------------------------------------------------------*/

static int LGetInt_(lua_State *L, GLuint texture, GLenum target, GLint level, GLenum pname, int boolean)
#define LGetInt(L,texture,target,level,pname) LGetInt_((L),(texture),(target),(level),(pname),0)
#define LGetBoolean(L,texture,target,level,pname) LGetInt_((L),(texture),(target),(level),(pname),1)
    {
    GLint param;
    if(texture==0)
        glGetTexLevelParameteriv(target, level, pname, &param);
    else
        glGetTextureLevelParameteriv(texture, level, pname, &param);
    CheckError(L);
    if(boolean)
        lua_pushboolean(L, param); 
    else
        lua_pushinteger(L, param); 
    return 1;
    }

static int LGetEnum(lua_State *L, GLuint texture, GLenum target, GLint level, GLenum pname, enum_t *e)
    {
    GLint param;
    if(texture==0)
        glGetTexLevelParameteriv(target, level, pname, &param);
    else
        glGetTextureLevelParameteriv(texture, level, pname, &param);
    CheckError(L);
    enumPush(L, param, e);
    return 1;
    }

//void glGetTexLevelParameterfv(GLenum target, GLint level, GLenum pname, GLfloat *params);
//void glGetTexLevelParameteriv(GLenum target, GLint level, GLenum pname, GLint *params);
//void glGetTextureLevelParameterfv(GLuint texture, GLint level, GLenum pname, GLfloat *params);
//void glGetTextureLevelParameteriv(GLuint texture, GLint level, GLenum pname, GLint *params);
static int GetTextureLevelParameter(lua_State *L)
    {
    GLenum target;
    GLuint texture = CheckTargetOrName(L, 1, &target);
    GLint level = luaL_checkinteger(L, 2);
    GLenum pname = CheckLPname(L, 3);
    switch(pname)
        {
        case GL_TEXTURE_COMPRESSED:
        case GL_TEXTURE_FIXED_SAMPLE_LOCATIONS:  return LGetBoolean(L,texture,target,level,pname);
        case GL_TEXTURE_WIDTH:
        case GL_TEXTURE_HEIGHT:
        case GL_TEXTURE_DEPTH:
        case GL_TEXTURE_COMPRESSED_IMAGE_SIZE:
        case GL_TEXTURE_SAMPLES:
        case GL_TEXTURE_SHARED_SIZE:
        case GL_TEXTURE_BUFFER_OFFSET:
        case GL_TEXTURE_BUFFER_SIZE:
        case GL_TEXTURE_RED_SIZE:
        case GL_TEXTURE_GREEN_SIZE:
        case GL_TEXTURE_BLUE_SIZE:
        case GL_TEXTURE_ALPHA_SIZE:
        case GL_TEXTURE_DEPTH_SIZE: return LGetInt(L,texture,target,level,pname);
        case GL_TEXTURE_RED_TYPE:
        case GL_TEXTURE_GREEN_TYPE:
        case GL_TEXTURE_BLUE_TYPE:
        case GL_TEXTURE_ALPHA_TYPE:
        case GL_TEXTURE_DEPTH_TYPE: 
                return LGetEnum(L, texture, target, level, pname, enumComponentType());
        case GL_TEXTURE_INTERNAL_FORMAT:  
                    return LGetEnum(L, texture, target, level, pname, enumInternalFormat());
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }


/*--------------------------------------------------------------------------*
 | Gen, bind etc                                                            |
 *--------------------------------------------------------------------------*/

NEW_TARGET_FUNC(Texture, &TargetEnum)
GEN_FUNC(Texture)
BIND_TARGET_FUNC(Texture, &TargetEnum)
DELETE_FUNC(Texture)
IS_FUNC(Texture)
BINDN_FUNC(Texture)
UINT2_FUNC(BindTextureUnit)

static int CreateTextures(lua_State *L)
    {
    GLuint* names;
    GLsizei i, n;
    GLenum target = CheckTarget(L, 1);
    check_init_called(L);
    n = 2;
    while(lua_isinteger(L, n)) n++; /* get the number of names */
    if(n==2) return luaL_argerror(L, 2, "integer expected");
    n = n - 2;
    names = (GLuint*)Malloc(L, n*sizeof(GLuint));
    for(i = 0; i < n; i++)
            names[i] = lua_tointeger(L, i+2);
    glCreateTextures(target, n, names);
    Free(L, names);
    CheckError(L);
    return 0;
    }


static int ActiveTexture(lua_State *L)
    {
    GLuint n = luaL_checkinteger(L, 1);
    GLenum texture;
    switch(n)
        {
#define C(i) case i: texture = GL_TEXTURE##i; break
        C(0); C(1); C(2); C(3); C(4); C(5); C(6); C(7); C(8); C(9); 
        C(10); C(11); C(12); C(13); C(14); C(15); C(16); C(17); C(18); C(19); C(20); 
        C(21); C(22); C(23); C(24); C(25); C(26); C(27); C(28); C(29); C(30); C(31); 
#undef C
        default: return luaL_argerror(L, 1, "out of range");
        }
    glActiveTexture(texture);
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "new_texture", NewTexture },
        { "gen_textures", GenTextures },
        { "bind_texture", BindTexture },
        { "bind_textures", BindTextures },
        { "is_texture", IsTexture },
        { "create_textures", CreateTextures },
        { "delete_textures", DeleteTextures },
        { "bind_texture_unit", BindTextureUnit },
        { "active_texture", ActiveTexture },
        { "texture_parameter", TextureParameter },
        { "get_texture_parameter", GetTextureParameter },
        { "get_texture_level_parameter", GetTextureLevelParameter },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_texture(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }


