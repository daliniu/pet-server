#ifndef __MSG_INL__
#define __MSG_INL__

#include "LogManager.h"

extern int *g_pFdSn;

int Msg::GetPoolID()
{ 
    return m_nPoolID ; 
}

void Msg::SetPoolID(int nPoolID)
{ 
    m_nPoolID = nPoolID; 
}

MsgHead* Msg::GetHead() 
{ 
    return &m_oMsgHead; 
}

short Msg::GetID()
{ 
    return m_oMsgHead.m_nID; 
}

void Msg::SetID(short nID)
{ 
    m_oMsgHead.m_nID = nID; 
}

int Msg::GetQueueID()
{ 
    return m_nQueueID; 
}

void Msg::SetQueueID(int nID)
{ 
    m_nQueueID = nID;
}

int Msg::GetObjFD()
{ 
    return m_nObjFD; 
}

void Msg::SetObjFD(int nObjFD)
{ 
    m_nObjFD = nObjFD; 
}

MSGTYPE Msg::GetMsgType()
{ 
    return m_eMsgType; 
}

void Msg::SetMsgType(MSGTYPE eType) 
{ 
    m_eMsgType = eType; 
}

evbuffer* Msg::GetBuf()
{ 
    return m_pBuf; 
}

short Msg::GetReceiverCount() 
{ 
    return m_nReceiverNum;
}

bool Msg::CheckLen()
{
    return m_oMsgHead.m_nLen == (int)(evbuffer_get_length(m_pBuf) + MSG_HEAD_LEN);
}
 

void Msg::SetHead(const MsgHead* pHead)
{
    m_oMsgHead.m_nLen = pHead->m_nLen;
    m_oMsgHead.m_nID = pHead->m_nID;
    //m_oMsgHead.m_nMask = pHead->m_nMask;
    //m_oMsgHead.m_nSN = pHead->m_nSN;
}

bool Msg::PushReceiver(int nFD){
    if (nFD == -1) return false;
    if(m_nReceiverNum < MAX_RECEIVER_NUM){
        m_AryReceivers[m_nReceiverNum].fd = nFD;
        m_AryReceivers[m_nReceiverNum].sn = g_pFdSn[nFD];
        m_nReceiverNum++;
        return true;
    }
    else{
        g_oLogManager.WriteErrorLog("[EngineWarn] exceed max receiver num");
        return false;
    }
}

const Receiver* Msg::PopReceiver(){
    if (m_nReceiverNum > 0){
        --m_nReceiverNum;
        return &m_AryReceivers[m_nReceiverNum]; 
    }
    else{
        return NULL;
    }
}
/*
char Msg::ReadByte(){ 
    char c;
    evbuffer_copyout(m_pBuf, &c, BYTE_LEN);
    evbuffer_drain(m_pBuf, BYTE_LEN);
    return c;
}

short Msg::ReadShort(){ 
    short s;
    evbuffer_copyout(m_pBuf, &s, WORD_LEN);
    evbuffer_drain(m_pBuf, WORD_LEN);
    return ntohs(s);
}

int Msg::ReadInt(){ 
    int i;
    evbuffer_copyout(m_pBuf, &i, DWORD_LEN);
    evbuffer_drain(m_pBuf, DWORD_LEN);
    return ntohl(i);
}

void Msg::WriteByte(char c){ 
    evbuffer_add(m_pBuf, &c, BYTE_LEN);
    m_oMsgHead.m_nLen += BYTE_LEN;
}

void Msg::WriteShort(short s){ 
    short ns = htons(s);
    evbuffer_add(m_pBuf, &ns, WORD_LEN);
    m_oMsgHead.m_nLen += WORD_LEN;
}

void Msg::WriteInt(int i){ 
    int ni = htonl(i);
    evbuffer_add(m_pBuf, &ni, DWORD_LEN);
    m_oMsgHead.m_nLen += DWORD_LEN;
}

void Msg::ReadString(char *pBuf, short nMaxLen){

    short sLen = 0;
    evbuffer_copyout(m_pBuf, &sLen, WORD_LEN);
    evbuffer_drain(m_pBuf, WORD_LEN);
    sLen = ntohs(sLen);

    if (sLen >= nMaxLen) return;

    evbuffer_copyout(m_pBuf, pBuf, sLen);
    evbuffer_drain(m_pBuf, sLen);
}

void Msg::WriteString(const char* pBody, short nLen){
    short sLenN = htons(nLen);
    evbuffer_add(m_pBuf, &sLenN, WORD_LEN);
    m_oMsgHead.m_nLen += WORD_LEN;

    evbuffer_add(m_pBuf, pBody, nLen);
    m_oMsgHead.m_nLen += nLen;
}
*/
void Msg::AppendString(const char* pStr, int nLen)
{
    evbuffer_add(m_pBuf, pStr, nLen);
    m_oMsgHead.m_nLen += nLen;

}

#endif //__MSG_INL__
