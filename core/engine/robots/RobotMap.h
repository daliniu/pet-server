#ifndef __ROBOT_MAP__
#define __ROBOT_MAP__

#include <algorithm>
#include <cassert>
#include <cmath>
#include <functional>


#ifndef mmax
#define mmax(a,b)            (((a) > (b)) ? (a) : (b))
#endif
#ifndef mmin
#define mmin(a,b)            (((a) < (b)) ? (a) : (b))
#endif

extern "C"
{
#include "lauxlib.h"
}

#pragma pack(1)

#define N2H(n) \
{ \
    char *p = (char*)&n; \
    for (int i = 0; i < sizeof(n) >> 1; ++i) \
    { \
        p[i] ^= p[sizeof(n) - 1 - i]; \
        p[sizeof(n) - 1 - i] ^= p[i]; \
        p[i] ^= p[sizeof(n) - 1 - i]; \
    } \
} \

using namespace std;
typedef pair<int, int> PII;

struct MapHead
{
    int     m_width;
    int     m_height;
    short   m_tileSize;
    void NtoH()
    {
        N2H(m_width);
        N2H(m_height);
        N2H(m_tileSize);
    }
};

struct MapItemPoint
{
    int     m_ID;
    short   m_x;
    short   m_y;
    void NtoH()
    {
        N2H(m_ID);
        N2H(m_x);
        N2H(m_y);
    }
};

struct RobotMap
{
    char m_dir[16];
    static const int N = 65536;
    MapHead m_mapHead;
    char *m_pMaze;
    MapItemPoint *m_pMapItemPoint;
    short m_mapItemPointLen;
    int (*m_adj)[9];
    int m_height;
    int m_width;
    char m_mapName[64];

    int UpDiv(int a, int b)
    {
        return (a + b - 1) / b;
    }
    int GetHeight()
    {
        return UpDiv(m_mapHead.m_height, m_mapHead.m_tileSize);
    }
    int GetWidth()
    {
        return UpDiv(m_mapHead.m_width, m_mapHead.m_tileSize);
    }
    int GetIndex(int i, int j)
    {
        if (0<=i&&i<m_height && 0<=j&&j<m_width)
        {
            return i * m_width + j;
        }
        return -1;
    }
    bool IsBlock(int i, int j)
    {
        int index = GetIndex(i, j);
        if (index < 0)
        {
            return true;
        }
        return !(m_pMaze[index] & 1);
    }

    bool ReadMap(const char *pMapFile)
    {
        strncpy(m_mapName, pMapFile, sizeof(m_mapName));
        FILE *pFile = fopen(pMapFile, "rb");
        if (!pFile){
            fprintf(stderr, "[Error] open file %s failed\n", pMapFile);
            return false;
        }

        int nRet = fread(&m_mapHead, sizeof(m_mapHead), 1, pFile);
        assert(nRet == 1);
        m_mapHead.NtoH();
        int mazeLen = GetHeight() * GetWidth();
        m_pMaze = new char[mazeLen];
        nRet = fread(m_pMaze, sizeof(*m_pMaze), mazeLen, pFile);
        assert(nRet == mazeLen);
        nRet = fread(&m_mapItemPointLen, sizeof(m_mapItemPointLen), 1, pFile);
        assert(nRet == 1);
        N2H(m_mapItemPointLen);
        m_pMapItemPoint = new MapItemPoint[m_mapItemPointLen];
        nRet = fread(m_pMapItemPoint, sizeof(*m_pMapItemPoint), m_mapItemPointLen, pFile);
        for (int i = 0; i < m_mapItemPointLen; ++i)
        {
            N2H(m_pMapItemPoint[i]);
        }
        assert(nRet == m_mapItemPointLen);
        char checkEnd = 0;
        nRet = fread(&checkEnd, sizeof(checkEnd), 1, pFile);
        assert(!nRet);
        fclose(pFile);
        return true;
    }

    int GetNearEnd(int si, int sj)
    {
        bool vis[N] = {};
        int q[N];
        si = mmax(0, si);
        si = mmin(si, m_height - 1);
        sj = mmax(0, sj);
        sj = mmin(sj, m_width - 1);

        int qb = 0;
        int qf = 0;

        int s = GetIndex(si, sj);
        vis[s] = 1;
        q[qb++] = s;
        while (qf < qb)
        {
            int front = q[qf++];
            int i = front / m_width;
            int j = front % m_width;
            if (!IsBlock(i, j))
            {
                return front;
            }
            int klen = sizeof(m_dir) / sizeof(*m_dir) >> 1;
            for (int k = 0; k < klen; ++k)
            {
                int ti = i + m_dir[k];
                int tj = j + m_dir[k + klen];
                int t = GetIndex(ti, tj);
                if (0 <= t && !vis[t])
                {
                    vis[t] = 1;
                    q[qb++] = t;
                }
            }
        }
        assert(0);
        return -1;
    }

    bool InitAdj()
    {
        m_adj = new int[m_height * m_width][(sizeof(m_dir) / sizeof(*m_dir) >> 1) + 1];
        for (int i = 0; i < m_height; ++i)
        {
            for (int j = 0; j < m_width; ++j)
            {
                int s = GetIndex(i, j);
                if (IsBlock(i, j))
                {
                    m_adj[s][0]=-1;
                    continue;
                }
                int sLen = 0;
                int klen = sizeof(m_dir) / sizeof(*m_dir) >> 1;
                for (int k = 0; k < klen; ++k)
                {
                    int ti = i + m_dir[k];
                    int tj = j + m_dir[k + klen];
                    if (!IsBlock(ti, tj))
                    {
                        m_adj[s][sLen++] = GetIndex(ti, tj);
                    }
                }
                m_adj[s][sLen] = -1;
            }
        }
        return true;
    }

    int bfsGetSize(int si, int sj)
    {
        PII q[N];
        int qb = 0;
        int qf = 0;
        q[qb++] = PII(si, sj);
        while (qf < qb)
        {
            PII front = q[qf++];
            int i = front.first;
            int j = front.second;
            int klen = sizeof(m_dir) / sizeof(*m_dir) >> 1;
            for (int k = 0; k < klen; ++k)
            {
                int ti = i + m_dir[k];
                int tj = j + m_dir[k + klen];
                int t = GetIndex(ti, tj);
                if (!IsBlock(ti, tj) && !(m_pMaze[t] & 128))
                {
                    m_pMaze[t] |= 128;
                    q[qb++] = PII(ti, tj);
                }
            }
        }
        return qb;
    }

    bool CheckBfs()
    {
        int cnt = 0;
        for (int i = 0; i < m_height; ++i)
        {
            for (int j = 0; j < m_width; ++j)
            {
                if (!IsBlock(i, j))
                {
                    if (cnt)
                    {
                        int n = m_pMaze[GetIndex(i, j)];
                        if (!(n & 128))
                        {
                            //printf("%s %d %d %d\n", m_mapName, i, j, bfsGetSize(i, j));
                        }
                    }
                    else
                    {
                        //printf("%s %d %d %d\n", m_mapName, i, j, bfsGetSize(i, j));
                    }
                    ++cnt;
                }
            }
        }
        return true;
    }

    bool Init(const char *pMapFile)
    {
        ReadMap(pMapFile);
        m_height = GetHeight();
        m_width = GetWidth();
        //assert(m_height * m_width < N);
        int dirLen = 0;
        for (int i = -1; i < 2; ++i)
        {
            for (int j = -1; j < 2; ++j)
            {
                if (i || j)
                {
                    m_dir[dirLen] = i;
                    m_dir[dirLen + 8] = j;
                    ++dirLen;
                }
            }
        }
        InitAdj();
        CheckBfs();
        return true;
    }

    bool CheckPath(int s, int t)
    {
        int si = s / m_width;
        int sj = s % m_width;
        int ti = t / m_width;
        int tj = t % m_width;
        if (s == t)
        {
            return !IsBlock(si, sj);
        }
        int di = ti - si ? (ti - si) / abs(ti - si) : 0;
        int dj = tj - sj ? (tj - sj) / abs(tj - sj) : 0;

        if (abs(ti - si) < abs(tj - sj))
        {
            for (int j = sj; ; j += dj)
            {
                double i = si + (j - sj) * (ti - si) * 1.0 / (tj - sj);
                if (IsBlock(i, j) && IsBlock(i + 1, j))
                {
                    return false;
                }
                if (j == tj)
                {
                    break;
                }
            }
        }
        else
        {
            for (int i = si; ; i += di)
            {
                double j = sj + (i - si) * (tj - sj) * 1.0 / (ti - si);
                if (IsBlock(i, j) && IsBlock(i, j + 1))
                {
                    return false;
                }
                if (i == ti)
                {
                    break;
                }
            }
        }
        return true;


/*
        int x1 =m_mapHead.m_tileSize * (s / m_width) + m_mapHead.m_tileSize>>1;
        int y1 = m_mapHead.m_tileSize * (s % m_width) + m_mapHead.m_tileSize>>1;
        int x2 = m_mapHead.m_tileSize * (t / m_width) + m_mapHead.m_tileSize>>1;
        int y2 = m_mapHead.m_tileSize * (t % m_width) + m_mapHead.m_tileSize>>1;
        bool order = false;
        int left,right,left_y,right_y;
        int dx, dy;
        if (((dx = x2 - x1) > 0 ? dx : -dx) > ((dy = y2 - y1) > 0 ? dy : -dy))
        {
            order = true;
            if (x1 < x2)
            {
                left = x1;
                right = x2;
                left_y = y1;
                right_y = y2;
            }
            else
            {
                left = x2;
                right = x1;
                left_y = y2;
                right_y = y1;
            }
        }
        else
        {
            order = false;
            if (y1 < y2)
            {
                left = y1;
                right = y2;
                left_y = x1;
                right_y = x2;
            }
            else
            {
                left = y2;
                right = y1;
                left_y = x2;
                right_y = x1;
            }
        }
        double rate = 1.0 * (right_y - left_y) / (right - left);
        int LY = left_y / m_mapHead.m_tileSize;
        int len = right / m_mapHead.m_tileSize;
        double m1 = rate * m_mapHead.m_tileSize;
        double m2 = (m_mapHead.m_tileSize - left) * rate + left_y + 0.5;
        for (int X= left / m_mapHead.m_tileSize; X < len; X++)
        {
            int Y = (X * m1 + m2) / m_mapHead.m_tileSize;
            if (order ? IsBlock(LY,X) : IsBlock(X,LY))
                return false;
            if (Y != LY)
            {
                if (order ? IsBlock(Y,X) : IsBlock(X,Y))
                    return false;
                LY = Y;
            }
        }
        return true;
        */
    }

    bool ReducePath(int *fa, int s, int t)
    {
        if (s == t)
        {
            return true;
        }

        int start = s;
        for (int i=t;i>=0 && i!=start;)
        {
            if (CheckPath(i, start))
            {
                fa[i] = start;
                start = i;
                i=t;
            }
            else
            {
                i=fa[i];
            }
        }
        return false;
/*
        int tt = t;
        int pret = t;
        int prex = t / m_width;
        int prey = t % m_width;
        while(fa[tt]>0 && tt > 0)
        {
            tt = fa[tt];
            int x = tt / m_width;
            int y = tt % m_width;
            if(fabs(prex - x) < 3 || fabs(prey - y) < 3)
            {
                fa[pret] = tt;
            }
            else
            {
                fa[fa[pret]] = tt;
                pret = fa[pret];
                prex = pret / m_width;
                prey = pret % m_width;
            }
            if(tt == s)
            {
                return true;
            }
        }
        */

    }

    int GetH(int s, int t)
    {
        int di = s / m_width - t / m_width;
        di = 0 <= di ? di : -di;
        int dj = s - s / m_width * m_width - (t - t / m_width * m_width);
        dj = 0 <= dj ? dj : -dj;
        //return di < dj ? dj : di;
        return di + dj;
    }

    int FaToPath(PII *path, int *fa, int t)
    {
        int n = 0;
        while (0 <= t && 0 <= fa[t] )
        {
            path[n++] = PII(t % m_width * m_mapHead.m_tileSize + m_mapHead.m_tileSize>>1, t / m_width * m_mapHead.m_tileSize + m_mapHead.m_tileSize>>1);
            t = fa[t];
        }
        for (int i = 0; i < n >> 1; ++i)
        {
            swap(path[i], path[n - 1 - i]);
        }
        return n;
    }

    int Astar(PII *path, int s, int t)
    {
        assert(!IsBlock(s / m_width, s % m_width));
        assert(!IsBlock(t / m_width, t % m_width));
        int* fa = new int[m_width*m_height];
        memset(fa,-1,sizeof(int)*m_width*m_height);
        
        int *g = new int[m_width*m_height];
        memset(g, 127, sizeof(int)*m_width*m_height);
        PII *pq = new PII[m_width*m_height];
        g[s] = 0;
        fa[s] = -1;
        int pqlen = 0;
        pq[pqlen++] = PII(GetH(s, t), s);
        int cntPush = 0;
        while (pqlen)
        {
            PII top = *pq;
            pop_heap(pq, pq + pqlen--, greater<PII>());
            int i = top.second;
            if (i == t || m_width*m_height <= pqlen)
            { 
                ReducePath(fa, s, i);
                int ret = FaToPath(path, fa, i);
                delete g;
                delete fa;
                delete pq;
                return ret;
            }
            if (g[i] + GetH(i, t) < top.first)
            {
                continue;
            }
            for (int k = 0; 0 <= m_adj[i][k]; ++k)
            {
                int j = m_adj[i][k];
                if (g[i] + 1 < g[j])
                {
                    ++cntPush;
                    assert(cntPush + 8 < N);
                    g[j] = g[i] + 1;
                    fa[j] = i;
                    pq[pqlen++] = PII(g[j] + GetH(j, t), j);
                    push_heap(pq, pq + pqlen, greater<PII>());
                }
            }
        }
        delete g;
        delete fa;
        delete pq;
        assert(0);
        return 0;
    }

    int GetPath(PII *path, int sx, int sy, int tx, int ty)
    {
        if(tx<0 || ty < 0)  //全地图随机
        {
            tx = rand()%m_mapHead.m_width;
            ty = rand()%m_mapHead.m_height;
        }
        int si = sy / m_mapHead.m_tileSize;
        int sj = sx / m_mapHead.m_tileSize;
        int ti = ty / m_mapHead.m_tileSize;
        int tj = tx / m_mapHead.m_tileSize;
        int s = GetNearEnd(si, sj);
        int t = GetNearEnd(ti, tj);
        return Astar(path, s, t);
    }
};

struct RobotMapManager
{
    int m_mapLen;
    RobotMap m_robotMap[1];
    int InitRobotMap(const char *pMapFile)
    {
        return 0;
        if (sizeof(m_robotMap) / sizeof(*m_robotMap) <= m_mapLen)
        {
            fprintf(stderr, "warnning: map %s not inited\n", pMapFile);
            return -1;
        }
        for (int i = 0; i < m_mapLen; ++i)
        {
            if (!strcmp(m_robotMap[i].m_mapName, pMapFile))
            {
                return i;
            }
        }
        if (!m_robotMap[m_mapLen].Init(pMapFile))
        {
            assert(0);
            return -1;
        }

        //fprintf(stderr, "map %s init ok\n", pMapFile);
        return m_mapLen++;
    }
    int GetPath(int mapID, PII *path, int sx, int sy, int tx, int ty)
    {
        //printf("in c %d %d %d %d %d\n", mapID, sx, sy, tx, ty);
        for (int i = 0; i < m_mapLen; ++i)
        {
            char szMapID[64];
            sprintf(szMapID, "scene/%d.map", mapID);
            if (strcmp(m_robotMap[i].m_mapName, szMapID)==0)
            {
                return m_robotMap[i].GetPath(path, sx, sy, tx, ty);
            }
        }
        return 0;
    }
    static RobotMapManager *GetInstance()
    {
        static RobotMapManager robotManager;
        return &robotManager;
    }
    static int _InitRobotMap(lua_State *pL)
    {
        int n = GetInstance()->InitRobotMap(luaL_checkstring(pL, 1));
        lua_pushnumber(pL, n);
        return 1;
    }
    static int _GetPath(lua_State *pL)
    {
        PII pii[64];
        int n = GetInstance()->GetPath(luaL_checknumber(pL, 2), pii, luaL_checknumber(pL, 3), luaL_checknumber(pL, 4), luaL_checknumber(pL, 5), luaL_checknumber(pL, 6));
        for (int i = 0; i < n; ++i)
        {
            lua_pushnumber(pL, pii[i].first);
            lua_rawseti(pL, 1, 2 * i + 1);
            lua_pushnumber(pL, pii[i].second);
            lua_rawseti(pL, 1, 2 * i + 2);
        }
        lua_pushnumber(pL, n);
        return 1;
    }
};

#endif

