#include "LuaMongoDB.h"
#include "LuaDBUtils.h"
#include "iostream"
#include "Assertx.h"

using namespace std;

const char LuaMongoDB::className[] = "MongoDB";
unsigned int LuaMongoDB::s_uiTID = 0;
Lunar<LuaMongoDB>::RegType LuaMongoDB::methods[] = 
{ 
    LUNAR_DECLARE_METHOD(LuaMongoDB, SyncInsert),
    LUNAR_DECLARE_METHOD(LuaMongoDB, Insert),
	LUNAR_DECLARE_METHOD(LuaMongoDB, SyncDelete),
    LUNAR_DECLARE_METHOD(LuaMongoDB, Delete),
    LUNAR_DECLARE_METHOD(LuaMongoDB, Find),
    LUNAR_DECLARE_METHOD(LuaMongoDB, Update),
    LUNAR_DECLARE_METHOD(LuaMongoDB, SyncUpdate),
    LUNAR_DECLARE_METHOD(LuaMongoDB, SyncFind),
    LUNAR_DECLARE_METHOD(LuaMongoDB, Connect),
	LUNAR_DECLARE_METHOD(LuaMongoDB, SyncCount),
    LUNAR_DECLARE_METHOD(LuaMongoDB, Count),
    LUNAR_DECLARE_METHOD(LuaMongoDB, EnsureIndex),
    LUNAR_DECLARE_METHOD(LuaMongoDB, DropIndex),
    {0,0}
};
/**/
int LuaMongoDB::Connect(lua_State* pL)
{
    const char* pIP = luaL_checkstring(pL,1);
    const char* pDBName = luaL_checkstring( pL, 2);
    const char* pDBUser = luaL_checkstring( pL, 3);
    const char* pDBPwd  = luaL_checkstring( pL, 4);
	int nPort  = (int)luaL_checknumber( pL, 5);
    if( !m_pMongoDBInterface->Connect(pIP, pDBName, pDBUser, pDBPwd, nPort))
    {
        lua_pushboolean(pL, false);  
    } 
    else
    { 
        lua_pushboolean(pL, true);  
    } 
    return 1;
}
int LuaMongoDB::SyncInsert(lua_State* pL)
{
    g_pMonitor->nDBInserts++;   
    const char *pNS = luaL_checkstring(pL, 1);
	int nRet = 0;
	char oidhex[25];
    if(!lua_istable( pL, 2))
    {
		lua_pushnil(pL);
        printf("insert interface must be a bable\n");
    } 
    else
    {
        bson b[1];
        bson_init(b);
		lua_pushstring(pL,"_id");
		lua_rawget(pL,-2);
		if (lua_isnoneornil(pL,-1))
		{
			bson_oid_t oid;
			bson_oid_gen( &oid );
			bson_append_oid( b, "_id", &oid );
			bson_oid_to_string(&oid,oidhex);
		}
		else
		{
			strncpy(oidhex,lua_tostring(pL,-1),24);
		}
		oidhex[24] = 0;
		lua_pop(pL, 1);

        if( LuaDBUtils::LuaToBson(pL, 2,b)) 
        {
            bson_finish(b);
            if(m_pMongoDBInterface->Insert(pNS, b))  
            { 
                nRet  = 1;
            } 
        } 
        bson_destroy(b);
	} 
	lua_pushboolean(pL, nRet);   
	lua_pushstring(pL, oidhex);
    return 2;
}
int LuaMongoDB::SyncFind(lua_State* pL)
{
    g_pMonitor->nDBSelects++;   
    const char* pNS = luaL_checkstring(pL, 1);
    bson *query = m_pMongoDBInterface->GetQuery();
    bson *show = m_pMongoDBInterface->GetShow();
    int limit=0;
    int skip=0;

    bson_init(query);
    if(LuaDBUtils::LuaToBson(pL, 2, query))
    {
        bson_finish(query);
    }
    else
    {
        bson_destroy(query);
        printf("query to bson fail\n");
        return 0;
    }

    
    bson_init(show);
    if(!lua_isnoneornil(pL, 3))
    {
        if(LuaDBUtils::LuaToBson(pL,3,show))
        {
            bson_finish(show);
        }
        else
        {
            printf("show to bson fail\n");
            bson_destroy(show);
            return 0;
        }

        if(!lua_isnoneornil(pL,4))
        {
            limit = luaL_checkint(pL,4);

            if(!lua_isnoneornil(pL,5))
            {
                skip = luaL_checkint(pL,5);
            }
        }
    }
    else
    {
        bson_finish(show);
    }

    mongo_cursor* pCursor = m_pMongoDBInterface->Find(pNS,query,show,limit,skip);


    bson_destroy(query);
    bson_destroy(show);

    lua_pushlightuserdata(pL, pCursor);
    return 1;
}
int LuaMongoDB::Insert(lua_State* pL)
{  
	//AssertFt(false,"fuck %s","xiao luo zi");
    const char *pNS = luaL_checkstring(pL, 1);
    int nRet = 0;
  //  char oidhex[25];  // the oid will be returned
    if(!lua_istable( pL, 2))
    {
        printf("insert interface must be a table\n");
        nRet = 0;
    } 
    else
    {
        sQuery *q = g_pDBQueryPool->NewObj();
        if (q)
		{
			char* oidhex = q->m_oidhex;
			q->strNS = pNS;
            bson_init(&(q->bsQuery));
            lua_pushstring(pL,"_id");
            lua_rawget(pL, 2);
            if (lua_isnoneornil(pL,-1))
            {
                //bson_append_new_oid(&(q->bsQuery),"_id")
                bson_oid_t oid;
                bson_oid_gen( &oid );
                bson_append_oid( &(q->bsQuery), "_id", &oid );
                bson_oid_to_string(&oid,oidhex);
            }
            else
            {
                strncpy(oidhex,lua_tostring(pL,-1),24);
            }
			oidhex[24] = 0;
			lua_pop(pL, 1);

            if( LuaDBUtils::LuaToBson(pL, 2,&(q->bsQuery)))
            {
                bson_finish(&(q->bsQuery));
                q->eQT = eInsert;
                q->m_nTID = getTID();
                g_pDBRequestQueue->Push(q);
            }
            else
            {
				bson_destroy(&(q->bsQuery));
                AssertEx(false,"lua to bson fail");
            }
            nRet = q->m_nTID;
        } 
    }
    lua_pushnumber(pL,nRet); 
    return 1;
}

int LuaMongoDB::Delete(lua_State* pL)
{
    const char* pNS = luaL_checkstring(pL, 1);
    int nRet = 0;
    if( !lua_istable(pL, 2))
    {      
        printf("delete interface must be a table\n");
        nRet = 0;
    }
    else 
    { 
        sQuery *q = g_pDBQueryPool->NewObj();
        if (q)
		{
			q->strNS = pNS;
            q->eQT = eDelete;
            bson_init(&(q->bsQuery));
            if( LuaDBUtils::LuaToBson(pL,2, &(q->bsQuery)))
            {
                bson_finish(&(q->bsQuery));
                q->m_nTID = getTID();
                g_pDBRequestQueue->Push(q);
            }
            else
            {
				bson_destroy(&(q->bsQuery));
                assert(0);
            }
        }
        else
        {
            assert(0);
        }
        nRet = q->m_nTID;
    }
    lua_pushinteger(pL, nRet);
    return 1;
}
int LuaMongoDB::SyncDelete(lua_State* pL)
{
	const char* pNS = luaL_checkstring(pL, 1);
	int nRet = 0;
	if( !lua_istable(pL, 2))
	{      
		printf("delete interface must be a table\n");
		nRet = 0;
	}
	else 
	{ 
		bson query;
		bson_init(&query);
		if( LuaDBUtils::LuaToBson(pL,2, &query))
		{
			bson_finish(&query);
			m_pMongoDBInterface->Remove(pNS,&query);
		}
		bson_destroy(&query);
	}
	lua_pushinteger(pL, nRet);
	return 1;
}

int LuaMongoDB::Find(lua_State* pL)
{  
    const char* pNS = luaL_checkstring(pL, 1);
    int nRet = 0;
    sQuery *q = g_pDBQueryPool->NewObj();
    if (!q)
    {
        assert(0);
		return 0;
    }

	q->strNS = pNS;

    bson_init(&(q->bsQuery));
    if(LuaDBUtils::LuaToBson(pL, 2, &(q->bsQuery)))
    {
        bson_finish(&(q->bsQuery));
    }
    else
    {
        bson_destroy(&(q->bsQuery));
        printf("query to bson fail\n");
        g_pDBQueryPool->DeleteObj(q);
        return 0;
    }

    q->m_nTID = getTID();
    q->eQT = eFind;
    bson_init(&(q->bsSubQuery));
    if(!lua_isnoneornil(pL, 3))
    {
        if(LuaDBUtils::LuaToBson(pL,3,&(q->bsSubQuery)))
        {
            bson_finish(&(q->bsSubQuery));
        }
        else
        {
            printf("show to bson fail\n");
            bson_destroy(&(q->bsSubQuery));
            lua_pushinteger(pL, nRet);
            g_pDBQueryPool->DeleteObj(q);
            return 0;
        }

        if(!lua_isnoneornil(pL,4))
        {
            q->uLimit = luaL_checkint(pL,4);

            if(!lua_isnoneornil(pL,5))
            {
                q->uSkip = luaL_checkint(pL,5);
            }
        }
    }
    else
    {
        bson_finish(&(q->bsSubQuery));
    }


    g_pDBRequestQueue->Push(q);
    nRet = q->m_nTID;
    lua_pushinteger(pL, nRet);
    return 1;
}
int LuaMongoDB::SyncUpdate(lua_State* pL)
{
    g_pMonitor->nDBUpdates++;   
    const char* pNS  =  luaL_checkstring(pL, 1);
    int flag = MONGO_UPDATE_BASIC;
    bson query[1],modify[1];
    bson_init(query);
    if(LuaDBUtils::LuaToBson(pL,2,query))
    {
        bson_finish(query);
    }
    else
    {
        bson_destroy(query);
        lua_pushboolean(pL,0);
        return 1;
    }

    bson_init(modify);
    if(LuaDBUtils::LuaToBson(pL,3,modify))
    {
        bson_finish(modify);
    }
    else
    {
        bson_destroy(modify);
        lua_pushboolean(pL,0);
        return 1;
    }
    if(!lua_isnoneornil(pL, 4)) 
    {
        if(luaL_checkint(pL, 4))
        {
            flag |= MONGO_UPDATE_UPSERT;
        }
        if( !lua_isnoneornil(pL, 5))   
        {
            if(luaL_checkint(pL,5))
			{
				//目前这个参数有问题，等求解
                //flag |= MONGO_UPDATE_MULTI; 
            }
        }
    }
    bool nRet = m_pMongoDBInterface->Update(pNS,query,modify,flag);

    bson_destroy(query);
    bson_destroy(modify);

    lua_pushboolean(pL,nRet);
    return 1;
}

int LuaMongoDB::Update(lua_State* pL)
{

    const char* pNS  =  luaL_checkstring(pL, 1);
    int nRet = 0;
    
    sQuery *q = g_pDBQueryPool->NewObj();
	if(!q)
	{
		assert(false);
		return 0;
	}
    q->strNS = pNS;
    q->m_nTID = getTID();
    q->eQT = eUpdate;
    q->flag = MONGO_UPDATE_BASIC;
    bson_init(&(q->bsQuery));
    if(LuaDBUtils::LuaToBson(pL,2,&(q->bsQuery)))
    {
        bson_finish(&(q->bsQuery));
    }
    else
    {
        bson_destroy(&(q->bsQuery));
        lua_pushboolean(pL,0);
        return 0;
    }

    bson_init(&(q->bsSubQuery));
    if(LuaDBUtils::LuaToBson(pL,3,&(q->bsSubQuery)))
    {
        printf("LuaToBson ok!");
        bson_finish(&(q->bsSubQuery));
    }
    else
    {
        printf("LuaToBson fail!");
        bson_destroy(&(q->bsSubQuery));
        lua_pushboolean(pL,0);
        return 0;
    }
    
    if(!lua_isnoneornil(pL, 4)) 
    {
        if(luaL_checkint(pL, 4))
        {
            q->flag |= MONGO_UPDATE_UPSERT;
        }
        if( !lua_isnoneornil(pL, 5))   
        {
            if(luaL_checkint(pL,5))
            {
				//目前这个参数有问题，等求解
                //flag |= MONGO_UPDATE_MULTI; 
            }
        }
    }
    

    g_pDBRequestQueue->Push(q);
    nRet = q->m_nTID;
    lua_pushinteger(pL, nRet);
    return 1;
}


int LuaMongoDB::Count(lua_State* pL)
{
    const char* pNS = luaL_checkstring(pL, 1);
    sQuery *q = g_pDBQueryPool->NewObj();
	if(!q)
	{
		assert(false);
		return 0;
	}
    q->strNS = pNS;
    q->m_nTID = getTID();
    q->eQT = eCount;
    int nRet = 0;
    bson_init(&(q->bsQuery));
    if(LuaDBUtils::LuaToBson(pL,2,&(q->bsQuery)))
    {
        bson_finish(&(q->bsQuery));
    }
    else
    {
        bson_destroy(&(q->bsQuery));
        g_pDBQueryPool->DeleteObj(q);
        lua_pushnumber(pL,0);
        return 0;
    }

    g_pDBRequestQueue->Push(q);
    nRet = q->m_nTID;

    lua_pushnumber(pL,nRet);
    return 1;
}

int LuaMongoDB::SyncCount(lua_State* pL)
{
	const char* pNS = luaL_checkstring(pL, 1);
	bson query;
	bson_init(&query);
	int count = 0;
	if(LuaDBUtils::LuaToBson(pL,2,&query))
	{
		bson_finish(&query);
		count = m_pMongoDBInterface->Count(pNS,&query);
	}

	bson_destroy(&query);
	lua_pushnumber(pL,count);
	return 1;
}

int LuaMongoDB::EnsureIndex(lua_State* pL)
{
    //bson b, out;    bson_iterator it;    bson_init( &b );    bson_append_int( &b, "foo", 1 );    bson_finish( &b );    mongo_create_index( conn, "test.bar", &b, MONGO_INDEX_SPARSE | MONGO_INDEX_UNIQUE, &out );    bson_destroy( &b );    bson_destroy( &out );
    int nRet = 1;
    const char* pNS = luaL_checkstring(pL, 1);
    if(!lua_istable(pL,2))
    {
       luaL_error(pL,"EnsureIndex,param2 must be a table"); 
       nRet = 0;
    }
    //lua_gettable(pL,2);

    if(nRet)
    {
        int len = lua_objlen(pL,2);
        bson b[1];
        bson_init(b);
        char szKey[32] = {0};
        for(int i=1;i<=len;i++)
        {
            lua_rawgeti(pL,2,i);
            if(!lua_istable(pL,-1))
            {
                nRet = 0;
                luaL_error(pL,"EnsureIndex,param2 must like this {{},{}}"); 
                break;
            }
            lua_pushnil(pL);
            if(lua_next(pL,-2))
            {
                //处理key
                const char* pKey = NULL;
                if( lua_type(pL, -2) == LUA_TSTRING)
                {
                    pKey = lua_tostring(pL, -2);
                } 
                else if( lua_type(pL, -2) == LUA_TNUMBER)
                {
                    tsnprintf(szKey, 31,"%d", (int)lua_tointeger(pL, -2));
                    pKey = szKey;
                } 
                else 
                {
                    luaL_error(pL, " table key require string or number");
                    nRet = 0;
                    break;
                }
                int order = luaL_checkint(pL,-1);
                if(order != -1  && order != 1)
                {
                    luaL_error(pL,"EnsuerIndex,order must be 1 or -1");
                    nRet = 0;
                    break;
                }
                bson_append_int( b,pKey, order );
                lua_pop(pL,2);   //
                
            }
            else
            {
                nRet = 0;
                lua_pop(pL,1);
                break;
            }
        }

        bson_finish( b ); 

        if(nRet)
        {
            nRet = m_pMongoDBInterface->EnsureIndex(pNS,b);
		}
		bson_destroy( b );    
    }
    

    lua_pushnumber(pL,nRet);
    return 1;

}
int LuaMongoDB::DropIndex(lua_State* L)
{
    return 0;
}

