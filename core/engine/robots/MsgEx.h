#ifndef __MSG_EX_H__
#define __MSG_EX_H__

struct lua_State;

int _RecvMsg(lua_State *pL);
int _SendMsg(lua_State *pL);

#endif //__MSG_EX_H__

