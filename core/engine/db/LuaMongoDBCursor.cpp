#include "LuaMongoDBCursor.h"
const char LuaMongoDBCursor::className[] = "MongoDBCursor";
Lunar<LuaMongoDBCursor>::RegType LuaMongoDBCursor::methods[] = 
{
    LUNAR_DECLARE_METHOD(LuaMongoDBCursor, Next),
    LUNAR_DECLARE_METHOD(LuaMongoDBCursor, Count),
    {0,0}
};

int LuaMongoDBCursor::Next(lua_State* pL)
{

    if(!m_pCursor)
    {
        lua_pushboolean(pL, 0);
        return 1;
    }

    if( mongo_cursor_next( m_pCursor ) == MONGO_OK )
    {
        //bson_print( &m_pCursor->current );
        LuaDBUtils::BsonToLua( pL, &m_pCursor->current);
        lua_pushboolean(pL, 1);
    }
    else
    {
        //printf("query -- next err= %d\n",m_pCursor->conn->err);
        mongo_cursor_destroy(m_pCursor);
        m_pCursor = NULL;
        lua_pushboolean(pL,0);
    }   
    return 1;
}

int LuaMongoDBCursor::Count( lua_State* pL)
{
    int nCount = 0;
    //if( m_pCursor)
    //{
    //    //暂时不实现
    //}

    lua_pushnumber(pL,nCount);
    return 1;
}
