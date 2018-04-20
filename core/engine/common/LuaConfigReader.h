#ifndef _LUA_CONFIG_READER_
#define _LUA_CONFIG_READER_
class lua_State;

#include <cassert>
#define CREATE(FILENAME) \
	LuaConfigReader m_objReader; \
	if (!m_objReader.Create(FILENAME)) \
	{ \
		assert(0); \
		return false; \
	}

#define GETINT(DST, SRC, ...) \
	{ \
		int _n = 0; \
		if (!m_objReader.GetINT(_n, SRC, __VA_ARGS__)) \
		{ \
			printf("%s not in %s\n", SRC, m_objReader.GetFileName()); \
			assert(0); \
			return false; \
		} \
		DST = _n; \
	}

#define GETSTRING(DST, SRC, ...) \
	{ \
		if (!m_objReader.GetSTRING(DST, sizeof(DST) / sizeof(*DST), SRC, __VA_ARGS__)) \
		{ \
			printf("%s not in %s\n", SRC, m_objReader.GetFileName()); \
			assert(0); \
			return false; \
		} \
	}

class LuaConfigReader
{
public:
	LuaConfigReader();
	~LuaConfigReader();
	const char *GetFileName();
	bool Create(const char *pFileName);
	bool Close();
	bool GetINT(int &n, const char *pFormat, ...);
	bool GetSTRING(char *pBuf, const int nCap, const char *pFormat, ...);
private:
	char m_aryFileName[64];
	lua_State *m_L;
};

#endif

