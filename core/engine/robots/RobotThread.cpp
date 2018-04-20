#include <errno.h>
#include <event2/bufferevent.h>
#include "Events.h"
#include "MsgEx.h"
#include "RobotThread.h"
#include "common/LuaUtils.h"
#include "common/PackProto.h"
#include "common/LogManager.h"
#include "RobotMap.h"

#ifndef __WINDOWS__
#include <arpa/inet.h>
#endif

char RobotThread::m_szIP[32];
short RobotThread::m_nPort;
int RobotThread::m_nRobotNum;
int RobotThread::m_nHeartbeat;
int RobotThread::m_nErrorFuncIndex;
int RobotThread::m_mapID;

bool RobotThread::Init(const char *pName, bool bSupportHotUpdate, int mapID)
{
    m_timeLastTimerCB = 0;
    strncpy(m_nRobotName, pName, sizeof(m_nRobotName));
    m_mapID = mapID;

    if (!SetupLua())
    {
        assert(0);
        return false;
    }

    m_pBase = event_base_new();
    if (!m_pBase)
    {
        assert(0);
        fprintf(stderr, "event_base_new fail\n");
        return false;
    }

    m_pBev = bufferevent_socket_new(m_pBase, -1, BEV_OPT_CLOSE_ON_FREE);
    if (!m_pBev)
    {
        assert(0);
        fprintf(stderr, "bufferevent_socket_new fail\n");
        return false;
    }

    bufferevent_setcb(m_pBev, ReadCB, NULL, EventCB, this);
    bufferevent_enable(m_pBev, EV_READ);

    timeval tv = {};
    tv.tv_sec = m_nHeartbeat / 1000000;
    tv.tv_usec = m_nHeartbeat % 1000000;

    event_assign(&m_timeEvent, m_pBase, -1, EV_PERSIST, TimerCB, this);
    event_add(&m_timeEvent, &tv);

    if (bSupportHotUpdate)
    {
        event_assign(&m_timeEventReNew, m_pBase, -1, EV_PERSIST, TimerReNewCB, this);
        tv.tv_sec = 8;
        tv.tv_usec = 0;
        event_add(&m_timeEventReNew, &tv);    
    }

    return true;
}

void RobotThread::Run()
{
    m_timeStart = CurrentTime(); 
    sockaddr_in mysock = {};
    mysock.sin_family =AF_INET;
    mysock.sin_addr.s_addr = inet_addr(m_szIP);
    mysock.sin_port = htons(m_nPort);
    if (bufferevent_socket_connect(m_pBev, (sockaddr*)&mysock, sizeof(struct sockaddr_in)) < 0)
    {
        assert(0);
        fprintf(stderr, "bufferevent_socket_connect fail:%s\n", strerror(errno));
        return;
    }
    event_base_dispatch(m_pBase);

    printf("RobotThread::Run end\n");
}
void RobotThread::Stop()
{
	struct timeval delay = {0,0};
	event_base_loopexit(m_pBase, &delay);
}
int StopRobot(lua_State *pL)
{
	RobotThread *pRobotThread = (RobotThread *)lua_touserdata(pL, 1);
	pRobotThread->Stop();
	return 1;
}

bool RobotThread::SetupLua()
{
    m_pL = luaL_newstate();
    luaL_openlibs(m_pL);
    lua_pushcfunction(m_pL, luaErrorHandler);
    m_nErrorFuncIndex = lua_gettop(m_pL);

    lua_pushlightuserdata(m_pL, this);
    lua_setglobal(m_pL, "_pRobotThread");

    lua_pushstring(m_pL, "../scripts/");
    lua_setglobal(m_pL, "LUA_SCRIPT_ROOT");

	lua_register(m_pL, "ProtoTemplateToTree", PackProto::reg_proto);
    lua_register(m_pL, "_print", _print);
    lua_register(m_pL, "_CurrentTime", _CurrentTime);
    lua_register(m_pL, "_RecvMsg", _RecvMsg);
    lua_register(m_pL, "_SendMsg", _SendMsg);
	lua_register(m_pL, "_StopRobot",StopRobot);
    //lua_register(m_pL, "_WriteLog", _WriteErrorLog);
    lua_register(m_pL, "_InitRobotMap", RobotMapManager::_InitRobotMap);
    lua_register(m_pL, "_GetPath", RobotMapManager::_GetPath);

    if (luaL_loadfile(m_pL, "../scripts/robot/Main.lua"))
    {
        puts(lua_tostring(m_pL, -1));
        lua_pop(m_pL, 1);
        return false;
    }

    if (lua_pcall(m_pL, 0, 0, m_nErrorFuncIndex))
    {
        puts(lua_tostring(m_pL, -1));
        lua_pop(m_pL, 1);
        return false;
    }

    lua_getglobal(m_pL, "SERVER_IP");
    const char* p = lua_tostring(m_pL, -1);
    strncpy(m_szIP, p, sizeof(m_szIP));
    lua_pop(m_pL, 1);

    lua_getglobal(m_pL, "SERVER_PORT");
    m_nPort = lua_tointeger(m_pL, -1);
    lua_pop(m_pL, 1);

    lua_getglobal(m_pL, "HEARTBEAT");
    m_nHeartbeat = lua_tointeger(m_pL, -1);
    lua_pop(m_pL, 1);

    return true;
}

