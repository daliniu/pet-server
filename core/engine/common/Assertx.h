//--------------------------------------------------------------------------------
//
// Filename   : Assert.h
//
//--------------------------------------------------------------------------------

#ifndef __ASSERT__H__
#define __ASSERT__H__

#include "Type.h"
#define CHAR char 
#define UINT unsigned int

extern int g_Command_Assert ;//控制参数，不提示Assert的对话框，直接忽略
extern int g_Command_IgnoreMessageBox ;//控制参数，跳过MyMessageBox的中断

//--------------------------------------------------------------------------------
//
// 
// 
//
//--------------------------------------------------------------------------------
void __assert__ (const CHAR* file, UINT line, const CHAR* func, const CHAR* expr) ;
void __assertex__ (const CHAR* file, UINT line, const CHAR* func, const CHAR* expr, const CHAR* msg) ;
void __assertft__ (const CHAR* file, UINT line, const CHAR* func, const CHAR* expr, const CHAR* fmt,...) ; 
void __assertspecial__ (const CHAR* file, UINT line, const CHAR* func, const CHAR* expr, const CHAR* msg) ;
void __messagebox__(const CHAR*msg ) ;
//--------------------------------------------------------------------------------
//
// 
// 
//
//--------------------------------------------------------------------------------

#if defined(NDEBUG)
	#define Assert(expr) ((void)0)
	#define AssertEx(expr,msg) ((void)0)
	#define AssertFt(expr,fmt,...) ((void)0)
	#define AssertSpecial(expr,msg) ((void)0)
	#define MyMessageBox(msg) ((void)0)
#elif __LINUX__
	#define Assert(expr) {if(g_Command_Assert == 1 && (!(expr))){__assert__(__FILE__,__LINE__,__PRETTY_FUNCTION__,#expr);}}
	#define ProtocolAssert(expr) ((void)((expr)?0:(__protocol_assert__(__FILE__,__LINE__,__PRETTY_FUNCTION__,#expr),0)))
	#define AssertEx(expr,msg) {if(g_Command_Assert == 1 && (!(expr))){__assertex__(__FILE__,__LINE__,__PRETTY_FUNCTION__,#expr,msg);}}
	#define AssertFt(expr,fmt,...) {if(g_Command_Assert == 1 && (!(expr))){__assertft__(__FILE__,__LINE__,__PRETTY_FUNCTION__,#expr,fmt,__VA_ARGS__);}}
	#define AssertSpecial(expr,msg) {if(!(expr)){__assertspecial__(__FILE__,__LINE__,__PRETTY_FUNCTION__,#expr,msg);}}
	#define AssertExPass(expr,msg) {if(!(expr)){__assertex__(__FILE__,__LINE__,__PRETTY_FUNCTION__,#expr,msg);}}
	#define MyMessageBox(msg) ((void)0)
#elif __WIN_CONSOLE__ || __WIN32__ || __WINDOWS__
	#define Assert(expr) ((void)((expr)?0:(__assert__(__FILE__,__LINE__,__FUNCTION__,#expr),0)))
	#define AssertEx(expr,msg) ((void)((expr)?0:(__assertex__(__FILE__,__LINE__,__FUNCTION__,#expr,msg),0)))
	#define AssertFt(expr,fmt,...) ((void)((expr)?0:(__assertft__(__FILE__,__LINE__,__FUNCTION__,#expr,fmt,__VA_ARGS__),0)))
	#define AssertSpecial(expr,msg) ((void)((expr)?0:(__assertspecial__(__FILE__,__LINE__,__FUNCTION__,#expr,msg),0)))
	#define MyMessageBox(msg) __messagebox__(msg)
#elif __MFC__
	#define Assert(expr) ASSERT(expr)
	#define AssertEx(expr,msg) ((void)0)
	#define AssertSpecial(expr,msg) ((void)0)
	#define MyMessageBox(msg) ((void)0)
#endif

#endif
