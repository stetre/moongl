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

#define TargetEnum enumTextureTarget()
#define CheckTarget(L, arg) enumCheck((L), (arg), TargetEnum)
#define PushTarget(L, code) enumPush((L), (code), TargetEnum)


ENUM_STRINGS(PnameStrings) = {
    "clear buffer", 
    "clear texture",
    "color encoding",
    "color components",
    "color renderable", 
    "compute texture", 
    "depth components",
    "depth renderable",
    "filter",
    "framebuffer blend",
    "framebuffer renderable",
    "framebuffer renderable layered",
    "fragment texture", 
    "geometry texture", 
    "get texture image format",
    "get texture image type",
    "image compatibility class",
    "image pixel format",
    "image pixel type",
    "image format compatibility type",
    "image texel size",
    "internalformat preferred",
    "internalformat supported",
    "internalformat red size",
    "internalformat green size",
    "internalformat alpha size", 
    "internalformat depth size", 
    "internalformat stencil size", 
    "internalformat blue size", 
    "internalformat shared size",
    "internalformat red type",
    "internalformat green type", 
    "internalformat blue type", 
    "internalformat alpha type", 
    "internalformat depth type", 
    "internalformat stencil type",
    "manual generate mipmap",
    "generate mipmap",
    "auto generate mipmap",
    "mipmap",
    "max combined dimensions",
    "max width",
    "max height",
    "max depth", 
    "max layers",
    "num sample counts", 
    "read pixels",
    "read pixels format",
    "read pixels type",
    "samples", 
    "shader image atomic",
    "shader image load", 
    "shader image store",
    "simultaneous texture and depth test",
    "simultaneous texture and depth write",
    "simultaneous texture and stencil test",
    "simultaneous texture and stencil write",
    "srgb read", 
    "srgb write",
    "stencil components",
    "stencil renderable",
    "tess control texture",
    "tess evaluation texture",
    "texture compressed",
    "texture compressed block size",
    "texture compressed block width", 
    "texture compressed block height",
    "texture gather",
    "texture gather shadow",
    "texture image format",
    "texture image type",
    "texture shadow", 
    "texture view", 
    "vertex texture", 
    "view compatibility class",
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_CLEAR_BUFFER, 
    GL_CLEAR_TEXTURE,
    GL_COLOR_ENCODING,
    GL_COLOR_COMPONENTS,
    GL_COLOR_RENDERABLE, 
    GL_COMPUTE_TEXTURE, 
    GL_DEPTH_COMPONENTS,
    GL_DEPTH_RENDERABLE,
    GL_FILTER,
    GL_FRAMEBUFFER_BLEND,
    GL_FRAMEBUFFER_RENDERABLE,
    GL_FRAMEBUFFER_RENDERABLE_LAYERED,
    GL_FRAGMENT_TEXTURE, 
    GL_GEOMETRY_TEXTURE, 
    GL_GET_TEXTURE_IMAGE_FORMAT,
    GL_GET_TEXTURE_IMAGE_TYPE,
    GL_IMAGE_COMPATIBILITY_CLASS,
    GL_IMAGE_PIXEL_FORMAT,
    GL_IMAGE_PIXEL_TYPE,
    GL_IMAGE_FORMAT_COMPATIBILITY_TYPE,
    GL_IMAGE_TEXEL_SIZE,
    GL_INTERNALFORMAT_PREFERRED,
    GL_INTERNALFORMAT_SUPPORTED,
    GL_INTERNALFORMAT_RED_SIZE,
    GL_INTERNALFORMAT_GREEN_SIZE,
    GL_INTERNALFORMAT_ALPHA_SIZE, 
    GL_INTERNALFORMAT_DEPTH_SIZE, 
    GL_INTERNALFORMAT_STENCIL_SIZE, 
    GL_INTERNALFORMAT_BLUE_SIZE, 
    GL_INTERNALFORMAT_SHARED_SIZE,
    GL_INTERNALFORMAT_RED_TYPE,
    GL_INTERNALFORMAT_GREEN_TYPE, 
    GL_INTERNALFORMAT_BLUE_TYPE, 
    GL_INTERNALFORMAT_ALPHA_TYPE, 
    GL_INTERNALFORMAT_DEPTH_TYPE, 
    GL_INTERNALFORMAT_STENCIL_TYPE,
    GL_MANUAL_GENERATE_MIPMAP,
    GL_GENERATE_MIPMAP,
    GL_AUTO_GENERATE_MIPMAP,
    GL_MIPMAP,
    GL_MAX_COMBINED_DIMENSIONS,
    GL_MAX_WIDTH,
    GL_MAX_HEIGHT,
    GL_MAX_DEPTH, 
    GL_MAX_LAYERS,
    GL_NUM_SAMPLE_COUNTS, 
    GL_READ_PIXELS,
    GL_READ_PIXELS_FORMAT,
    GL_READ_PIXELS_TYPE,
    GL_SAMPLES, 
    GL_SHADER_IMAGE_ATOMIC,
    GL_SHADER_IMAGE_LOAD, 
    GL_SHADER_IMAGE_STORE,
    GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST,
    GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE,
    GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST,
    GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE,
    GL_SRGB_READ, 
    GL_SRGB_WRITE,
    GL_STENCIL_COMPONENTS,
    GL_STENCIL_RENDERABLE,
    GL_TESS_CONTROL_TEXTURE,
    GL_TESS_EVALUATION_TEXTURE,
    GL_TEXTURE_COMPRESSED,
    GL_TEXTURE_COMPRESSED_BLOCK_SIZE,
    GL_TEXTURE_COMPRESSED_BLOCK_WIDTH, 
    GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT,
    GL_TEXTURE_GATHER,
    GL_TEXTURE_GATHER_SHADOW,
    GL_TEXTURE_IMAGE_FORMAT,
    GL_TEXTURE_IMAGE_TYPE,
    GL_TEXTURE_SHADOW, 
    GL_TEXTURE_VIEW, 
    GL_VERTEX_TEXTURE, 
    GL_VIEW_COMPATIBILITY_CLASS,
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)

ENUM_STRINGS(SupportedOpStrings) = {
    "none",
    "caveat",
    "full",
    NULL
};
ENUM_CODES(SupportedOpCodes) = {
    GL_NONE,
    GL_CAVEAT_SUPPORT,
    GL_FULL_SUPPORT,
};
ENUM_T(SupportedOpEnum, SupportedOpStrings, SupportedOpCodes)
#define CheckSupportedOp(L, arg) enumCheck((L), (arg), &SupportedOpEnum)
#define PushSupportedOp(L, code) enumPush((L), (code), &SupportedOpEnum)


ENUM_STRINGS(ImageCompatibilityClassStrings) = {
    "none",
    "4 x 32",
    "2 x 32",
    "1 x 32",
    "4 x 16",
    "2 x 16",
    "1 x 16",
    "4 x 8",
    "2 x 8",
    "1 x 8",
    "11 11 10",
    "10 10 10 2",
    NULL
};
ENUM_CODES(ImageCompatibilityClassCodes) = {
    GL_NONE,
    GL_IMAGE_CLASS_4_X_32,
    GL_IMAGE_CLASS_2_X_32,
    GL_IMAGE_CLASS_1_X_32,
    GL_IMAGE_CLASS_4_X_16,
    GL_IMAGE_CLASS_2_X_16,
    GL_IMAGE_CLASS_1_X_16,
    GL_IMAGE_CLASS_4_X_8,
    GL_IMAGE_CLASS_2_X_8,
    GL_IMAGE_CLASS_1_X_8,
    GL_IMAGE_CLASS_11_11_10,
    GL_IMAGE_CLASS_10_10_10_2,
};
ENUM_T(ImageCompatibilityClassEnum, ImageCompatibilityClassStrings, ImageCompatibilityClassCodes)
#define CheckImageCompatibilityClass(L, arg) enumCheck((L), (arg), &ImageCompatibilityClassEnum)
#define PushImageCompatibilityClass(L, code) enumPush((L), (code), &ImageCompatibilityClassEnum)

ENUM_STRINGS(ImageFormatCompTypeStrings) = {
    "none",
    "by size",
    "by class",
    NULL
};
ENUM_CODES(ImageFormatCompTypeCodes) = {
    GL_NONE,
    GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE,
    GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS,
};
ENUM_T(ImageFormatCompTypeEnum, ImageFormatCompTypeStrings, ImageFormatCompTypeCodes)
#define CheckImageFormatCompType(L, arg) enumCheck((L), (arg), &ImageFormatCompTypeEnum)
#define PushImageFormatCompType(L, code) enumPush((L), (code), &ImageFormatCompTypeEnum)


ENUM_STRINGS(ViewCompatibilityTypeStrings) = {
    "128 bits",
    "96 bits",
    "64 bits",
    "48 bits",
    "32 bits",
    "24 bits",
    "16 bits",
    "8 bits",
    "s3tc dxt1 rgb",
    "s3tc dxt1 rgba",
    "s3tc dxt3 rgba",
    "s3tc dxt5 rgba",
    "rgtc1 red",
    "rgtc2 rg",
    "bptc unorm",
    "bptc float",
    NULL
};
ENUM_CODES(ViewCompatibilityTypeCodes) = {
    GL_VIEW_CLASS_128_BITS,
    GL_VIEW_CLASS_96_BITS,
    GL_VIEW_CLASS_64_BITS,
    GL_VIEW_CLASS_48_BITS,
    GL_VIEW_CLASS_32_BITS,
    GL_VIEW_CLASS_24_BITS,
    GL_VIEW_CLASS_16_BITS,
    GL_VIEW_CLASS_8_BITS,
    GL_VIEW_CLASS_S3TC_DXT1_RGB,
    GL_VIEW_CLASS_S3TC_DXT1_RGBA,
    GL_VIEW_CLASS_S3TC_DXT3_RGBA,
    GL_VIEW_CLASS_S3TC_DXT5_RGBA,
    GL_VIEW_CLASS_RGTC1_RED,
    GL_VIEW_CLASS_RGTC2_RG,
    GL_VIEW_CLASS_BPTC_UNORM,
    GL_VIEW_CLASS_BPTC_FLOAT,
};
ENUM_T(ViewCompatibilityTypeEnum, ViewCompatibilityTypeStrings, ViewCompatibilityTypeCodes)
#define CheckViewCompatibilityType(L, arg) enumCheck((L), (arg), &ViewCompatibilityTypeEnum)
#define PushViewCompatibilityType(L, code) enumPush((L), (code), &ViewCompatibilityTypeEnum)


static GLsizei GetNum(lua_State *L, GLenum target, GLenum internalformat, GLenum pname)
    {
    GLint param;
    glGetInternalformativ(target, internalformat, pname, sizeof(param), &param);
    CheckError(L);
    return param;
    }

static int GetInt_(lua_State *L, GLenum target, GLenum internalformat, GLenum pname, int boolean)
#define GetInt(L, target, intfmt, pname) GetInt_((L), (target), (intfmt), (pname), 0)
#define GetBoolean(L, target, intfmt, pname) GetInt_((L), (target), (intfmt), (pname), 1)
    {
    GLint64 param;
    glGetInternalformati64v(target, internalformat, pname, sizeof(param), &param);
    CheckError(L);
    if(boolean)
        lua_pushboolean(L, param);
    else
        lua_pushinteger(L, param);
    return 1;
    }

static int GetN(lua_State *L, GLenum target, GLenum internalformat, GLenum pname, GLenum numpname)
    {
    GLint64 *params;
    GLsizei i, num = GetNum(L, target, internalformat, numpname);
    if(num==0) return 0;
    params = (GLint64*)Malloc(L, num*sizeof(GLint64));
    glGetInternalformati64v(target, internalformat, pname, num*sizeof(GLint64), params);
    CheckErrorFree(L, params);
    for(i = 0; i<num; i++)
        lua_pushinteger(L, params[i]);
    Free(L, params);
    return num;
    }

static int GetEnum(lua_State *L, GLenum target, GLenum internalformat, GLenum pname, enum_t *e)
    {
    GLint param;
    glGetInternalformativ(target, internalformat, pname, sizeof(param), &param);
    CheckError(L);
    return enumPush(L, param, e);
    }


static int GetInternalformat(lua_State *L)
    {
    GLenum target = CheckTarget(L, 1);
    GLenum internalformat = checkinternalformat(L, 2);
    GLenum pname = CheckPname(L, 3);
    switch(pname)
        {
        /* supported operations queries: */
        case GL_CLEAR_BUFFER:
        case GL_CLEAR_TEXTURE:
        case GL_COMPUTE_TEXTURE:
        case GL_FILTER:
        case GL_FRAGMENT_TEXTURE:
        case GL_FRAMEBUFFER_BLEND:
        case GL_FRAMEBUFFER_RENDERABLE:
        case GL_FRAMEBUFFER_RENDERABLE_LAYERED:
        case GL_GEOMETRY_TEXTURE:
        case GL_MANUAL_GENERATE_MIPMAP:
        case GL_GENERATE_MIPMAP:
        case GL_AUTO_GENERATE_MIPMAP:
        case GL_READ_PIXELS:
        case GL_SHADER_IMAGE_ATOMIC:
        case GL_SHADER_IMAGE_LOAD:
        case GL_SHADER_IMAGE_STORE:
        case GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST:
        case GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE:
        case GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST:
        case GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE:
        case GL_SRGB_READ:
        case GL_SRGB_WRITE:
        case GL_TESS_CONTROL_TEXTURE:
        case GL_TESS_EVALUATION_TEXTURE:
        case GL_TEXTURE_GATHER:
        case GL_TEXTURE_GATHER_SHADOW:
        case GL_TEXTURE_SHADOW:
        case GL_TEXTURE_VIEW:
        case GL_VERTEX_TEXTURE:
                    return GetEnum(L, target, internalformat, pname, &SupportedOpEnum);
        /* booleans */
        case GL_COLOR_COMPONENTS:
        case GL_COLOR_RENDERABLE:
        case GL_DEPTH_COMPONENTS:
        case GL_DEPTH_RENDERABLE:
        case GL_INTERNALFORMAT_SUPPORTED:  
        case GL_MIPMAP:
        case GL_STENCIL_COMPONENTS:
        case GL_STENCIL_RENDERABLE:
        case GL_TEXTURE_COMPRESSED:
                        return GetBoolean(L, target, internalformat, pname);
        /* integer */
        case GL_INTERNALFORMAT_RED_SIZE:
        case GL_INTERNALFORMAT_GREEN_SIZE:
        case GL_INTERNALFORMAT_ALPHA_SIZE:
        case GL_INTERNALFORMAT_DEPTH_SIZE:
        case GL_INTERNALFORMAT_STENCIL_SIZE:
        case GL_INTERNALFORMAT_BLUE_SIZE:
        case GL_INTERNALFORMAT_SHARED_SIZE:
        case GL_MAX_COMBINED_DIMENSIONS:
        case GL_MAX_WIDTH:
        case GL_MAX_HEIGHT:
        case GL_MAX_DEPTH:
        case GL_MAX_LAYERS:
        case GL_NUM_SAMPLE_COUNTS:
        case GL_TEXTURE_COMPRESSED_BLOCK_SIZE:
        case GL_TEXTURE_COMPRESSED_BLOCK_WIDTH:
        case GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT:
        case GL_IMAGE_TEXEL_SIZE:
                         return GetInt(L, target, internalformat, pname);
        /* N integers */
        case GL_SAMPLES:
                    return GetN(L, target, internalformat, pname, GL_NUM_SAMPLE_COUNTS);
        /* enums */
        case GL_COLOR_ENCODING:
                    return GetEnum(L, target, internalformat, pname, enumColorEncoding());
        case GL_GET_TEXTURE_IMAGE_FORMAT:
                    return GetEnum(L, target, internalformat, pname, enumFormat());
        case GL_GET_TEXTURE_IMAGE_TYPE:
                    return GetEnum(L, target, internalformat, pname, enumType());
        case GL_IMAGE_COMPATIBILITY_CLASS:
                return GetEnum(L, target, internalformat, pname, &ImageCompatibilityClassEnum);
        case GL_IMAGE_FORMAT_COMPATIBILITY_TYPE:
                return GetEnum(L, target, internalformat, pname, &ImageFormatCompTypeEnum);
        case GL_IMAGE_PIXEL_FORMAT:
                return GetEnum(L, target, internalformat, pname, enumFormat());
        case GL_IMAGE_PIXEL_TYPE:
                    return GetEnum(L, target, internalformat, pname, enumType());
        case GL_VIEW_COMPATIBILITY_CLASS:
                return GetEnum(L, target, internalformat, pname, &ViewCompatibilityTypeEnum);
        case GL_INTERNALFORMAT_PREFERRED:
                    return GetEnum(L, target, internalformat, pname, enumInternalFormat());
        case GL_INTERNALFORMAT_RED_TYPE:
        case GL_INTERNALFORMAT_GREEN_TYPE:
        case GL_INTERNALFORMAT_BLUE_TYPE:
        case GL_INTERNALFORMAT_ALPHA_TYPE:
        case GL_INTERNALFORMAT_DEPTH_TYPE:
        case GL_INTERNALFORMAT_STENCIL_TYPE:
                    return GetEnum(L, target, internalformat, pname, enumComponentType());
        case GL_READ_PIXELS_FORMAT:
                    return GetEnum(L, target, internalformat, pname, enumFormat());
        case GL_READ_PIXELS_TYPE: 
                    return GetEnum(L, target, internalformat, pname, enumType());
        case GL_TEXTURE_IMAGE_FORMAT:
                    return GetEnum(L, target, internalformat, pname, enumFormat());
        case GL_TEXTURE_IMAGE_TYPE:
                    return GetEnum(L, target, internalformat, pname, enumType());

        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "get_internalformat", GetInternalformat },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_getintformat(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }


