#ifndef __IO_THREAD_H__
#define __IO_THREAD_H__

#include "common/Thread.h"
#include "common/Msg.h"
#include "common/ObjPool.h"
#include "common/RoundQueue.h"
#include "Globals.h"

#include <event2/bufferevent.h>
#include <event2/buffer.h>


#define DEFAULT_IO_THREAD_LISTEN_PORT   80
#define MAX_CONNECT_FD                  20000


class Obj;
class IOThread: public Thread
{
    public:
        IOThread(int nPort=DEFAULT_IO_THREAD_LISTEN_PORT);
        ~IOThread();

        bool Init();
        void Run();
        void Stop();

        inline event_base* GetEventBase(){ return m_pEventBase; }

        inline bufferevent* GetBufferEvent(int nFD){ 
            if (nFD < 0 || nFD >= MAX_CONNECT_FD)
                return NULL;

            return m_pFD2BE[nFD]; 
        }

        void CloseConnect(int nFD);
        void SetBufferEvent(int nFD, struct bufferevent* pBE);

        inline int GetMaxFD() { return m_nMaxFD; }
        inline int GetMinFD() { return m_nMinFD; }

        //通知逻辑线程处理
        bool ModFixingNotice(int nHumanId, int nProtoId);

        //private:
        //通知逻辑线程处理
        bool DisconnectNotice(int nFD, char nReason);

    private:
        int m_nPort;
        struct event_base * m_pEventBase;
        struct evconnlistener * m_pListener;
        struct bufferevent* m_pFD2BE[MAX_CONNECT_FD];
        int m_nMaxFD;
        int m_nMinFD;
};


#endif //__IO_THREAD_H__

