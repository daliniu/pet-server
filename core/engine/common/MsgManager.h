#ifndef __LUA_MSG_MANAGER_H__
#define __LUA_MSG_MANAGER_H__

#include "Msg.h"
#include "ObjPool.h"
#include "RoundQueue.h"


extern ObjPool<Msg> * g_pMsgPool;
extern RoundQueue<Msg> * g_pRecvMsgQueue;
extern RoundQueue<Msg> * g_pSendMsgQueue;
extern RoundQueue<Msg> * g_pHttpSendMsgQueue;
extern RoundQueue<Msg> * g_pHttpRecvMsgQueue;

/*
class MsgManager
{
    public:
        inline Msg* NewMsg(){
            return g_pMsgPool->NewObj();
        }

        inline void DeleteMsg(Msg* pMsg){
            return g_pMsgPool->DeleteObj(pMsg);
        }

        inline Msg* RecvMsg(){
            return g_pSendMsgQueue->Pop();
        }

        inline bool SendMsg(Msg* pMsg){
            return g_pSendMsgQueue->Push(pMsg);
        }
};*/

#endif //__LUA_MSG_MANAGER_H__

