#ifndef __MONGO_DB_INTERFACE_H__
#define __MONGO_DB_INTERFACE_H__
#ifdef max
#undef max
#endif

#ifdef min
#undef min
#endif

extern "C" {
    #include "mongo.h"
}

#define MAX_HOST_IP_SIZE        32
#define MAX_DATABASE_SIZE     128
#define MAX_DB_USER_NAME_SIZE    64
#define MAX_DB_PWD_SIZE           64
#define MAX_FULL_NS     256

class MongoDBInterface
{
public:
    MongoDBInterface();
    virtual ~MongoDBInterface(); 
    bool Connect(const char* pHostIP,const char* pDataBase,const char* pUserName,const char* pPassword,int nPort=27017);
    bool Connect();
    bool Insert(const char* pNS, const bson* b);
    bool Remove(const char* pNS, const bson* b);
    bool Update(const char* pNS,const bson* query,const bson* modify,int flag);
    double Count(const char* pNS,const bson* query);
    int EnsureIndex(const char* pNS,const bson* b);
    int DropIndex(const char* pNS,const bson* b);
    mongo_cursor* Find(const char* pNS,const bson* query,const bson* show = 0,int limit=0,int skip=0);
    bson* GetQuery(){return m_query;}
    bson* GetShow(){return m_show;}
    
private:
    char* GetFullNsName(const char* pNS);
        char m_aryHostIP[MAX_HOST_IP_SIZE];
        char m_aryDataBase[MAX_DATABASE_SIZE];
        char m_aryUserName[MAX_DB_USER_NAME_SIZE];
        char m_aryPassword[MAX_DB_PWD_SIZE];
        char m_aryFullNS[MAX_FULL_NS];
        int  m_nPort;
        mongo m_pConn[1];
        //mongo_cursor m_pCursor[1];
        bson m_query[1];
        bson m_show[1];
    
};

#endif
