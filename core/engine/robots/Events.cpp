extern "C"
{
    #include "lauxlib.h"
}
#include <event2/bufferevent.h>
#include "RobotThread.h"
#include "common/Msg.h"
#include "common/Utils.h"
#include "common/LogManager.h"
#include <time.h>
#include <errno.h>
#include "common/PackProto.h"
#define PP (PackProto::GetInst())
void EventCB(bufferevent *pBev, short nEvents, void *pArg)
{

    RobotThread *pRobot = (RobotThread*)pArg;
    if (nEvents & BEV_EVENT_EOF )
    {
        printf("connect closed\n");
        //assert(0);
        return;
    }
    if (nEvents & BEV_EVENT_CONNECTED)
    {
        int fd = (int)bufferevent_getfd(pBev);
        int curTime = CurrentTime();
        int costTime = curTime - pRobot->m_timeStart;
        printf("connect ok, ev:%d, fd:%d, name:%s, curTime:%d, cost time:%d\n", 
                nEvents, fd, pRobot->m_nRobotName, curTime, costTime);

        return;
    }
    if (nEvents & BEV_EVENT_ERROR)
    {
        int iErr = EVUTIL_SOCKET_ERROR();
        printf("connect error:%d\n", iErr);
        //assert(0);
        return;
    }
}

void ReadCB(bufferevent *pBev, void * pArg)
{
    RobotThread *pRobot = (RobotThread*)pArg;
    assert(lua_gettop(pRobot->GetLuaState()) == 1);
    evbuffer *pIn = bufferevent_get_input(pBev);
    int bufferLen = evbuffer_get_length(pIn);
    
    //time_t tsBegin = 0;
    //time_t tsEnd = 0;

    while (bufferLen >= MSG_HEAD_LEN)
    {
        //if (tsBegin == 0) time(&tsBegin);

        MsgHead oHead;
        int siz = evbuffer_copyout(pIn, &oHead, MSG_HEAD_LEN); 
        assert(siz == MSG_HEAD_LEN);
        oHead.ntoh();
        if (!(MSG_HEAD_LEN<=oHead.m_nLen && oHead.m_nLen<MAX_RECV_PKG_LEN*4))
        {
            assert(0);
            fprintf(stderr, "invalid msg len: %d\n",  oHead.m_nLen);
            bufferevent_free(pBev);
            return;
        }
        if (bufferLen < oHead.m_nLen)
        {
            return;
        }
        //CHECK_DEAL_TIME(1000, "file = %s, line = %d", __FILE__, __LINE__);
        Msg *pMsg = pRobot->GetMsgRead();
        siz = evbuffer_drain(pIn, MSG_HEAD_LEN);
        bufferLen -= MSG_HEAD_LEN;
        assert(bufferLen == evbuffer_get_length(pIn));
        assert(!siz);
        pMsg->SetHead(&oHead);
        evbuffer *pBuf = pMsg->GetBuf();
        siz = evbuffer_remove_buffer(pIn, pBuf, oHead.m_nLen - MSG_HEAD_LEN);
        bufferLen -= siz;
        assert(bufferLen == evbuffer_get_length(pIn));
        assert(siz == oHead.m_nLen - MSG_HEAD_LEN); 
        lua_State *pL = pRobot->GetLuaState();

		//static unsigned char sbuff[10240];
		evbuffer* evbuff = pRobot->GetMsgRead()->GetBuf();
		unsigned int len = evbuffer_get_length(evbuff);
		evbuffer_copyout(evbuff,pRobot->m_buff,len);
        lua_getglobal(pL, "MsgDispatch");
        //lua_pushnumber(pL, pMsg->GetID());
		lua_pushnumber(pL, 1);
		lua_pushnumber(pL, oHead.m_nID);
		lua_pushnumber(pL, 1);
		int uiArgNum = PP->decode(oHead.m_nID,pRobot->m_buff,len,pL);
        if (lua_pcall(pL, 3+uiArgNum, 1, pRobot->m_nErrorFuncIndex))
        {
            //g_oLogManager.WriteErrorLog(lua_tostring(pL, -1));

            fprintf(stderr, "lua_pcall fail: %s\n", lua_tostring(pL, -1));
            lua_pop(pL, 1);
            //assert(0);
        }
        else
        {
            int ret = lua_toboolean(pL, -1);
            lua_pop(pL, 1);
            if (!ret)
            {
                char temp[100] = {0};
                sprintf(temp, "process fail, nPacketID:%d", pMsg->GetHead()->m_nID);
                //g_oLogManager.WriteErrorLog(temp);

                fprintf(stderr, "process fail, nPacketID:%d\n", pMsg->GetHead()->m_nID);
                //assert(0);
            }
        }
        pMsg->CleanUp();

        //time(&tsEnd);

        //if ((tsEnd - tsBegin) > 1) 
        //{
        //    printf("Robot ReadCB time over 1 second, return\n");
        //    return;
        //}
    }
}

void TimerCB(evutil_socket_t fd, short nEvents, void * pArg)
{
    //CHECK_DEAL_TIME(1000, "file = %s, line = %d", __FILE__, __LINE__);
    RobotThread* pRobot = (RobotThread*)pArg;
    int timeCur = time(0);
    if (timeCur - pRobot->m_timeLastTimerCB < 1)
    {
        return;
    }
    pRobot->m_timeLastTimerCB = timeCur;
    lua_State *pL = pRobot->GetLuaState();
    assert(lua_gettop(pL) == 1);
    lua_getglobal(pL, "HeartBeat");
    lua_pushstring(pL, pRobot->m_nRobotName);
    lua_pushnumber(pL, pRobot->m_mapID);
    if (lua_pcall(pL, 2, 1, pRobot->m_nErrorFuncIndex) != 0)
    {
        fprintf(stderr, "HeartBeat error: %s\n", lua_tostring(pL, -1));
        lua_pop(pL, 1);
        assert(0);
        return;
    }
    int ret = lua_toboolean(pL, -1);
    lua_pop(pL, 1);
    assert(ret); 
}

bool CheckLuaRenew(lua_State *pL, int nErrorFuncIndex)
{
    static int s_nStepInCheck = 0;
    static long long s_llLastModifyTime = 0;
    const char *pRenewFileName = "../scripts/Renew.lua";
    bool bLoad = 0;
    if (s_nStepInCheck)
    {
        s_nStepInCheck = s_nStepInCheck - 1;
        bLoad = 1;
    }
    else if (CheckFileLastModifyTime(pRenewFileName, s_llLastModifyTime))
    {
        s_nStepInCheck = RobotThread::m_nRobotNum;
        bLoad = 1;
    }
    if (bLoad)
    {
        if (luaL_loadfile(pL, "../scripts/robot/Main.lua"))
        {
            puts(lua_tostring(pL, -1));
            lua_pop(pL, 1);
            return false;
        }
        if (lua_pcall(pL, 0, 0, nErrorFuncIndex))
        {
            puts(lua_tostring(pL, -1));
            lua_pop(pL, 1);
            return false;
        }
    }
    return true;
}

void TimerReNewCB(evutil_socket_t fd, short nEvents, void * pArg)
{
    RobotThread* pRobot = (RobotThread*)pArg;
    lua_State *pL = pRobot->GetLuaState();
    //CheckLuaRenew(pL, pRobot->m_nErrorFuncIndex);
}

