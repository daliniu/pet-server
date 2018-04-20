#ifndef __ROBOT_THREAD_H__
#define __ROBOT_THREAD_H__

#include <event2/event_struct.h>
#include "common/Thread.h"
#include "common/Msg.h"

struct lua_State;

class RobotThread: public Thread
{
public:

    static int m_nRobotNum;
    static int m_nErrorFuncIndex;
    static char m_nLuaMainFileName[];
    static int m_mapID;
    int m_timeLastTimerCB;
    int m_timeStart;
    char m_nRobotName[32];
	unsigned char m_buff[10240];
    bool Init(const char *pName, bool bSupportHotUpdate, int mapID);
    void Run();
	void Stop();
    lua_State* GetLuaState()
    {
        return m_pL;
    }
    event_base* GetEventBase()
    {
        return m_pBase;
    }
    struct bufferevent* GetBufferEvent()
    {
        return m_pBev;
    }
    Msg* GetMsgRead()
    {
        return &m_msgRead;
    }
    Msg* GetMsgWrite()
    {
        return &m_msgWrite;
    }
private:
    static char m_szIP[32];
    static short m_nPort;
    static int m_nHeartbeat;

    Msg m_msgRead;
    Msg m_msgWrite;
    lua_State *m_pL;

    int m_nMsgLen;
    event m_timeEvent;
    event_base *m_pBase;
    event m_timeEventReNew;
    bufferevent *m_pBev;
    bool SetupLua();
};
#endif //__ROBOT_THREAD_H__

