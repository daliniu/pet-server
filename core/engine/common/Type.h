#ifndef __TYPE_H__
#define __TYPE_H__


#if defined(__WINDOWS__)
#define     WIN32_LEAN_AND_MEAN   //去除一些不常用的
#include    <Windows.h>
#include    <direct.h>
#include    <io.h>
#define		tvsnprintf		_vsnprintf
#define		tstricmp		_stricmp
#define		tsnprintf		_snprintf
#define		tgetcwd		    _getcwd
#define		taccess		    _access
#else
#include    <pthread.h>
#include    <netinet/in.h>
#include    <unistd.h>
#define		tvsnprintf		vsnprintf
#define		tstricmp		strcasecmp
#define		tsnprintf		snprintf
#define		tgetcwd		    getcwd
#define		taccess		    access
#endif

#include <assert.h>

#if defined(__WINDOWS__)
typedef DWORD TID ;
#else 
typedef pthread_t	TID ;
#endif

typedef int	ObjID_t;			//场景中固定的所有OBJ拥有不同的ObjID_t
typedef unsigned int UINT;
typedef int   BOOL;
#define     INVALID_ID		-1
#define 	FALSE			0
#define		TRUE			1

#endif //__TYPE_H__

