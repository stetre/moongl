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

GLenum enumCheck(lua_State *L, int arg, enum_t *e)
    { return e->codes[checkoption(L, arg, NULL, e->strings)]; }

int enumPush(lua_State *L, GLenum code, enum_t *e)
    {
    size_t i;
    for(i = 0; i < e->n; i++) 
        { if(e->codes[i]==code) 
            { 
            lua_pushstring(L, e->strings[i]); 
            return 1; 
            } 
        }
    //return luaL_error(L, "invalid enum value %d", code);
    lua_pushfstring(L, "%d???", code); 
    return 1;
    }

const char* enumToString(GLenum code, enum_t *e)
    {
    size_t i;
    for(i = 0; i < e->n; i++) 
        if(e->codes[i]==code) return e->strings[i];
    return NULL;
    }

int enumAssert(lua_State *L, enum_t *e, GLenum code, const char *string)
    {
    const char *s = enumToString(code, e);
    if( (s==NULL) || (strcmp(s, string) !=0))
        return unexpected(L);       
    return 0;
    }

GLuint enumOrUint(lua_State *L, int arg, GLenum *dst, enum_t *e, GLuint def)
/* The element at the index arg on the Lua stack may be an enum (string),
 * or an integer. In the first case the enum code is stored in 'code' and
 * 'def' is returned. In the second case the integer value is returned.
 */
    {
    if(lua_isstring(L, arg))
        {
        *dst = enumCheck(L, arg, e);
        return def;
        }
    return (GLuint)luaL_checkinteger(L, arg);
    }

/*--------------------------------------------------------------------------*
 | Common enums                                                             |
 *--------------------------------------------------------------------------*/

ENUM_STRINGS(TypeStrings) = {
    "none", 
    "ubyte", 
    "byte", 
    "ushort", 
    "short", 
    "uint", 
    "int", 
    "fixed", 
    "half float", 
    "float", 
    "double", 
    "ubyte 3 3 2", 
    "ubyte 2 3 3 rev", 
    "ushort 5 6 5", 
    "ushort 5 6 5 rev", 
    "ushort 4 4 4 4", 
    "ushort 4 4 4 4 rev", 
    "ushort 5 5 5 1", 
    "ushort 1 5 5 5 rev", 
    "uint 8 8 8 8", 
    "uint 8 8 8 8 rev", 
    "uint 10 10 10 2", 
    "uint 2 10 10 10 rev",
    "uint 24 8",
    "uint 10f 11f 11f rev",
    "uint 5 9 9 9 rev",
    "float 32 uint 24 8 rev", 
    "int 2 10 10 10 rev",
    NULL
};
ENUM_CODES(TypeCodes) = {
    GL_NONE, 
    GL_UNSIGNED_BYTE, 
    GL_BYTE, 
    GL_UNSIGNED_SHORT, 
    GL_SHORT, 
    GL_UNSIGNED_INT, 
    GL_INT, 
    GL_FIXED, 
    GL_HALF_FLOAT, 
    GL_FLOAT, 
    GL_DOUBLE,
    GL_UNSIGNED_BYTE_3_3_2, 
    GL_UNSIGNED_BYTE_2_3_3_REV, 
    GL_UNSIGNED_SHORT_5_6_5, 
    GL_UNSIGNED_SHORT_5_6_5_REV, 
    GL_UNSIGNED_SHORT_4_4_4_4, 
    GL_UNSIGNED_SHORT_4_4_4_4_REV, 
    GL_UNSIGNED_SHORT_5_5_5_1, 
    GL_UNSIGNED_SHORT_1_5_5_5_REV, 
    GL_UNSIGNED_INT_8_8_8_8, 
    GL_UNSIGNED_INT_8_8_8_8_REV, 
    GL_UNSIGNED_INT_10_10_10_2, 
    GL_UNSIGNED_INT_2_10_10_10_REV,
    GL_UNSIGNED_INT_24_8,
    GL_UNSIGNED_INT_10F_11F_11F_REV,
    GL_UNSIGNED_INT_5_9_9_9_REV,
    GL_FLOAT_32_UNSIGNED_INT_24_8_REV, 
    GL_INT_2_10_10_10_REV,
};
ENUM_T(TypeEnum, TypeStrings, TypeCodes)
#define CheckType(L, arg) enumCheck((L), (arg), &TypeEnum)
#define PushType(L, code) enumPush((L), (code), &TypeEnum)

int checktype(lua_State *L, int arg)
    { return CheckType(L, arg); }

enum_t *enumType(void)
    { return &TypeEnum; }

size_t sizeoftype(lua_State *L, int type)
    {
    switch(type)
        {
        case GL_NONE: return 0;
        case GL_UNSIGNED_BYTE: return sizeof(GLbyte);
        case GL_BYTE:  return sizeof(GLubyte);
        case GL_UNSIGNED_SHORT:  return sizeof(GLushort);
        case GL_SHORT:  return sizeof(GLshort);
        case GL_UNSIGNED_INT: return sizeof(GLuint);
        case GL_INT:  return sizeof(GLint);
        case GL_FIXED: return sizeof(GLfixed);
        case GL_HALF_FLOAT:  return sizeof(GLhalf);
        case GL_FLOAT:  return sizeof(GLfloat);
        case GL_DOUBLE: return sizeof(GLdouble);
        case GL_UNSIGNED_BYTE_3_3_2:
        case GL_UNSIGNED_BYTE_2_3_3_REV:  return sizeof(GLubyte);
        case GL_UNSIGNED_SHORT_5_6_5:
        case GL_UNSIGNED_SHORT_5_6_5_REV:
        case GL_UNSIGNED_SHORT_4_4_4_4:
        case GL_UNSIGNED_SHORT_4_4_4_4_REV:
        case GL_UNSIGNED_SHORT_5_5_5_1:
        case GL_UNSIGNED_SHORT_1_5_5_5_REV: return sizeof(GLshort);
        case GL_UNSIGNED_INT_8_8_8_8: 
        case GL_UNSIGNED_INT_8_8_8_8_REV: 
        case GL_UNSIGNED_INT_10_10_10_2: 
        case GL_UNSIGNED_INT_2_10_10_10_REV:
        case GL_UNSIGNED_INT_24_8:
        case GL_UNSIGNED_INT_10F_11F_11F_REV:
        case GL_UNSIGNED_INT_5_9_9_9_REV: return sizeof(GLuint);
        case GL_FLOAT_32_UNSIGNED_INT_24_8_REV: return 8; /* 2*32 bit, see 8.4.4.2 */
        case GL_INT_2_10_10_10_REV: return sizeof(GLint);
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }


ENUM_STRINGS(GlslTypeStrings) = {
    "float",
    "vec2",
    "vec3",
    "vec4",
    "double",
    "dvec2",
    "dvec3",
    "dvec4",
    "int",
    "ivec2",
    "ivec3",
    "ivec4",
    "uint",
    "uvec2",
    "uvec3",
    "uvec4",
    "bool",
    "bvec2",
    "bvec3",
    "bvec4",
    "mat2",
    "mat3",
    "mat4",
    "mat2x3",
    "mat2x4",
    "mat3x2",
    "mat3x4",
    "mat4x2",
    "mat4x3",
    "dmat2",
    "dmat3",
    "dmat4",
    "dmat2x3",
    "dmat2x4",
    "dmat3x2",
    "dmat3x4",
    "dmat4x2",
    "dmat4x3",
    "sampler1D",
    "sampler2D",
    "sampler3D",
    "samplerCube",
    "sampler1DShadow",
    "sampler2DShadow",
    "sampler1DArray",
    "sampler2DArray",
    "sampler1DArrayShadow",
    "sampler2DArrayShadow",
    "sampler2DMS",
    "sampler2DMSArray",
    "samplerCubeShadow",
    "samplerBuffer",
    "sampler2DRect",
    "sampler2DRectShadow",
    "isampler1D",
    "isampler2D",
    "isampler3D",
    "isamplerCube",
    "isampler1DArray",
    "isampler2DArray",
    "isampler2DMS",
    "isampler2DMSArray",
    "isamplerBuffer",
    "isampler2DRect",
    "usampler1D",
    "usampler2D",
    "usampler3D",
    "usamplerCube",
    "usampler2DArray",
    "usampler2DArray",
    "usampler2DMS",
    "usampler2DMSArray",
    "usamplerBuffer",
    "usampler2DRect",
    "image1D",
    "image2D",
    "image3D",
    "image2DRect",
    "imageCube",
    "imageBuffer",
    "image1DArray",
    "image2DArray",
    "image2DMS",
    "image2DMSArray",
    "iimage1D",
    "iimage2D",
    "iimage3D",
    "iimage2DRect",
    "iimageCube",
    "iimageBuffer",
    "iimage1DArray",
    "iimage2DArray",
    "iimage2DMS",
    "iimage2DMSArray",
    "uimage1D",
    "uimage2D",
    "uimage3D",
    "uimage2DRect",
    "uimageCube",
    "uimageBuffer",
    "uimage1DArray",
    "uimage2DArray",
    "uimage2DMS",
    "uimage2DMSArray",
    "atomic_uint",
    NULL
};
ENUM_CODES(GlslTypeCodes) = {
    GL_FLOAT,
    GL_FLOAT_VEC2,
    GL_FLOAT_VEC3,
    GL_FLOAT_VEC4,
    GL_DOUBLE,
    GL_DOUBLE_VEC2,
    GL_DOUBLE_VEC3,
    GL_DOUBLE_VEC4,
    GL_INT,
    GL_INT_VEC2,
    GL_INT_VEC3,
    GL_INT_VEC4,
    GL_UNSIGNED_INT,
    GL_UNSIGNED_INT_VEC2,
    GL_UNSIGNED_INT_VEC3,
    GL_UNSIGNED_INT_VEC4,
    GL_BOOL,
    GL_BOOL_VEC2,
    GL_BOOL_VEC3,
    GL_BOOL_VEC4,
    GL_FLOAT_MAT2,
    GL_FLOAT_MAT3,
    GL_FLOAT_MAT4,
    GL_FLOAT_MAT2x3,
    GL_FLOAT_MAT2x4,
    GL_FLOAT_MAT3x2,
    GL_FLOAT_MAT3x4,
    GL_FLOAT_MAT4x2,
    GL_FLOAT_MAT4x3,
    GL_DOUBLE_MAT2,
    GL_DOUBLE_MAT3,
    GL_DOUBLE_MAT4,
    GL_DOUBLE_MAT2x3,
    GL_DOUBLE_MAT2x4,
    GL_DOUBLE_MAT3x2,
    GL_DOUBLE_MAT3x4,
    GL_DOUBLE_MAT4x2,
    GL_DOUBLE_MAT4x3,
    GL_SAMPLER_1D,
    GL_SAMPLER_2D,
    GL_SAMPLER_3D,
    GL_SAMPLER_CUBE,
    GL_SAMPLER_1D_SHADOW,
    GL_SAMPLER_2D_SHADOW,
    GL_SAMPLER_1D_ARRAY,
    GL_SAMPLER_2D_ARRAY,
    GL_SAMPLER_1D_ARRAY_SHADOW,
    GL_SAMPLER_2D_ARRAY_SHADOW,
    GL_SAMPLER_2D_MULTISAMPLE,
    GL_SAMPLER_2D_MULTISAMPLE_ARRAY,
    GL_SAMPLER_CUBE_SHADOW,
    GL_SAMPLER_BUFFER,
    GL_SAMPLER_2D_RECT,
    GL_SAMPLER_2D_RECT_SHADOW,
    GL_INT_SAMPLER_1D,
    GL_INT_SAMPLER_2D,
    GL_INT_SAMPLER_3D,
    GL_INT_SAMPLER_CUBE,
    GL_INT_SAMPLER_1D_ARRAY,
    GL_INT_SAMPLER_2D_ARRAY,
    GL_INT_SAMPLER_2D_MULTISAMPLE,
    GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
    GL_INT_SAMPLER_BUFFER,
    GL_INT_SAMPLER_2D_RECT,
    GL_UNSIGNED_INT_SAMPLER_1D,
    GL_UNSIGNED_INT_SAMPLER_2D,
    GL_UNSIGNED_INT_SAMPLER_3D,
    GL_UNSIGNED_INT_SAMPLER_CUBE,
    GL_UNSIGNED_INT_SAMPLER_1D_ARRAY,
    GL_UNSIGNED_INT_SAMPLER_2D_ARRAY,
    GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE,
    GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
    GL_UNSIGNED_INT_SAMPLER_BUFFER,
    GL_UNSIGNED_INT_SAMPLER_2D_RECT,
    GL_IMAGE_1D,
    GL_IMAGE_2D,
    GL_IMAGE_3D,
    GL_IMAGE_2D_RECT,
    GL_IMAGE_CUBE,
    GL_IMAGE_BUFFER,
    GL_IMAGE_1D_ARRAY,
    GL_IMAGE_2D_ARRAY,
    GL_IMAGE_2D_MULTISAMPLE,
    GL_IMAGE_2D_MULTISAMPLE_ARRAY,
    GL_INT_IMAGE_1D,
    GL_INT_IMAGE_2D,
    GL_INT_IMAGE_3D,
    GL_INT_IMAGE_2D_RECT,
    GL_INT_IMAGE_CUBE,
    GL_INT_IMAGE_BUFFER,
    GL_INT_IMAGE_1D_ARRAY,
    GL_INT_IMAGE_2D_ARRAY,
    GL_INT_IMAGE_2D_MULTISAMPLE,
    GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY,
    GL_UNSIGNED_INT_IMAGE_1D,
    GL_UNSIGNED_INT_IMAGE_2D,
    GL_UNSIGNED_INT_IMAGE_3D,
    GL_UNSIGNED_INT_IMAGE_2D_RECT,
    GL_UNSIGNED_INT_IMAGE_CUBE,
    GL_UNSIGNED_INT_IMAGE_BUFFER,
    GL_UNSIGNED_INT_IMAGE_1D_ARRAY,
    GL_UNSIGNED_INT_IMAGE_2D_ARRAY,
    GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE,
    GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY,
    GL_UNSIGNED_INT_ATOMIC_COUNTER,
};

ENUM_T(GlslTypeEnum, GlslTypeStrings, GlslTypeCodes)
#define CheckGlslType(L, arg) enumCheck((L), (arg), &GlslTypeEnum)
#define PushGlslType(L, code) enumPush((L), (code), &GlslTypeEnum)

GLenum checkglsltype(lua_State *L, int arg)
    { return CheckGlslType(L, arg); }

int pushglsltype(lua_State *L, GLenum code)
    { return PushGlslType(L, code); }


ENUM_STRINGS(InternalFormatStrings) = {
    "none",
    /* base int. formats */
    "stencil index", 
    "depth component", 
    "depth stencil",
    "red",
    "rg", 
    "rgb", 
    "rgba", 
    /* sized int. formats */
    "r8",
    "r8 snorm",
    "r16",
    "r16 snorm",
    "rg8",
    "rg8 snorm",
    "rg16",
    "rg16 snorm",
    "r3 g3 b2",
    "rgb4",
    "rgb5",
    "rgb8",
    "rgb8 snorm",
    "rgb10",
    "rgb12",
    "rgb16 snorm",
    "rgba2",
    "rgba4",
    "rgb5 a1",
    "rgba8",
    "rgba8 snorm",
    "rgb10 a2",
    "rgb10 a2ui",
    "rgba12",
    "rgba16",
    "srgb",
    "srgb8",
    "srgb8 alpha8",
    "r16f",
    "rg16f",
    "rgb16f",
    "rgba16f",
    "r32f",
    "rg32f",
    "rgb32f",
    "rgba32f",
    "r11f g11f b10f",
    "rgb9 e5",
    "r8i",
    "r8ui",
    "r16i",
    "r16ui",
    "r32i",
    "r32ui",
    "rg8i",
    "rg8ui",
    "rg16i",
    "rg16ui",
    "rg32i",
    "rg32ui",
    "rgb8i",
    "rgb8ui",
    "rgb16i",
    "rgb16ui",
    "rgb32i",
    "rgb32ui",
    "rgba8i",
    "rgba8ui",
    "rgba16i",
    "rgba16ui",
    "rgba32i",
    "rgba32ui",
    /* sized depth and stencil int. formats */
    "depth component16",
    "depth component24",
    "depth component32",
    "depth component32f",
    "depth24 stencil8",
    "depth32f stencil8",
    "stencil index8",
    /* compressed */
    "compressed red",
    "compressed rg",
    "compressed rgb",
    "compressed rgba",
    "compressed srgb",
    "compressed srgb alpha",
    "compressed red rgtc1",
    "compressed signed red rgtc1",
    "compressed rg rgtc2",
    "compressed signed rg rgtc2",
    "compressed rgba bptc unorm",
    "compressed srgb alpha bptc unorm",
    "compressed rgb bptc signed float",
    "compressed rgb bptc unsigned float",
    /* S3TC compressed */
    "compressed rgb s3tc dxt1 ext",
    "compressed srgb s3tc dxt1 ext",
    "compressed rgba s3tc dxt1 ext",
    "compressed srgb alpha s3tc dxt1 ext",
    "compressed rgba s3tc dxt3 ext",
    "compressed srgb alpha s3tc dxt3 ext",
    "compressed rgba s3tc dxt5 ext",
    "compressed srgb alpha s3tc dxt5 ext",
#if 0
    "compressed rgb8 etc2",
    "compressed srgb8 etc2",
    "compressed rgb8 punchthrough alpha1 etc2",
    "compressed srgb8 punchthrough alpha1 etc2",
    "compressed rgba8 etc2 eac",
    "compressed srgb8 alpha8 etc2 eac",
    "compressed r11 eac",
    "compressed signed r11 eac",
    "compressed rg11 eac",
    "compressed signed rg11 eac",
    "compressed rgba bptc unorm arb",
    "compressed srgb alpha bptc unorm arb",
    "compressed rgb bptc signed float arb",
    "compressed rgb bptc unsigned float arb",
    "compressed rgba astc 4x4 khr",
    "compressed rgba astc 5x4 khr",
    "compressed rgba astc 5x5 khr",
    "compressed rgba astc 6x5 khr",
    "compressed rgba astc 6x6 khr",
    "compressed rgba astc 8x5 khr",
    "compressed rgba astc 8x6 khr",
    "compressed rgba astc 8x8 khr",
    "compressed rgba astc 10x5 khr",
    "compressed rgba astc 10x6 khr",
    "compressed rgba astc 10x8 khr",
    "compressed rgba astc 10x10 khr",
    "compressed rgba astc 12x10 khr",
    "compressed rgba astc 12x12 khr",
    "compressed srgb8 alpha8 astc 4x4 khr",
    "compressed srgb8 alpha8 astc 5x4 khr",
    "compressed srgb8 alpha8 astc 5x5 khr",
    "compressed srgb8 alpha8 astc 6x5 khr",
    "compressed srgb8 alpha8 astc 6x6 khr",
    "compressed srgb8 alpha8 astc 8x5 khr",
    "compressed srgb8 alpha8 astc 8x6 khr",
    "compressed srgb8 alpha8 astc 8x8 khr",
    "compressed srgb8 alpha8 astc 10x5 khr",
    "compressed srgb8 alpha8 astc 10x6 khr",
    "compressed srgb8 alpha8 astc 10x8 khr",
    "compressed srgb8 alpha8 astc 10x10 khr",
    "compressed srgb8 alpha8 astc 12x10 khr",
    "compressed srgb8 alpha8 astc 12x12 khr",
#endif
    NULL
};
ENUM_CODES(InternalFormatCodes) = {
    GL_NONE, 
    /* base int. formats */
    GL_STENCIL_INDEX, 
    GL_DEPTH_COMPONENT, 
    GL_DEPTH_STENCIL,
    GL_RED,
    GL_RG, 
    GL_RGB, 
    GL_RGBA, 
    /* sized int. formats */
    GL_R8,
    GL_R8_SNORM,
    GL_R16,
    GL_R16_SNORM,
    GL_RG8,
    GL_RG8_SNORM,
    GL_RG16,
    GL_RG16_SNORM,
    GL_R3_G3_B2,
    GL_RGB4,
    GL_RGB5,
    GL_RGB8,
    GL_RGB8_SNORM,
    GL_RGB10,
    GL_RGB12,
    GL_RGB16_SNORM,
    GL_RGBA2,
    GL_RGBA4,
    GL_RGB5_A1,
    GL_RGBA8,
    GL_RGBA8_SNORM,
    GL_RGB10_A2,
    GL_RGB10_A2UI,
    GL_RGBA12,
    GL_RGBA16,
    GL_SRGB,
    GL_SRGB8,
    GL_SRGB8_ALPHA8,
    GL_R16F,
    GL_RG16F,
    GL_RGB16F,
    GL_RGBA16F,
    GL_R32F,
    GL_RG32F,
    GL_RGB32F,
    GL_RGBA32F,
    GL_R11F_G11F_B10F,
    GL_RGB9_E5,
    GL_R8I,
    GL_R8UI,
    GL_R16I,
    GL_R16UI,
    GL_R32I,
    GL_R32UI,
    GL_RG8I,
    GL_RG8UI,
    GL_RG16I,
    GL_RG16UI,
    GL_RG32I,
    GL_RG32UI,
    GL_RGB8I,
    GL_RGB8UI,
    GL_RGB16I,
    GL_RGB16UI,
    GL_RGB32I,
    GL_RGB32UI,
    GL_RGBA8I,
    GL_RGBA8UI,
    GL_RGBA16I,
    GL_RGBA16UI,
    GL_RGBA32I,
    GL_RGBA32UI,
    /* sized depth and stencil int. formats */
    GL_DEPTH_COMPONENT16,
    GL_DEPTH_COMPONENT24,
    GL_DEPTH_COMPONENT32,
    GL_DEPTH_COMPONENT32F,
    GL_DEPTH24_STENCIL8,
    GL_DEPTH32F_STENCIL8,
    GL_STENCIL_INDEX8,
    /* compressed */
    GL_COMPRESSED_RED,
    GL_COMPRESSED_RG,
    GL_COMPRESSED_RGB,
    GL_COMPRESSED_RGBA,
    GL_COMPRESSED_SRGB,
    GL_COMPRESSED_SRGB_ALPHA,
    GL_COMPRESSED_RED_RGTC1,
    GL_COMPRESSED_SIGNED_RED_RGTC1,
    GL_COMPRESSED_RG_RGTC2,
    GL_COMPRESSED_SIGNED_RG_RGTC2,
    GL_COMPRESSED_RGBA_BPTC_UNORM,
    GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM,
    GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT,
    GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT,
    /* S3TC compressed */
    GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
    GL_COMPRESSED_SRGB_S3TC_DXT1_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,
    GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,
    GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT,
    GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,
    GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT,
#if 0
    GL_COMPRESSED_RGB8_ETC2,
    GL_COMPRESSED_SRGB8_ETC2,
    GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2,
    GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2,
    GL_COMPRESSED_RGBA8_ETC2_EAC,
    GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC,
    GL_COMPRESSED_R11_EAC,
    GL_COMPRESSED_SIGNED_R11_EAC,
    GL_COMPRESSED_RG11_EAC,
    GL_COMPRESSED_SIGNED_RG11_EAC,
    GL_COMPRESSED_RGBA_BPTC_UNORM_ARB,
    GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB,
    GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB,
    GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB,
    GL_COMPRESSED_RGBA_ASTC_4x4_KHR,
    GL_COMPRESSED_RGBA_ASTC_5x4_KHR,
    GL_COMPRESSED_RGBA_ASTC_5x5_KHR,
    GL_COMPRESSED_RGBA_ASTC_6x5_KHR,
    GL_COMPRESSED_RGBA_ASTC_6x6_KHR,
    GL_COMPRESSED_RGBA_ASTC_8x5_KHR,
    GL_COMPRESSED_RGBA_ASTC_8x6_KHR,
    GL_COMPRESSED_RGBA_ASTC_8x8_KHR,
    GL_COMPRESSED_RGBA_ASTC_10x5_KHR,
    GL_COMPRESSED_RGBA_ASTC_10x6_KHR,
    GL_COMPRESSED_RGBA_ASTC_10x8_KHR,
    GL_COMPRESSED_RGBA_ASTC_10x10_KHR,
    GL_COMPRESSED_RGBA_ASTC_12x10_KHR,
    GL_COMPRESSED_RGBA_ASTC_12x12_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR,
    GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR,
#endif
};
ENUM_T(InternalFormatEnum, InternalFormatStrings, InternalFormatCodes)
#define CheckInternalFormat(L, arg) enumCheck((L), (arg), &InternalFormatEnum)
#define PushInternalFormat(L, code) enumPush((L), (code), &InternalFormatEnum)

GLenum checkinternalformat(lua_State *L, int arg)
    { return CheckInternalFormat(L, arg); }

enum_t *enumInternalFormat(void)
    { return &InternalFormatEnum; }

ENUM_STRINGS(FormatStrings) = {
    "none", 
    "stencil index", 
    "depth component", 
    "depth stencil",
    "red",
    "green",
    "blue",
    "rg", 
    "rgb", 
    "rgba", 
    "bgr", 
    "bgra", 
    "red integer", 
    "green integer", 
    "blue integer", 
    "rg integer", 
    "rgb integer", 
    "rgba integer", 
    "bgr integer", 
    "bgra integer", 
    NULL
};
ENUM_CODES(FormatCodes) = {
    GL_NONE,
    GL_STENCIL_INDEX, 
    GL_DEPTH_COMPONENT, 
    GL_DEPTH_STENCIL,
    GL_RED,
    GL_GREEN,
    GL_BLUE,
    GL_RG, 
    GL_RGB, 
    GL_RGBA, 
    GL_BGR, 
    GL_BGRA, 
    GL_RED_INTEGER, 
    GL_GREEN_INTEGER, 
    GL_BLUE_INTEGER, 
    GL_RG_INTEGER, 
    GL_RGB_INTEGER, 
    GL_RGBA_INTEGER, 
    GL_BGR_INTEGER, 
    GL_BGRA_INTEGER, 
};
ENUM_T(FormatEnum, FormatStrings, FormatCodes)
#define CheckFormat(L, arg) enumCheck((L), (arg), &FormatEnum)
#define PushFormat(L, code) enumPush((L), (code), &FormatEnum)

GLenum checkformat(lua_State *L, int arg)
    { return CheckFormat(L, arg); }

enum_t *enumFormat(void)
    { return &FormatEnum; }

