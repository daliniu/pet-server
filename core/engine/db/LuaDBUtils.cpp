#include "LuaDBUtils.h"
#include "RoundQueue.h"
#include "ObjPool.h"

//LuaDBUtils g_oLuaDBUtils ;
/*
RoundQueue<sQuery> *g_pDBRequestQueue;
RoundQueue<sQueryResult> *g_pDBResponseQueue;
ObjPool<sQuery>     *g_pQueryPool;
ObjPool<sQueryResult>   *g_pQueryResultPool;
*/
int LuaDBUtils::Init()
{
    /*
    g_pQueryPool = new ObjPool<sQuery>;
    g_pQueryPool->Init(1000);
    g_pQueryResultPool = new ObjPool<sQueryResult>;
    g_pQueryResultPool->Init(1000);
    g_pDBRequestQueue = new RoundQueue<sQuery>;
    g_pDBRequestQueue->Init(1000);
    g_pDBResponseQueue = new RoundQueue<sQueryResult>;
    g_pDBResponseQueue->Init(1000);
    */
    return 0;
}

int LuaDBUtils::CheckArray(lua_State* pL,int nStackPos)
{
    return lua_objlen(pL,nStackPos);
    
}

bool LuaDBUtils::IsDigit(const char* str)
{
    for(int i=0;str[i];i++)
    {
        if(str[i]<'0' || str[i]>'9')
        {
            return false;
        }
    }
    return true;
}

void LuaDBUtils::SetValue(lua_State* pL,const char* pKey,bool isArray)
{
    if(IsDigit(pKey))
    {
        lua_rawseti(pL, -2, atoi(pKey) + isArray); 
    }
    else
    {
        
    }
}

bool LuaDBUtils::LuaToBson(lua_State* pL,int nStackPos,bson* b,bool isArray)
{
	std::string strMsg;
	if (LuaToBson(pL,nStackPos,b,strMsg,isArray))
	{
		return true;
	}
	else
	{
		luaL_error(pL,strMsg.c_str());
		return false;
	}
}
bool LuaDBUtils::LuaToBson(lua_State* pL,int nStackPos,bson* b,std::string& strMsg,bool isArray)
{
    if( !lua_istable(pL, nStackPos))   
    {
        luaL_error(pL, "LuaToBson must be a table");
        return false;
    }   
    lua_pushnil(pL);
    char szKey[32]={0};
    while(lua_next(pL,nStackPos))
    {
        //处理key
        const char* pKey = NULL;
        if( lua_type(pL, -2) == LUA_TSTRING)
        {
            //只允许keyde类型为string
            pKey = lua_tostring(pL, -2);
        }
        else if (isArray && lua_type(pL,-2) == LUA_TNUMBER)
        {
            //the array index start from 0
            tsnprintf(szKey, 31,"%d", (int)lua_tointeger(pL, -2) - 1);
            pKey = szKey;
        }
        else 
        {
			char m[2048];
#ifdef __WINDOWS__
            _snprintf(m,2048,"key type = %d\n key = %d\n table key require string\n",lua_type(pL,-2),int(lua_tointeger(pL,-2)));
#else
			snprintf(m,2048,"key type = %d\n key = %d\n table key require string\n",lua_type(pL,-2),int(lua_tointeger(pL,-2)));
#endif
			strMsg+=m;
            return false;
        }
        
        //---处理value
        switch(lua_type(pL,-1))
        {
            case LUA_TSTRING:
            {
                if(strcmp(pKey,"_id")==0)
                {
                    bson_oid_t oid;
                    bson_oid_from_string( &oid, lua_tostring(pL,-1));
                    if (BSON_OK != bson_append_oid( b, "_id", &oid ))
                    {
                        luaL_error(pL,"lua to mongon _id error");
                        return false;
                    }
                }
                else
                {
                    if (BSON_OK != bson_append_string(b,pKey,lua_tostring(pL,-1)))
                    {
                        luaL_error(pL,"lua to mongo string error");
                    }
                }
            }
            break;

            case LUA_TBOOLEAN:
            {
                if (BSON_OK != bson_append_bool(b,pKey,lua_toboolean(pL,-1)))
                {
                    luaL_error(pL,"lua to mongo bool error");
                }
            }
            break;

            case LUA_TNUMBER:
            {
                if (BSON_OK != bson_append_double(b,pKey,lua_tonumber(pL,-1)))
                {
                    luaL_error(pL,"lua to mongo number error");
                }
            }
            break;

            case LUA_TTABLE:
            {

                int nArray = CheckArray(pL,lua_gettop(pL));
                if(nArray > 0)
                {
                    bson_append_start_array(b,pKey);
                    if(LuaToBson(pL,lua_gettop(pL),b,strMsg,true))
                    {
                        if (BSON_OK != bson_append_finish_array(b))
                        {
                            luaL_error(pL,"lua to mongo array error");
                            return false;
                        }
                    }
                    else
                    {
						char m[2048];
#ifdef __WINDOWS__
						_snprintf(m,2048,"key value = %s\n \n",pKey);
#else
						snprintf(m,2048,"key value = %s\n \n",pKey);
#endif
						strMsg+=m;
                        return false;
                    }
                }
                else
                {
                    bson_append_start_object(b,pKey);
                    if(LuaToBson(pL,lua_gettop(pL),b,strMsg))
                    {
                        if (BSON_OK != bson_append_finish_object(b))
                        {
                            luaL_error(pL,"lua to mongo object error");
                            return false;
                        }
                    }
                    else
                    {
						char m[2048];
#ifdef __WINDOWS__
						_snprintf(m,2048,"key value = %s\n \n",pKey);
#else
						snprintf(m,2048,"key value = %s\n \n",pKey);
#endif
						strMsg+=m;
                        return false;
                    }
                }
            }
            break;

            default:
            {
                luaL_error(pL, "LuaToBson type_key=%d", lua_type(pL,-1));
            }
            break;
        }




        lua_pop(pL,1);   //弹出value,剩下key取下一个key-value 
    }
    return true; 
}

bool LuaDBUtils::BsonToLua(lua_State* pL,const bson* b,bool isArray)
{
    if(!lua_istable(pL, -1)) 
    {
        printf("=========BsonToLua no table=============\n");
        lua_pop(pL, 1);

        lua_newtable(pL);
    }

    bson_iterator it[1];
    bson_iterator_init( it, (bson *)b );
    while( bson_iterator_next( it ) ) 
    {
        const char* pKey = bson_iterator_key( it );
        bool nextIsArray = false;

        switch(bson_iterator_type(it))
        {
            case BSON_DOUBLE:
            case BSON_INT:
            case BSON_LONG:
            {
                lua_pushnumber(pL,bson_iterator_double(it));
            }
            break;
            case BSON_STRING:
            {
                lua_pushstring(pL,bson_iterator_string(it));
            }
            break;
            case BSON_ARRAY:
                nextIsArray = true;
            case BSON_OBJECT:
            {
                if (isArray)
                {
                    lua_rawgeti(pL, -1,atoi(pKey) + 1);
                    if(!lua_istable(pL, -1))
                    {              
                        lua_pop(pL,1);
                        lua_newtable(pL);
                    }
                }
                else
                {
                    lua_getfield(pL,-1,pKey);
                    if(!lua_istable(pL,-1))
                    {
                        lua_pop(pL,1);
                        lua_newtable(pL);
                    }                    
                }

                bson sub[1];
                bson_iterator_subobject_init( it, sub ,false);
                BsonToLua(pL,sub,nextIsArray);
            }
            break;
            case BSON_OID:
            {
                bson_oid_t *oid = bson_iterator_oid(it);
                char _id[128]= {0};
                bson_oid_to_string(oid,_id);
                lua_pushstring(pL,_id);
            }
            break;
            case BSON_BOOL:
            {
                lua_pushboolean(pL,bson_iterator_bool(it));
            }
            break;
            default:
            {
                lua_pushstring(pL,"Bson To Lua ... error bson type");
            }
            break;
        }
        if (isArray)
        {
            lua_rawseti(pL, -2, atoi(pKey) + 1); 
        }
        else
        {
            lua_setfield(pL,-2,pKey); 
        }
        
        //lua_setfield(pL,-2,pKey); 
        //SetValue(pL,pKey,isArray);

    }


    return true;
}


