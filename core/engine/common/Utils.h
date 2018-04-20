#ifndef __COMMON_UTILS_H__
#define __COMMON_UTILS_H__
#ifndef __WINDOWS__
#include <sys/time.h>
#include <sys/stat.h>
#else
#include <Winsock2.h>
#endif

#include "Type.h"
#include <event2/event.h>
#include <event2/event_struct.h>
#include <assert.h>
class MyTimer
{
    public:
        MyTimer();
        ~MyTimer(){};

        void Start(const char *sTimerName);
        void Stop();
        void Report();

    private:
        char m_sName[60];
        int m_nMicrosecondsCost;

#if defined(__WINDOWS__)
        int			m_StartTime ;
        int			m_CurrentTime ;
#else
        struct timeval m_TimeBegin;
        struct timeval m_TimeEnd;
#endif
};


#if defined(__WINDOWS__)
class MyLock
{
	CRITICAL_SECTION m_Lock ;
public :
	MyLock( ){ InitializeCriticalSection(&m_Lock); } ;
	~MyLock( ){ DeleteCriticalSection(&m_Lock); } ;
	void	Lock( ){ EnterCriticalSection(&m_Lock); } ;
	void	Unlock( ){ LeaveCriticalSection(&m_Lock); } ;
};
#else
#include <pthread.h>
class MyLock
{
	pthread_mutex_t 	m_Mutex; 
public :
	MyLock( ){ pthread_mutex_init( &m_Mutex , NULL );} ;
	~MyLock( ){ pthread_mutex_destroy( &m_Mutex) ; } ;
	void	Lock( ){ pthread_mutex_lock(&m_Mutex); } ;
	void	Unlock( ){ pthread_mutex_unlock(&m_Mutex); } ;
};
#endif

extern TID			MyGetCurrentThreadID( ) ;

#define SAFE_DELETE(x)  if( (x)!=NULL ) { delete (x); (x)=NULL; }
#define SAFE_DELETE_ARRAY(x)    if( (x)!=NULL ) { delete[] (x); (x)=NULL; }

bool CheckFileLastModifyTime(const char *pszFile, long long &llLastModifyTime);


typedef void (*callback)(evutil_socket_t, short, void *);
class EventTimer
{
    public:
        EventTimer(struct event_base *base, int ms, callback cb, void *arg){
            event_assign(&m_oTimerEvent, base, -1, EV_PERSIST, cb, arg);
	        evutil_timerclear(&m_oTimeVal);
            m_oTimeVal.tv_sec = ms/1000;
	        m_oTimeVal.tv_usec = (ms%1000) * 1000;
	        event_add(&m_oTimerEvent, &m_oTimeVal);
        }

    private:
	    struct event m_oTimerEvent;
        struct timeval m_oTimeVal;
};

#ifndef mmax
#define mmax(a,b)            (((a) > (b)) ? (a) : (b))
#endif
#ifndef mmin
#define mmin(a,b)            (((a) < (b)) ? (a) : (b))
#endif

//当前时间计数值，起始值根据系统不同有区别
//返回的值为：毫妙单位的时间值
unsigned int CurrentTime( );

long long GetUSec();

struct CheckDealTime
{
    long long m_nInterval;
    long long m_nTimeBegin;
    char szMsg[512];
    CheckDealTime(int nInterval, const char *pFormat, ...):m_nInterval(nInterval), m_nTimeBegin(GetUSec())
    {
        va_list args;
	    va_start (args, pFormat);
	    tsnprintf(szMsg, sizeof(szMsg) - 1, pFormat, args);
	    va_end (args);
    }
    ~CheckDealTime()
    {
        long long nDif = GetUSec() - m_nTimeBegin;
#ifdef __WINDOWS__
        if (nDif > m_nInterval && nDif > 16000)
        {
            //printf("process time = %lld us, ", nDif); // reyes 暂时屏蔽
            //puts(szMsg);
        }
#else
        if (nDif > m_nInterval)
        {
            //printf("process time = %lld us, ", nDif); // reyes 暂时屏蔽
            //puts(szMsg);
        }
#endif
    }
};
#define CHECK_DEAL_TIME(...) CheckDealTime oCheckDealTime(__VA_ARGS__)

#endif //__COMMON_UTILS_H__
