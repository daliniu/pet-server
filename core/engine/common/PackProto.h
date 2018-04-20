#ifndef __PACKPROTO__
#define __PACKPROTO__
#include <vector>
#include <string>
extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}
#define  MAX_PROTO_ID 20000

enum PA_TYPE
{
	PA_NONE,
	PA_INT,
	PA_SINT,
	PA_STRING,
	PA_TABLE,
};

struct sPA
{
	std::string strName;
	PA_TYPE eType;
	bool	bIsArray;
	bool	bIsHash;
	unsigned int nSubProtoID;
	unsigned int nTag;
	sPA(){
		eType = PA_NONE;
		strName = "";
		bIsArray = false;
		bIsHash = false;
		nSubProtoID = 0;
	}
};

typedef std::vector<sPA> vecProto_t;
class PackProto
{
public:
	int init(lua_State*);
	static PackProto *GetInst()
	{
		static PackProto pp;
		return &pp;
	}
	static int reg_proto(lua_State *pL);
	//从lua栈顶取table编码到buf中 返回编码长度
	unsigned int encode(unsigned int nProtoID,unsigned char* buf,lua_State* pL,int nArgOffset);

	//从buf中解码协议内容，写到lua的栈顶
	unsigned int decode(unsigned int nProtoID,const unsigned char* buf,unsigned int uiLen,lua_State* pL);
	unsigned int writeUInt(unsigned char *buf,unsigned int value);
	unsigned int readUInt(const unsigned char *buf,unsigned int &value);
	unsigned int writeSInt(unsigned char *buf,int value);
	unsigned int readSInt(const unsigned char *buf,int &value);
	unsigned int writeString(unsigned char *buf,const char* value,unsigned int uiLen);
	unsigned int readString(const unsigned char *buf,std::string &value);
private:
	bool proto_tree(int nProtoID, lua_State *pL);
	
	inline unsigned int ZigZagEncode32(int n)
	{
		return (n << 1) ^ (n >> 31);
	}
	inline int ZigZagDecode32(unsigned int n) {
		return (n >> 1) ^ -static_cast<int>(n & 1);
	}
	

	unsigned int encode_travel(vecProto_t vp,unsigned char* buf,lua_State *pL,bool bWithTag = false);
	unsigned int decode_travel(vecProto_t vp,const unsigned char* buf,lua_State *pL);
	unsigned int decodeWithTag_travel(vecProto_t vp,const unsigned char* buf,lua_State *pL);
	unsigned int encodeWithTag(unsigned int nProtoID,unsigned char* buf,lua_State*);



	std::vector<std::vector<sPA> > m_vvp;
	std::vector<int> m_vip;
	unsigned int m_nMaxProtoID;
};


#endif

