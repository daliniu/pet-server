
#include "DBThread.h"
#include "MongoDBInterface.h"
#include "Globals.h"



DBThread::DBThread()
{

}

DBThread::~DBThread()
{
}
bool DBThread::Init()
{
	m_pMongoDBInterface = new MongoDBInterface();
	if (!m_pMongoDBInterface->Connect(g_cDBIP,g_cDBName,g_cDBUser, g_cDBPass,g_cDBPort))
	{
		return false;
	}
	else
	{
		return true;
	}
}

void DBThread::Run()
{
	while (true)
	{
		sQuery *q = g_pDBRequestQueue->Pop();

		if (!q)
		{
			//usleep(0);
#ifdef __WINDOWS__
			Sleep(1);
#else
			usleep(1);
#endif
			continue;
		}
		sQueryResult *r = g_pDBQueryResultPool->NewObj();
		r->m_nTID = q->m_nTID;
		r->eQT = q->eQT;
		switch (q->eQT)
		{
		case eInsert:
			{
				if (m_pMongoDBInterface->Insert(q->strNS.c_str(),&(q->bsQuery)))
				{
					r->eRetCode = eQueryOK;
				}
				else
				{
					r->eRetCode = eQueryError;
				}
				strncpy(r->m_oidhex,q->m_oidhex,25);
			}
			break;
		case eUpdate:
			{
				if (m_pMongoDBInterface->Update(q->strNS.c_str(),&(q->bsQuery),&(q->bsSubQuery),q->flag))
				{
					r->eRetCode = eQueryOK;
				}
				else
				{
					r->eRetCode = eQueryError;
				}
			}
			break;
		case eFind:
			{
				mongo_cursor* pCursor = m_pMongoDBInterface->Find(q->strNS.c_str(),&(q->bsQuery),&(q->bsSubQuery),q->uLimit,q->uSkip);
				if (pCursor)
				{
					while (mongo_cursor_next(pCursor) == MONGO_OK)
					{
						bson b ;
						bson_copy(&	b,&pCursor->current);
						r->bsVecResult.push_back(b);

					}
					mongo_cursor_destroy(pCursor);
					r->eRetCode = eQueryOK;
				}
				else
				{
					r->eRetCode = eQueryError;
				}
			}
			break;
		case eCount:
			{
				double ret = m_pMongoDBInterface->Count(q->strNS.c_str(),&(q->bsQuery));
				if (ret == MONGO_ERROR)
				{
					r->eRetCode = eQueryError;
				}
				else
				{
					r->eRetCode = eQueryOK;
					r->m_dCount = ret;
				}
			}
			break;
		case eDelete:
			{
				if (m_pMongoDBInterface->Remove(q->strNS.c_str(),&(q->bsQuery)))
				{
					r->eRetCode = eQueryOK;
				}
				else
				{
					r->eRetCode = eQueryError;
				}
			}
			break;
		default:
			assert(0);
			break;
		}
		g_pDBQueryPool->DeleteObj(q);
		g_pDBResponseQueue->Push(r);
	}
}