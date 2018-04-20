#ifndef __MSG_EX_H__
#define __MSG_EX_H__

#include "common/Msg.h"
#include "common/Lunar.h"

#define MAX_PACKET_LENGTH  (10*1024)
class MsgEx
{
    public:
        MsgEx(){
            m_pReadMsg = NULL;
        }

        inline Msg* GetReadMsg(){
            return m_pReadMsg;
        }

        inline void SetReadMsg(Msg* pMsg){
            assert(pMsg != NULL);
            m_pReadMsg = pMsg;
        }

    private:
        Msg *m_pReadMsg;
};


struct lua_State;
class LuaMsgEx
{
    public:
        LuaMsgEx(lua_State *pL){
            m_pMsgEx = (MsgEx*)lua_touserdata(pL, -1);
        }

        int ReadMsg(lua_State* pL);
        int SendMsgByFD(lua_State* pL); //protoid, fd, msg
        int SendMsg(lua_State* pL); //protoid, objid, msg
        int UserBroadcast(lua_State* pL); //protoid,objidlist,msg
        int ZoneBroadcast(lua_State* pL); //protoid, objid, msg
        int SceneBroadcast(lua_State* pL); //protoid, sceneid, msg
        int WorldBroadcast(lua_State* pL); //protoid, msg

        const static char className [] ;        
        static Lunar<LuaMsgEx>::RegType methods[];

    private:
        MsgEx* m_pMsgEx;
		unsigned char m_buf[MAX_PACKET_LENGTH];
};


#endif //__MSG_EX_H__
