#include "HttpThread.h"
#include "common/LogEx.h"
#include "common/Utils.h"
#include "common/MsgManager.h"
#include "Globals.h"
#include "common/LogManager.h"

#include <string.h>
#include <errno.h>
#include <event2/http.h>
#include <event2/event.h>
#include <event2/keyvalq_struct.h>
#include <event2/event_struct.h>
#include <event2/http_compat.h>
#include <event2/http_struct.h>
#include <event2/event_compat.h>

#ifdef __WINDOWS__
#else
#include <sys/time.h>
#endif


static void AdminRequestCB(struct evhttp_request *, void *);
static void GeneralRequestCB(struct evhttp_request *, void *);
static void TimerCB(evutil_socket_t, short, void *);

HttpThread::HttpThread(int nPort)
{
    m_nPort = nPort;
    m_pEventBase = NULL;
    m_pEventHttp = NULL;
}

HttpThread::~HttpThread()
{
}

bool HttpThread::Init()
{
    m_pEventBase = event_base_new();
    if (!m_pEventBase) {
        fprintf(stderr, "[Error] Could not initialize libevent!\n");
        return false;
    }

    /* Create a new evhttp object to handle requests. */
    m_pEventHttp = evhttp_new(m_pEventBase);
    if (!m_pEventHttp) {
        fprintf(stderr, "[Error] couldn't create evhttp. Exiting.\n");
        return false;
    }

    evhttp_set_cb(m_pEventHttp, "/admin", AdminRequestCB, NULL);

    evhttp_set_gencb(m_pEventHttp, GeneralRequestCB, NULL);

    struct evhttp_bound_socket *handle = evhttp_bind_socket_with_handle(m_pEventHttp, "0.0.0.0", m_nPort);
    if (!handle) {
        fprintf(stderr, "[Error] couldn't bind to port %d. Exiting.\n",
            (int)m_nPort);
        return 1;
    }

    if (g_bRunAsDaemon){
        g_oLogManager.WriteHttpLog("http started!");
    }else{
        printf("Http thread init ok. port:%d!\n", m_nPort);
    }

    return true;
}

void HttpThread::Run()
{
    struct event oTimeEvent;
    struct timeval tv;

    event_assign(&oTimeEvent, m_pEventBase, -1, EV_PERSIST, TimerCB, (void*)this);

    tv.tv_sec = 0; 
    tv.tv_usec = GAME_IO_HEARTBEAT * 1000;
    event_add(&oTimeEvent, &tv);

    event_base_dispatch(m_pEventBase);  
    evhttp_free(m_pEventHttp);
    event_base_free(m_pEventBase);
}

void HttpThread::Stop()
{
	struct timeval delay = { 0, 0 };
    event_base_loopexit(m_pEventBase, &delay); 
}

static void AdminRequestCB(struct evhttp_request * pReq, void * pArg)
{
    do 
    {
        // 只响应http get post请求
		evhttp_cmd_type cmdType = evhttp_request_get_command(pReq);
		if (cmdType != EVHTTP_REQ_GET && cmdType != EVHTTP_REQ_POST) break;
        struct evhttp_connection *pConn = evhttp_request_get_connection(pReq);

        char *address;
        unsigned short port;
        evhttp_connection_get_peer(pConn, &address, &port);
        bool bIpAllowed = false;
        for(int i=0; i<g_nAdminIpCount; i++){
            if (strcmp(g_pAdminIpList[i].ip, address) == 0){
                bIpAllowed = true;
                break;
            }
        }

        if (!bIpAllowed){
            char log[128] = {0};
            tsnprintf(log, sizeof(log), "[warn] Access denied from %s", address);
            g_oLogManager.WriteHttpLog(log);
            break;
        }

		// for debug only
		//printf("Received a request: path:%s, query:%s, fragment:%s\n", 
		//    evhttp_uri_get_path(pEvHttpUri),
		//    evhttp_uri_get_query(pEvHttpUri),
		//    evhttp_uri_get_fragment(pEvHttpUri));
		const struct evhttp_uri * pEvHttpUri = evhttp_request_get_evhttp_uri(pReq);
		if (pEvHttpUri == NULL) break;
		const char *query = evhttp_uri_get_query(pEvHttpUri);
		g_pHttpReqLock->Lock();
		evbuffer_drain(g_pHttpReqEvBuf, evbuffer_get_length(g_pHttpReqEvBuf));
		if (query != NULL){
			evbuffer_add(g_pHttpReqEvBuf, query,strlen(query) );
		}
		if (cmdType == EVHTTP_REQ_POST){
			struct evbuffer *input = evhttp_request_get_input_buffer(pReq);
			evbuffer_add(g_pHttpReqEvBuf,"&",1);
			evbuffer_add_buffer(g_pHttpReqEvBuf,input);
		}
		g_pHttpReqLock->Unlock();	

        int iTimeCount = 0;
        while (true)
        {
#ifdef __WINDOWS__
            Sleep(1);
#else
            usleep(1000);
#endif
            iTimeCount++;
            if (iTimeCount > 6000) // 6秒钟的超时
            {
                evhttp_send_error(pReq, 408, "Request Time-out");
                return;
            }

            g_pHttpRespLock->Lock();
            if (evbuffer_get_length(g_pHttpRespEvBuf) > 0)
            {
				evhttp_add_header( pReq->output_headers, "Content-Type",  "text/html; charset=UTF-8"); 
                evhttp_send_reply(pReq, 200, "", g_pHttpRespEvBuf);
                g_pHttpRespLock->Unlock();
                return;
            }
            g_pHttpRespLock->Unlock();
        }
    }
    while (false);

    evhttp_send_error(pReq, 404, "404");
    return;
}

static void GeneralRequestCB(struct evhttp_request * pReq, void * pArg)
{
    // 这个http server 只给后台使用，不响应其他任何请求
    evhttp_send_error(pReq, 404, "Document was not found");
}

void HttpSendRequestCB(struct evhttp_request * req, void * arg) {  
	Msg *sendMsg = (Msg *)arg;
	int nFd = sendMsg->GetObjFD();
	int nId = sendMsg->GetID();
	g_pMsgPool->DeleteObj(sendMsg);
	if (req == NULL) {
		return;
	}
	/**
    struct evhttp_connection *pConn = evhttp_request_get_connection(req);
    evhttp_connection_free(pConn);
	**/
	Msg *pMsg = g_pMsgPool->NewObj();
	if (!pMsg){
		char sLog[128] = {0};
		tsnprintf(sLog, sizeof(sLog), "[EngineError] g_pMsgPool->NewObj() fail\n");
		g_oLogManager.WriteErrorLog(sLog);
		return ;
	}
	pMsg->SetObjFD(nFd);
	pMsg->SetID(nId);
	if (req->response_code == HTTP_OK){
		struct evbuffer *input = evhttp_request_get_input_buffer(req);
		if (NULL == input){
			g_pMsgPool->DeleteObj(pMsg);
			return ;
		}
		evbuffer *pBuf = pMsg->GetBuf();
		size_t len = evbuffer_get_length(input);
		if (evbuffer_remove_buffer(input,pBuf,MAX_RECV_HTTP_LEN) < 0){
			g_pMsgPool->DeleteObj(pMsg);
			return ;
		}
		evbuffer_drain(input,len-MAX_RECV_HTTP_LEN);
	}else{
		char sLog[128] = {0};
		if (req->response_code_line != NULL){
			sprintf(sLog,"error:[%d]%s",req->response_code,req->response_code_line);
		}else{
			sprintf(sLog,"error:[%d]%s",req->response_code,"connection refuse");
		}
		pMsg->AppendString(sLog,strlen(sLog));
	}
	g_pHttpRecvMsgQueue->Push(pMsg);
}

static void TimerCB(evutil_socket_t nFD, short nEvent, void *pArg)
{
    HttpThread *pThread = (HttpThread*) pArg;
    Msg *pMsg = g_pHttpSendMsgQueue->Pop();
    //struct bufferevent *pBE = NULL;
    if (pMsg){
		char writeBuff[8192]={0};
        evbuffer_copyout(pMsg->GetBuf(), writeBuff, evbuffer_get_length(pMsg->GetBuf()));
        evbuffer_drain(pMsg->GetBuf(), evbuffer_get_length(pMsg->GetBuf()));

		struct evhttp_uri *uri = evhttp_uri_parse(writeBuff);
		if (NULL == uri){
			g_pMsgPool->DeleteObj(pMsg);
			fprintf(stderr, "[HttpError]evhttp_uri_parse fail");
			char sLog[512] = {0};
			tsnprintf(sLog, sizeof(sLog), "[HttpError]evhttp_uri_parse fail:%s\n",writeBuff);
			g_oLogManager.WriteErrorLog(sLog);
			return ;
		}
		const char* host = evhttp_uri_get_host(uri);
		int port = evhttp_uri_get_port(uri);  
		const char *path = evhttp_uri_get_path(uri);  
		const char *query = evhttp_uri_get_query(uri);
		size_t pathQueryLen = (query ? strlen(query) : 0) + (path ? strlen(path) : 0);  
		char pathQuery[2048] = {0};  
		if (pathQueryLen > 0) {  
			sprintf(pathQuery, "%s?%s", path, query);  
		}     

        struct evhttp_connection *evhttp_connection = NULL;  
        struct evhttp_request *evhttp_request = NULL;  
        //evhttp_connection = evhttp_connection_new(host, (port == -1 ? 80 : port));
        //evhttp_connection_set_base(evhttp_connection, pThread->GetEventBase());
		evhttp_connection = evhttp_connection_base_new(pThread->GetEventBase(),NULL,host,(port == -1 ? 80 : port));
		if (NULL == evhttp_connection){
			g_pMsgPool->DeleteObj(pMsg);
			fprintf(stderr, "[HttpError]connection fail");
			g_oLogManager.WriteErrorLog( "[HttpError]connection fail");
			return ;
		}
        evhttp_request = evhttp_request_new(HttpSendRequestCB, pMsg);  
        evhttp_add_header( evhttp_request->output_headers,  "Host",  host); 
        if(evhttp_make_request(evhttp_connection, evhttp_request, EVHTTP_REQ_GET, (pathQueryLen>0 ? pathQuery: "/")) != 0){
			g_pMsgPool->DeleteObj(pMsg);
			fprintf(stderr, "[HttpError]make_request fail");
			g_oLogManager.WriteErrorLog( "[HttpError]make_request fail");
			return ;
		}else{
			if (NULL != evhttp_request->evcon)
			{
				evhttp_connection_set_timeout(evhttp_request->evcon, 3); 
			}
		}
    }
}

