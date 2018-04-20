#include <event2/bufferevent.h>
#include "RobotThread.h"

#include "common/PackProto.h"
#include "common/Utils.h"
#include "common/LogManager.h"
#include <errno.h>
#define PP (PackProto::GetInst())
extern "C"
{
    #include "lauxlib.h"
}


//static unsigned char sg_buff[10240];
int _RecvMsg(lua_State *pL)
{
    RobotThread *pRobotThread = (RobotThread*)lua_touserdata(pL, 1);
    int nProtoId = (int)luaL_checknumber(pL, 2);
	evbuffer* evbuff = pRobotThread->GetMsgRead()->GetBuf();
	unsigned int len = evbuffer_get_length(evbuff);
	evbuffer_copyout(evbuff,pRobotThread->m_buff,len);
	unsigned int uiLen = PP->decode(nProtoId,pRobotThread->m_buff,len,pL);
	bool bRes = (len == uiLen); 
    lua_pushboolean(pL, bRes);
    return 1;
}

int _SendMsg(lua_State *pL)
{

    RobotThread *pRobotThread = (RobotThread *)lua_touserdata(pL, 2);
    int nProtoId = (int)luaL_checknumber(pL, 1);
    Msg *pWriteMsg = pRobotThread->GetMsgWrite();
	unsigned int uiLen = PP->encode(nProtoId,pRobotThread->m_buff,pL,2);
	bool bRes = uiLen < sizeof(pRobotThread->m_buff);
	evbuffer_add(pWriteMsg->GetBuf(), pRobotThread->m_buff, uiLen);
	pWriteMsg->GetHead()->m_nLen += uiLen;
    if (bRes)
    {
        pWriteMsg->SetID(nProtoId);
        pWriteMsg->GetHead()->hton();

        /*int nRet = evbuffer_prepend(pWriteMsg->GetBuf(), pWriteMsg->GetHead(), MSG_HEAD_LEN);
        assert(!nRet);
        nRet = bufferevent_write_buffer(pRobotThread->GetBufferEvent(), pWriteMsg->GetBuf());
        assert(!nRet);*/
        
        int eight = send(bufferevent_getfd(pRobotThread->GetBufferEvent()), (const char*)pWriteMsg->GetHead(), MSG_HEAD_LEN, 0);

        if (eight != MSG_HEAD_LEN)
        {
            printf("eight = %d\n", eight);
            char temp[100] = {0};
            sprintf(temp, "send 8 error:%d", errno);
            //g_oLogManager.WriteErrorLog(temp);
            puts(temp);
            //assert(0);
        }

        //assert(eight == MSG_HEAD_LEN);
        char szBuf[8192] = {0};
        int aa = evbuffer_remove(pWriteMsg->GetBuf(), szBuf, sizeof(szBuf));

        assert(0 <= aa && aa < sizeof(szBuf));
        int bb = send(bufferevent_getfd(pRobotThread->GetBufferEvent()), szBuf, aa, 0);
        if (aa != bb)
        {
            printf("aa = %d, bb = %d\n", aa, bb); 
            char temp[100] = {0};
            sprintf(temp, "send body error:%d", errno);
            //g_oLogManager.WriteErrorLog(temp);
            puts(temp);
            //assert(0);
        }
    }
    else
    {
        assert(0);
        fprintf(stderr, "WriteMsgDfs fail\n");
    }
    pWriteMsg->CleanUp();
    lua_pushboolean(pL, bRes);

    return 1;
}

