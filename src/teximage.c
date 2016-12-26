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

#define border 0 /* obsolete, must be zero */

#define TargetEnum enumTextureTarget()
#define CheckTarget(L, arg) enumCheck((L), (arg), TargetEnum)
#define CheckTargetOrName(L, arg, dst) enumOrUint((L), (arg), (dst), TargetEnum, 0)

ENUM_STRINGS(AccessStrings) = {
    "read only",
    "write only",
    "read write",
    NULL
};
ENUM_CODES(AccessCodes) = {
    GL_READ_ONLY,
    GL_WRITE_ONLY,
    GL_READ_WRITE,
};
ENUM_T(AccessEnum, AccessStrings, AccessCodes)
#define CheckAccess(L, arg) enumCheck((L), (arg), &AccessEnum)
#define PushAccess(L, code) enumPush((L), (code), &AccessEnum)

/*------------------------------------------------------------------------------*
 | Mutable textures                                                             |
 *------------------------------------------------------------------------------*/

static int TextureImage(lua_State *L)
/* texture_image(target, level, intfmt, format, type, data|buffer, width)
 * texture_image(target, level, intfmt, format, type, data|buffer, width, height)
 * texture_image(target, level, intfmt, format, type, data|buffer, width, height, depth)
 */
    {
    intptr_t data;
    GLsizei width, height, depth;
    int arg = 1;
    GLenum target = CheckTarget(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    if(lua_type(L, arg) == LUA_TSTRING)
        {
        data = (intptr_t)luaL_checkstring(L, arg++);
        }
	else if(lua_isnil(L, arg))
		{ data = 0; arg++; }
    else
        {
        /* data may be a buffer name (if a buffer is bound to GL_PIXEL_UNPACK_BUFFER) */
        data = luaL_checkinteger(L, arg++);
        }
    width = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        glTexImage1D(target,level,intfmt,width,border,format,type,(void*)data);
        CheckError(L);
        return 0;
        }
    height = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        glTexImage2D(target,level,intfmt,width,height,border,format,type,(void*)data);
        CheckError(L);
        return 0;
        }
    depth = luaL_checkinteger(L, arg++);
    glTexImage3D(target,level,intfmt,width,height,depth,border,format,type,(void*)data);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Immutable textures                                                           |
 *------------------------------------------------------------------------------*/

static int TextureStorage(lua_State *L)
/* texture_storage(target|texture, levels, intfmt, width)
 * texture_storage(target|texture, levels, intfmt, width, height)
 * texture_storage(target|texture, levels, intfmt, width, height, depth)
 */
    {
    GLsizei height, depth;
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLsizei levels = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glTexStorage1D(target, levels, intfmt, width);
        else
            glTextureStorage1D(texture, levels, intfmt, width);
        CheckError(L);
        return 0;
        }
    height = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glTexStorage2D(target, levels, intfmt, width, height);
        else
            glTextureStorage2D(texture, levels, intfmt, width, height);
        CheckError(L);
        return 0;
        }
    depth = luaL_checkinteger(L, arg++);
    if(texture==0)
        glTexStorage3D(target, levels, intfmt, width, height, depth);
    else
        glTextureStorage3D(texture, levels, intfmt, width, height, depth);
    CheckError(L);
    return 0;
    }

static int TextureSubImage(lua_State *L)
/* texture_sub_image(target|texture, level, format, type, data|buffer, xofs, w)
 * texture_sub_image(target|texture, level, format, type, data|buffer, xofs, yofs, w, h)
 * texture_sub_image(target|texture, level, format, type, data|buffer, xofs, yofs, zofs, w, h, d)
 */
    {
    intptr_t data;
    int arg = 1;
    GLint v1, v2, v3, v4, v5, v6;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    if(lua_type(L, arg) == LUA_TSTRING)
        data = (intptr_t)luaL_checkstring(L, arg++);
	else if(lua_isnil(L, arg))
		{ data = 0; arg++; }
    else /* data may be a buffer name (if a buffer is bound to GL_PIXEL_UNPACK_BUFFER) */
        data = luaL_checkinteger(L, arg++);
    v1 = luaL_checkinteger(L, arg++);
    v2 = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glTexSubImage1D(target, level, v1, v2, format, type, (void*)data);
        else
            glTextureSubImage1D(texture, level, v1, v2, format, type, (void*)data);
        CheckError(L);
        return 0;
        }
    v3 = luaL_checkinteger(L, arg++);
    v4 = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glTexSubImage2D(target, level, v1, v2, v3, v4, format, type, (void*)data);
        else
            glTextureSubImage2D(texture, level, v1, v2, v3, v4, format, type, (void*)data);
        CheckError(L);
        return 0;
        }
    v5 = luaL_checkinteger(L, arg++);
    v6 = luaL_checkinteger(L, arg++);
    if(texture==0)
        glTexSubImage3D(target,level, v1, v2, v3, v4, v5, v6,format,type,(void*)data);
    else
        glTextureSubImage3D(texture,level,v1, v2, v3, v4, v5, v6,format,type,(void*)data); 
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Compressed                                                                   |
 *------------------------------------------------------------------------------*/

static int CompressedTextureImage(lua_State *L)
/* compressed_texture_image(target, level, intfmt, data, width)
 * compressed_texture_image(target, level, intfmt, data, width, height)
 * compressed_texture_image(target, level, intfmt, data, width, height, depth)
 */
    {
#define imagesize (GLsizei)len
    size_t len;
    GLsizei height, depth;
    int arg = 1;
    GLenum target = CheckTarget(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    const void* data = (void*)luaL_checklstring(L, arg++, &len);
    GLsizei width = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        glCompressedTexImage1D(target, level, intfmt, width, border, imagesize, data);
        CheckError(L);
        return 0;
        }
    height = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        glCompressedTexImage2D(target,level,intfmt,width,height,border,imagesize,data);
        CheckError(L);
        return 0;
        }
    depth = luaL_checkinteger(L, arg++);
    glCompressedTexImage3D(target,level,intfmt,width,height,depth,border,imagesize,data);
    CheckError(L);
    return 0;
#undef imagesize
    }


static int CompressedTextureSubImage(lua_State *L)
/* compressed_texture_subimage(target|texture, level, format, data, xofs, w)
 * compressed_texture_subimage(target|texture, level, format, data, xofs, yofs, w, d)
 * compressed_texture_subimage(target|texture, level, format, data, xofs, yofs, zofs, w, d, h)
 */
    {
#define imagesize (GLsizei)len
    size_t len;
    int arg = 1;
    GLint v1, v2, v3, v4, v5, v6;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    const void* data = (void*)luaL_checklstring(L, arg++, &len);
    v1 = luaL_checkinteger(L, arg++);
    v2 = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        CheckError(L);
        if(texture==0)
            glCompressedTexSubImage1D(target,level,v1,v2,intfmt,imagesize,data);
        else
            glCompressedTextureSubImage1D(texture,level,v1,v2,intfmt,imagesize,data);
        return 0;
        }
    v3 = luaL_checkinteger(L, arg++);
    v4 = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glCompressedTexSubImage2D(target,level,v1,v2,v3,v4,intfmt,imagesize,data);
        else
            glCompressedTextureSubImage2D(texture,level,v1,v2,v3,v4,intfmt,imagesize,data);
        CheckError(L);
        return 0;
        }
    v5 = luaL_checkinteger(L, arg++);
    v6 = luaL_checkinteger(L, arg++);
    if(texture==0)
        glCompressedTexSubImage3D(target,level,v1,v2,v3,v4,v5,v6,intfmt,imagesize,data);
    else
        glCompressedTextureSubImage3D(texture,level,v1,v2,v3,v4,v5,v6,intfmt,imagesize,data);
    CheckError(L);
    return 0;
#undef imagesize
    }


/*------------------------------------------------------------------------------*
 | Multisample                                                                  |
 *------------------------------------------------------------------------------*/

static int TextureStorageMultisample(lua_State *L)
/* texture_storage_multisample(target|texture, samples, intfmt, fslocs, width, height)
 * texture_storage_multisample(target|texture, samples, intfmt, fslocs, width, height, depth)
 */
    {
    GLsizei depth;
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLsizei samples = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLboolean fslocs = checkboolean(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    GLsizei height = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glTexStorage2DMultisample(target,samples,intfmt,width,height,fslocs);
        else
            glTextureStorage2DMultisample(texture,samples,intfmt,width,height,fslocs);
        CheckError(L);
        return 0;
        }
    depth = luaL_checkinteger(L, arg++);
    if(texture==0)
        glTexStorage3DMultisample(target,samples,intfmt,width,height,depth,fslocs);
    else
        glTextureStorage3DMultisample(texture,samples,intfmt,width,height,depth,fslocs);
    CheckError(L);
    return 0;
    }

static int TextureImageMultisample(lua_State *L)
/* texture_image_multisample(target, samples, intfmt, fslocs, width, depth [, height]) */
    {
    GLsizei depth;
    int arg = 1;
    GLenum target = CheckTarget(L, arg++);
    GLsizei samples = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLboolean fslocs = checkboolean(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    GLsizei height = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        glTexImage2DMultisample(target, samples, intfmt, width, height, fslocs);
        CheckError(L);
        return 0;
        }
    depth = luaL_checkinteger(L, arg++);
    glTexImage3DMultisample(target, samples, intfmt, width, height, depth, fslocs);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Copy                                                                         |
 *------------------------------------------------------------------------------*/

static int CopyTextureImage(lua_State *L)
/* copy_texture_image(target, level, intfmt, x, y, width)
 * copy_texture_image(target, level, intfmt, x, y, width, height)
 */
    {
    GLsizei height;
    int arg = 1;
    GLenum target = CheckTarget(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLint x = luaL_checkinteger(L, arg++);
    GLint y = luaL_checkinteger(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        glCopyTexImage1D(target, level, intfmt, x, y, width, border);
        CheckError(L);
        return 0;
        }
    height = luaL_checkinteger(L, arg++);
    glCopyTexImage2D(target, level, intfmt, x, y, width, height, border);
    CheckError(L);
    return 0;
    }


static int CopyTextureSubImage(lua_State *L)
/* copy_texture_subimage(target|texture, level, xofs, x, y, w)
 * copy_texture_subimage(target|texture, level, xofs,yofs, x, y, w, h)
 * copy_texture_subimage(target|texture, level, xofs,yofs,zofs, x, y, w, h)
 */
    {
    GLint v1, v2, v3, v4, v5, v6, v7;
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLint level = luaL_checkinteger(L, arg++);
    v1 = luaL_checkinteger(L, arg++);
    v2 = luaL_checkinteger(L, arg++);
    v3 = luaL_checkinteger(L, arg++);
    v4 = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glCopyTexSubImage1D(target, level, v1, v2, v3, v4);
        else
            glCopyTextureSubImage1D(texture, level, v1, v2, v3, v4);
        CheckError(L);
        return 0;
        }
    v5 = luaL_checkinteger(L, arg++);
    v6 = luaL_checkinteger(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        if(texture==0)
            glCopyTexSubImage2D(target, level, v1, v2, v3, v4, v5, v6);
        else
            glCopyTextureSubImage2D(texture, level, v1, v2, v3, v4, v5, v6);
        CheckError(L);
        return 0;
        }
    v7 = luaL_checkinteger(L, arg++);
    if(texture==0)
        glCopyTexSubImage3D(target, level, v1, v2, v3, v4, v5, v6, v7);
    else
        glCopyTextureSubImage3D(texture, level, v1, v2, v3, v4, v5, v6, v7);
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Invalidate, Clear                                                            |
 *------------------------------------------------------------------------------*/

static int InvalidateTextureImage(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    glInvalidateTexImage(texture, level);
    CheckError(L);
    return 0;
    }


static int InvalidateTextureSubImage(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLint xoffset = luaL_checkinteger(L, arg++);
    GLint yoffset = luaL_checkinteger(L, arg++);
    GLint zoffset = luaL_checkinteger(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    GLsizei height = luaL_checkinteger(L, arg++);
    GLsizei depth = luaL_checkinteger(L, arg++);
    glInvalidateTexSubImage(texture, level, xoffset, yoffset, zoffset, width, height, depth);
    CheckError(L);
    return 0;
    }


static int ClearTextureImage(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    const void* data = (void*)luaL_checkstring(L, arg++);
    glClearTexImage(texture, level, format, type, data);
    CheckError(L);
    return 0;
    }

static int ClearTextureSubImage(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    const void* data = (void*)luaL_checkstring(L, arg++);
    GLint xoffset = luaL_checkinteger(L, arg++);
    GLint yoffset = luaL_checkinteger(L, arg++);
    GLint zoffset = luaL_checkinteger(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    GLsizei height = luaL_checkinteger(L, arg++);
    GLsizei depth = luaL_checkinteger(L, arg++);
    glClearTexSubImage(texture, level,xoffset,yoffset,zoffset,width,height,depth,format,type,data);
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Buffer                                                                       |
 *------------------------------------------------------------------------------*/

static int TexBuffer(lua_State *L)
    {
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLuint buffer = luaL_checkinteger(L, arg++);
    if(texture==0)
        glTexBuffer(target, intfmt, buffer);
    else
        glTextureBuffer(texture, intfmt, buffer);
    CheckError(L);
    return 0;
    }


static int TexBufferRange(lua_State *L)
    {
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLuint buffer = luaL_checkinteger(L, arg++);
    GLintptr offset = luaL_checkinteger(L, arg++);
    GLsizei size = luaL_checkinteger(L, arg++);
    if(texture==0)
        glTexBufferRange(target, intfmt, buffer, offset, size);
    else
        glTextureBufferRange(texture, intfmt, buffer, offset, size);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | GetImage/SubImage                                                            |
 *------------------------------------------------------------------------------*/

/* From OpenGL Programming Guide 8ed:
 * "Great care should be exercised when using this function [glGetTexImage. ndr]. 
 * The number of bytes written into image is determined by the dimensions of the 
 * texture currently bound to target, and by format and type. Potentially, a great
 * deal of data could be returned and no bound checks are performed by OpenGL on 
 * the memory area you supply. Therefore, incorrect usage of this function could 
 * lead to buffer overruns and bad things happening.
 * Furthermore, reading pixel data back from textures is generally not a high-perfor-
 * mance operation. Doing so should be a sparingly invoked operation and should 
 * certainly not be in a performance critical path of your application. If you must 
 * read data back from textures, we strongly recommend that you bind a buffer to the
 * GL_PIXEL_PACK_BUFFER buffer target, read the texels into that, and subsequently 
 * map the buffer in order to transfer the pixel data into your application.
 */

static GLsizei Bsz = 0;
static GLsizei BufSize(lua_State *L)
    {
    GLsizei bufsz = Bsz;
    if(bufsz == 0)
        return luaL_error(L, "missing gl.expected_data_size() call");
    Bsz = 0; /* one shot only */
    return bufsz;
    }

static int ExpectedDataSize(lua_State *L) /* NONGL @@DOC */
/* Sets the size of the temporary buffer where to receive data
 * for some functions */
    {
    int bufsz = luaL_checkinteger(L, 1);
    if(bufsz <= 0)
        return luaL_argerror(L, 1, "positive integer expected");
    Bsz = bufsz;    
    return 0;
    }

static int GetTextureImage(lua_State *L)
/* get_texture_image(target|texture, lod, format, type [, buffer])
 * -> bstring (or nil if buffer is passed)
 */
    {
    intptr_t buffer, data = 0;
    GLsizei bufsz = 0;
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    if(lua_isnoneornil(L, arg))
        {
        bufsz = BufSize(L);
        data = (intptr_t)Malloc(L, bufsz *sizeof(char));
        if(texture==0)
            glGetTexImage(target, level, format, type, (void*)data);
        else
            glGetTextureImage(texture, level, format, type, bufsz, (void*)data);
        CheckErrorFree(L, (void*)data);
        lua_pushlstring(L, (char*)data, bufsz);
        Free(L, (void*)data);
        return 1;
        }
    /* buffer should be bound to GL_PIXEL_PACK_BUFFER... */
    buffer = luaL_checkinteger(L, arg++);
    if(texture==0)
        glGetTexImage(target, level, format, type, (void*)buffer);
    else
        glGetTextureImage(texture, level, format, type, 0, (void*)buffer);
    CheckError(L);
    return 0;
    }

static int GetTextureSubImage(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    GLint xoffset = luaL_checkinteger(L, arg++);
    GLint yoffset = luaL_checkinteger(L, arg++);
    GLint zoffset = luaL_checkinteger(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    GLsizei height = luaL_checkinteger(L, arg++);
    GLsizei depth = luaL_checkinteger(L, arg++);
    GLsizei bufsz = BufSize(L);
    char* data = (char*)Malloc(L, bufsz *sizeof(char));
    glGetTextureSubImage(texture, level, xoffset, yoffset, zoffset, width, height, depth, format, type, bufsz, (void*)data);
    CheckErrorFree(L, data);
    lua_pushlstring(L, data, bufsz);
    Free(L, data);
    return 1;
    }


#if 0
static int GetnTextureImage(lua_State *L)
    {
    int arg = 1;
    GLuint target = CheckTarget(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLenum format = checkformat(L, arg++);
    GLenum type = checktype(L, arg++);
    GLsizei bufsz = BufSize(L);
    char* data = (char*)Malloc(L, bufsz *sizeof(char));
    glGetnTexImage(target, level, format, type, bufsz, (void*)data);
    CheckErrorFree(L, data);
    lua_pushlstring(L, data, bufsz);
    Free(L, data);
    return 1;
    }
#endif

#if 0
static int GetnCompressedTextureImage(lua_State *L)
    {
    int arg = 1;
    GLuint target = CheckTarget(L, arg++);
    GLint lod = luaL_checkinteger(L, arg++);
    GLsizei bufsz = BufSize(L);
    char* data = (char*)Malloc(L, bufsz *sizeof(char));
    glGetnCompressedTexImage(target, lod, bufsz, (void*)data);
    CheckErrorFree(L, data);
    lua_pushlstring(L, data, bufsz);
    Free(L, data);
    return 1;
    }
#endif

static int GetCompressedTextureImage(lua_State *L)
    {
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    GLint level = luaL_checkinteger(L, arg++);
    GLsizei bufsz = BufSize(L);
    char* data = (char*)Malloc(L, bufsz *sizeof(char));
    if(texture==0)
        glGetCompressedTexImage(target, level, (void*)data);
    else
        glGetCompressedTextureImage(texture, level, bufsz, (void*)data);
    CheckErrorFree(L, data);
    lua_pushlstring(L, data, bufsz);
    Free(L, data);
    return 1;
    }

static int GetCompressedTextureSubImage(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLint xoffset = luaL_checkinteger(L, arg++);
    GLint yoffset = luaL_checkinteger(L, arg++);
    GLint zoffset = luaL_checkinteger(L, arg++);
    GLsizei width = luaL_checkinteger(L, arg++);
    GLsizei height = luaL_checkinteger(L, arg++);
    GLsizei depth = luaL_checkinteger(L, arg++);
    GLsizei bufsz = BufSize(L);
    char* data = (char*)Malloc(L, bufsz *sizeof(char));
    glGetCompressedTextureSubImage(texture, level, xoffset, yoffset, zoffset, width, height, depth, bufsz, (void*)data);
    CheckErrorFree(L, data);
    lua_pushlstring(L, data, bufsz);
    Free(L, data);
    return 1;
    }


/*------------------------------------------------------------------------------*
 | MipMap, TextureView, BindImage                                               |
 *------------------------------------------------------------------------------*/

static int GenerateMipmap(lua_State *L)
    {
    int arg = 1;
    GLenum target;
    GLuint texture = CheckTargetOrName(L, arg++, &target);
    if(texture==0)
        glGenerateMipmap(target);
    else
        glGenerateTextureMipmap(texture);
    CheckError(L);
    return 0;
    }


static int TextureView(lua_State *L)
    {
    int arg = 1;
    GLuint texture = luaL_checkinteger(L, arg++);
    GLenum target = CheckTarget(L, arg++);
    GLuint origtexture = luaL_checkinteger(L, arg++);
    GLenum intfmt = checkinternalformat(L, arg++);
    GLuint minlevel = luaL_checkinteger(L, arg++);
    GLuint numlevels = luaL_checkinteger(L, arg++);
    GLuint minlayer = luaL_checkinteger(L, arg++);
    GLuint numlayers = luaL_checkinteger(L, arg++);
    glTextureView(texture, target, origtexture, intfmt, minlevel, numlevels, minlayer, numlayers);
    CheckError(L);
    return 0;
    }


static int BindImageTexture(lua_State *L)
    {
    int arg = 1;
    GLuint unit = luaL_checkinteger(L, arg++);
    GLuint texture = luaL_checkinteger(L, arg++);
    GLint level = luaL_checkinteger(L, arg++);
    GLboolean layered = checkboolean(L, arg++);
    GLint layer = luaL_checkinteger(L, arg++);
    GLenum access = CheckAccess(L, arg++);
    GLenum format = checkinternalformat(L, arg++);
    glBindImageTexture(unit, texture, level, layered, layer, access, format);
    CheckError(L);
    return 0;
    }


static int BindImageTextures(lua_State *L)
    {
    GLsizei count, i, arg;
    GLuint *textures;
    GLuint first = luaL_checkinteger(L, 1);
    arg = 2;
    while(!lua_isnoneornil(L, arg))
        luaL_checkinteger(L, arg++);
    if(arg==2)
        luaL_checkinteger(L, arg); /* raise an error */
    count = arg - 2;
    textures = (GLuint*)Malloc(L, count*sizeof(GLuint));
    arg = 2;
    for(i=0; i < count; i++)
        textures[i]=lua_tointeger(L, arg++);
    glBindImageTextures(first, count, textures);
    Free(L, textures);  
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "texture_image", TextureImage },
        { "texture_sub_image", TextureSubImage},
        { "compressed_texture_image", CompressedTextureImage },
        { "compressed_texture_sub_image", CompressedTextureSubImage },
        { "texture_image_multisample", TextureImageMultisample },
        { "texture_storage", TextureStorage },
        { "texture_storage_multisample", TextureStorageMultisample },
        { "copy_texture_image", CopyTextureImage },
        { "copy_texture_sub_image", CopyTextureSubImage },
        { "invalidate_texture_image", InvalidateTextureImage },
        { "invalidate_texture_sub_image", InvalidateTextureSubImage },
        { "clear_texture_image", ClearTextureImage },
        { "clear_texture_sub_image", ClearTextureSubImage },
        { "texture_buffer", TexBuffer },
        { "texture_buffer_range", TexBufferRange },
        { "get_texture_image", GetTextureImage },
        { "get_compressed_texture_image", GetCompressedTextureImage },
        { "get_texture_sub_image", GetTextureSubImage },
        { "get_compressed_texture_sub_image", GetCompressedTextureSubImage },
#if 0
        { "getn_texture_image", GetnTextureImage },
        { "getn_compressed_texture_image", GetnCompressedTextureImage },
#endif
        { "generate_mipmap", GenerateMipmap },
        { "texture_view", TextureView },
        { "bind_image_texture", BindImageTexture },
        { "bind_image_textures", BindImageTextures },
        { "expected_data_size", ExpectedDataSize },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_teximage(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }


