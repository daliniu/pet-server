#ifndef __HTTP_THREAD_H__
#define __HTTP_THREAD_H__

#include "common/Thread.h"
#include <event2/buffer.h>

class HttpThread: public Thread
{
    public:
        HttpThread(int nPort);
        ~HttpThread();

        bool Init();
        void Run();
        void Stop();

        inline event_base* GetEventBase(){ return m_pEventBase; }

    private:
        int m_nPort;
        struct event_base * m_pEventBase;
        struct evhttp * m_pEventHttp;
};

#endif //__HTTP_THREAD_H__

