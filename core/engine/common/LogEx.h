#ifndef __LOG_H__
#define __LOG_H__

#include "Type.h"
#include <string.h>
#include <event2/util.h>
#include <stdio.h>

#define DEFAULT_LOG_CACHE_SIZE  1024*1024*5 // 日志缓存大小
#define LOG_MSG_BUF_LEN         2048        // 每条日志最大字节
#define LOG_FLUSH_PERIOD        3000        // 3秒刷一次日志

#ifndef MAX_PATH
#define MAX_PATH  256
#endif

struct lua_State;

class Log
{
public:
    Log( ) ;
    ~Log( ) ;

    bool			Init(const char * pFilePath, int nSeperateTime, const char * pHeader) ;

    //外部暴露的写log接口，这里不是直接读写文件，先写到缓存中
    void            WriteLog(const char* pMsg);

    //将日志内存数据写入文件
    void			FlushLog() ;

private:
    //取得保存日志的文件名称
    void			GetLogName(char* szName) ;

    void            DoOpenLogFile(char* szName);

private :
    char*			m_pLogCache;	                //日志内存区
    int				m_LogPos;		                //日志当前有效数据位置
    char            m_aryLogPath[MAX_PATH];         //日志保存路径
    int             m_nSeperateTime;                //划分间隔时间  单位s
    int             m_nLastSeperateSN;              //日志划分序列号

    char            m_aryHead[MAX_PATH];            // 日志头
    FILE*           m_pF;                           // 已打开文件的句柄缓存
    char            m_aryOpenFilePath[MAX_PATH];    // 已打开文件的路径
};

// 定时刷日志
void LogTimerCB(evutil_socket_t nFD, short nEvent, void *pArg);
int PrintfLog(lua_State *pL);

#endif //__LOG_H__

