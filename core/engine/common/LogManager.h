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
    Log m_oGameLog;             // ����lua����Ӫ��־
    Log m_oHttpLog;             // Http������־
    Log m_oEngineLog;           // Http������־
    Log m_oErrorLog;            // ����lua�㱨����־
};

extern LogManager g_oLogManager; 
extern int _WriteGameLog(lua_State* pL);
extern int _WriteErrorLog(lua_State* pL);

#endif //__LOGIC_LOG_MANAGER_H__

