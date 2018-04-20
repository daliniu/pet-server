#ifndef __LOG_H__
#define __LOG_H__

#include "Type.h"
#include <string.h>
#include <event2/util.h>
#include <stdio.h>

#define DEFAULT_LOG_CACHE_SIZE  1024*1024*5 // ��־�����С
#define LOG_MSG_BUF_LEN         2048        // ÿ����־����ֽ�
#define LOG_FLUSH_PERIOD        3000        // 3��ˢһ����־

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

    //�ⲿ��¶��дlog�ӿڣ����ﲻ��ֱ�Ӷ�д�ļ�����д��������
    void            WriteLog(const char* pMsg);

    //����־�ڴ�����д���ļ�
    void			FlushLog() ;

private:
    //ȡ�ñ�����־���ļ�����
    void			GetLogName(char* szName) ;

    void            DoOpenLogFile(char* szName);

private :
    char*			m_pLogCache;	                //��־�ڴ���
    int				m_LogPos;		                //��־��ǰ��Ч����λ��
    char            m_aryLogPath[MAX_PATH];         //��־����·��
    int             m_nSeperateTime;                //���ּ��ʱ��  ��λs
    int             m_nLastSeperateSN;              //��־�������к�

    char            m_aryHead[MAX_PATH];            // ��־ͷ
    FILE*           m_pF;                           // �Ѵ��ļ��ľ������
    char            m_aryOpenFilePath[MAX_PATH];    // �Ѵ��ļ���·��
};

// ��ʱˢ��־
void LogTimerCB(evutil_socket_t nFD, short nEvent, void *pArg);
int PrintfLog(lua_State *pL);

#endif //__LOG_H__

