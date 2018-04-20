#ifndef __ROUND_QUEUE_H__
#define __ROUND_QUEUE_H__

#include "Type.h"
#include "Utils.h"
#include "LogManager.h"

template <typename T>
class RoundQueue
{
    public:
        RoundQueue(){
            m_nHead = 0;
            m_nTail = 0;
            m_nMaxLen = 0;
            m_pQueue = NULL;
        }

        ~RoundQueue(){
            SAFE_DELETE_ARRAY(m_pMark);
            SAFE_DELETE_ARRAY(m_pQueue);
        }

        bool Init(int nMaxQueueLen)
        {
            m_nMaxLen = nMaxQueueLen;
            m_pMark = new char[nMaxQueueLen];
            m_pQueue = new T*[nMaxQueueLen];
            if (!m_pMark || !m_pQueue)
                return false;

            for (int i=0; i<m_nMaxLen; i++)
            {
                m_pMark[i] = 0;
                m_pQueue[i] = NULL;
            }
            return true;
        }

        inline bool Push(T* pItem)
        {
            if (!pItem) return false;
            if (m_pMark[m_nHead] != 0)
            {
                char sLog[128] = {0};
                tsnprintf(sLog, sizeof(sLog), 
                        "[RoundQueueError] m_pMark[m_nHead] !=0; m_nHead:%d, m_nTail:%d, m_nMaxLen:%d, qLen:%d",
                        m_nHead, m_nTail, m_nMaxLen, GetQueueLen());
                g_oLogManager.WriteErrorLog(sLog);
                return false;
            }

            m_pQueue[m_nHead] = pItem;
            pItem->SetQueueID(m_nHead);
            m_pMark[m_nHead] = 1;
            m_nHead = (m_nHead + 1)%m_nMaxLen;
            return true; 
        }

        inline T* Pop()
        {
            if (m_pMark[m_nTail] == 0)
                return NULL;

            T* pRet = m_pQueue[m_nTail];
            m_pQueue[m_nTail] = NULL;
            m_pMark[m_nTail] = 0;
            m_nTail = (m_nTail + 1)%m_nMaxLen;
            pRet->SetQueueID(-1);
            return pRet;
        }


        inline int GetQueueLen()
        {
            if (m_nHead >= m_nTail)
                return (m_nHead - m_nTail);
            else
                return (m_nMaxLen - m_nTail + m_nHead);
        }


    private:
        int m_nHead;
        int m_nTail;
        int m_nMaxLen;
        char *m_pMark;
        T ** m_pQueue;
};

#endif //__ROUND_QUEUE_H__
