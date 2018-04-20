#include "IOThread.h"
#include "DBThread.h"
#include "HttpThread.h"
#include "Config.h"
#include "MsgEx.h"
#include "Globals.h"
#include "common/Msg.h"
#include "common/MsgManager.h"
#include "common/Utils.h"
#include "common/LuaUtils.h"
#include "common/PackProto.h"
#include "common/PkLimit.h"
#include "common/PacketID.h"
#include "common/LogManager.h"
#include "Assertx.h"
#include <stdio.h>
#include <signal.h>
#include <event2/event.h>
#include <event2/event_struct.h>

#if defined(__WINDOWS__)
#include "signal.h"
#else
#include <errno.h>
#include <getopt.h>
#include <unistd.h>
#include <signal.h>
#endif

#if defined(__WINDOWS__)  
extern "C" {
 //luasocket for mobdebug
#include "luasocket/luaopen_socket.h" 
}
#endif

static void SignalCB(evutil_socket_t, short, void *);
static void HotUpdateCB(evutil_socket_t, short, void *);

static void LogicTimerCB(evutil_socket_t, short, void *);
static void LogFlushTimerCB(evutil_socket_t, short, void *);
static void AoiTimerCB(evutil_socket_t, short, void *);
static void FastAoiTimerCB(evutil_socket_t,short,void *);
static bool SetupLua();
static void HandleIOPacket();
static void HandleHttpPacket();
static void HandleDBPacket();

static MsgEx* g_pMsgEx;
LogManager g_oLogManager; 

struct event_base *g_pEventBase;
#define PP (PackProto::GetInst())
int main(int argc, char* argv[])
{
    bool bRunCDPThread = false;
#if defined(__WINDOWS__)
    // ï¿½ï¿½Ê¼ï¿½ï¿½windowsï¿½ï¿½wsï¿½ï¿½ï¿½ï¿½
    WSADATA wsaData;
    WORD wVersionRequested = MAKEWORD( 2, 2 );
    int err = WSAStartup( wVersionRequested, &wsaData ); 
#else
    int opt;
    while(1){
        int option_index = 0;
        static struct option long_options[] = {
            {"cdp",  0, 0, 'x'},
            {"daemon",  0, 0, 'd'},
            {0, 0, 0, 0}
        };

        opt = getopt_long(argc, argv, "hxd", long_options, &option_index);
        if (opt == -1) break;
        switch(opt){
            case 'x':
                bRunCDPThread = true;
                break;
            case 'd':
                g_bRunAsDaemon = true;
                break;
            default:
                break;
        }
    }
    if(g_bRunAsDaemon){
        daemon(1,1);
    }
    signal(SIGPIPE,SIG_IGN);
#endif

    if (!InitGlobals()){
        return -1;
    }

    if (!g_oLogManager.Init()) {
        fprintf(stderr, "[Error] Init Logic Log fail\n");
        return -1;
    }
    
    // ï¿½ï¿½ï¿½ï¿½flashï¿½Ãµï¿½CrossDomanProtocolï¿½ß³ï¿½
    
    g_pEventBase = event_base_new();
    if (!g_pEventBase) {
        fprintf(stderr, "[Error] Could not initialize libevent!\n");
        return -1;
    }

    //RegisterTimer(g_pL);
    if (!SetupLua()){
        return -1;
    }

    IOThread oIOThread(g_nLogicPort);
    if (!oIOThread.Init()){
        fprintf(stderr, "[Error] Init IOThread fail\n");
        return -1;
    }
    oIOThread.Start();

    g_nIOThreadId = oIOThread.GetTID();


    DBThread oDBThread;
    if (!oDBThread.Init()){
        fprintf(stderr, "[Error] Init DBThread fail\n");
        return -1;
    }
    oDBThread.Start();

	/*
    CDPThread oCDPThread;
    if (bRunCDPThread){
        if (!oCDPThread.Init()){
            fprintf(stderr, "[Error] Init CDPThread fail\n");
            return -1;
        }
        oCDPThread.Start();
    }
	*/

    // ï¿½ï¿½ï¿½ï¿½HttpServerï¿½ß³ï¿½
    HttpThread oHttpThread(g_nHttpPort);
    if (!oHttpThread.Init()){
        fprintf(stderr, "[Error] Init oHttpThread fail\n");
        return -1;
    }
    oHttpThread.Start();

    // ï¿½ï¿½ï¿½ï¿½ï¿½Ã»ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ß³ï¿½
    
    EventTimer *pLogicTimer = new EventTimer(g_pEventBase, GAME_IO_HEARTBEAT , LogicTimerCB, NULL);  
    EventTimer *pLogTimer = new EventTimer(g_pEventBase, LOG_FLUSH_PERIOD, LogFlushTimerCB, NULL);
    EventTimer *pAoiTimer = new EventTimer(g_pEventBase, GAME_LOGIC_HEARTBEAT, AoiTimerCB, 0);

    struct event *pSignalEvent;
    pSignalEvent = evsignal_new(g_pEventBase, SIGINT, SignalCB, g_pEventBase);
    if (!pSignalEvent|| event_add(pSignalEvent, NULL)<0) {
        fprintf(stderr, "[Error] Could not create/add a signal event!\n");
        return 1;
    }

#if defined(__WINDOWS__)
#else
	struct event *pSignalEventUSR1;
	pSignalEventUSR1 = evsignal_new(g_pEventBase, SIGUSR1, SignalCB, g_pEventBase);
	if (!pSignalEventUSR1|| event_add(pSignalEventUSR1, NULL)<0) {
		fprintf(stderr, "[Error] Could not create/add a signal event!\n");
		return 1;
	}

	struct event *pSignalEventUSR2;
	pSignalEventUSR2 = evsignal_new(g_pEventBase, SIGUSR2, HotUpdateCB, g_pEventBase);
	if (!pSignalEventUSR2|| event_add(pSignalEventUSR2, NULL)<0) {
		fprintf(stderr, "[Error] Could not create/add a signal event!\n");
		return 1;
	}
#endif


    printf("=====game started success=====\n");
    g_oLogManager.WriteEngineLog("[system] engine started!");
    event_base_dispatch(g_pEventBase);
    event_free(pSignalEvent);
    event_base_free(g_pEventBase);

    oIOThread.Stop();       // ï¿½Í·ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ioï¿½ß³ï¿½
    oHttpThread.Stop();     // ï¿½Í·ï¿½HttpServerï¿½ß³ï¿½
	/*
    if (bRunCDPThread){
        oCDPThread.Stop();  // ï¿½Í·ï¿½CDPï¿½ß³ï¿½
    }
	*/

#if defined(__WINDOWS__)
    // ï¿½Í·ï¿½windowsï¿½ï¿½wsï¿½ï¿½ï¿½ï¿½
    WSACleanup();
#endif

    SAFE_DELETE(pLogicTimer);
    SAFE_DELETE(pLogTimer);
    SAFE_DELETE(pAoiTimer);
    DestroyGlobals();
    return 0;
}

static void SignalCB(evutil_socket_t nSignal, short nEvents, void *pArg)
{
    g_oLogManager.WriteEngineLog("[system] Engine exit...");
    static bool bSignaled = false;
    if (bSignaled){ return; }
    bSignaled = true;
    lua_rawgeti(g_pL, LUA_REGISTRYINDEX, g_nGameExitRef);
    if (lua_pcall(g_pL, 0, 0, g_nErrorFuncIndex))
    {
        const char * pRetMsg = lua_tostring(g_pL, -1);
        if (g_bRunAsDaemon){
            g_oLogManager.WriteErrorLog(pRetMsg);
        }else{
            puts(pRetMsg);
        }
        lua_pop(g_pL, 1);
    }

	g_nMsgDispatcherRef = LuaRef(g_pL, "MsgDispatch");
	g_nDBDispatcherRef = LuaRef(g_pL, "dbDispatch");
    struct event_base *pEB= (struct event_base*) pArg;
    struct timeval delay = { 30, 0 };
    event_base_loopexit(pEB, &delay);
    g_oLogManager.WriteEngineLog("[system] Exit begin.");
    printf("Exit begin!\n");
}

static void HotUpdateCB(evutil_socket_t nSignal, short nEvents, void *pArg)
{
    char sLog[128] = {0};
    if (!g_bRunAsDaemon){
        printf(">>>>>>>> Hot update start...\n");
    }
    g_oLogManager.WriteEngineLog("[system] hot update start ...");
    g_oLogManager.FlushAll();
    const char *pRenewFileName = "../scripts/Renew.lua";
    unsigned int uiStart = CurrentTime();
    if (luaL_loadfile(g_pL, pRenewFileName))
    {
        tsnprintf(sLog, sizeof(sLog), "[system] %s", lua_tostring(g_pL, -1));
        g_oLogManager.WriteEngineLog(sLog);
        lua_pop(g_pL, 1);
        return ;
    }
    if (lua_pcall(g_pL, 0, 0, g_nErrorFuncIndex))
    {
        tsnprintf(sLog, sizeof(sLog), "[system] %s", lua_tostring(g_pL, -1));
        g_oLogManager.WriteEngineLog(sLog);
        lua_pop(g_pL, 1);
        return ;
    }

    tsnprintf(sLog, sizeof(sLog), "[system] Hot update ok, cost time:%d(ms)\n", CurrentTime() - uiStart);
    g_oLogManager.WriteEngineLog(sLog);
    g_oLogManager.FlushAll();
    if (!g_bRunAsDaemon){
        printf(">>>>>>>>> Hot update ok, cost time:%d\n", CurrentTime() - uiStart);
    }
}


int nCnt = 0;
static void LogFlushTimerCB(evutil_socket_t nFD, short nEvent, void *pArg)
{
    nCnt++;
    //Ã¿·ÖÖÓÒ»´Î
    if (nCnt % 20 == 0){
        //Êä³ö¼à¿ØÈÕÖ¾
        g_pMonitor->WriteLog();

        //¼ì²â¶ÔÏóÐ¹Â©ÒÔ¼°»ØÊÕ
        nCnt = 0;
    }

    CheckLeakAndRecycle();
    g_oLogManager.FlushAll();
}

// Ã¿Ö¡ï¿½ï¿½ï¿½ï¿½
static void LogicTimerCB(evutil_socket_t nFD, short nEvent, void *pArg)
{
    g_pMonitor->nProcessTimes++;
    HandleIOPacket();
    HandleHttpPacket();
    HandleDBPacket();
}
static void HandleDBPacket()
{
    sQueryResult* pResp = g_pDBResponseQueue->Pop();
    while(pResp)
    {
        int retCode = pResp->eRetCode;
        int tid = pResp->m_nTID;
        lua_rawgeti(g_pL, LUA_REGISTRYINDEX, g_nDBDispatcherRef);
        lua_pushnumber(g_pL, tid);
        lua_pushnumber(g_pL, retCode);
        if (pResp->eRetCode == eQueryOK)
        {
            if (pResp->eQT == eFind)
            {
                int retnum = pResp->bsVecResult.size();
                lua_createtable(g_pL,retnum,0);
                for (int i = 0;i < retnum;i++)
                {
                    lua_newtable(g_pL);
                    LuaDBUtils::BsonToLua(g_pL,&(pResp->bsVecResult[i]));
                    lua_rawseti(g_pL,-2,i+1);
                }                
            }
            else if (pResp->eQT == eCount)
            {
                lua_pushnumber(g_pL,pResp->m_dCount);
            }
            else if (pResp->eQT == eInsert)
            {
                lua_pushstring(g_pL,pResp->m_oidhex);
            }
            else
            {
                lua_pushnil(g_pL);
            }

        }
        else
        {
            lua_createtable(g_pL,0,0);
        }
        if (lua_pcall(g_pL,3,1,g_nErrorFuncIndex))
        {
            const char * pRetMsg = lua_tostring(g_pL, -1);
            if (g_bRunAsDaemon){
                g_oLogManager.WriteErrorLog(pRetMsg);
            }else{
                puts(pRetMsg);
            }
        }
        else
        {
            bool ret = lua_toboolean(g_pL, -1);
            if (!ret){
                //fprintf(stderr, "process fail, nPacketID:%d\n", pHead->m_nID);
            }
        }
        lua_pop(g_pL, 1);
        g_pDBQueryResultPool->DeleteObj(pResp);
        pResp = g_pDBResponseQueue->Pop();

    }
}
static void HandleIOPacket()
{
	static unsigned char szPacketBuff[MAX_PACKET_LENGTH];
    int ret = false;
    int iPacketCount = 0;
	Msg *pMsg = g_pRecvMsgQueue->Pop();
    while(pMsg != NULL)
    {
        iPacketCount++;
        const MsgHead *pHead = pMsg->GetHead(); 

		if (pHead->m_nID != CG_HEART_BEAT)
		{
			int nFD = pMsg->GetObjFD();
			int nSN = g_pFdSn[pMsg->GetObjFD()];
			int nInitTop = lua_gettop(g_pL);
			g_pMsgEx->SetReadMsg(pMsg);
			lua_rawgeti(g_pL, LUA_REGISTRYINDEX, g_nMsgDispatcherRef);
			lua_pushnumber(g_pL, nFD);
			lua_pushnumber(g_pL, pHead->m_nID);
			lua_pushnumber(g_pL, nSN);
			evbuffer* evbuff = pMsg->GetBuf();
			unsigned int len = evbuffer_get_length(evbuff);
			evbuffer_copyout(evbuff,szPacketBuff,len);

		    unsigned int uiArgNum = 0;
			int nTopOld = lua_gettop(g_pL);
			uiArgNum = PP->decode(pHead->m_nID,szPacketBuff,len,g_pL);
			int nTopNew = lua_gettop(g_pL);
			if (uiArgNum == -1)
			{
				lua_settop(g_pL,nInitTop);
				char sLog[128] = {0};
				tsnprintf(sLog, sizeof(sLog), " decode error proto= %d\n", pHead->m_nID);
				g_oLogManager.WriteErrorLog(sLog);
				Assert(0);
			}
			else if (nTopNew - nTopOld != uiArgNum)
			{
				lua_settop(g_pL,nInitTop);
				char sLog[128] = {0};
				tsnprintf(sLog, sizeof(sLog), " args len not match proto= %d, %d %d\n", pHead->m_nID, nTopNew,nTopOld);
				g_oLogManager.WriteErrorLog(sLog);
				Assert(0);

			}
            else 
			{
				if (lua_pcall(g_pL, 3+uiArgNum, 1, g_nErrorFuncIndex))
				{
					const char * pRetMsg = lua_tostring(g_pL, -1);
					if (g_bRunAsDaemon){
						g_oLogManager.WriteErrorLog(pRetMsg);
					}else{
						puts(pRetMsg);
					}
					lua_pop(g_pL, 1);
				}
				else
				{
					ret = lua_toboolean(g_pL, -1);
					lua_pop(g_pL, 1);
					if (!ret){
						//fprintf(stderr, "process fail, nPacketID:%d\n", pHead->m_nID);
					}
				}
			}

        }

		g_pMonitor->nCCL++;
		g_pMsgPool->DeleteObj(pMsg);
        if (iPacketCount > 10000){
            // ÕâÀï²»ÄÜ·è¿ñ´¦Àí ÒªbreakÒ»ÏÂ Áô¸øÆäËûtimer
            g_oLogManager.WriteErrorLog("[warn] break after 10000 package processed");
            break;
        }

        pMsg = g_pRecvMsgQueue->Pop();
    } 
}


static void HandleHttpPacket()
{
	//handle client httprequest  
    g_pHttpReqLock->Lock();
    if (evbuffer_get_length(g_pHttpReqEvBuf) > 0){
        lua_rawgeti(g_pL, LUA_REGISTRYINDEX, g_nHttpReqDispatcherRef);
        char aryInput[4096] = {0};
        evbuffer_remove(g_pHttpReqEvBuf, aryInput, 4095);
        g_oLogManager.WriteHttpLog(aryInput);

        g_pHttpReqLock->Unlock();

        //evbuffer_lock(g_pHttpRespEvBuf);
        g_pHttpRespLock->Lock();
        evbuffer_drain(g_pHttpRespEvBuf, evbuffer_get_length(g_pHttpRespEvBuf));
		g_pHttpRespLock->Unlock();

        lua_pushlstring(g_pL, aryInput, strlen(aryInput));
        g_pMonitor->nCCL++;
        if (lua_pcall(g_pL, 1, 1, g_nErrorFuncIndex))
        {
			const char * pRetMsg = lua_tostring(g_pL, -1);
			if (g_bRunAsDaemon){
				g_oLogManager.WriteErrorLog(pRetMsg);
			}else{
				puts(pRetMsg);
			}
        }
		else
		{
			bool ret = lua_toboolean(g_pL, -1);
			if (!ret){
				g_pHttpRespLock->Lock();
				evbuffer_add(g_pHttpRespEvBuf, "{\"code\":500}", 12);
				g_pHttpRespLock->Unlock();
			}
		}
		lua_pop(g_pL, 1);
        //evbuffer_unlock(g_pHttpRespEvBuf);
    }else{
        g_pHttpReqLock->Unlock();
    }
	//handle http response packet
	int iPacketCount = 0;
	static unsigned char szPacketBuff[MAX_RECV_HTTP_LEN] = {0};
	Msg *pMsg = g_pHttpRecvMsgQueue->Pop();
	while(pMsg != NULL)
	{
		lua_rawgeti(g_pL, LUA_REGISTRYINDEX, g_nMsgDispatcherRef);
		evbuffer* buff = pMsg->GetBuf();
		size_t len = evbuffer_get_length(buff);
		evbuffer_copyout(buff,szPacketBuff,len);
		lua_pushnumber(g_pL,pMsg->GetObjFD());
		lua_pushnumber(g_pL,pMsg->GetID());
		lua_pushnumber(g_pL,1);
		lua_pushlstring(g_pL,(const char*)szPacketBuff,len);
		if (lua_pcall(g_pL,4,1,g_nErrorFuncIndex)){
			const char * pRetMsg = lua_tostring(g_pL, -1);
			if (g_bRunAsDaemon){
				g_oLogManager.WriteErrorLog(pRetMsg);
			}else{
				puts(pRetMsg);
			}
		}
		lua_pop(g_pL, 1);
		g_pMsgPool->DeleteObj(pMsg);
		if (iPacketCount > 100){
			g_oLogManager.WriteErrorLog("[warn] break after 100 http package processed");
			break;
		}
		pMsg = g_pHttpRecvMsgQueue->Pop();
	}
}

static void AoiTimerCB(evutil_socket_t nFD, short nEvent, void *pArg)
{
    g_pMonitor->nFrames++;



    lua_rawgeti(g_pL, LUA_REGISTRYINDEX, g_nTimerDispatcherRef);
    lua_pushnumber(g_pL, CurrentTime());
    g_pMonitor->nCCL++;
    if (lua_pcall(g_pL, 1, 0, g_nErrorFuncIndex))
    {
        if (g_bRunAsDaemon){
            g_oLogManager.WriteErrorLog(lua_tostring(g_pL, -1));
        }else{
            fprintf(stderr, lua_tostring(g_pL, -1));
        }
        lua_pop(g_pL, 1);
        return;
    }
}

int _OnGameExit(lua_State *pL)
{
	event_base_loopexit(g_pEventBase, NULL);
	g_oLogManager.WriteEngineLog("[system] OnGameExit Exit ok.");
	g_oLogManager.FlushAll();
	printf("OnGameExit Exit ok!\n");
	return 0;
}

int _SetServerInfo(lua_State* pL)
{
    g_nLogicPort = lua_tointeger(pL, 1);
    assert(g_nLogicPort != 0);
    g_nHttpPort = lua_tointeger(pL, 2);
    assert(g_nHttpPort != 0);
    const char* pStr = lua_tostring(pL, 3); 
    assert(pStr != NULL);
    memcpy(g_aryCrossServerHost, pStr, strlen(pStr));
    g_nCrossServerHttpPort = lua_tointeger(pL, 4);
    assert(g_nCrossServerHttpPort != 0);
    return 0;
}
int RegisterAdminIp(lua_State* pL)
{
	g_pMonitor->nLCC++;
	if (g_nAdminIpCount >= ADMIN_IP_LIST_SIZE){
		lua_pushboolean(pL, false);
		return 1;
	}

	const char* pIp = lua_tostring(pL, 1);    
	strncpy(g_pAdminIpList[g_nAdminIpCount].ip, pIp, sizeof(g_pAdminIpList[g_nAdminIpCount].ip));
	g_nAdminIpCount++;
	lua_pushboolean(pL, true);
	return 1;
}
int RegisterDB(lua_State* pL)
{
    const char* pDBIP = lua_tostring(pL,1);
    const char* pDBName = lua_tostring(pL,2);
    const char* pDBUser = lua_tostring(pL,3);
    const char* pDBPass = lua_tostring(pL,4);
	int nDBPort = (int)lua_tonumber(pL,5);
    strcpy(g_cDBIP,pDBIP);
    strcpy(g_cDBName,pDBName);
    strcpy(g_cDBUser,pDBUser);
    strcpy(g_cDBPass,pDBPass);
	g_cDBPort = nDBPort;
    lua_pushboolean(pL,true);
    return 1;
}
int _SendHttpRequest(lua_State* pL)
{
	int nId = luaL_checkinteger(pL, 1); 
	int nFd = luaL_checkinteger(pL, 2); 
    const char* pStr = lua_tostring(pL, 3); 
    Msg * pMsg = g_pMsgPool->NewObj();
    if (pMsg == NULL)
    {
        assert(false);
        lua_pushboolean(pL, false);
        return 1;
    }
	pMsg->SetID(nId);
	pMsg->SetObjFD(nFd);
    pMsg->AppendString(pStr, strlen(pStr));
    g_pHttpSendMsgQueue->Push(pMsg);

    lua_pushboolean(pL, true);
    return 1;
}

int _SendHttpResponse(lua_State* pL)
{
    g_pHttpRespLock->Lock();
	size_t nLen = 0;
	const char *p = lua_tolstring(pL, 1 , &nLen);
	evbuffer_drain(g_pHttpReqEvBuf, evbuffer_get_length(g_pHttpReqEvBuf));
	evbuffer_add(g_pHttpRespEvBuf, p, nLen);
    g_pHttpRespLock->Unlock();
	lua_pop(pL, 1);
    lua_pushboolean(pL, 1);
	return 1;
}

static bool SetupLua()
{
    lua_pushcfunction(g_pL, luaErrorHandler); 
    g_nErrorFuncIndex = lua_gettop(g_pL);

    lua_register(g_pL, "_print", _print);
    lua_register(g_pL, "PRINT", PRINT);
	lua_register(g_pL, "_RegisterAdminIp", RegisterAdminIp);
    lua_register(g_pL, "_RegisterDB",RegisterDB);
	lua_pushcfunction(g_pL, _CurrentTime);
	lua_setglobal(g_pL, "_CurrentTime");

	lua_pushcfunction(g_pL, _USec);
	lua_setglobal(g_pL, "_USec");

    lua_pushcfunction(g_pL, _GBK2UTF8);
    lua_setglobal(g_pL, "_GBK2UTF8");

    lua_pushcfunction(g_pL, _md5);
    lua_setglobal(g_pL, "_md5");

    lua_pushcfunction(g_pL, _SendHttpRequest);
    lua_setglobal(g_pL, "_SendHttpRequest");

    lua_pushcfunction(g_pL, _WriteGameLog);
    lua_setglobal(g_pL, "_LOG_GAME");
    lua_pushcfunction(g_pL, _WriteErrorLog);
    lua_setglobal(g_pL, "_LOG_ERR");

    lua_pushcfunction(g_pL, _SetServerInfo);
    lua_setglobal(g_pL, "_SetServerInfo");

	lua_pushcfunction(g_pL, _OnGameExit);
	lua_setglobal(g_pL, "_OnGameExit");

	lua_pushcfunction(g_pL, _SendHttpResponse);
	lua_setglobal(g_pL, "_SendHttpResponse");

	lua_register(g_pL, "ProtoTemplateToTree", PackProto::reg_proto);
    lua_register(g_pL, "_SetHashPk", PkLimit::_SetHashPk);
    lua_register(g_pL, "_SetPkLimit", PkLimit::_SetPkLimit);
	lua_register(g_pL, "_GetIP", _GetIP);
    g_pMsgEx = new MsgEx();
    lua_pushlightuserdata(g_pL, g_pMsgEx);
    lua_setglobal(g_pL, "_Msg");
    Lunar<LuaMsgEx>::Register(g_pL);
    Lunar<LuaMongoDB>::Register(g_pL);
    Lunar<LuaMongoDBCursor>::Register(g_pL);

#if defined(__WINDOWS__)  //luasocket for mobdebug
	//luaopen_socket(g_pL);
#endif

    char arrWorkingDir[100] = {0};
    if (!tgetcwd(arrWorkingDir, sizeof(arrWorkingDir))){
        fprintf(stderr, "getcwd fail:%s\n", strerror(errno)); 
        return false;
    }
    printf(arrWorkingDir);

    char arrLuaEntrance[128] = {0};
    char arrLuaRoot[128] = {0};
    tsnprintf(arrLuaEntrance, sizeof(arrLuaEntrance), "%s/../scripts/Main.lua", arrWorkingDir);
    tsnprintf(arrLuaRoot, sizeof(arrLuaRoot), "%s/../scripts", arrWorkingDir);

    lua_pushstring(g_pL, arrLuaRoot);
    lua_setglobal(g_pL, "LUA_SCRIPT_ROOT");

    if (taccess(arrLuaEntrance, 0) != 0){
        fprintf(stderr, "Could not access '%s'\n", arrLuaEntrance);
        return false;
    }

    if (luaL_loadfile(g_pL, arrLuaEntrance))
    {
        fprintf(stderr, "Loadfile error:%s\n", lua_tostring(g_pL, -1));
        lua_pop(g_pL, 1);
        getchar();
        return false;
    }

    if (lua_pcall(g_pL, 0, 0, g_nErrorFuncIndex) != 0)
    {
        fprintf(stderr, " pcall error:%s\n", lua_tostring(g_pL, -1));
        lua_pop(g_pL, 1);
        getchar();
        return false;
    }

    g_nMsgDispatcherRef = LuaRef(g_pL, "MsgDispatch");
    g_nDBDispatcherRef = LuaRef(g_pL, "dbDispatch");
    g_nTimerDispatcherRef = LuaRef(g_pL, "TimerDispatch");
    g_nHttpReqDispatcherRef = LuaRef(g_pL, "HttpReqDispatch");
    g_nGameExitRef = LuaRef(g_pL, "GameExit");
    g_nRemoveObjRef = LuaRef(g_pL, "RemoveObj");

    lua_getglobal(g_pL, "Init");
    if (lua_pcall(g_pL, 0, 0, g_nErrorFuncIndex) != 0){
        fprintf(stderr, "===== Init failed =====.\n");
        fprintf(stderr, "Init error:%s\n", lua_tostring(g_pL, -1));
        lua_pop(g_pL, 1);
        getchar();
        return false;
    }

    return true;
}

