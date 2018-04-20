#ifndef __LOGIC_LOG_MANAGER_H__
#define __LOGIC_LOG_MANAGER_H__

#include <map>
#include "LogEx.h"
extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

class LogManager
{
public:
    bool Init();
    void FlushAll();
    void WriteEngineLog(const char * pLog);
    void WriteGameLog(const char * pLog);
    void WriteHttpLog(const char * pLog);
    void WriteErrorLog(const char * pLog);

private:
    Log m_oGameLog;             // 程序lua层运营日志
    Log m_oHttpLog;             // Http请求日志
    Log m_oEngineLog;           // Http请求日志
    Log m_oErrorLog;            // 程序lua层报错日志
};

extern LogManager g_oLogManager; 
extern int _WriteGameLog(lua_State* pL);
extern int _WriteErrorLog(lua_State* pL);

#endif //__LOGIC_LOG_MANAGER_H__

