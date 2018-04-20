#include "Thread.h"
#include <stdio.h>

Thread::Thread () 
{
	m_TID		= 0 ;
	m_Status	= Thread::READY ;

#if defined(__WINDOWS__)
	m_hThread = NULL ;
#endif
}


void Thread::Start () 
{ 
	if ( m_Status != Thread::READY )
		return ;

#if defined(__WINDOWS__)
	m_hThread = ::CreateThread( NULL, 0, MyThreadProcess , this, 0, &m_TID ) ;

#else
	pthread_create( &m_TID, NULL , MyThreadProcess , this );
#endif
}


void Thread::Exit( void * retval )
{
#if defined(__WINDOWS__)
    ::CloseHandle( m_hThread ) ; 
#else
    pthread_join(m_TID, &retval );
#endif
    m_Status = Thread::EXIT;
}

#if defined(__WINDOWS__)
DWORD WINAPI MyThreadProcess(  void* derivedThread )
#else
void * MyThreadProcess ( void * derivedThread )
#endif
{
    Thread * thread = (Thread *)derivedThread;
    if( thread==NULL )
        return 0;

    // set thread's status to "RUNNING"
    thread->SetStatus(Thread::RUNNING);

    // here - polymorphism used. (derived::run() called.)
    thread->Run();

    int nRet = 0;
	thread->Exit(&nRet);
    // set thread's status to "EXIT"
    thread->SetStatus(Thread::EXIT);

    return 0;	// avoid compiler's warning
}
