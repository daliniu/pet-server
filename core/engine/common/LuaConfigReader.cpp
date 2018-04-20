#include "LuaConfigReader.h"
#include <cstring>

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

LuaConfigReader::LuaConfigReader()
{
	*m_aryFileName = 0;
	m_L = 0;
}

LuaConfigReader::~LuaConfigReader()
{
	Close();
}

const char *LuaConfigReader::GetFileName()
{
	return m_aryFileName;
}

bool LuaConfigReader::Create(const char *pFileName)
{
	Close();
	//m_L = lua_open();
	m_L =  luaL_newstate();
	if (!m_L)
	{
		return false;
	}
	luaL_openlibs(m_L);
	if (luaL_dofile(m_L, pFileName))
	{
		puts(luaL_checkstring(m_L, -1));
		Close();
		return false;
	}
	strncpy(m_aryFileName, pFileName, sizeof(m_aryFileName));
	return true;
}

bool LuaConfigReader::Close()
{
	if (m_L)
	{
		*m_aryFileName = 0;
		lua_close(m_L);
		m_L = 0;
		return true;
	}
	return false;
}



bool LuaConfigReader::GetINT(int &n, const char *pFormat, ...)
{
	va_list args;
	va_start (args, pFormat);
	char aryBufA[512] = {};
	vsnprintf(aryBufA, sizeof(aryBufA) - 1, pFormat, args);
	va_end (args);
	char aryBufB[512] = "return ";
	strncat(aryBufB, aryBufA, sizeof(aryBufB));
	int nTopOld = lua_gettop(m_L);
	if (luaL_dostring(m_L, aryBufB))
	{
		puts(luaL_checkstring(m_L, -1));
		lua_settop(m_L, nTopOld);
		return false;
	}

	if (!lua_isnumber(m_L, -1))
	{
		lua_settop(m_L, nTopOld);
		return false;
	}
	n = (int)luaL_checknumber(m_L, -1);
	lua_settop(m_L, nTopOld);
	return true;
}

bool LuaConfigReader::GetSTRING(char *pBuf, const int nCap, const char *pFormat, ...)
{
	va_list args;
	va_start (args, pFormat);
	char aryBufA[512] = {};
	vsnprintf(aryBufA, sizeof(aryBufA) - 1, pFormat, args);
	va_end (args);
	char aryBufB[512] = "return ";
	strncat(aryBufB, aryBufA, sizeof(aryBufB));
	int nTopOld = lua_gettop(m_L);
	if (luaL_dostring(m_L, aryBufB))
	{
		puts(luaL_checkstring(m_L, -1));
		lua_settop(m_L, nTopOld);
		return false;
	}

	if (!lua_isstring(m_L, -1))
	{
		lua_settop(m_L, nTopOld);
		return false;
	}
	const char *pRet = luaL_checkstring(m_L, -1);
	if (!pRet)
	{
		lua_settop(m_L, nTopOld);
		return false;
	}
	strncpy(pBuf, pRet, nCap);
	lua_settop(m_L, nTopOld);
	return true;
}

