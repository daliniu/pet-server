#ifndef __GLOBALS_H__
#define __GLOBALS_H__
#include "common/ObjPool.h"
#include "common/RoundQueue.h"
#include "common/Type.h"
#include "common/Msg.h"
#include "Config.h"
#include "Monitor.h"
#include "Type.h"
//#include <pthread.h>

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

#include "db/MongoDBInterface.h"
#include "db/LuaMongoDB.h"
#include "db/LuaMongoDBCursor.h"
#include "db/LuaDBUtils.h"


#define    MAX_SOCKET_FD             20000 
#define    MAX_OBJPOOL_SIZE          30000 
#define    MAX_TIMER_POOL_SIZE       10
#define    MAX_MSG_POOL_SIZE         (MAX_OBJPOOL_SIZE + MAX_ONLINE_PLAYER*30)
#define	   MAX_DBQUERY_POOL_SIZE	 1000
#define    MAX_RECV_MSG_QUEUE_LEN    (MAX_ONLINE_PLAYER* 20)
#define    MAX_SEND_MSG_QUEUE_LEN    (MAX_ONLINE_PLAYER* 50)
#define    MAX_RECV_HTTP_LEN		 2048		//����http���󷵻ص�����ֽ���


extern ObjPool<Msg> * g_pMsgPool ;          //��Ϣ�����
extern ObjPool<sQuery> *g_pDBQueryPool;
extern ObjPool<sQueryResult>   *g_pDBQueryResultPool;
extern RoundQueue<Msg> * g_pRecvMsgQueue ;  //������Ϣ����
extern RoundQueue<Msg> * g_pSendMsgQueue ;  //������Ϣ����
extern RoundQueue<sQuery> *g_pDBRequestQueue;
extern RoundQueue<sQueryResult> *g_pDBResponseQueue;
extern struct evbuffer * g_pHttpReqEvBuf;   // http�̵߳�request
extern struct evbuffer * g_pHttpRespEvBuf;  // http�̵߳�response

extern class MyLock * g_pHttpReqLock;
extern class MyLock * g_pHttpRespLock;
extern Monitor *g_pMonitor;                 //�ؼ�״̬���
extern lua_State *g_pL;                     //Lua�����
extern int g_nErrorFuncIndex;
extern int g_nMsgDispatcherRef;
extern int g_nDBDispatcherRef;
extern int g_nTimerDispatcherRef;
extern int g_nHttpReqDispatcherRef;
extern int g_nGameExitRef;
extern int g_nRemoveObjRef;


bool InitGlobals();
void DestroyGlobals();
void CheckLeakAndRecycle();
bool IsIOThread();

extern int g_nLogicPort;
extern int g_nHttpPort;
extern char g_aryCrossServerHost[200];
extern int g_nCrossServerHttpPort;
extern bool g_bRunAsDaemon;

extern char g_cDBIP[20];
extern char g_cDBName[50];
extern char g_cDBUser[50];
extern char g_cDBPass[50];
extern int g_cDBPort;

#define  ADMIN_IP_LIST_SIZE  50
struct Host{
    char ip[32];
    Host(){
        memset(ip, 0, sizeof(ip));
    }
};

extern int g_nAdminIpCount;
extern Host *g_pAdminIpList;
extern int *g_pFdSn;    //fd�����кŹ���
//extern pthread_t g_nIOThreadId;
extern TID g_nIOThreadId;

#endif //__GLOBALS_H__
