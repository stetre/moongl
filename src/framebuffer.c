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

#define RbTargetEnum enumRbTarget()
#define CheckRbTarget(L, arg) enumCheck((L), (arg), RbTargetEnum)
#define PushRbTarget(L, code) enumPush((L), (code), RbTargetEnum)

#define AttachmentEnum enumBuffer()
#define CheckAttachment(L, arg) enumCheck((L), (arg), AttachmentEnum)
#define PushAttachment(L, code) enumPush((L), (code), AttachmentEnum)

ENUM_STRINGS(TargetStrings) = {
    "draw",
    "read",
/*  "framebuffer", */
    NULL
};
ENUM_CODES(TargetCodes) = {
    GL_DRAW_FRAMEBUFFER,
    GL_READ_FRAMEBUFFER,
/*  GL_FRAMEBUFFER, */
};
ENUM_T(TargetEnum,TargetStrings, TargetCodes)
#define CheckTarget(L, arg) enumCheck((L), (arg), &TargetEnum)
#define PushTarget(L, code) enumPush((L), (code), &TargetEnum)
#define CheckTargetOrName(L, arg, dst) enumOrUint((L), (arg), (dst), &TargetEnum, 0)

ENUM_STRINGS(PnameStrings) = {
    "default width",
    "default height",
    "default layers",
    "default samples",
    "default fixed sample locations",
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_FRAMEBUFFER_DEFAULT_WIDTH,
    GL_FRAMEBUFFER_DEFAULT_HEIGHT,
    GL_FRAMEBUFFER_DEFAULT_LAYERS,
    GL_FRAMEBUFFER_DEFAULT_SAMPLES,
    GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS,
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)

ENUM_STRINGS(StatusStrings) = {
    "complete",
    "undefined",
    "incomplete attachment",
    "incomplete missing attachment",
    "incomplete draw buffer",
    "incomplete read buffer",
    "unsupported",
    "incomplete multisample",
    "incomplete layer targets",
    NULL
};
ENUM_CODES(StatusCodes) = {
    GL_FRAMEBUFFER_COMPLETE,
    GL_FRAMEBUFFER_UNDEFINED,
    GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT,
    GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,
    GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER,
    GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER,
    GL_FRAMEBUFFER_UNSUPPORTED,
    GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE,
    GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS,
};
ENUM_T(StatusEnum, StatusStrings, StatusCodes)
#define CheckStatus(L, arg) enumCheck((L), (arg), &StatusEnum)
#define PushStatus(L, code) enumPush((L), (code), &StatusEnum)

ENUM_STRINGS(GPnameStrings) = {
    "default width",
    "default height",
    "default layers",
    "default samples",
    "default fixed sample locations",
    "doublebuffer",
    "implementation color read format",
    "implementation color read type",
    "samples",
    "sample buffers",
    "stereo",
    NULL
};
ENUM_CODES(GPnameCodes) = {
    GL_FRAMEBUFFER_DEFAULT_WIDTH,
    GL_FRAMEBUFFER_DEFAULT_HEIGHT,
    GL_FRAMEBUFFER_DEFAULT_LAYERS,
    GL_FRAMEBUFFER_DEFAULT_SAMPLES,
    GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS,
    GL_DOUBLEBUFFER,
    GL_IMPLEMENTATION_COLOR_READ_FORMAT,
    GL_IMPLEMENTATION_COLOR_READ_TYPE,
    GL_SAMPLES,
    GL_SAMPLE_BUFFERS,
    GL_STEREO,
};
ENUM_T(GPnameEnum, GPnameStrings, GPnameCodes)
#define CheckGPname(L, arg) enumCheck((L), (arg), &GPnameEnum)
#define PushGPname(L, code) enumPush((L), (code), &GPnameEnum)

#define TexTargetEnum enumTextureTarget()
#define CheckTexTarget(L, arg) enumCheck((L), (arg), TexTargetEnum)

ENUM_STRINGS(APnameStrings) = {
    "object type",
    "object name",
    "component type",
    "red size",
    "green size",
    "blue size", 
    "alpha size", 
    "depth size",
    "stencil size", 
    "color encoding",
    "texture layer",
    "texture level",
    "layered", 
    "texture cube map face",
    NULL
};
ENUM_CODES(APnameCodes) = {
    GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
    GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
    GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE,
    GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE,
    GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE,
    GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE, 
    GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE, 
    GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE,
    GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE, 
    GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING,
    GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER,
    GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL,
    GL_FRAMEBUFFER_ATTACHMENT_LAYERED, 
    GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE,
};
ENUM_T(APnameEnum, APnameStrings, APnameCodes)
#define CheckAPname(L, arg) enumCheck((L), (arg), &APnameEnum)
#define PushAPname(L, code) enumPush((L), (code), &APnameEnum)

ENUM_STRINGS(ObjectTypeStrings) = {
    "none",
    "framebuffer default",
    "texture",
    "framebuffer",
    NULL
};
ENUM_CODES(ObjectTypeCodes) = {
    GL_NONE,
    GL_FRAMEBUFFER_DEFAULT,
    GL_TEXTURE,
    GL_RENDERBUFFER,
};
ENUM_T(ObjectTypeEnum, ObjectTypeStrings, ObjectTypeCodes)
#define CheckObjectType(L, arg) enumCheck((L), (arg), &ObjectTypeEnum)
#define PushObjectType(L, code) enumPush((L), (code), &ObjectTypeEnum)

ENUM_STRINGS(ComponentTypeStrings) = {
    "none",
    "snorm",
    "unorm",
    "float",
    "int",
    "uint",
    NULL
};
ENUM_CODES(ComponentTypeCodes) = {
    GL_NONE,
    GL_SIGNED_NORMALIZED,
    GL_UNSIGNED_NORMALIZED,
    GL_FLOAT,
    GL_INT,
    GL_UNSIGNED_INT,
};
ENUM_T(ComponentTypeEnum, ComponentTypeStrings, ComponentTypeCodes)
#define CheckComponentType(L, arg) enumCheck((L), (arg), &ComponentTypeEnum)
#define PushComponentType(L, code) enumPush((L), (code), &ComponentTypeEnum)

enum_t *enumComponentType(void)
    { return &ComponentTypeEnum; }

ENUM_STRINGS(ColorEncodingStrings) = {
    "linear",
    "srgb",
    NULL
};
ENUM_CODES(ColorEncodingCodes) = {
    GL_LINEAR,
    GL_SRGB,
};
ENUM_T(ColorEncodingEnum, ColorEncodingStrings, ColorEncodingCodes)
#define CheckColorEncoding(L, arg) enumCheck((L), (arg), &ColorEncodingEnum)
#define PushColorEncoding(L, code) enumPush((L), (code), &ColorEncodingEnum)

enum_t *enumColorEncoding(void)
    { return &ColorEncodingEnum; }


/*--------------------------------------------------------------------------*
 | framebuffer_parameter()                                                  |
 *--------------------------------------------------------------------------*/

static int FramebufferParameter(lua_State *L)
    {
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum pname = CheckPname(L, 2);
    GLint param = luaL_checkinteger(L, 3);
    if(framebuffer==0)
        glFramebufferParameteri(target, pname, param);
    else
        glNamedFramebufferParameteri(framebuffer, pname, param);
    CheckError(L);
    return 0;
    }

/*--------------------------------------------------------------------------*
 | get_framebuffer_parameter()                                              |
 *--------------------------------------------------------------------------*/

static int GetInt_(lua_State *L, GLenum target, GLuint framebuffer, GLenum pname, int boolean)
#define GetInt(L, target, framebuffer, pname) GetInt_((L),(target),(framebuffer),(pname), 0)
#define GetBoolean(L, target, framebuffer, pname) GetInt_((L),(target),(framebuffer),(pname), 1)
    {
    GLint param;
    if(framebuffer==0)
        glGetFramebufferParameteriv(target, pname, &param);
    else
        glGetNamedFramebufferParameteriv(framebuffer, pname, &param);
    CheckError(L);
    if(boolean)
        lua_pushboolean(L, param);
    else
        lua_pushinteger(L, param);
    return 1;
    }

static int GetEnum(lua_State *L, GLenum target, GLuint framebuffer, GLenum pname, enum_t *e)
    {
    GLint param;
    if(framebuffer==0)
        glGetFramebufferParameteriv(target, pname, &param);
    else
        glGetNamedFramebufferParameteriv(framebuffer, pname, &param);
    CheckError(L);
    return enumPush(L, (GLenum)param, e);
    }

static int GetFramebufferParameter(lua_State *L)
    {
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum pname = CheckGPname(L, 2);
    switch(pname)
        {
        case GL_FRAMEBUFFER_DEFAULT_WIDTH:
        case GL_FRAMEBUFFER_DEFAULT_HEIGHT:
        case GL_FRAMEBUFFER_DEFAULT_LAYERS:
        case GL_FRAMEBUFFER_DEFAULT_SAMPLES:
        case GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS:
        case GL_SAMPLES:
        case GL_SAMPLE_BUFFERS:
                return GetInt(L, target, framebuffer, pname);
        case GL_DOUBLEBUFFER:
        case GL_STEREO:
                return GetBoolean(L, target, framebuffer, pname);
        case GL_IMPLEMENTATION_COLOR_READ_FORMAT:
                return GetEnum(L, target, framebuffer, pname, enumFormat());
        case GL_IMPLEMENTATION_COLOR_READ_TYPE:
                return GetEnum(L, target, framebuffer, pname, enumType());
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }

/*--------------------------------------------------------------------------*
 | get_framebuffer_attachment_parameter()                                   |
 *--------------------------------------------------------------------------*/


static int AGetInt_(lua_State *L, GLenum target, GLuint framebuffer, 
    GLenum attachment, GLenum pname, int boolean)
#define AGetInt(L, target, framebuffer, attachment, pname) \
            AGetInt_((L),(target),(framebuffer), (attachment), (pname), 0)
#define AGetBoolean(L, target, framebuffer, attachment, pname) \
            AGetInt_((L),(target),(framebuffer), (attachment), (pname), 0)
    {
    GLint param;
    if(framebuffer==0)
        glGetFramebufferAttachmentParameteriv(target, attachment, pname, &param);
    else
        glGetNamedFramebufferAttachmentParameteriv(framebuffer, attachment, pname, &param);
    CheckError(L);
    if(boolean)
        lua_pushboolean(L, param);
    else
        lua_pushinteger(L, param);
    return 1;
    }

static int AGetEnum(lua_State *L, GLenum target, GLuint framebuffer, GLenum attachment, GLenum pname, enum_t *e)
    {
    GLint param;
    if(framebuffer==0)
        glGetFramebufferAttachmentParameteriv(target, attachment, pname, &param);
    else
        glGetNamedFramebufferAttachmentParameteriv(framebuffer, attachment, pname, &param);
    CheckError(L);
    return enumPush(L, (GLenum)param, e);
    }

static int GetFramebufferAttachmentParameter(lua_State *L)
    {
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum attachment = CheckAttachment(L, 2);
    GLenum pname = CheckAPname(L, 3);
    switch(pname)
        {
        case GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:
                return AGetEnum(L, target, framebuffer, attachment, pname, &ObjectTypeEnum);
        case GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:
                        return AGetInt(L, target, framebuffer, attachment, pname);
        case GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE:
                return AGetEnum(L, target, framebuffer, attachment, pname, &ComponentTypeEnum);
        case GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE:
        case GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE:
        case GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE: 
        case GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE: 
        case GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE:
        case GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE: 
                            return AGetInt(L, target, framebuffer, attachment, pname);
        case GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING:
                return AGetEnum(L, target, framebuffer, attachment, pname, &ColorEncodingEnum);
        case GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER:
        case GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:
                            return AGetInt(L, target, framebuffer, attachment, pname);
        case GL_FRAMEBUFFER_ATTACHMENT_LAYERED:
                            return AGetBoolean(L, target, framebuffer, attachment, pname);
        case GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:
                return AGetEnum(L, target, framebuffer, attachment, pname, TexTargetEnum);
        default:
            return luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }


/*--------------------------------------------------------------------------*
 | check_framebuffer_status()                                               |
 *--------------------------------------------------------------------------*/

static int CheckFramebufferStatus(lua_State *L)
    {
    GLuint framebuffer;
    GLenum status;
    GLuint target = CheckTarget(L, 1);
    if(lua_isnoneornil(L, 2))
        status = glCheckFramebufferStatus(target);
    else 
        {
        framebuffer = luaL_checkinteger(L, 2);
        status = glCheckNamedFramebufferStatus(framebuffer, target);
        }
    CheckError(L);
    PushStatus(L, status);
    return 1;
    }

/*--------------------------------------------------------------------------*
 | FramebufferRenderbuffer                                                  |
 *--------------------------------------------------------------------------*/

static int FramebufferRenderbuffer(lua_State *L)
    {
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum attachment = CheckAttachment(L, 2);
    GLenum rbtarget = CheckRbTarget(L, 3);
    GLuint renderbuffer = luaL_checkinteger(L, 4);
    if(framebuffer == 0)
        glFramebufferRenderbuffer(target, attachment, rbtarget, renderbuffer);
    else
        glNamedFramebufferRenderbuffer(framebuffer, attachment, rbtarget, renderbuffer);
    CheckError(L);
    return 0;
    }

static int FramebufferTexture(lua_State *L)
    {
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum attachment = CheckAttachment(L, 2);
    GLuint texture = luaL_checkinteger(L, 3);
    GLint level = luaL_checkinteger(L, 4);
    if(framebuffer == 0)
        glFramebufferTexture(target, attachment, texture, level);
    else
        glNamedFramebufferTexture(framebuffer,attachment, texture, level);
    CheckError(L);
    return 0;
    }

static int FramebufferTexture1D(lua_State *L)
    {
    GLenum target = CheckTarget(L, 1);
    GLenum attachment = CheckAttachment(L, 2);
    GLenum textarget = CheckTexTarget(L, 3);
    GLuint texture = luaL_checkinteger(L, 4);
    GLint level = luaL_checkinteger(L, 5);
    glFramebufferTexture1D(target, attachment, textarget, texture, level);
    CheckError(L);
    return 0;
    }

static int FramebufferTexture2D(lua_State *L)
    {
    GLenum target = CheckTarget(L, 1);
    GLenum attachment = CheckAttachment(L, 2);
    GLenum textarget = CheckTexTarget(L, 3);
    GLuint texture = luaL_checkinteger(L, 4);
    GLint level = luaL_checkinteger(L, 5);
    glFramebufferTexture2D(target, attachment, textarget, texture, level);
    CheckError(L);
    return 0;
    }

static int FramebufferTexture3D(lua_State *L)
    {
    GLenum target = CheckTarget(L, 1);
    GLenum attachment = CheckAttachment(L, 2);
    GLenum textarget = CheckTexTarget(L, 3);
    GLuint texture = luaL_checkinteger(L, 4);
    GLint level = luaL_checkinteger(L, 5);
    GLint layer = luaL_checkinteger(L, 6);
    glFramebufferTexture3D(target, attachment, textarget, texture, level, layer);
    CheckError(L);
    return 0;
    }

static int FramebufferTextureLayer(lua_State *L)
    {
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum attachment = CheckAttachment(L, 2);
    GLuint texture = luaL_checkinteger(L, 3);
    GLint level = luaL_checkinteger(L, 4);
    GLint layer = luaL_checkinteger(L, 5);
    if(framebuffer == 0)
        glFramebufferTextureLayer(target, attachment, texture, level, layer);
    else
        glNamedFramebufferTextureLayer(framebuffer, attachment, texture, level, layer);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Invalidating                                                                 |
 *------------------------------------------------------------------------------*/

static GLenum *CheckAttachments(lua_State *L, int argfirst, GLsizei *count)
    {
    GLsizei i, arg = argfirst;
    GLenum *attachments;
    while(!lua_isnoneornil(L, arg))
        luaL_checkstring(L, arg++);
    if(arg == argfirst)
        CheckAttachment(L, argfirst); /* raise an error */
    *count = arg - argfirst;
    attachments = (GLenum*)Malloc(L, (*count)*sizeof(GLenum));
    arg = argfirst;
    for(i = 0; i < *count; i++)
        attachments[i] = CheckAttachment(L, arg++);
    return attachments;
    }



static int InvalidateSubFramebuffer(lua_State *L)
/* invalidate_sub_framebuffer(target, x, y, w, h, attachm1 [, attachm2, ...]) 
 */
    {
    GLsizei count;
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLuint x = luaL_checkinteger(L, 2);
    GLuint y = luaL_checkinteger(L, 3);
    GLuint width = luaL_checkinteger(L, 4);
    GLuint height = luaL_checkinteger(L, 5);
    GLenum *attachments = CheckAttachments(L, 6, &count);
    if(framebuffer)
        glInvalidateNamedFramebufferSubData(framebuffer, count, attachments, x, y, width, height);
    else
        glInvalidateSubFramebuffer(target, count, attachments, x, y, width, height);
    Free(L, attachments);
    CheckError(L);
    return 0;
    }

static int InvalidateFramebuffer(lua_State *L)
    {
    GLsizei count;
    GLenum target;
    GLuint framebuffer = CheckTargetOrName(L, 1, &target);
    GLenum *attachments = CheckAttachments(L, 2, &count);
    if(framebuffer)
        glInvalidateNamedFramebufferData(framebuffer, count, attachments);
    else
        glInvalidateFramebuffer(target, count, attachments);
    Free(L, attachments);
    CheckError(L);
    return 0;
    }

/*------------------------------------------------------------------------------*
 | Gen, bind etc                                                                |
 *------------------------------------------------------------------------------*/


NEW_TARGET_FUNC(Framebuffer, &TargetEnum)
GEN_FUNC(Framebuffer)
BIND_TARGET_FUNC(Framebuffer, &TargetEnum)
DELETE_FUNC(Framebuffer)
IS_FUNC(Framebuffer)
CREATE_FUNC(Framebuffer)

static int TextureBarrier(lua_State *L) 
    { 
    glTextureBarrier();
    CheckError(L);
    return 0;
    }


/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "new_framebuffer", NewFramebuffer },
        { "gen_framebuffers", GenFramebuffers },
        { "create_framebuffers", CreateFramebuffers },
        { "bind_framebuffer", BindFramebuffer },
        { "is_framebuffer", IsFramebuffer },
        { "delete_framebuffers", DeleteFramebuffers },
        { "framebuffer_parameter", FramebufferParameter },
        { "get_framebuffer_parameter", GetFramebufferParameter },
        { "get_framebuffer_attachment_parameter", GetFramebufferAttachmentParameter },
        { "check_framebuffer_status", CheckFramebufferStatus },
        { "framebuffer_renderbuffer", FramebufferRenderbuffer },
        { "framebuffer_texture", FramebufferTexture },
        { "framebuffer_texture_1d", FramebufferTexture1D },
        { "framebuffer_texture_2d", FramebufferTexture2D },
        { "framebuffer_texture_3d", FramebufferTexture3D },
        { "framebuffer_texture_layer", FramebufferTextureLayer },
        { "texture_barrier", TextureBarrier },
        { "invalidate_sub_framebuffer", InvalidateSubFramebuffer },
        { "invalidate_framebuffer", InvalidateFramebuffer },
        { NULL, NULL } /* sentinel */
    };


void moongl_open_framebuffer(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

