#include "Utils.h"

#include <string.h>
#include <stdio.h>

MyTimer::MyTimer()
{
    memset(m_sName, 0, sizeof(m_sName));
    strcpy(m_sName, "UnKnown");
    m_nMicrosecondsCost = -1;
#if defined(__WINDOWS__)
    m_StartTime = 0;
    m_CurrentTime = 0;
#else
    m_TimeBegin.tv_sec = 0;
    m_TimeBegin.tv_usec = 0;
    m_TimeEnd.tv_sec = 0;
    m_TimeEnd.tv_usec = 0;
#endif
}

void MyTimer::Start(const char *sTimerName)
{
    if (sTimerName)
        strncpy(m_sName, sTimerName, sizeof(m_sName)); 

#if defined(__WINDOWS__)
    m_StartTime = GetTickCount() ;
#else 
    gettimeofday(&m_TimeBegin, NULL);  
#endif
}

void MyTimer::Stop()
{
#if defined(__WINDOWS__)
    m_CurrentTime = GetTickCount() ;
    m_nMicrosecondsCost = (m_CurrentTime - m_StartTime) * 1000;
#else 
    gettimeofday(&m_TimeEnd, NULL); 
    m_nMicrosecondsCost = (m_TimeEnd.tv_sec - m_TimeBegin.tv_sec) * 1000 * 1000 + 
        (m_TimeEnd.tv_usec - m_TimeBegin.tv_usec);
#endif
  

}

void MyTimer::Report()
{
    printf("%s: %d,%d,%d (s/ms/us)\n", 
            m_sName, 
            m_nMicrosecondsCost/1000000, 
            m_nMicrosecondsCost/1000, 
            m_nMicrosecondsCost%1000000); 
}


TID MyGetCurrentThreadID( )
{
#if defined(__WINDOWS__)
    return GetCurrentThreadId( ) ;
#else
    return pthread_self();
#endif
}

bool CheckFileLastModifyTime(const char *pszFile, long long &llLastModifyTime)
{
#ifdef __WINDOWS__
    HANDLE hFile=CreateFile(pszFile, 0, 0, 0, OPEN_EXISTING, 0, 0);
    if(hFile==INVALID_HANDLE_VALUE)
    {
        printf("CreateFile failed!\nErrorCode:%d\n",GetLastError());
        CloseHandle(hFile);
        return true;
    }
    long long llTmp;
    int nRet = GetFileTime(hFile, 0, 0, (LPFILETIME)&llTmp);
    if (!nRet)
    {
        printf("GetFileTime failed!\nErrorCode:%d\n",GetLastError());
        CloseHandle(hFile);
        return true;
    }

    CloseHandle(hFile);
    
    if (llLastModifyTime == llTmp)
    {
        return false;
    }
    llLastModifyTime = llTmp;
	return true;


#else
	struct stat st;
	int n = stat(pszFile, &st);
	if (n)
	{
		return true;
	}
	if (llLastModifyTime == st.st_mtime)
	{
		return false;
	}
	llLastModifyTime = st.st_mtime;
	return true;
#endif
}

#if defined(__WINDOWS__)
unsigned int CurrentTime( )
{
    return GetTickCount() ;
}

#else
class StartTime
{
   public:
       StartTime(){ gettimeofday(&t, NULL);}
       struct timeval t;
};
static StartTime startTime;
unsigned int CurrentTime( )
{
    struct timeval oTimeTemp;
    gettimeofday(&oTimeTemp, NULL); 
    return ((oTimeTemp.tv_sec-startTime.t.tv_sec) * 1000 + (oTimeTemp.tv_usec-startTime.t.tv_usec)/ 1000);
}
#endif

long long GetUSec()
{
    timeval tv;
    evutil_gettimeofday(&tv, 0);
    return tv.tv_sec * 1000000LL + tv.tv_usec;
}

