#include <cstdlib>
#include <ctime>
#include <signal.h>
#include "RobotThread.h"
#include "RobotMap.h"

LogManager g_oLogManager; 


int main(int argc, char *argv[])
{
	/*
    if(!g_oLogManager.Init())
    {
        puts("logManager init fail!!!!!\n");
        return 0;
    }
	*/
    srand(time(0));
    static char name[6000][16];
    FILE *pFile = fopen("name.txt", "rb");
    if (!pFile)
    {
        assert(0);
        return 0;
    }
    for (int i = 0; i < sizeof(name) / sizeof(*name); ++i)
    {
        if (fscanf(pFile, "%s", name[i]) < 0)
        {
            break;
        }
    }
    /*
    RobotMap map101, map102, map103, map104, map201, map204, map301;
    map101.Init("scene/101.map");
    PII pii[64];
    //printf("\n%d\n", time(0));
    int n = 0;
    for (int i = 0; i < 1; ++i)
    {
        n = map101.GetPath(pii, 1, 1, 55555, 55555);
    }
    printf("\n%d\n", time(0));
    for (int i = 0; i < n; ++i)
    {
        printf("%d, %d\n", pii[i].first, pii[i].second);
    }
    map102.Init("scene/102.map");
    map103.Init("scene/103.map");
    */

#ifdef __WINDOWS__
    WSADATA wsaData;
    WSAStartup(MAKEWORD(2, 2), &wsaData);
    RobotThread::m_nRobotNum = 50;
    int nRobotNameStart = 0;
    bool bSupportHotUpdate = 0;
    int mapID = 102;
#else
    if (argc != 4)
    {
        printf("Usage: %s robot_num robot_start_from mapID\n", argv[0]);
        return -1;
    }
    RobotThread::m_nRobotNum = atoi(argv[1]);
    int nRobotNameStart = atoi(argv[2]);
    int mapID = atoi(argv[3]);
    bool bSupportHotUpdate = false;

    signal(SIGPIPE,SIG_IGN);
#endif

    RobotThread *pRobotThreads = new RobotThread[RobotThread::m_nRobotNum];
    for (int i = 0; i < RobotThread::m_nRobotNum; ++i)
    {
        if (!pRobotThreads[i].Init(name[nRobotNameStart + i], bSupportHotUpdate, mapID))
        {
            printf("Init RobotThread %d fail\n", i);
            assert(0);
        }

        pRobotThreads[i].Start();

/**/
#ifdef __WINDOWS__
        Sleep(50);
#else
        usleep(50000);
#endif

    }

    printf("Robot num: %d\n",RobotThread::m_nRobotNum);

    for (;;)
    {
#ifdef __WINDOWS__
        Sleep(1);
#else
        usleep(1000);
#endif
    }

    printf("robot normal exit\n");

    return 0;
}

