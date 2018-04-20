// Filename   : Assert.cpp 
//
//--------------------------------------------------------------------------------

#include "Assertx.h"
#include "Type.h"
#include <stdio.h>
#include "Utils.h"

int	g_Command_Assert=1 ;//���Ʋ�����0:���� 1:�����׳��쳣���ڻ�ȡ���ж�ջ
int g_Command_IgnoreMessageBox=FALSE ;//���Ʋ���������MyMessageBox���ж�





void __show__( const CHAR* szTemp )
{
#ifdef __LINUX__
	printf("Assert:%s",szTemp);
#endif
#if defined(__WINDOWS__)
	static MyLock lock ;
	if( g_Command_Assert!=0 )
	{
		lock.Lock() ;
		INT iRet = ::MessageBoxA( NULL, szTemp, "�쳣", MB_OK ) ;
		lock.Unlock() ;
	}
	throw(1);
#elif defined(__LINUX__)
	
#endif
}

void __messagebox__(const CHAR*msg )
{
	if( g_Command_IgnoreMessageBox )
		return ;
#if defined(__WINDOWS__)
	::MessageBoxA( NULL, msg, "��Ϣ", MB_OK ) ;
#elif defined(__LINUX__)
#endif
}
//--------------------------------------------------------------------------------
//
// __assert__
//
//
//--------------------------------------------------------------------------------
void __assert__ ( const CHAR * file , UINT line , const CHAR * func , const CHAR * expr )
{
	CHAR szTemp[1024] = {0};
	
#ifdef __LINUX__ //������ʽ
	sprintf( szTemp, "[%s][%d][%s][%s]\n", file, line, func, expr ) ;
#elif __WINDOWS__
	sprintf( szTemp, "[%s][%d][%s][%s]", file, line, func, expr ) ;
#endif
	__show__(szTemp) ;
}

void __assertex__ ( const CHAR * file , UINT line , const CHAR * func , const CHAR * expr ,const CHAR* msg)
{
	CHAR szTemp[1024] = {0};
#ifdef __LINUX__
	sprintf( szTemp, "[%s][%d][%s][%s]\n[%s]\n", file, line, func, expr ,msg ) ;
#elif __WINDOWS__
	sprintf( szTemp, "[%s][%d][%s][%s]\n[%s]", file, line, func, expr ,msg ) ;
#endif
	__show__(szTemp) ;
}

void __assertft__ ( const CHAR * file, UINT line ,const CHAR * func ,const CHAR * expr, const CHAR * fmt,...)
{
	CHAR szTemp[1024] = {0};
	CHAR szFormat[1024] = {0};

	va_list vlist;
	va_start( vlist, fmt );
	tvsnprintf(szFormat, 1024, fmt, vlist); 
	va_end(vlist);
	//sprintf(szFormat,fmt,__VA_ARGS__);

#ifdef __LINUX__
	sprintf( szTemp, "[%s][%d][%s][%s]\n[%s]\n", file, line, func, expr ,szFormat ) ;
#elif __WINDOWS__
	sprintf( szTemp, "[%s][%d][%s][%s]\n[%s]", file, line, func, expr ,szFormat ) ;
#endif
	__show__(szTemp) ;
}


void __assertspecial__ ( const CHAR * file , UINT line , const CHAR * func , const CHAR * expr ,const CHAR* msg)
{
	CHAR szTemp[1024] = {0};
	
#ifdef __LINUX__
	sprintf( szTemp, "S[%s][%d][%s][%s]\n[%s]\n", file, line, func, expr ,msg ) ;
#elif __WINDOWS__
	sprintf( szTemp, "S[%s][%d][%s][%s]\n[%s]", file, line, func, expr ,msg ) ;
#endif
	__show__(szTemp) ;
}
