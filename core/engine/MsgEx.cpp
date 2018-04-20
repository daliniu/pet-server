#include "MsgEx.h"
#include "common/ObjPool.h"
#include "common/RoundQueue.h"
#include "Globals.h"
#include <assert.h>
#include "PackProto.h"
#define PP (PackProto::GetInst())

extern ObjPool<Msg> * g_pMsgPool;
extern RoundQueue<Msg> * g_pSendMsgQueue;

int LuaMsgEx::ReadMsg(lua_State *pL)
{
	if (!m_pMsgEx->GetReadMsg())
	{
        assert(0);
		return 0;
	}
	int nProtoId = luaL_checkinteger(pL, 1);
	evbuffer* evbuff = m_pMsgEx->GetReadMsg()->GetBuf();
	unsigned int len = evbuffer_get_length(evbuff);
	evbuffer_copyout(evbuff,m_buf,len);
	bool bRes = PP->decode(nProtoId,m_buf,len,pL);
	lua_pushboolean(pL, bRes);
	return 1;
}
//对象管理全部放到lua层之后，c++层全部接受fd进行sendmsg、因此SendMsgByFD直接改成SendMsg
int LuaMsgEx::SendMsg(lua_State* pL) //protoid, fd, msg
{
    Msg *pWriteMsg = g_pMsgPool->NewObj();
    if (!pWriteMsg){
        assert(0);
        return 0;
    }

    int nProtoId = luaL_checkinteger(pL, 1);
    int nFD = luaL_checkinteger(pL, 2);
    pWriteMsg->SetID(nProtoId);
    pWriteMsg->SetMsgType(USER_BROADCAST);

	unsigned int uiLen = PP->encode(nProtoId,m_buf,pL,2);
	bool bRes = uiLen < sizeof(m_buf);
    if (!bRes){
        g_pMsgPool->DeleteObj(pWriteMsg);
        lua_pushboolean(pL, bRes);
        return 1;
    }
	evbuffer_add(pWriteMsg->GetBuf(), m_buf, uiLen);
	pWriteMsg->GetHead()->m_nLen += uiLen;

    pWriteMsg->PushReceiver(nFD);
    if (!g_pSendMsgQueue->Push(pWriteMsg)){
        g_pMsgPool->DeleteObj(pWriteMsg);
        lua_pushboolean(pL, false);
    }
    else{
        lua_pushboolean(pL, true);
    }

    return 1;
}
int LuaMsgEx::WorldBroadcast(lua_State* pL) //protoid, msg
{
    Msg *pWriteMsg = g_pMsgPool->NewObj();
    if (!pWriteMsg){
        assert(0);
        return 0;
    }

    int nProtoId = luaL_checkinteger(pL, 1);
    pWriteMsg->SetID(nProtoId);
    pWriteMsg->SetMsgType(WORLD_BROADCAST);
    unsigned int uiLen = PP->encode(nProtoId,m_buf,pL,1);
    bool bRes = uiLen < sizeof(m_buf);
    if (!bRes){
        g_pMsgPool->DeleteObj(pWriteMsg);
        lua_pushboolean(pL,bRes);
        return 1;
    }
    evbuffer_add(pWriteMsg->GetBuf(), m_buf, uiLen);
    pWriteMsg->GetHead()->m_nLen += uiLen;
    if (!g_pSendMsgQueue->Push(pWriteMsg)){
        g_pMsgPool->DeleteObj(pWriteMsg);
        lua_pushboolean(pL,false);
        return 1;
    }


    lua_pushboolean(pL, bRes);
    return 1;
}
//对象管理全部放到lua层之后，c++层全部接受fd进行sendmsg
/*
int LuaMsgEx::SendMsg(lua_State* pL) //protoid, objid, msg
{
    Msg *pWriteMsg = g_pMsgPool->NewObj();
    if (!pWriteMsg){
        assert(0);
        return 0;
    }

	int nProtoId = luaL_checkinteger(pL, 1);
    int nObjID = luaL_checkinteger(pL, 2);
    pWriteMsg->SetID(nProtoId);
    pWriteMsg->SetMsgType(USER_BROADCAST);

    Obj* pObj = g_pObjIDManager->Get(nObjID);
    if (pObj == NULL) 
    {
        g_pMsgPool->DeleteObj(pWriteMsg);
        lua_pushboolean(pL, false);
        return 1;
    }
	//by tanjie
	//bool bRes = PP->WriteMsgDfs(pWriteMsg, nProtoId, pL);
	unsigned int uiLen = PP->encode(nProtoId,m_buf,pL);
	bool bRes = uiLen < sizeof(m_buf);
	if (!bRes){
		g_pMsgPool->DeleteObj(pWriteMsg);
        lua_pushboolean(pL, bRes);
        return 1;
	}
	evbuffer_add(pWriteMsg->GetBuf(), m_buf, uiLen);
	pWriteMsg->GetHead()->m_nLen += uiLen;



    // 这三个协议是特别的 我们缓存到c++层
    if ((nProtoId == GG_ADD_PLAYER_CACHE_DATA) ||
        (nProtoId == GG_ADD_MONSTER_CACHE_DATA) ||
        (nProtoId == GG_ADD_NPC_CACHE_DATA)||
        (nProtoId == GG_ADD_ITEM_CACHE_DATA)||
        (nProtoId == GG_ADD_PET_CACHE_DATA))
    {
        pObj->UpdateCacheInfoMsg(pWriteMsg);
    }
    else
    {
        pWriteMsg->PushReceiver(pObj->GetFD());
        if (!g_pSendMsgQueue->Push(pWriteMsg)){
		    g_pMsgPool->DeleteObj(pWriteMsg);
	        lua_pushboolean(pL, false);
	        return 1;
        }
    }

	lua_pushboolean(pL, true);
	return 1;
}
*/

//改成根据fdlist进行广播
int LuaMsgEx::UserBroadcast(lua_State* pL) //protoid,objidlist, msg
{
    if (!lua_istable(pL, 2)){
        return 0;
    }

    Msg *pWriteMsg = g_pMsgPool->NewObj();
    if (!pWriteMsg){
        assert(0);
        return 0;
    }

	int nProtoId = luaL_checkinteger(pL, 1);
    pWriteMsg->SetID(nProtoId);
    pWriteMsg->SetMsgType(USER_BROADCAST);

	//by tanjie
	unsigned int uiLen = PP->encode(nProtoId,m_buf,pL,2);
	bool bRes = uiLen < sizeof(m_buf);
    if (!bRes){
		g_pMsgPool->DeleteObj(pWriteMsg);
	}
    else{
        int nCnt = lua_objlen(pL, 2);
        //int nObjID = 0;
		int nFD = 0;
        for(int i=1; i<=nCnt; i++){
            lua_rawgeti(pL, 2, i);
			//改成根据fdlist进行广播
			nFD = lua_tointeger(pL, -1); 
            lua_pop(pL, 1);
			pWriteMsg->PushReceiver(nFD);
        }
        evbuffer_add(pWriteMsg->GetBuf(), m_buf, uiLen);
        pWriteMsg->GetHead()->m_nLen += uiLen;
        if (!g_pSendMsgQueue->Push(pWriteMsg)){
		    g_pMsgPool->DeleteObj(pWriteMsg);
        }
    }

	lua_pushboolean(pL, bRes);
	return 1;
}

//场景管理放到lua层之后，c++层的区域广播和场景广播已经没有意义了，但是全服广播还是有意义的

int LuaMsgEx::ZoneBroadcast(lua_State* pL) //protoid, objid, msg 
{
    Msg *pWriteMsg = g_pMsgPool->NewObj();
    if (!pWriteMsg){
        assert(0);
        return 0;
    }
	int nProtoId = luaL_checkinteger(pL, 1);
    int nObjID = luaL_checkinteger(pL, 2);
    pWriteMsg->SetID(nProtoId);
    pWriteMsg->SetMsgType(USER_BROADCAST);

    g_pMsgPool->DeleteObj(pWriteMsg);
	lua_pushboolean(pL, false);
	return 1;
}

int LuaMsgEx::SceneBroadcast(lua_State* pL) //protoid, sceneid, msg
{
    Msg *pWriteMsg = g_pMsgPool->NewObj();
    if (!pWriteMsg){
        assert(0);
        return 0;
    }
    int nProtoId = luaL_checkinteger(pL, 1);
    int nSceneID = luaL_checkinteger(pL, 2);
    pWriteMsg->SetID(nProtoId);
    pWriteMsg->SetMsgType(USER_BROADCAST);

    g_pMsgPool->DeleteObj(pWriteMsg);
    lua_pushboolean(pL, false);
    return 1;
}



const char LuaMsgEx::className[] = "LuaMsgEx";
Lunar<LuaMsgEx>::RegType LuaMsgEx::methods[] = {    
    LUNAR_DECLARE_METHOD(LuaMsgEx, ReadMsg),
    LUNAR_DECLARE_METHOD(LuaMsgEx, SendMsg),
    LUNAR_DECLARE_METHOD(LuaMsgEx, UserBroadcast),
    LUNAR_DECLARE_METHOD(LuaMsgEx, ZoneBroadcast),
    LUNAR_DECLARE_METHOD(LuaMsgEx, SceneBroadcast),
    LUNAR_DECLARE_METHOD(LuaMsgEx, WorldBroadcast),
    {0, 0} 
};

