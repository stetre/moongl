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

#ifndef enumDEFINED
#define enumDEFINED

/*--------------------------------------------------------------------------*
 | GLenum <-> string mappings                                               |
 *--------------------------------------------------------------------------*/

#define enum_t moongl_enum_t
typedef struct {
    const char **strings;
    GLenum *codes;
    size_t n;
} enum_t;

#define enumCheck moongl_enumCheck
GLenum enumCheck(lua_State *L, int arg, enum_t *e);
#define enumPush moongl_enumPush
int enumPush(lua_State *L, GLenum code, enum_t *e);
#define enumToString moongl_enumToString
const char* enumToString(GLenum code, enum_t *e);
#define enumAssert moongl_enumAssert
int enumAssert(lua_State *L, enum_t *e, GLenum code, const char *string);
#define enumOrUint moongl_enumOrUint
GLuint enumOrUint(lua_State *L, int arg, GLenum *dst, enum_t *e, GLuint def);

#define ENUM_STRINGS(strings)   static const char* (strings) []
#define ENUM_CODES(codes)       static GLenum (codes) []
#define ENUM_T(name, strings, codes)    \
    static enum_t name = { (strings), (codes), sizeof((codes))/sizeof(GLenum) };


#define checktype moongl_checktype
int checktype(lua_State *L, int arg);
#define sizeoftype moongl_sizeoftype
size_t sizeoftype(lua_State *L, int type);
#define checkglsltype moongl_checkglsltype
GLenum checkglsltype(lua_State *L, int arg);
#define pushglsltype moongl_pushglsltype
int pushglsltype(lua_State *L, GLenum code);
#define checkinternalformat moongl_checkinternalformat
GLenum checkinternalformat(lua_State *L, int arg);
#define checkformat moongl_checkformat
GLenum checkformat(lua_State *L, int arg);

#define enumType moongl_enumType
enum_t *enumType(void);
#define enumFormat moongl_enumFormat
enum_t *enumFormat(void);
#define enumInternalFormat moongl_enumInternalFormat
enum_t *enumInternalFormat(void);
#define enumHintMode moongl_enumHintMode
enum_t *enumHintMode(void);
#define enumDrawMode moongl_enumDrawMode
enum_t *enumDrawMode(void);
#define enumBuffer moongl_enumBuffer
enum_t *enumBuffer(void);
#define enumBufferTarget moongl_enumBufferTarget
enum_t *enumBufferTarget(void);
#define enumProvokeMode moongl_enumProvokeMode
enum_t *enumProvokeMode(void);
#define enumLogicOp moongl_enumLogicOp
enum_t *enumLogicOp(void);
#define enumStencilOp moongl_enumStencilOp
enum_t *enumStencilOp(void);
#define enumStencilFunc moongl_enumStencilFunc
enum_t *enumStencilFunc(void);
#define enumBlendMode moongl_enumBlendMode
enum_t *enumBlendMode(void);
#define enumBlendFactor moongl_enumBlendFactor
enum_t *enumBlendFactor(void);
#define enumRbTarget moongl_enumRbTarget
enum_t *enumRbTarget(void);
#define enumShaderType moongl_enumShaderType
enum_t *enumShaderType(void);
#define enumUniformType moongl_enumUniformType
enum_t *enumUniformType(void);
#define enumTextureTarget moongl_enumTextureTarget
enum_t *enumTextureTarget(void);
#define enumMagFilter moongl_enumMagFilter
enum_t *enumMagFilter(void);
#define enumMinFilter moongl_enumMinFilter
enum_t *enumMinFilter(void);
#define enumWrap moongl_enumWrap
enum_t *enumWrap(void);
#define enumCompareFunc moongl_enumCompareFunc
enum_t *enumCompareFunc(void);
#define enumCompareMode moongl_enumCompareMode
enum_t *enumCompareMode(void);
#define enumComponentType moongl_enumComponentType
enum_t *enumComponentType(void);
#define enumColorEncoding moongl_enumColorEncoding
enum_t *enumColorEncoding(void);
#define enumClamp moongl_enumClamp
enum_t *enumClamp(void);
#define enumCullFaceMode moongl_enumCullFaceMode
enum_t *enumCullFaceMode(void);
#define enumFrontFaceMode moongl_enumFrontFaceMode
enum_t *enumFrontFaceMode(void);
#define enumOrigin moongl_enumOrigin
enum_t *enumOrigin(void);
#define enumPolygonModeMode moongl_enumPolygonModeMode
enum_t *enumPolygonModeMode(void);
#define enumBufferMode moongl_enumBufferMode
enum_t *enumBufferMode(void);

#if 0
#define  moongl_

#define enumZzz moongl_enumZzz
enum_t *enumZzz(void);
enum_t *enumZzz(void)
    { return &ZzzEnum; }

#endif


#if 0 /* 11yy */
ENUM_STRINGS(ZzzStrings) = {
    "",
    NULL
};
ENUM_CODES(ZzzCodes) = {
    GL_,
};
ENUM_T(ZzzEnum, ZzzStrings, ZzzCodes)
#define CheckZzz(L, arg) enumCheck((L), (arg), &ZzzEnum)
#define PushZzz(L, code) enumPush((L), (code), &ZzzEnum)


#define ToStringZzz(code) enumToString((code), &ZzzEnum)

#define CheckZzzOrNnn(L, arg, dst) enumOrUint((L), (arg), (dst), &ZzzEnum, 0)

enum_t *enumZzz(void)
    { return &ZzzEnum; }

#define ZzzEnum yyyZzz()
#define CheckZzz(L, arg) enumCheck((L), (arg), ZzzEnum)
#define PushZzz(L, code) enumPush((L), (code), ZzzEnum)
#define ToStringZzz(code) enumToString((code), ZzzEnum)

#endif

#endif /* enumDEFINED */
