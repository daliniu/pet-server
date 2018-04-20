#ifndef __THREAD_H__
#define __THREAD_H__

#include "Type.h"

class Thread 
{
public :

    enum ThreadStatus 
    {
        READY ,		// 当前线程处于准备状态
        RUNNING ,	// 处于运行状态
        EXITING ,	// 线程正在退出
        EXIT		// 已经退出 
    };

	Thread ( ) ;
	virtual ~Thread () {};

	void Start () ;
	void Stop() {} ;
	virtual void Run () {};

	void Exit(void * retval = NULL );

	TID GetTID () { return m_TID; }
	ThreadStatus GetStatus () { return m_Status; }
	void SetStatus ( ThreadStatus status ) { m_Status = status; }
	
private :
	TID m_TID;
	ThreadStatus m_Status;

#if defined(__WINDOWS__)
	HANDLE m_hThread ;
#endif

};

#if defined(__WINDOWS__)
DWORD WINAPI MyThreadProcess(  void* derivedThread ) ;
#else
void * MyThreadProcess ( void * derivedThread ) ;
#endif

#endif //__THREAD_H__
