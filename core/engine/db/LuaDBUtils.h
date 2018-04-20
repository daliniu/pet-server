#ifndef __LUA_DB_UTILS_H__
#define __LUA_DB_UTILS_H__
#include "../common/Lunar.h"
#include "RoundQueue.h"
#include "ObjPool.h"
#include <string>
#include <vector>
extern "C" 
{
    #include "mongo.h"
}


enum eQueryCode
{
	eQueryOK = 0,
	eQueryTimeout,
	eQueryError,
};
enum eQueryType
{
	eNone = 0,
	eInsert,
	eDelete,
	eFind,
	eUpdate,
	eCount,

};

struct sQuery
{
	eQueryType eQT;
	std::string strNS;
	bson bsQuery;
	bson bsSubQuery;
	int flag;
	unsigned int uLimit;
	unsigned int uSkip;
	sQuery(){
		eQT = eNone;
		uLimit = 0;
		uSkip = 0;
		m_nQueueID = 0;
		memset(&bsQuery,0,sizeof(bsQuery));
		memset(&bsSubQuery,0,sizeof(bsSubQuery));
	}
	inline int GetQueueID(){return m_nQueueID;}
	inline void SetQueueID(int nID) {m_nQueueID = nID;}
	inline short GetPoolID(){return m_nPoolID;}
	inline void CleanUp(){eQT = eNone;bson_destroy(&bsQuery);bson_destroy(&bsSubQuery);}
	inline void SetPoolID(int nPoolID){m_nPoolID = nPoolID;}
	unsigned int m_nTID;
	int m_nQueueID;
	int m_nPoolID;
	char m_oidhex[25];
};

struct sQueryResult
{
	eQueryCode eRetCode;
	//bson bsQueryResult;
	eQueryType eQT;
	inline int GetQueueID(){return m_nQueueID;}
	inline void SetQueueID(int nID) {m_nQueueID = nID;}
	inline short GetPoolID(){return m_nPoolID;}
	inline void SetPoolID(int nPoolID){m_nPoolID = nPoolID;}
	inline void CleanUp()
	{
		eQT = eNone;
		printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
		for (int i=0;i<bsVecResult.size();i++)
		{
			bson_destroy(&bsVecResult[i]);
		}
		bsVecResult.clear();
			
	}
	std::vector<bson> bsVecResult;
	double m_dCount;
	int m_nQueueID;
	unsigned int m_nTID;
	int m_nPoolID;
	char m_oidhex[25];
};
extern RoundQueue<sQuery> *g_pDBRequestQueue;
extern RoundQueue<sQueryResult> *g_pDBResponseQueue;
extern ObjPool<sQuery>		*g_pQueryPool;
extern ObjPool<sQueryResult>	*g_pQueryResultPool;
class LuaDBUtils
{
public:
	static bool LuaToBson(lua_State* pL,int nStackPos,bson* b,bool isArray=false);
    static bool LuaToBson(lua_State* pL,int nStackPos,bson* b,std::string& szMsg,bool isArray=false);
    static bool BsonToLua(lua_State* pL,const bson* b,bool isArray=false);
	static int Init();
public:
    static int CheckArray(lua_State* pL,int nStackPos);
    static bool IsDigit(const char* str);
    static void SetValue(lua_State* pL,const char* pKey,bool isArray = false);
};
//extern LuaDBUtils g_oLuaDBUtils;

#endif
