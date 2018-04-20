#ifndef __LUA_MONGODB_CURSOR_H__
#define  __LUA_MONGODB_CURSOR_H__
#include "LuaDBUtils.h"
#include "../common/Lunar.h"

extern "C" 
{
    #include "mongo.h"
}

class LuaMongoDBCursor
{
    public: 
        LuaMongoDBCursor( lua_State* pL)
        { 
            m_pCursor = (mongo_cursor*)lua_touserdata(pL, -1);
        } 
        ~LuaMongoDBCursor()
        { 
            //printf("LuaMongoDBCursor into delete\n");
            if(m_pCursor) 
            { 
                //delete m_pCursor ;   
                mongo_cursor_destroy(m_pCursor);
                m_pCursor = NULL;
            }
        }
        int Next( lua_State* pL);  
        int Count( lua_State* pL);
        const static char className[];
        static Lunar<LuaMongoDBCursor>::RegType methods[];
    private:  
        mongo_cursor* m_pCursor;
};

#endif
