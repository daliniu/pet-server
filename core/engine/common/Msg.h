#ifndef __MSG_STRUCT_H__
#define __MSG_STRUCT_H__

#include "Type.h"

#include <stdio.h>
#include <string.h>
#include <event2/buffer.h> 

#define  MAX_RECEIVER_NUM    200 

#define  BYTE_LEN           1 
#define  WORD_LEN           2 
#define  DWORD_LEN          4

#define  MSG_HEAD_LEN       (WORD_LEN * 2)
#define  MAX_RECV_PKG_LEN   (1024 * 2) 


enum MSGTYPE
{
    USER_BROADCAST,
    WORLD_BROADCAST,
};

struct Receiver
{
    short fd;
    int sn;

    Receiver(){
        fd = -1;
        sn = -1;
    }
};

struct MsgHead
{
    short m_nLen;
    short m_nID;
    //short m_nMask;
    //short m_nSN;

    void dump(){
        printf("m_nID:%d, m_nLen:%d\n",
                m_nID, m_nLen);
    }

    void hton(){
        m_nID = htons(m_nID);
        m_nLen = htons(m_nLen);
        //m_nMask = htons(m_nMask);
        //m_nSN = htons(m_nSN);
    }

    void ntoh(){
        m_nID = ntohs(m_nID);
        m_nLen = ntohs(m_nLen);
       //m_nMask = ntohs(m_nMask);
       //m_nSN = ntohs(m_nSN);
    }
};


class Msg
{
    public:
        Msg();
        ~Msg();

        void CleanUp();
        inline int  GetPoolID();
        inline void SetPoolID(int nPoolID);

        inline MsgHead* GetHead();
        inline void SetHead(const MsgHead* pHead);

        inline short GetID();
        inline void SetID(short nID);

        inline int GetQueueID();
        inline void SetQueueID(int nID);

        inline int GetObjFD();
        inline void SetObjFD(int nObjFD);

        inline MSGTYPE GetMsgType();
        inline void SetMsgType(MSGTYPE eType);

        inline evbuffer* GetBuf();

        inline bool PushReceiver(int nFD);
        inline const Receiver* PopReceiver();

        inline short GetReceiverCount();
		void WriteUInt(unsigned int value);
		/*
        inline char ReadByte();
        inline short ReadShort();
        inline int ReadInt();
        inline void ReadString(char *pBuf, short nMaxLen);

        inline void WriteByte(char c);
        inline void WriteShort(short s);
        inline void WriteInt(int i);
        inline void WriteString(const char* pBody, short nLen);

        static int StaticReadByte(void *p)
        {
            return ((Msg*)p)->ReadByte();
        }
        static int StaticReadShort(void *p)
        {
            return ((Msg*)p)->ReadShort();
        }
        static int StaticReadInt(void *p)
        {
            return ((Msg*)p)->ReadInt();
        }

        static void StaticWriteByte(void *p, int n)
        {
            ((Msg*)p)->WriteByte(n);
        }
        static void StaticWriteShort(void *p, int n)
        {
            ((Msg*)p)->WriteShort(n);
        }

        static void StaticWriteString(void *p, int len, const char *psz)
        {
            ((Msg*)p)->WriteString(psz, len);
        }
		static void StaticWriteInt(void *p, int n)
		{
			((Msg*)p)->WriteUInt(n);
		}
		*/

        inline bool CheckLen();
        
        inline void AppendString(const char* pStr, int nLen);

        void IncLeakCheck(){ m_nLeakCheck++; }
        short GetLeakCheck(){ return m_nLeakCheck; }

    private:

        MsgHead m_oMsgHead;
        evbuffer *m_pBuf;

        int m_nObjFD;
        int m_nPoolID;
        int m_nQueueID;
        MSGTYPE m_eMsgType;

        short m_nReceiverNum;
        Receiver m_AryReceivers[MAX_RECEIVER_NUM]; 

        short m_nLeakCheck;
};

#include "Msg.inl"
#endif //__MSG_STRUCT_H__

