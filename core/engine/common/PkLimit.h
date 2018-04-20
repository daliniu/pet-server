#ifndef _PK_LIMIT_
#define _PK_LIMIT_

#define PKLIMIT PkLimit::GetInstance()

struct PkLimit
{
    enum{
        OK,
        FD_OR_PKID_INVALID,
        FIXING,
        TOO_FAST
    };
    static const int CG_ID_MAX = 32768; //��CG_��ͷ�İ����ID��CG_ID_MAX
    static const int CG_CNT_MAX = 512; //��CG_��ͷ�İ������PK_CG_CNT_MAX
    static const int FD_MAX = 8192 * 2;
    char second[CG_CNT_MAX];//������Ϊһ�����
    char cnt[CG_CNT_MAX];   //һ�����֮�����Ϊ���ٴ�
    short hash[CG_ID_MAX];   //��PacketID����hash
    int lastTime[FD_MAX][CG_CNT_MAX];   //��¼��fd��Э�����һ�ε�ʱ��
    char lastCnt[FD_MAX][CG_CNT_MAX];    //��¼��fd��Э��Ŵ���

    static PkLimit *GetInstance()
    {
        static PkLimit ref;
        return &ref;
    }

    static int _SetHashPk(lua_State *pL)
    {
        PKLIMIT->hash[(int)luaL_checknumber(pL, 1)] = (short)luaL_checknumber(pL, 2);
        return 0;
    }

    static int _SetPkLimit(lua_State *pL)
    {
        short hashPkID = PKLIMIT->hash[(short)luaL_checknumber(pL, 1)];
        assert(hashPkID);
        PKLIMIT->second[hashPkID] = (char)luaL_checknumber(pL, 2);
        PKLIMIT->cnt[hashPkID] = (char)luaL_checknumber(pL, 3);
        return 0;
    }

    int CheckPkLimit(short fd, short packetID)
    {
        if (!(0<=fd&&fd<FD_MAX
            && 0<=packetID&&packetID<CG_ID_MAX
            && hash[packetID]))
        {
            return FD_OR_PKID_INVALID;
        }
        short hashPkID = hash[packetID];
        if (cnt[hashPkID] <= 0)
        {
            return FIXING;
        }
        if (second[hashPkID] <= 0)  //������
        {
            return OK;
        }
        
        int curTime = (int)time(0);
        if (curTime < lastTime[fd][hashPkID] + second[hashPkID] && cnt[hashPkID] <= lastCnt[fd][hashPkID])
        {
            return TOO_FAST;
        }
        if (lastTime[fd][hashPkID] + second[hashPkID] <= curTime)
        {
            lastTime[fd][hashPkID] = curTime;
            lastCnt[fd][hashPkID] = 0;
        }
        ++lastCnt[fd][hashPkID];
        return OK;
    }
};

#endif

