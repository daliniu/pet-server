
#ifndef __LUA_EXTRA_H_
#define __LUA_EXTRA_H_

#if defined(_USRDLL)
    #define LUA_EXTENSIONS_DLL     __declspec(dllexport)
#else         /* use a DLL library */
    #define LUA_EXTENSIONS_DLL
#endif


#include "lauxlib.h"

void LUA_EXTENSIONS_DLL luaopen_socket(lua_State *L);
    

#endif /* __LUA_EXTRA_H_ */
