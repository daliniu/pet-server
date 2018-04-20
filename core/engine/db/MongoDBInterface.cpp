#include "MongoDBInterface.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Type.h"

MongoDBInterface::MongoDBInterface()
{
    memset(m_aryHostIP, 0, sizeof(m_aryHostIP));
    memset(m_aryDataBase, 0, sizeof(m_aryDataBase));
    memset(m_aryUserName, 0, sizeof(m_aryUserName));
    memset(m_aryPassword, 0 , sizeof(m_aryPassword));
    memset(m_aryFullNS,0,sizeof(m_aryFullNS));
    mongo_init_sockets();
    m_nPort = 0;
}

MongoDBInterface::~MongoDBInterface()
{
    mongo_destroy( m_pConn );
}

char* MongoDBInterface::GetFullNsName(const char* pNS)
{
    //return (char*)pNS;
    //===========================================================//
    tsnprintf(m_aryFullNS,MAX_FULL_NS-1,"%s.%s",m_aryDataBase,pNS);
    return m_aryFullNS;
}

bool MongoDBInterface::Connect(const char* pHostIP,const char* pDataBase,const char* pUserName,const char* pPassword,int nPort/*=27017*/)
{
    strncpy(m_aryHostIP, pHostIP, MAX_HOST_IP_SIZE);
    strncpy(m_aryDataBase, pDataBase, MAX_DATABASE_SIZE);
    strncpy(m_aryUserName, pUserName, MAX_DB_USER_NAME_SIZE);
    strncpy(m_aryPassword, pPassword, MAX_DB_PWD_SIZE);
    m_nPort = nPort;
    return Connect();
}

bool MongoDBInterface::Connect()
{
    //int status = mongo_connect( m_pConn, m_aryHostIP, m_nPort );
    int status = mongo_client( m_pConn, m_aryHostIP, m_nPort );
    if( status != MONGO_OK ) {
        printf("connect err=%d\n",m_pConn->err);
        return false;
    }
    if(mongo_cmd_authenticate( m_pConn, m_aryDataBase, m_aryUserName, m_aryPassword ) != MONGO_OK)
    {
        printf("auth fail database=%s,username=%s,password=%s\n",m_aryDataBase,m_aryUserName,m_aryPassword);
        return false;
    }


    return true;
}

bool MongoDBInterface::Insert(const char* pNS,const bson* b) 
{
    if (MONGO_OK!=mongo_insert( m_pConn, GetFullNsName(pNS), b,0 ))
    {
        printf("Insert fail pNS=%s\n",pNS);
        printf("conn err=%d\n",m_pConn->err);
        return false;
    }
    return true;
}

bool MongoDBInterface::Remove(const char* pNS,const bson* b)
{
    if(MONGO_OK!=mongo_remove(m_pConn,GetFullNsName(pNS),b,0))
    {
        printf("Remove fail pNS=%s\n",pNS);
        printf("conn err=%d\n",m_pConn->err);
        return false;
    }
    return true;
}

bool MongoDBInterface::Update(const char* pNS,const bson* query,const bson* modify,int flag)
{
    if(MONGO_OK!=mongo_update(m_pConn,GetFullNsName(pNS),query,modify,flag,0))
    {
        printf("update fail pNS=%s\n",pNS);
        printf("conn err = %d\n",m_pConn->err);
        return false;
    }
    return true;
}

double MongoDBInterface::Count(const char* pNS,const bson* query)
{
    return mongo_count(m_pConn,m_aryDataBase,pNS,query);
}


mongo_cursor* MongoDBInterface::Find(const char* pNS,const bson* query,const bson* show,int limit,int skip)
{
    return mongo_find(m_pConn,GetFullNsName(pNS),query,show,limit,skip,0);
    /*
    mongo_cursor_init( m_pCursor, m_pConn, GetFullNsName(pNS) );
    mongo_cursor_set_query( m_pCursor, query );
    if(show)
    {
        printf("-----------show------------\n");
        mongo_cursor_set_fields(m_pCursor,show);
    }
    if(limit)
    {
        printf("--------------limit--------------\n");
        mongo_cursor_set_limit(m_pCursor,limit);
    }
    if(skip)
    {
        printf("---------------skip------------------\n");
        mongo_cursor_set_skip(m_pCursor,skip);
    }

    return m_pCursor;
    */
}
int MongoDBInterface::EnsureIndex(const char* pNS,const bson* b)
{
    bson out[1];
    int ret = mongo_create_index( m_pConn, GetFullNsName(pNS), b,NULL, 0, out );   
	if (MONGO_ERROR != ret)
	{
		bson_destroy(out);
	}
	
    return ret;
}

int MongoDBInterface::DropIndex(const char* pNS,const bson* b)
{
    
    return 0;
}
