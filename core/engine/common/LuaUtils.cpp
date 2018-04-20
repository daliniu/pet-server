extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}
#ifndef __WINDOWS__
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#else
typedef int socklen_t;
#endif
#include "LuaUtils.h"
#include <string.h>
#include <wchar.h>
#include <locale.h>
#include <stdlib.h>
#include "md5.h"
int _CurrentTime(lua_State* pL)
{
    lua_pushnumber(pL, CurrentTime());
    return 1;
}

int _USec(lua_State* pL)
{
	lua_pushnumber(pL, GetUSec());
	return 1;
}

int luaErrorHandler(lua_State *L) {
    //lua_getfield(L, LUA_GLOBALSINDEX, "debug");
	//by tanjie 20150210
	lua_pushglobaltable(L);
	lua_getfield(L,-1,"debug");
	lua_remove(L,-2);


    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return 1;
    }
    lua_getfield(L, -1, "traceback");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return 1;
    }
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 2);
    lua_call(L, 2, 1);
    return 1;
}

int PRINT(lua_State* pL)
{
    const char* pStr = lua_tostring(pL, 1);
    printf("%s", pStr);
    return 0;
}

int _print(lua_State *pL)
{
    int nArgc = (int)lua_gettop(pL);
    char szBuf[2048] = {};
    int nBufLen = 0;
    for (int i = 0; i < nArgc; ++i)
    {
        switch(lua_type(pL, i + 1))
        {
#define MY_STRCPY(STR) strncpy(szBuf + nBufLen, STR, sizeof(szBuf) - nBufLen); nBufLen += sizeof(STR);
case LUA_TNIL:
    MY_STRCPY("(type):nil");
    break;
case LUA_TNUMBER:
    {
        double d = lua_tonumber(pL, i + 1);
        if (d - (int)d < 1e-8)
        {
            nBufLen += tsnprintf(szBuf + nBufLen, sizeof(szBuf) - 1 - nBufLen, "%d", (int)d);
        }
        else
        {
            nBufLen += tsnprintf(szBuf + nBufLen, sizeof(szBuf) - 1 - nBufLen, "%lf", d);
        }
    }
    break;
case LUA_TBOOLEAN:
    {
        if (lua_toboolean(pL, i + 1))
        {
            MY_STRCPY("true");
        }
        else
        {
            MY_STRCPY("false");
        }
    }
    break;
case LUA_TSTRING:
    {
        size_t nLen = 0;
        const char *p = lua_tolstring(pL, i + 1, &nLen);
        strncpy(szBuf + nBufLen, p, sizeof(szBuf) - 1 - nBufLen);
        nBufLen += nLen;
    }
    break;
case LUA_TTABLE:
    MY_STRCPY("(type):table");
    break;
case LUA_TFUNCTION:
    MY_STRCPY("(type):function");
    break;
case LUA_TUSERDATA:
    MY_STRCPY("(type):userdata");
    break;
case LUA_TTHREAD:
    MY_STRCPY("(type):thread");
    break;
case LUA_TLIGHTUSERDATA:
    MY_STRCPY("(type):lightuserdata");
    break;
default:
    break;
#undef MY_STRCPY
        }
    }
    szBuf[nBufLen] = 0;
    puts(szBuf);
    return 0;
}

int LuaRef(lua_State* pL, const char* pLuaFuncName)
{
    lua_getglobal(pL, pLuaFuncName);
    int r = luaL_ref(pL, LUA_REGISTRYINDEX);
    return r;
}

int _GBK2UTF8(lua_State* pL)
{
    const char* pStr = lua_tostring(pL, 1); 
    if (pStr == NULL || strlen(pStr) > 100)
    {
        assert(false);
        return 0;
    }

    static char aryOut[300];
    static wchar_t aryUtf8[300];

    memset(aryOut, 0, 300);
    memset(aryUtf8, 0, 600);

#if defined(__WINDOWS__)
    int len=MultiByteToWideChar(CP_ACP, 0, pStr, -1, NULL,0);
    MultiByteToWideChar(CP_ACP, 0, pStr, -1, aryUtf8, len);

    len = WideCharToMultiByte(CP_UTF8, 0, aryUtf8, -1, NULL, 0, NULL, NULL); 
    WideCharToMultiByte (CP_UTF8, 0, aryUtf8, -1, aryOut, len, NULL,NULL);
#else
    setlocale(LC_ALL,"zh_CN.gbk"); 
    int len = mbstowcs(aryUtf8, pStr, 299);
    setlocale(LC_ALL, "zh_CN.utf8"); 
    len = wcstombs(aryOut, aryUtf8, 599);
#endif

    lua_pushstring(pL, aryOut);

    return 1;
}

int _md5(lua_State* pL)
{
    const char* pStr = luaL_checkstring(pL,1);
    MD5 context;
    context.update((unsigned char*)pStr, (unsigned int)strlen(pStr));
    context.finalize(); 
    char md5[90] = {0}; 
    context.hex_digest_lowcase(md5, sizeof(md5));
    lua_pushstring(pL, md5); 
    return 1;
}

int _GetIP(lua_State* pL)
{
	int nFD = luaL_checkinteger(pL, 1);
	struct sockaddr_in addr;
	socklen_t nAddrLen = sizeof(addr);
	getpeername(nFD,(struct sockaddr*)&addr, &nAddrLen);
	static char strIP[24]; 
	strcpy(strIP, inet_ntoa(addr.sin_addr));
	lua_pushstring(pL,strIP);
	return 1;
}
