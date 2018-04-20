#include "LogManager.h"

bool LogManager::Init()
{
    //engine.log
    if (!m_oEngineLog.Init("./logs/engine", 0, NULL)) { 
        fprintf(stderr, "[Error] Init ./log/engine.log failed\n");
        return false;
    }

    //game.log
    if (!m_oGameLog.Init("./logs/game", 300, NULL)) { 
        fprintf(stderr, "[Error] Init ./log/game.log failed\n");
        return false;
    }

    //http.log
    if (!m_oHttpLog.Init("./logs/http", 0, NULL)) { 
        fprintf(stderr, "[Error] Init ./log/http.log failed\n");
        return false;
    }

    //error.log
    if (!m_oErrorLog.Init("./logs/error", 0, NULL)) {
        fprintf(stderr, "[Error] Init ./logs/error.log failed\n");
        return false;
    }

    return true;
}

void LogManager::FlushAll()
{
    m_oEngineLog.FlushLog();
    m_oGameLog.FlushLog();
    m_oHttpLog.FlushLog();
    m_oErrorLog.FlushLog();
}

void LogManager::WriteEngineLog(const char *pLog)
{
    m_oEngineLog.WriteLog(pLog);
}

void LogManager::WriteGameLog(const char *pLog)
{
    m_oGameLog.WriteLog(pLog);
}

void LogManager::WriteHttpLog(const char *pLog)
{
    m_oHttpLog.WriteLog(pLog);
}

void LogManager::WriteErrorLog(const char *pLog)
{
    m_oErrorLog.WriteLog(pLog);
}

int _WriteGameLog(lua_State* pL)
{
    const char* pStr = lua_tostring(pL, 1);
    g_oLogManager.WriteGameLog(pStr);
    return 0;
}

int _WriteErrorLog(lua_State* pL)
{
    const char* pStr = lua_tostring(pL, 1);
    g_oLogManager.WriteErrorLog(pStr);
    return 0;
}

