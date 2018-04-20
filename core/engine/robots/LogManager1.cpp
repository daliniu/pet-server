
#include "LogManager.h"

LogManager g_oLogManager;

LogManager::LogManager()
{
    m_oLog.Init("./log/robot", false, "");
}

LogManager::~LogManager()
{

}

void LogManager::WriteLog(const char * pStr)
{
    m_Lock.Lock();

    m_oLog.WriteLog(pStr);
    m_oLog.FlushLog();

    m_Lock.Unlock();
}

int _WriteLog(lua_State* pL)
{
    const char* pStr = lua_tostring(pL, 1);

    g_oLogManager.WriteLog(pStr);

    return 0;
}

