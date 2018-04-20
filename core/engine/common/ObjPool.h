#ifndef __OBJPOOL_H__
#define __OBJPOOL_H__

#include "Type.h"
#include "Utils.h"

template<class T>
class ObjPool
{
public:
	ObjPool()
	{
		m_papObj	    = NULL;
        m_pAvailable    = NULL;
		m_nMaxCount		= 0;
		m_nPosition		= 0;
        m_nUsedCount    = 0;
	}

	~ObjPool( void )
	{
		Term() ;
	}

    T* Get(int i)
    {
        if (i>=0 && i<m_nMaxCount)
            return m_papObj[i];
        else
            return NULL;
    }

	bool Init(int nMaxCount = 10)
	{
		if ( nMaxCount <= 0 )
			return false;

		m_nMaxCount		= nMaxCount;
		m_nPosition		= 0;
        m_nUsedCount    = 0;
		m_papObj	= new T* [m_nMaxCount];
        m_pAvailable = new bool[m_nMaxCount];

		int i;
		for( i = 0; i < m_nMaxCount; i++ )
		{
			m_papObj[i] = new T;
            m_pAvailable[i] = true;
			if ( m_papObj[i] == NULL )
			{
				return false;
			}
		}
		return true;
	}


	T* NewObj( void )
	{
        m_Lock.Lock();
		if ( m_nUsedCount == m_nMaxCount )
		{
            ReSize();
		}

        int i= 0; 
        while(i<m_nMaxCount){
            m_nPosition = (m_nPosition + 1)%m_nMaxCount;
            if (m_pAvailable[m_nPosition]){
                break;
            }
            i++;
        }

		T *pObj = m_papObj[m_nPosition];
		pObj->SetPoolID( (int)m_nPosition );
        m_pAvailable[m_nPosition] = false;
        m_nUsedCount++;
        m_Lock.Unlock();
		return pObj;
	}
	
	void DeleteObj( T *pObj )
    {
		if ( pObj == NULL )
			return ;

        m_Lock.Lock();
        DeleteObj(pObj->GetPoolID());
        m_Lock.Unlock();
    }

    int PoolSize()
    {
        return m_nMaxCount;
    }

	int GetCount( void )const
	{
        return m_nUsedCount;
	}

private:

    void ReSize()
    {
        if (m_nUsedCount < m_nMaxCount)
            return;

        int oldsize = m_nMaxCount;
        m_nMaxCount = m_nMaxCount + (m_nMaxCount >> 1); 

        T ** pObj = new T* [m_nMaxCount]; 
        bool *pAvailable = new bool[m_nMaxCount];

        for (int i=0; i<m_nMaxCount; i++)
        {
            if (i < oldsize){
                pObj[i] = m_papObj[i];
                pAvailable[i] = m_pAvailable[i]; 
            }
            else
            {
                pObj[i] = new T;
                pAvailable[i] = true;
            }
        }

        SAFE_DELETE_ARRAY(m_papObj);
        SAFE_DELETE_ARRAY(m_pAvailable);
        m_papObj = pObj;
        m_pAvailable = pAvailable;
    }

    void DeleteObj( int nDelIndex )
    {
        if (nDelIndex >= m_nMaxCount || nDelIndex < 0)
        {          
           return ;
        }

        T *pDelObj = m_papObj[nDelIndex];
        pDelObj->SetPoolID(-1);
        pDelObj->CleanUp();
        m_pAvailable[nDelIndex] = true;
        m_nUsedCount--;
    }

	void Term( void )
	{
		if ( m_papObj != NULL )
		{
			int i;
			for ( i = 0; i < m_nMaxCount; i++ )
			{
				SAFE_DELETE(m_papObj[i]);
                m_pAvailable[i] = true;
			}

			SAFE_DELETE_ARRAY(m_papObj);
		}

		m_nMaxCount		= 0;
		m_nPosition		= 0;
        m_nUsedCount    = 0;
	}

private:
	T				**m_papObj;
    bool            *m_pAvailable;
	int				m_nMaxCount;
	int				m_nPosition;
    int             m_nUsedCount;
    MyLock          m_Lock;
};

#endif

