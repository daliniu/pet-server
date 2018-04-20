
#ifndef __LOG_MANAGER_H__
#define __LOG_MANAGER_H__

#include "../common/LogEx.h"
#include "../common/Utils.h"
extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}
class LogManager
{
public:
    LogManager();
    virtual ~LogManager();

    void WriteLog(const char * pStr);

private:
    Log             m_oLog;
    MyLock          m_Lock;
};

extern LogManager g_oLogManager;

extern int _WriteLog(lua_State* pL);

#endif //__LOG_MANAGER_H__

