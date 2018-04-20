#ifndef __COMMON_LUA_UTILS_H__
#define __COMMON_LUA_UTILS_H__
#include "Type.h"
#include "Utils.h"

struct lua_State;

//当前时间计数值，起始值根据系统不同有区别
//返回的值为：微妙单位的时间值
int _CurrentTime(lua_State* pL);

int _USec(lua_State* pL);

int luaErrorHandler(lua_State *L);

int _print(lua_State *pL);

int PRINT(lua_State* pL);

int LuaRef(lua_State* pL, const char* pLuaFuncName);

int _GBK2UTF8(lua_State* pL);

int _md5(lua_State* pL);

int _GetIP(lua_State* pL);
#endif //__COMMON_LUA_UTILS_H__

