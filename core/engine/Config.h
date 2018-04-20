#ifndef __CONFIG_H__
#define __CONFIG_H__

#define     GAME_IO_HEARTBEAT           5               // 网络io心跳间隔 ms
#define     GAME_LOGIC_HEARTBEAT        250             // 游戏logic层心跳间隔 ms
#define     GAME_LOG_HEARTBEAT          200             // 游戏日志线程心跳间隔 ms
#define     MAX_ONLINE_PLAYER           4000            // 最大在线玩家数
#define     CLIENT_READ_TIMEOUT         60 * 1          //s 

#endif //__CONFIG_H__
