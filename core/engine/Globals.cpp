#include "Globals.h"
#include "common/LogManager.h"
#include <stdio.h>

ObjPool<Msg> * g_pMsgPool = NULL;
ObjPool<sQuery> *g_pDBQueryPool = NULL;  //by tanjie pool for async db access
ObjPool<sQueryResult>   *g_pDBQueryResultPool = NULL;  //by tanjie pool for async db access


RoundQueue<Msg> * g_pRecvMsgQueue = NULL;
RoundQueue<Msg> * g_pSendMsgQueue = NULL;

RoundQueue<sQuery> *g_pDBRequestQueue        = NULL;
RoundQueue<sQueryResult> *g_pDBResponseQueue = NULL;


struct evbuffer * g_pHttpReqEvBuf = NULL;  // 外部http请求的传入参数
struct evbuffer * g_pHttpRespEvBuf = NULL;  // 外部http请求 lua逻辑处理后的响应内容
struct MyLock * g_pHttpReqLock = NULL;
struct MyLock * g_pHttpRespLock = NULL;

RoundQueue<Msg> * g_pHttpSendMsgQueue = NULL; // server向外部发送的http消息
RoundQueue<Msg> * g_pHttpRecvMsgQueue = NULL; // server向外部发送的http消息的响应

Monitor *g_pMonitor = NULL;                 //关键状态监控

int g_nAdminIpCount = 0;
Host *g_pAdminIpList = NULL; 
int *g_pFdSn = NULL; 


//AOI *g_pAOIManager = NULL;
lua_State *g_pL = NULL;
int g_nErrorFuncIndex = 0;
int g_nMsgDispatcherRef = 0;
int g_nDBDispatcherRef = 0;
int g_nTimerDispatcherRef = 0;
int g_nMonsterAIRef = 0;
int g_nMoveBreakRef = 0;
int g_nIsCanJumpRef = 0;
int g_nHttpReqDispatcherRef = 0;
int g_nGameExitRef = 0;
int g_nRemoveObjRef;

int g_nLogicPort;
int g_nHttpPort;
char g_aryCrossServerHost[200] = {0};
int g_nCrossServerHttpPort;
bool g_bRunAsDaemon = false;
//pthread_t g_nIOThreadId = 0;
TID g_nIOThreadId = 0;

char g_cDBIP[20] = {0};
char g_cDBName[50] = {0};
char g_cDBUser[50] = {0};
char g_cDBPass[50] = {0};
int  g_cDBPort = 0;

bool InitGlobals(){
    g_pAdminIpList = new Host[ADMIN_IP_LIST_SIZE];
    g_pFdSn = new int[MAX_SOCKET_FD];
    for(int i=0; i<MAX_SOCKET_FD; i++){
        g_pFdSn[i] = 0;
    }

    g_pMonitor = new Monitor();

    g_pMsgPool = new ObjPool<Msg>;
    if (!g_pMsgPool || !g_pMsgPool->Init(MAX_MSG_POOL_SIZE)){
        fprintf(stderr, "g_pMsgPool->Init fail\n");
        return false;
    }

    g_pDBQueryPool = new ObjPool<sQuery>;
    if (!g_pDBQueryPool || !g_pDBQueryPool->Init(MAX_DBQUERY_POOL_SIZE)){
        fprintf(stderr, "g_pDBQueryPool->Init fail\n");
        return false;
    }
    g_pDBQueryResultPool = new ObjPool<sQueryResult>;
    if (!g_pDBQueryResultPool || !g_pDBQueryResultPool->Init(MAX_DBQUERY_POOL_SIZE)){
        fprintf(stderr, "g_pDBQueryResultPool->Init fail\n");
        return false;
    }


    g_pRecvMsgQueue = new RoundQueue<Msg>();
    if (!g_pRecvMsgQueue || !g_pRecvMsgQueue->Init(MAX_RECV_MSG_QUEUE_LEN)){
        fprintf(stderr, "g_pRecvMsgQueue->Init fail\n");
        return false;
    }

    g_pSendMsgQueue = new RoundQueue<Msg>();
    if (!g_pSendMsgQueue || !g_pSendMsgQueue->Init(MAX_SEND_MSG_QUEUE_LEN)){
        fprintf(stderr, "g_pSendMsgQueue->Init fail\n");
        return false;
    }

    g_pHttpSendMsgQueue = new RoundQueue<Msg>();
    if (!g_pHttpSendMsgQueue || !g_pHttpSendMsgQueue->Init(50)){
        fprintf(stderr, "g_pHttpSendMsgQueue->Init fail\n");
        return false;
    }

	g_pHttpRecvMsgQueue = new RoundQueue<Msg>();
	if (!g_pHttpRecvMsgQueue || !g_pHttpRecvMsgQueue->Init(50)){
		fprintf(stderr, "g_pHttpRecvMsgQueue->Init fail\n");
		return false;
	}

    g_pDBRequestQueue = new RoundQueue<sQuery>();
    if (!g_pDBRequestQueue || !g_pDBRequestQueue->Init(20)){
        fprintf(stderr, "g_pDBRequestQueue->Init fail\n");
        return false;
    }

    g_pDBResponseQueue = new RoundQueue<sQueryResult>();
    if (!g_pDBResponseQueue || !g_pDBResponseQueue->Init(20)){
        fprintf(stderr, "g_pDBResponseQueue->Init fail\n");
        return false;
    }

    g_pL = luaL_newstate();
    luaL_openlibs(g_pL);

    g_pHttpReqEvBuf = evbuffer_new();
    evbuffer_enable_locking(g_pHttpReqEvBuf, NULL);

    g_pHttpRespEvBuf = evbuffer_new();
    evbuffer_enable_locking(g_pHttpRespEvBuf, NULL);

    g_pHttpReqLock = new MyLock();
    g_pHttpRespLock = new MyLock();

    return true;
}


void DestroyGlobals()
{
    evbuffer_free(g_pHttpReqEvBuf);
    g_pHttpReqEvBuf = NULL;

    evbuffer_free(g_pHttpRespEvBuf);
    g_pHttpRespEvBuf = NULL;

    delete g_pHttpReqLock;
    delete g_pHttpRespLock;

    delete g_pMsgPool;
    delete g_pRecvMsgQueue;  
    delete g_pSendMsgQueue; 
    delete g_pHttpSendMsgQueue;
	delete g_pHttpRecvMsgQueue;
    delete g_pMonitor;
    lua_close(g_pL);
}

static int nObjCheckPos = 0;
static int nMsgCheckPos = 0;

//检查对象泄漏并且回收
void CheckLeakAndRecycle()
{
//     int iBegin = nObjCheckPos;
//     int iEnd = iBegin + 300 ;
//     if (iEnd > g_pObjPool->PoolSize()) iEnd = g_pObjPool->PoolSize();
// 
//     //1. check obj PoolSize
//     for (int i=iBegin; i<iEnd; ++i){
//         Obj* pObj = g_pObjPool->Get(i);
//         if (pObj && pObj->GetType() != TYPE_HUMAN && pObj->GetPoolID() != -1 && pObj->GetScene() == NULL)
//         {
//             pObj->IncLeakCheck();
//             if (pObj->GetLeakCheck() >= 2 && pObj->GetActiveCnt() == 0){
//                 char sLog[128] = {0};
//                 snprintf(sLog, sizeof(sLog), "[EngineObjLeak] id:%d, type:%d", pObj->GetID(), pObj->GetType());
//                 g_oLogManager.WriteErrorLog(sLog);
//                 g_pObjPool->DeleteObj(pObj);
//             }
//         }
//     }
// 
//     iBegin = iEnd;
//     if (iBegin >= g_pObjPool->PoolSize()) iBegin = 0; 
//     nObjCheckPos = iBegin;

    //2. check all msgs
    int jBegin = nMsgCheckPos;
    int jEnd = jBegin + 1500;
    if (jEnd > g_pMsgPool->PoolSize()) jEnd = g_pMsgPool->PoolSize();

    for (int j=jBegin; j<jEnd; ++j){
        Msg* pMsg = g_pMsgPool->Get(j);
        if (pMsg && pMsg->GetID() >= 10000 && pMsg->GetPoolID() != -1 && pMsg->GetQueueID() == -1){
            pMsg->IncLeakCheck();
            if (pMsg->GetLeakCheck() >= 2){
                char sLog[128] = {0};
                tsnprintf(sLog, sizeof(sLog), "[MsgLeak] id:%d", pMsg->GetID());
                g_oLogManager.WriteErrorLog(sLog);
                g_pMsgPool->DeleteObj(pMsg);
            }
        }
    }
    jBegin = jEnd;
    if (jBegin >= g_pMsgPool->PoolSize()) jBegin = 0; 
    nMsgCheckPos = jBegin;
}

bool IsIOThread(){
    //return pthread_self() == g_nIOThreadId ;
	return MyGetCurrentThreadID() == g_nIOThreadId;
}

