#ifndef __LUA_MONGO_DB_INTERFACE_H__
#define __LUA_MONGO_DB_INTERFACE_H__
#include "../common/Lunar.h"
#include <cassert>
#include "LuaDBUtils.h"
#include "MongoDBInterface.h"
#include "RoundQueue.h"
#include "ObjPool.h"
#include "Globals.h"
class LuaMongoDB
{
    public:
        LuaMongoDB(lua_State* L) 
        {
            m_pMongoDBInterface = new MongoDBInterface();

        };   
        ~LuaMongoDB()
        {
            printf("LuaMongoDB into Delete\n");
        }
        int Connect(lua_State* pL);
        int SyncInsert(lua_State* pL);
        int Insert(lua_State* pL);
        int Delete(lua_State* pL);
		int SyncDelete(lua_State* pL);
        int Find(lua_State* pL);
        int SyncUpdate(lua_State* pL);
        int SyncFind(lua_State* pL);
        int Update(lua_State* pL);
        int Count(lua_State* pL);
		int SyncCount(lua_State* pL);
        int EnsureIndex(lua_State* pL);
        int DropIndex(lua_State* pL);
        const static char className[];
        static Lunar<LuaMongoDB>::RegType methods[];
        static unsigned int getTID() {return ++s_uiTID;}
    private:    
        // by tanjie this db interface is for sync access
        MongoDBInterface* m_pMongoDBInterface;
        //暂定主线程和db线程通过环形缓冲进行交换数据，暂时先用一组，只支持一个db线程，以后可扩充，上层接口保持不变

        static unsigned int s_uiTID;
};
#endif //__LUA_MONGO_DB_INTERFACE_H__
