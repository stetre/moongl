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

/*------------------------------------------------------------------------------*
 | malloc() wrappers                                                            |
 *------------------------------------------------------------------------------*/

void *Malloc(lua_State *L, size_t size)
    {
    void *ptr;
    if(size==0)
        { luaL_error(L, "malloc request with size = 0"); return NULL; }
    if((ptr = malloc(size)) == NULL)
        { luaL_error(L, "cannot allocate memory"); return NULL; }
    return ptr;
    }

void* Malloc2(lua_State *L, size_t size, void **ptr2, size_t size2)
    {
    void *ptr;
    if((size==0) || (size2 == 0))
        { luaL_error(L, "malloc request with size = 0"); return NULL; }
    if((ptr = malloc(size)) == NULL)
        { luaL_error(L, "cannot allocate memory"); return NULL; }
    if((*ptr2 = malloc(size2)) == NULL)
        { Free(L, ptr); luaL_error(L, "cannot allocate memory"); return NULL; }
    return ptr;
    }

void* Malloc3(lua_State *L, size_t size, void **ptr2, size_t size2, void **ptr3, size_t size3)
    {
    void *ptr;
    if((size==0) || (size2 == 0) || (size3 == 0))
        { luaL_error(L, "malloc request with size = 0"); return NULL; }
    if((ptr = malloc(size)) == NULL)
        { luaL_error(L, "cannot allocate memory"); return NULL; }
    if((*ptr2 = malloc(size2)) == NULL)
        { 
        Free(L, ptr); 
        luaL_error(L, "cannot allocate memory"); return NULL; 
        }
    if((*ptr3 = malloc(size3)) == NULL)
        { 
        Free(L, ptr); 
        Free(L, *ptr2); 
        luaL_error(L, "cannot allocate memory"); return NULL; 
        }
    return ptr;
    }


void Free(lua_State *L, void *ptr)
    {
    (void)L;
    if(ptr) free(ptr);
    }

/*------------------------------------------------------------------------------*
 | glGetError()                                                                 |
 *------------------------------------------------------------------------------*/


int CheckError(lua_State *L)
    {
    int rc = glGetError();
    if(rc != 0) return luaL_error((L), (char*)gluErrorString(rc));
    return 0;
    }

void *CheckErrorp(lua_State *L)
/* Same as CheckError() but returns a pointer instead */
    {
    CheckError(L);
    return NULL;
    }

int CheckErrorFree(lua_State *L, void *ptr)
/* On error, free ptr before raising the error */
    {
    int rc = glGetError();
    if(rc != 0) 
        {
        Free(L, ptr);
        return luaL_error(L, (char*)gluErrorString(rc));
        }
    return 0;
    }

int CheckErrorFree2(lua_State *L, void *ptr1, void *ptr2)
/* On error, free ptr1 and ptr2 before raising the error */
    {
    int rc = glGetError();
    if(rc != 0) 
        {
        Free(L, ptr1);
        Free(L, ptr2);
        return luaL_error(L, (char*)gluErrorString(rc));
        }
    return 0;
    }

int CheckErrorFree3(lua_State *L, void *ptr1, void *ptr2, void *ptr3)
    {
    int rc = glGetError();
    if(rc != 0) 
        {
        Free(L, ptr1);
        Free(L, ptr2);
        Free(L, ptr3);
        return luaL_error(L, (char*)gluErrorString(rc));
        }
    return 0;
    }

