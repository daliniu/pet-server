#include "LogEx.h"
#include "Utils.h"

#include <stdarg.h>
#include <string.h>
#include <time.h>

extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

Log::Log( )
{
    m_pLogCache = NULL ;
    m_LogPos = 0 ;
    m_nSeperateTime = 0;
    m_nLastSeperateSN = 0;
    memset(m_aryLogPath, 0, MAX_PATH);
    memset(m_aryHead, 0, MAX_PATH);
    memset(m_aryOpenFilePath, 0, MAX_PATH);
    m_pF = NULL;
}

Log::~Log( )
{
    FlushLog();
    if (m_pF)
    {
        fclose(m_pF) ;
        m_pF = NULL;
    }

    SAFE_DELETE(m_pLogCache);
    m_LogPos = 0;
}

bool Log::Init(const char * pFilePath, int nSeperateTime, const char * pHeader)
{
    if (NULL == pFilePath) return false;
    if (strlen(pFilePath) >= MAX_PATH) return false;
    if (nSeperateTime < 0){
        fprintf(stderr, "[error] invalid seperate time for %s\n", pFilePath);
        return false;
    }

    m_nSeperateTime = nSeperateTime;
    if (m_nSeperateTime != 0){
        time_t ts;
        time(&ts);
        m_nLastSeperateSN = ts/m_nSeperateTime; 
    }

    m_pLogCache = new char[DEFAULT_LOG_CACHE_SIZE] ;
    if( m_pLogCache == NULL )
    {
        return false ;
    }
    m_LogPos = 0 ;

    if (m_nSeperateTime != 0){
        strncpy(m_aryLogPath, pFilePath, MAX_PATH - 1);
    }else{
        time_t ts;
        time(&ts);
        struct tm * pTmTime = localtime(&ts);
        char aryTime[32] = {0};
        strftime(aryTime, sizeof(aryTime), "%Y%m%d", pTmTime);
        tsnprintf(m_aryLogPath, MAX_PATH - 1, "%s_%s", pFilePath, aryTime) ;
    }

    if (pHeader) 
    {
        strncpy(m_aryHead, pHeader, MAX_PATH - 1);
    }

    return true ;
}


void Log::WriteLog(const char* pMsg )
{
    if (pMsg == NULL) 
    {
        assert(false);
        return;
    }

    if (strlen(m_aryLogPath) == 0)
    {
        assert(false);
        return;
    }

    char aryInput[2048] = {0};
    char aryTime[MAX_PATH] = {0};
    char aryLog[2048] = {0};
	/**
	//@modify by luowei,考虑到pMsg中可能含有特殊字符,不再使用变长参数 
    va_list argptr;
    va_start(argptr, pMsg);
    tvsnprintf(aryInput, sizeof(aryInput), pMsg, argptr);
    va_end(argptr);
	**/
	tsnprintf(aryInput, sizeof(aryInput), "%s" ,pMsg);

    time_t ts;
    time(&ts);

    struct tm * pTmTime = localtime(&ts);
    strftime(aryTime, sizeof(aryTime), "%Y-%m-%d %H:%M:%S", pTmTime);

    tsnprintf(aryLog, LOG_MSG_BUF_LEN, "[%s] %s\n", aryTime, aryInput);
    int iLen = strlen(aryLog);
    if (iLen >= LOG_MSG_BUF_LEN) return;

    memcpy( m_pLogCache + m_LogPos, aryLog, iLen ) ;
    m_LogPos += iLen ;

    if(m_LogPos > (DEFAULT_LOG_CACHE_SIZE*2)/3 ||(m_nSeperateTime > 0 && ts/m_nSeperateTime != m_nLastSeperateSN)){
        FlushLog() ;
    }
}

void Log::FlushLog()
{
    if (m_LogPos == 0) return;
    char szName[MAX_PATH] = {0};
    GetLogName( szName );
    DoOpenLogFile(szName);
    time_t ts;
    time(&ts);
    if (m_nSeperateTime > 0){
        m_nLastSeperateSN = ts/m_nSeperateTime;
    }

    try
    {
        if (m_pF)
        {
            if (ftell(m_pF) == 0 && strlen(m_aryHead) > 0)
            {
                fwrite(m_aryHead, 1, strlen(m_aryHead), m_pF);
            }

            fwrite(m_pLogCache, 1, m_LogPos, m_pF);
            fflush(m_pF);

        }else{
            fprintf(stderr, "flush log failed, log file not opened: %s\n", szName);
        }

        m_LogPos = 0 ;
    }
    catch(...)
    {
        fprintf(stderr, "flush log failed, exception happened\n");
    }
}

void Log::DoOpenLogFile(char* szName)
{
    //if (access(szName, W_OK) != 0){
    //   memset(m_aryOpenFilePath, 0, MAX_PATH);
    //}

    if (m_pF && strcmp(szName, m_aryOpenFilePath) == 0) return; // 文件已经打开了 不需要打开
    if (m_pF)
    {
        // 已经有缓存文件句柄了 先关闭老文件
        fclose(m_pF) ;
        m_pF = NULL;
        memset(m_aryOpenFilePath, 0, MAX_PATH);
    }

    try
    {
        m_pF = fopen( szName, "ab" ) ;
        if (m_pF)
        {
            fseek(m_pF, 0, SEEK_END);
            strncpy(m_aryOpenFilePath, szName, MAX_PATH - 1);
        }
        else
        {
            assert(false);
            fprintf(stderr, "open file %s failed\n", szName);
        }
    }
    catch(...)
    {
        fprintf(stderr, "open file %s failed\n", szName);
    }
}

void Log::GetLogName(char* szName)
{
    if (m_nSeperateTime > 0) 
    {
        char aryTime[MAX_PATH] = {0};
        time_t ts;
        time(&ts);
        ts = (ts/m_nSeperateTime) * m_nSeperateTime;
        struct tm * pTmTime = localtime(&ts);
        strftime(aryTime, sizeof(aryTime), "%Y%m%d_%H%M", pTmTime);
        tsnprintf( szName, MAX_PATH - 1, "%s_%s.log", m_aryLogPath, aryTime) ;
    }
    else
    {
        tsnprintf( szName, MAX_PATH - 1, "%s.log", m_aryLogPath) ;
    }
}


int PrintfLog(lua_State *pL, Log* pLog)
{
	const char *pFmt = luaL_checkstring(pL, 1);
	char szBuf[8192] = {};
	int nBufLen = 0;
	int nTBLen = 1;
	for (const char *p = pFmt; *p; ++p)
	{
		if (*p != '%')
		{
			szBuf[nBufLen++] = *p;
			continue;
		}
		++p;
		if (!*p)
		{
			break;
		}
		if (*p == 'd')
		{
			lua_rawgeti(pL, -1, nTBLen++);
			int n = luaL_checkinteger(pL, -1);
			nBufLen += tsnprintf(szBuf + nBufLen, sizeof(szBuf) - nBufLen - 1, "%d", n);
			lua_pop(pL, 1);
			continue;
		}
		if (*p == 's')
		{
			lua_rawgeti(pL, -1, nTBLen++);
			int nLen = luaL_checkinteger(pL, -1);
			if (nLen > (int)sizeof(szBuf) - nBufLen - 1)
			{
				return 0;
			}
			lua_pop(pL, 1);
			lua_rawgeti(pL, -1, nTBLen++);
			for (int i = 0; i < nLen; ++i)
			{
				lua_rawgeti(pL, -1, i + 1);
				szBuf[nBufLen++] = (char)luaL_checknumber(pL, -1);
				lua_pop(pL, 1);
			}
			lua_pop(pL, 1);
			continue;
		}
	}
	szBuf[nBufLen] = 0;
	puts(szBuf);
	pLog->WriteLog(szBuf);
	return 0;
}


void LogTimerCB(evutil_socket_t nFD, short nEvent, void *pArg)
{
    Log * pLog = (Log *)pArg;
    if (pLog) pLog->FlushLog();
}


