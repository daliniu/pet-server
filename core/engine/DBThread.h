#ifndef __DBTHREAD_H__
#define __DBTHREAD_H__

#include "Thread.h"
#include "LuaDBUtils.h"
#include "ObjPool.h"
#include "RoundQueue.h"
#include "MongoDBInterface.h"


class DBThread:public Thread
{
public:
	DBThread();
    ~DBThread();
	bool Init();
	void Run();
	void Stop();
private:
	MongoDBInterface *m_pMongoDBInterface;
};








#endif



