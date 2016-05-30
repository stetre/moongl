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

ENUM_STRINGS(BufStrings) = {
    "none",
    "front left",
    "front right",
    "back left",
    "back right",
    "front",
    "back",
    "left",
    "right",
    "front and back",
    "color attachment 0",
    "color attachment 1",
    "color attachment 2",
    "color attachment 3",
    "color attachment 4",
    "color attachment 5",
    "color attachment 6",
    "color attachment 7",
    "color attachment 8",
    "color attachment 9",
    "color attachment 10",
    "color attachment 11",
    "color attachment 12",
    "color attachment 13",
    "color attachment 14",
    "color attachment 15",
/*-------------------------------------*/
    "color",
    "depth",
    "stencil",
    "depth attachment",
    "stencil attachment",
    "depth stencil attachment",
    NULL
};
ENUM_CODES(BufCodes) = {
    GL_NONE,
    GL_FRONT_LEFT,
    GL_FRONT_RIGHT,
    GL_BACK_LEFT,
    GL_BACK_RIGHT,
    GL_FRONT,
    GL_BACK,
    GL_LEFT,
    GL_RIGHT,
    GL_FRONT_AND_BACK,
    GL_COLOR_ATTACHMENT0,
    GL_COLOR_ATTACHMENT1,
    GL_COLOR_ATTACHMENT2,
    GL_COLOR_ATTACHMENT3,
    GL_COLOR_ATTACHMENT4,
    GL_COLOR_ATTACHMENT5,
    GL_COLOR_ATTACHMENT6,
    GL_COLOR_ATTACHMENT7,
    GL_COLOR_ATTACHMENT8,
    GL_COLOR_ATTACHMENT9,
    GL_COLOR_ATTACHMENT10,
    GL_COLOR_ATTACHMENT11,
    GL_COLOR_ATTACHMENT12,
    GL_COLOR_ATTACHMENT13,
    GL_COLOR_ATTACHMENT14,
    GL_COLOR_ATTACHMENT15,
/* for attachments (see framebuffer.c): */
    GL_COLOR,
    GL_DEPTH,
    GL_STENCIL,
    GL_DEPTH_ATTACHMENT,
    GL_STENCIL_ATTACHMENT,
    GL_DEPTH_STENCIL_ATTACHMENT,
};
ENUM_T(BufEnum, BufStrings, BufCodes)
#define CheckBuf(L, arg) enumCheck((L), (arg), &BufEnum)
#define PushBuf(L, code) enumPush((L), (code), &BufEnum)

enum_t *enumBuffer(void)
    { return &BufEnum; }


ENUM_STRINGS(ClearBufStrings) = {
    "color",
    "depth",
    "stencil",
    NULL
};
ENUM_CODES(ClearBufCodes) = {
    GL_COLOR,
    GL_DEPTH,
    GL_STENCIL
};
ENUM_T(ClearBufEnum, ClearBufStrings, ClearBufCodes)
#define CheckClearBuf(L, arg) enumCheck((L), (arg), &ClearBufEnum)
#define PushClearBuf(L, code) enumPush((L), (code), &ClearBufEnum)

BITFIELD_STRINGS(BufferBitStrings) = {
    "color", 
    "depth", 
    "stencil", 
    NULL
};
BITFIELD_CODES(BufferBitCodes) = {
    GL_COLOR_BUFFER_BIT,
    GL_DEPTH_BUFFER_BIT,
    GL_STENCIL_BUFFER_BIT
};
BITFIELD_T(BufferBitBitfield, BufferBitStrings, BufferBitCodes)
#define CheckBufferBit(L, arg, mand) bitfieldCheck((L), (arg), (mand), &BufferBitBitfield)
#define PushBufferBit(L, code) bitfieldPush((L), (code), &BufferBitBitfield)

bitfield_t *bitfieldBuffer(void)
    { return &BufferBitBitfield; }

static GLenum* CheckBufList(lua_State *L, int arg, GLsizei *n)
/* the caller must Free() the returned bufs */
    {
    GLenum *bufs;
    int i = arg;
    while(!lua_isnoneornil(L, i))
        { CheckBuf(L, i); i++; }
    if(i==arg) /* raise an error */
        CheckBuf(L, arg); 
    *n = i - arg;
    bufs = (GLenum*)Malloc(L, (*n)*sizeof(GLenum));
    i = 0;
    for(i = 0; i < (*n); i++)
        bufs[i] = CheckBuf(L, arg + i);
    return bufs;
    }

ENUM_STRINGS(FaceStrings) = {
    "back",
    "front",
    "front and back",
    NULL
};
ENUM_CODES(FaceCodes) = {
    GL_FRONT,
    GL_BACK,
    GL_FRONT_AND_BACK
};
ENUM_T(FaceEnum, FaceStrings, FaceCodes)
#define CheckFace(L, arg) enumCheck((L), (arg), &FaceEnum)
#define PushFace(L, code) enumPush((L), (code), &FaceEnum)

static int ColorMask(lua_State *L)
    {
    GLuint buf;
    GLboolean r, g, b, a;
    if(lua_isinteger(L, 1))
        {
        buf = luaL_checkinteger(L, 1);
        r = checkboolean(L, 2);
        g = checkboolean(L, 3);
        b = checkboolean(L, 4);
        a = checkboolean(L, 5);
        glColorMaski(buf, r, g, b, a);
        }
    else
        {
        r = checkboolean(L, 1);
        g = checkboolean(L, 2);
        b = checkboolean(L, 3);
        a = checkboolean(L, 4);
        glColorMask(r, g, b, a);
        }
    CheckError(L);
    return 0;
    }

BOOLEAN_FUNC(DepthMask)

static int StencilMask(lua_State *L)
    {
    GLenum face;
    GLuint mask = luaL_checkinteger(L, 1);
    if(lua_isstring(L, 2))
        {
        face = CheckFace(L, 2);
        glStencilMaskSeparate(face, mask);
        }
    else
        glStencilMask(mask);
    CheckError(L);
    return 0;
    }

static int Clear(lua_State *L)
    {
    GLbitfield mask = CheckBufferBit(L, 1, 0);
    glClear(mask);
    CheckError(L);
    return 0;
    }

static int ClearColor(lua_State *L)
    {
    GLfloat r = luaL_checknumber(L, 1);
    GLfloat g = luaL_checknumber(L, 2);
    GLfloat b = luaL_checknumber(L, 3);
    GLfloat a = luaL_checknumber(L, 4);
    glClearColor(r, g, b, a);
    CheckError(L);
    return 0;
    }

DOUBLE_FUNC(ClearDepth)

INT_FUNC(ClearStencil)

static int DrawBuffer(lua_State *L)
    {
    GLenum buf;
    GLuint framebuffer;
    if(lua_isinteger(L, 1))
        {
        framebuffer = luaL_checkinteger(L, 1);
        buf = CheckBuf(L, 2);
        glNamedFramebufferDrawBuffer(framebuffer, buf);
        }
    else
        {
        buf = CheckBuf(L, 1);
        glDrawBuffer(buf);
        }
    CheckError(L);
    return 0;
    }

static int DrawBuffers(lua_State *L)
    {
    int named, arg = 1;
    GLuint framebuffer = 0;
    GLsizei n;
    GLenum *bufs;
    if(lua_isinteger(L, arg))
        {
        named = 1;
        framebuffer = luaL_checkinteger(L, arg++);
        }
    else
        named = 0;
    bufs = CheckBufList(L, arg, &n);
    if(named)
        glNamedFramebufferDrawBuffers(framebuffer, n, bufs);
    else
        glDrawBuffers(n, bufs);
    Free(L, bufs);
    CheckError(L);
    return 0;
    }



static int ClearBuffer(lua_State *L)
/* clear_buffer("color", drawbuffer, red, green, blue, alpha)
 * clear_buffer("depth", value)
 * clear_buffer("stencil", value)
 */
    {
    int named, arg = 1;
    GLuint framebuffer;
    GLint drawbuffer;
    GLfloat value[4];
    GLint stencil;
    GLenum buffer;
    if(lua_isinteger(L, 1))
        { 
        named = 1; 
        framebuffer = luaL_checkinteger(L, arg++);
        }
    else
        named = 0;
    buffer = CheckClearBuf(L, arg++);
    switch(buffer)
        {
        case GL_COLOR:      drawbuffer = luaL_checkinteger(L, arg++);
                            value[0] = luaL_checknumber(L, arg++);
                            value[1] = luaL_checknumber(L, arg++);
                            value[2] = luaL_checknumber(L, arg++);
                            value[3] = luaL_checknumber(L, arg++);
                            if(named)
                                glClearNamedFramebufferfv(framebuffer, buffer, drawbuffer, value);
                            else
                                glClearBufferfv(buffer, drawbuffer, value);
                            break;

        case GL_DEPTH:      value[0] = luaL_checknumber(L, arg++);
                            if(named)
                                glClearNamedFramebufferfv(framebuffer, buffer, 0, value);
                            else
                                glClearBufferfv(buffer, 0, value);
                            break;
        case GL_STENCIL:    stencil = luaL_checkinteger(L, arg++);
                            if(named)
                                glClearNamedFramebufferiv(framebuffer, buffer, 0, &stencil);
                            else
                                glClearBufferiv(buffer, 0, &stencil);
                            break;
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    CheckError(L);
    return 0;
    }

static int ClearBufferfi(lua_State *L)
/* clear_bufferfi(depth, stencil)
 */
    {
    int named, arg = 1;
    GLuint framebuffer;
    GLfloat depth;
    GLint stencil;
    if(lua_isinteger(L, 1))
        {
        named = 1;
        framebuffer = luaL_checkinteger(L, arg++);
        }
    else
        named = 0;
    depth = luaL_checknumber(L, arg++);
    stencil = luaL_checkinteger(L, arg++);
    if(named)
        {
#if 0
/*@@NOTE: The prototype for glClearNamedFramebufferfi() in glcorearb.h is/was wrong,
 *        (rfr: https://www.khronos.org/bugzilla/show_bug.cgi?id=1394 ),
 *        so this may not compile with OpenGL v4.5.
 *      In such a case, you can update the glcorearb.h file on your system with the
 *      correct version, or just disable this function by setting to 0 the above "#if 1".
 */
        glClearNamedFramebufferfi(framebuffer, GL_DEPTH_STENCIL, 0, depth, stencil);
#else
        (void)framebuffer;
        NOT_AVAILABLE;
#endif
        }
    else
        glClearBufferfi(GL_DEPTH_STENCIL, 0, depth, stencil);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "color_mask", ColorMask },
        { "depth_mask", DepthMask },
        { "stencil_mask", StencilMask },
        { "clear", Clear },
        { "clear_color", ClearColor },
        { "clear_depth", ClearDepth },
        { "clear_stencil", ClearStencil },
        { "draw_buffer", DrawBuffer },
        { "draw_buffers", DrawBuffers },
        { "clear_buffer", ClearBuffer },
        { "clear_bufferfi", ClearBufferfi },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_whole_framebuffer(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

