#ifndef __MONITOR_H__
#define __MONITOR_H__

#include <stdlib.h>

class Monitor
{
    public: 
        Monitor();
        void WriteLog(); 
        void ClearDatas();

    public:
        int nOnline;

        unsigned int nPacketsIn;
        unsigned int nPacketsOut;
        unsigned int nBytesIn;
        unsigned int nBytesOut;
        int nMaxFD;

        int nRecvQ;
        int nMaxRecvQ;
        int nSendQ;
        int nMaxSendQ;

        int nFrames;
        int nCCL; //C Call Lua
        int nLCC; //Lua Call C
        int nMonsterAI; //Call monster AI

        int nProcessTimes; 
        int nSendTimes;
        
        int nDBSelects;
        int nDBInserts;
        int nDBUpdates;

        char sLog[512];
};


#endif //__MONITOR_H__

