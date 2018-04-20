#include "Monitor.h"
#include "common/LogManager.h"
#include "Globals.h"
#include <string.h>

Monitor::Monitor()
{
    nOnline = 0;
    nMaxFD = 0;
    ClearDatas();
}

void Monitor::ClearDatas()
{
    nPacketsIn = 0;
    nPacketsOut = 0;
    nBytesIn = 0;
    nBytesOut = 0;

    nRecvQ = 0;
    nMaxRecvQ = 0;
    nSendQ = 0;
    nMaxSendQ = 0;
    nFrames = 0;
    nCCL = 0;
    nLCC = 0;
    nMonsterAI = 0;

    nProcessTimes = 0;
    nSendTimes = 0;

    nDBSelects = 0;
    nDBInserts = 0;
    nDBUpdates = 0;
    memset(sLog, 0, sizeof(sLog));
}

void Monitor::WriteLog()
{
    memset(sLog, 0, sizeof(sLog));
    tsnprintf(sLog, sizeof(sLog), 
        "[monitor] online:%d,pkgsIn:%u,pkgsOut:%u,bytesIn:%u(k),bytesOut:%u(k),recvQ:%d/%d,sendQ:%d/%d,objPool:null/null,pkgPool:%d/%d,maxFD:%d,frames:%d,ccl:%d,lcc:%d,monsterAI:%d,processTimes:%d,sendTimes:%d,dbSelects:%d,dbInserts:%d,dbUpdates:%d,luaMem:%dKB",
         nOnline, nPacketsIn, nPacketsOut, nBytesIn/1024, nBytesOut/1024, 
         g_pRecvMsgQueue->GetQueueLen(), nMaxRecvQ, 
         g_pSendMsgQueue->GetQueueLen(), nMaxSendQ, 
         g_pMsgPool->GetCount(), g_pMsgPool->PoolSize(), 
         nMaxFD, nFrames,nCCL,nLCC,nMonsterAI,nProcessTimes,nSendTimes,nDBSelects,nDBInserts,nDBUpdates,
         lua_gc(g_pL,LUA_GCCOUNT,0));

    g_oLogManager.WriteEngineLog(sLog);
    ClearDatas();
}
