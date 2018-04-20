#ifndef __ROBOT_EVENTS_H__
#define __ROBOT_EVENTS_H__

struct bufferevent;

void ReadCB(bufferevent *, void *);
void EventCB(bufferevent *, short, void *);
void TimerCB(evutil_socket_t, short, void *);
void TimerReNewCB(evutil_socket_t, short, void *);

#endif //__ROBOT_EVENTS_H__

