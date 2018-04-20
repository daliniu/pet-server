#include "IOThread.h"
#include "Config.h"
#include "common/Utils.h"
#include "common/LogEx.h"
#include "common/Msg.h"
#include "common/PkLimit.h"
#include "common/LogManager.h"
#include <errno.h>
#include <event2/event.h>
#include <event2/listener.h>
#include <event2/event_struct.h>
#include "Globals.h"
#include "common/PacketID.h"
#include "Monitor.h"

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

static void ListenerCB(struct evconnlistener *, evutil_socket_t, 
struct sockaddr *, int socklen, void *);
static void ConnReadCB(struct bufferevent *, void *);
static void ConnWriteCB(struct bufferevent *, void *);
static void ConnEventCB(struct bufferevent *, short, void *);
static void TimerCB(evutil_socket_t, short, void *);

#define DISCONNECT_REASON_CLIENT 100					//-- client主动断开
#define DISCONNECT_REASON_TIMEOUT 101					//-- 长时间没有发包断开
#define DISCONNECT_REASON_PACKET_ERR 102				//-- 发送非法包断开
#define DISCONNECT_REASON_KICK 103                      //-- T掉

IOThread::IOThread(int nPort)
{
    m_nPort = nPort;
    m_pEventBase = NULL;
    m_pListener = NULL;
    for (int i=0; i<MAX_CONNECT_FD; i++)
    {
        m_pFD2BE[i] = NULL;
    }
    m_nMinFD = INVALID_ID;
    m_nMaxFD = INVALID_ID;
}

IOThread::~IOThread()
{
}

bool IOThread::Init()
{
    m_pEventBase = event_base_new();
    if (!m_pEventBase) {
        fprintf(stderr, "[Error] Could not initialize libevent!\n");
        return false;
    }

    struct sockaddr_in oSockectAddr;
    memset(&oSockectAddr, 0, sizeof(oSockectAddr));
    oSockectAddr.sin_family = AF_INET;
    oSockectAddr.sin_port = htons(m_nPort);

    m_pListener = evconnlistener_new_bind(m_pEventBase, ListenerCB, (void *)this,
        LEV_OPT_REUSEABLE|LEV_OPT_CLOSE_ON_FREE, -1,
        (struct sockaddr*)&oSockectAddr,
        sizeof(oSockectAddr));

    if (!m_pListener) {
        fprintf(stderr, "[Error] Could not create a listener!\n");
        return false;
    }

    fprintf(stderr, "IOThread init ok, port:%d\n", m_nPort);
    return true;
}

void IOThread::Run()
{
    struct event oTimeEvent;
    struct timeval tv;
    event_assign(&oTimeEvent, m_pEventBase, -1, EV_PERSIST, TimerCB, (void*)this);

    tv.tv_sec = 0; 
    tv.tv_usec = GAME_IO_HEARTBEAT * 1000;
    event_add(&oTimeEvent, &tv);

    event_base_dispatch(m_pEventBase);        
    evconnlistener_free(m_pListener);
    event_base_free(m_pEventBase);
}

void IOThread::Stop()
{
    struct timeval delay = {0,0};
    event_base_loopexit(m_pEventBase, &delay);
}

void IOThread::CloseConnect(int nFD)
{
    bufferevent* pBE = GetBufferEvent(nFD);
    if (pBE == NULL) {
        g_oLogManager.WriteErrorLog("[EngineError] CloseConnect, pBE == NULL");
        return;
    }

    g_pMonitor->nOnline--;
    g_pFdSn[nFD]++;
    SetBufferEvent(nFD, NULL);
    bufferevent_free(pBE);
}

static void ListenerCB(struct evconnlistener * pEventListener, evutil_socket_t fd, 
struct sockaddr * pSockAddr, int socklen, void * pArg)
{
    IOThread *pThread = (IOThread*) pArg;
    struct event_base *base = pThread->GetEventBase();
    struct bufferevent *bev;

    bev = bufferevent_socket_new(base, fd, BEV_OPT_CLOSE_ON_FREE);
    if (!bev) {
        g_oLogManager.WriteErrorLog("[EngineError] Error constructing bufferevent!");
        event_base_loopbreak(base);
        return;
    }

    if (fd > g_pMonitor->nMaxFD){ g_pMonitor->nMaxFD = fd; }
    if (fd >= MAX_CONNECT_FD){
        fprintf(stderr, "Error constructing bufferevent!");
        g_oLogManager.WriteErrorLog("[EngineError] fd >= MAX_CONNECT_FD");
        return;
    }

    ++g_pMonitor->nOnline;
    ++g_pFdSn[fd];
    pThread->SetBufferEvent(fd, bev);

    struct timeval oReadTimeout = {CLIENT_READ_TIMEOUT, 0};
    bufferevent_setwatermark(bev, EV_READ, MSG_HEAD_LEN, 1<<20);
    bufferevent_set_timeouts(bev, &oReadTimeout, NULL);
    bufferevent_setcb(bev, ConnReadCB, ConnWriteCB, ConnEventCB, (void*)pThread);
    bufferevent_enable(bev, EV_READ);
}

static void ConnReadCB(struct bufferevent *pBE, void *pArg)
{
    IOThread *pThread = (IOThread*) pArg;
	struct evbuffer *input = bufferevent_get_input(pBE);
	/*
    static char szPolicy[] = "<policy-file-request/>";
    static short nPolicyLen = sizeof(szPolicy);
    static char aryInput[128] = {0};

    
    if (evbuffer_get_length(input) == nPolicyLen)
    {
        memset(aryInput, 0, sizeof(aryInput));
        evbuffer_copyout(input, &aryInput, nPolicyLen);
        if (!memcmp(szPolicy, aryInput, nPolicyLen))
        {
            evbuffer_drain(input, nPolicyLen);
            bufferevent_write(pBE, CROSS_DOMAIN_PROTOCOL, sizeof(CROSS_DOMAIN_PROTOCOL));
            return;
        }
    }
	*/

    int nBufLen = evbuffer_get_length(input);
    while(nBufLen >= MSG_HEAD_LEN)
    {
        MsgHead oHead;
        evbuffer_copyout(input, &oHead, MSG_HEAD_LEN); 
        oHead.ntoh();
        if (oHead.m_nLen >= MAX_RECV_PKG_LEN || oHead.m_nLen < MSG_HEAD_LEN)
        {
            char sLog[128] = {0};
            tsnprintf(sLog, sizeof(sLog), "[EngineWarn] invalid msg(%d) len: %d\n",  
                    oHead.m_nID, oHead.m_nLen);

            g_oLogManager.WriteErrorLog(sLog);

			int nFD = bufferevent_getfd(pBE);
    		pThread->DisconnectNotice(nFD, DISCONNECT_REASON_PACKET_ERR);
            pThread->CloseConnect(nFD);
            return;
        }
        if (nBufLen < oHead.m_nLen)
        {
            //msg not fullly received
            return;
        }

        int fd = bufferevent_getfd(pBE);
        int nRet = PKLIMIT->CheckPkLimit(fd, oHead.m_nID);
        if (nRet != PkLimit::OK)
        {
            evbuffer_drain(input, oHead.m_nLen);
            nBufLen -= oHead.m_nLen;

            if (nRet == PkLimit::FIXING){
                pThread->ModFixingNotice(fd, oHead.m_nID);
            }

#ifdef DEBUG
            if (nRet == PkLimit::TOO_FAST)
            {
                char log[128] = {0};
                tsnprintf(log, sizeof(log), "[EngineWarn] PkLimit TOO_FAST pkgid: %d\n", oHead.m_nID);
                g_oLogManager.WriteErrorLog(log);
            }
#endif
            continue;
        }

        //内部通信ID，超过20000，禁止客户端发送
        if (oHead.m_nID < 10000 || oHead.m_nID > 20000){
            evbuffer_drain(input, oHead.m_nLen);
            nBufLen -= oHead.m_nLen;
            char sLog[128] = {0};
            tsnprintf(sLog, sizeof(sLog), "[EngineWarn] interal msg denied, id:%d", oHead.m_nID);
            continue;
        }

        Msg *pMsg = g_pMsgPool->NewObj();
        if (!pMsg)
        {
            evbuffer_drain(input, oHead.m_nLen);
            nBufLen -= oHead.m_nLen;
            char sLog[128] = {0};
            tsnprintf(sLog, sizeof(sLog), "[EngineError] g_pMsgPool->NewObj() fail\n");
            g_oLogManager.WriteErrorLog(sLog);
            continue;
        }

        pMsg->SetHead(&oHead);
        pMsg->SetObjFD(fd);
        evbuffer *pBuf = pMsg->GetBuf();
        evbuffer_drain(input, MSG_HEAD_LEN);
        evbuffer_remove_buffer(input, pBuf, oHead.m_nLen - MSG_HEAD_LEN);
        nBufLen -= oHead.m_nLen;
        
        ++g_pMonitor->nPacketsIn;
        g_pMonitor->nBytesIn += oHead.m_nLen;
        g_pRecvMsgQueue->Push(pMsg);
    }

    g_pMonitor->nRecvQ = g_pRecvMsgQueue->GetQueueLen();
    if (g_pMonitor->nRecvQ > g_pMonitor->nMaxRecvQ){
        g_pMonitor->nMaxRecvQ = g_pMonitor->nRecvQ;
    }
}

static void ConnWriteCB(struct bufferevent *pBE, void *pArg)
{
	/*
    int nFD = bufferevent_getfd(pBE);
    Obj* pObj = g_pFD2Obj->Get(nFD);
    if (!pObj)
    {
        IOThread *pThread = (IOThread*) pArg;
        g_pMonitor->nOnline--;
        g_pFdSn[nFD]++;
        g_pFD2Obj->Del(nFD);
        pThread->SetBufferEvent(nFD, NULL);
        bufferevent_free(pBE);
        pThread->DisconnectNotice(nFD, 0);
    }
	*/
}

static void ConnEventCB(struct bufferevent *pBE, short nEvents, void *pArg)
{
    IOThread *pThread = (IOThread*) pArg;
    static char sLog[128] = {0};
    char cReason = DISCONNECT_REASON_CLIENT;
    if (nEvents & BEV_EVENT_EOF) {
        //normal close
    } else if (nEvents & BEV_EVENT_ERROR) {
        
        memset(sLog, 0, sizeof(sLog));
        tsnprintf(sLog, sizeof(sLog), "[EngineWarn] Got an error on the connection");
        g_oLogManager.WriteErrorLog(sLog);
        
 
    } else if (nEvents & BEV_EVENT_TIMEOUT){
        memset(sLog, 0, sizeof(sLog));
        tsnprintf(sLog, sizeof(sLog), "[EngineWarn] close timeout connect");
        g_oLogManager.WriteErrorLog(sLog);
        cReason = DISCONNECT_REASON_TIMEOUT;
    } else{
        memset(sLog, 0, sizeof(sLog));
        tsnprintf(sLog, sizeof(sLog), "[EngineWarn] close connect, unknown reason");
        g_oLogManager.WriteErrorLog(sLog);
        cReason = DISCONNECT_REASON_TIMEOUT;
    }
	
	int nFD = bufferevent_getfd(pBE);
    pThread->DisconnectNotice(nFD, cReason);
    pThread->CloseConnect(nFD);
}

static void TimerCB(evutil_socket_t nFD, short nEvent, void *pArg)
{
    g_pMonitor->nSendTimes++;
    static char s_WriteBuff[65536];
    IOThread *pThread = (IOThread*) pArg;

    g_pMonitor->nSendQ = g_pSendMsgQueue->GetQueueLen();
    if (g_pMonitor->nSendQ > g_pMonitor->nMaxSendQ){
        g_pMonitor->nMaxSendQ = g_pMonitor->nSendQ;
    }

    Msg *pMsg = g_pSendMsgQueue->Pop();
    struct bufferevent *pBE = NULL;
    int nBeginTime = 0;
    while(pMsg){

        if (nBeginTime == 0) nBeginTime = CurrentTime();

        if(pMsg->GetID() == GC_DISCONNECT){
			const Receiver* pReceiver = pMsg->PopReceiver();
			if (pReceiver){
				pThread->CloseConnect(pReceiver->fd);
				g_pMsgPool->DeleteObj(pMsg);
				pMsg = g_pSendMsgQueue->Pop();
				continue;
			}
        }

        if (!pMsg->CheckLen()){
            g_oLogManager.WriteErrorLog("[EngineError] Wrong msg len");
            g_pMsgPool->DeleteObj(pMsg);
            pMsg = g_pSendMsgQueue->Pop();
            continue;
        }

        pMsg->GetHead()->hton();
        evbuffer_prepend(pMsg->GetBuf(), pMsg->GetHead(), MSG_HEAD_LEN);

        int nMsgLen = evbuffer_get_length(pMsg->GetBuf());
        if(nMsgLen >sizeof(s_WriteBuff))
        {
            g_pMsgPool->DeleteObj(pMsg);
            pMsg = g_pSendMsgQueue->Pop();
            g_oLogManager.WriteErrorLog("[EngineError] Fuck Msg len exceed gn_WriteBuff size:65536");
            continue;
        }

        evbuffer_copyout(pMsg->GetBuf(), s_WriteBuff, nMsgLen);
        evbuffer_drain(pMsg->GetBuf(), nMsgLen);

        if (pMsg->GetMsgType() == WORLD_BROADCAST)
        {
            int iMinFD = pThread->GetMinFD();
            int iMaxFD = pThread->GetMaxFD();
            for (int i = iMinFD; i <= iMaxFD; i++)
            {
                pBE = pThread->GetBufferEvent(i);
                //if (pBE && g_pFD2Obj->Get(i))
				if (pBE)
                {
                    ++g_pMonitor->nPacketsOut;
                    g_pMonitor->nBytesOut += nMsgLen;
                    bufferevent_write(pBE, s_WriteBuff, nMsgLen);
                }
            }
        }
        else
        {
            const Receiver* pReceiver = pMsg->PopReceiver();
            while (pReceiver){
                pBE = pThread->GetBufferEvent(pReceiver->fd);
                if (pBE && pReceiver->sn == g_pFdSn[pReceiver->fd]){
                    ++g_pMonitor->nPacketsOut;
                    g_pMonitor->nBytesOut += nMsgLen;
                    bufferevent_write(pBE, s_WriteBuff,nMsgLen);
                } else{
                    g_oLogManager.WriteErrorLog("[EngineWarn] drop wrong versioned message");
                }
                pReceiver = pMsg->PopReceiver();
            }
        }

        g_pMsgPool->DeleteObj(pMsg);
        if ((CurrentTime() - nBeginTime) > 500) 
        {
            g_oLogManager.WriteErrorLog("[EngineWarn] IOThread TimerCB time over 500ms");
            return;
        }

        pMsg = g_pSendMsgQueue->Pop();
    }
}

void IOThread::SetBufferEvent(int nFD, struct bufferevent* pBE)
{
    if (nFD > 0 && nFD < MAX_CONNECT_FD)
    {
        m_pFD2BE[nFD] = pBE;

        if (pBE) // 新增fd
        {
            m_nMinFD = (m_nMinFD == INVALID_ID) ? nFD : mmin(nFD, m_nMinFD);
            m_nMaxFD = mmax(nFD , m_nMaxFD);
        }
        else // 删除fd
        {
            if (nFD == m_nMinFD || nFD == m_nMaxFD)
            {
                m_nMinFD = INVALID_ID;
                m_nMaxFD = INVALID_ID;
                for (int i = 0; i < MAX_CONNECT_FD; i++)
                {
                    if (m_pFD2BE[i])
                    {
                        m_nMinFD = (m_nMinFD == INVALID_ID) ? i : min(i, m_nMinFD);
                        m_nMaxFD = max(i , m_nMaxFD);
                    }
                }
            }
        }
    }
}

bool IOThread::DisconnectNotice(int nFD, char nReason)
{
    Msg* pMsg = g_pMsgPool->NewObj();
    if(pMsg){
        MsgHead oHead;
        oHead.m_nID = CG_DISCONNECT;
        oHead.m_nLen = MSG_HEAD_LEN;
		//oHead.m_nMask = 0;
		//oHead.m_nSN = g_pFdSn[nFD];
        pMsg->SetHead(&oHead);
        pMsg->WriteUInt((unsigned int)nReason);
        pMsg->SetObjFD(nFD);
        g_pRecvMsgQueue->Push(pMsg);
    }
    else{
        g_oLogManager.WriteErrorLog("[EngineError] ConnectClose:g_pMsgPool->NewObj() Failed!\n");
    }

    return true;
}

bool IOThread::ModFixingNotice(int nFD, int nProtoId)
{
	/*
    Msg* pMsg = g_pMsgPool->NewObj();
    if(pMsg){
        MsgHead oHead;
        oHead.m_nID = GG_MOD_FIXING;
        oHead.m_nLen = MSG_HEAD_LEN;
        oHead.m_nMask = 0;
        pMsg->SetHead(&oHead);
        pMsg->WriteUInt(0);
        pMsg->WriteUInt(nProtoId);
        pMsg->SetObjFD(nFD);
        g_pRecvMsgQueue->Push(pMsg);
        return true;
    }
	*/
    return false;
}

