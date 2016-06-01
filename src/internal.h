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

/********************************************************************************
 * Internal common header                                                       *
 ********************************************************************************/

#ifndef internalDEFINED
#define internalDEFINED

#include <string.h>
#include <stdlib.h>
#include "moongl.h"

#define TOSTR_(x) #x
#define TOSTR(x) TOSTR_(x)

/* Note: all the dynamic symbols of this library (should) start with 'moongl_' .
 * The only exception is the luaopen_moongl() function, which is searched for
 * with that name by Lua.
 * MoonGL's string references on the Lua registry also start with 'moongl_'.
 */

#include "wrangler.h"
#include "enum.h"
#include "bitfield.h"
#include "func.h"

/*--------------------------------------------------------------------------*
 | Redefinitions                                                            |
 *--------------------------------------------------------------------------*/

#if 0
/* .c */
#define  moongl_
#endif

/* utils.c */
#define checkoption_hint moongl_checkoption_hint
int checkoption_hint(lua_State *L, int arg, const char *def, const char *const lst[]);
#define isoption moongl_isoption
int isoption(lua_State *L, int arg, const char *const lst[]);
#define checkboolean moongl_checkboolean
GLboolean checkboolean(lua_State *L, int arg);
#define noprintf moongl_noprintf
int noprintf(const char *fmt, ...); 
#define notavailable moongl_notavailable
int notavailable(lua_State *L, ...);

/* init.c */
#define check_init_called moongl_check_init_called
int check_init_called(lua_State *L);

/* get.c */
#define getSizei moongl_getSizei
GLsizei getSizei(lua_State *L, GLenum pname);
#define getUint(L, pname) (GLuint)getSizei((L), (pname))
/* program.c */
#define programGet moongl_programGet
GLint programGet(lua_State *L, GLuint program, GLenum pname);


int luaopen_moongl(lua_State *L);
void moongl_open_init(lua_State *L);
void moongl_open_hint(lua_State *L);
void moongl_open_capabilities(lua_State *L);
void moongl_open_whole_framebuffer(lua_State *L);
void moongl_open_buffer(lua_State *L);
void moongl_open_vertex_array(lua_State *L);
void moongl_open_getvertex(lua_State *L);
void moongl_open_texture(lua_State *L);
void moongl_open_teximage(lua_State *L);
void moongl_open_shader(lua_State *L);
void moongl_open_subroutine(lua_State *L);
void moongl_open_program(lua_State *L);
void moongl_open_proginterface(lua_State *L);
void moongl_open_uniform(lua_State *L);
void moongl_open_getuniform(lua_State *L);
void moongl_open_pipeline(lua_State *L);
void moongl_open_framebuffer(lua_State *L);
void moongl_open_query(lua_State *L);
void moongl_open_renderbuffer(lua_State *L);
void moongl_open_sampler(lua_State *L);
void moongl_open_draw(lua_State *L);
void moongl_open_transform(lua_State *L);
void moongl_open_raster(lua_State *L);
void moongl_open_get(lua_State *L);
void moongl_open_getstring(lua_State *L);
void moongl_open_getintformat(lua_State *L);
void moongl_open_perfragment(lua_State *L);
void moongl_open_pixel(lua_State *L);
void moongl_open_debug(lua_State *L);
void moongl_open_sync(lua_State *L);
void moongl_open_nongl(lua_State *L);

/*------------------------------------------------------------------------------*
 | Debug and other utilities                                                    |
 *------------------------------------------------------------------------------*/

#define MOONGL_BOOLEAN 0 /* see uniform.c */

//#define checkoption checkoption_hint
#define checkoption luaL_checkoption

#define UNUSED noprintf /* to avoid warnings for unused parameters */

/* If this is printed, it denotes a suspect bug: */
#define UNEXPECTED_ERROR "unexpected error (%s, %d)", __FILE__, __LINE__
#define unexpected(L) luaL_error((L), UNEXPECTED_ERROR)

#define NARGS_ERROR "wrong number of arguments"
#define PERM_ERROR "operation not permitted"
/*#define OPERANDS_ERROR "invalid operands"*/
#define OPERANDS_ERROR "invalid operands (%s, %d)", __FILE__, __LINE__

#define NOT_AVAILABLE do { return luaL_error(L, "function not available"); } while(0)

#define NOT_IMPLEMENTED(func)               \
static int func(lua_State *L)               \
    { return luaL_error(L, "function "#func" is not implemented");  }

#define NOT_SUPPORTED(func)                 \
static int func(lua_State *L)               \
    { return luaL_error(L, "function "#func" is not supported"); return 0;  }

#if defined(DEBUG)

#define DBG printf

#define TR() do {                                           \
    printf("trace %s %d\n",__FILE__,__LINE__);              \
} while(0)

#define BK() do {                                           \
    printf("break %s %d\n",__FILE__,__LINE__);              \
    getchar();                                              \
} while(0)

#else 

#define DBG noprintf
#define TR()
#define BK()

#endif /* DEBUG */

#endif /* internalDEFINED */
