#include "Msg.h"
#include "common/PackProto.h"
Msg::Msg(){
    m_pBuf = evbuffer_new();
    CleanUp();
}

Msg::~Msg(){
    CleanUp();
    evbuffer_free(m_pBuf);
}

void Msg::CleanUp()
{
    m_oMsgHead.m_nID = 0;
    m_oMsgHead.m_nLen = MSG_HEAD_LEN; //发送包的时候，默认加入包头长度
    //m_oMsgHead.m_nMask = 0;
    //m_oMsgHead.m_nSN = 0;
    m_nPoolID = -1;
    m_nObjFD = -1;
    m_nQueueID = -1;
    m_nReceiverNum = 0;
    for (int i=0; i<MAX_RECEIVER_NUM; i++)
    {
        m_AryReceivers[i].fd = -1;
        m_AryReceivers[i].sn = -1;
    }
    evbuffer_drain(m_pBuf, evbuffer_get_length(m_pBuf));
    m_eMsgType = USER_BROADCAST;
    m_nLeakCheck = 0;
}


void Msg::WriteUInt(unsigned int value){ 
	static unsigned char vbuf[20];
	PackProto *pp = PackProto::GetInst();
	unsigned int uLen = pp->writeUInt(vbuf,value);
	evbuffer_add(m_pBuf, &value,uLen);
	m_oMsgHead.m_nLen += uLen;
}