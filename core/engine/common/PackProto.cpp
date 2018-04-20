#include "PackProto.h"
#include <assert.h>
#include <string>
#include <string.h>
#include "Assertx.h"
using namespace std;


int PackProto::init(lua_State* pL)
{
	m_nMaxProtoID = MAX_PROTO_ID;
	//lua_register(pL, "reg_proto", PackProto::reg_proto);
	return 0;
}

int PackProto::reg_proto(lua_State *pL)
{
	int nProtoId = (int)luaL_checknumber(pL, 1);
	PackProto* pp = PackProto::GetInst();
	pp->proto_tree(nProtoId, pL);
	return 0;
}

bool PackProto::proto_tree(int nProtoID, lua_State *pL)
{
	int nTopOld = lua_gettop(pL);
	if (nProtoID >= (int)m_vvp.size())
	{
		m_vvp.resize(nProtoID + 1);
		m_vip.resize(nProtoID + 1);
	}
	if (m_vvp[nProtoID].size())
	{
		m_vvp[nProtoID].clear();
	}
	m_vip[nProtoID] = 1;


	int nObjLen = lua_objlen(pL, -1);
	m_vvp[nProtoID].resize(nObjLen);
	for (int i = 0; i < nObjLen; ++i)
	{
		lua_rawgeti(pL, -1, i + 1);
		sPA &protoAttr = m_vvp[nProtoID][i];
		protoAttr.nTag = i+1;

		//µÚËÄ¸ö×Ö¶ÎÈç¹ûÊÇrepeated£¬Ôò±íÊ¾ÊÇÊý×é£¬Èç¹ûÊ¡ÂÔ£¬Ôò±íÊ¾required
		if (lua_objlen(pL,-1) >= 4)
		{
			lua_rawgeti(pL, -1, 4);
			if (lua_isstring(pL, -1))
			{
				const char *pType = luaL_checkstring(pL, -1);
				if (strstr(pType, "repeated"))
				{
					m_vvp[nProtoID][i].bIsArray = true; 
				}
				else 
				{
					m_vvp[nProtoID][i].bIsArray = false;  
				}
				if (strstr(pType, "hash"))
				{
					m_vvp[nProtoID][i].bIsHash = true; 
				}
				else 
				{
					m_vvp[nProtoID][i].bIsHash = false;  
				}
			}
			else
			{
				puts("last field of protocol define must be string ");
				Assert(0);
				return false;
			}
			lua_pop(pL, 1);
		}
		else
		{
			m_vvp[nProtoID][i].bIsArray = false;
		}

		lua_rawgeti(pL, -1, 1);
		protoAttr.strName = luaL_checkstring(pL, -1);
		lua_pop(pL, 1);

		lua_rawgeti(pL, -1, 2);
		if (lua_isstring(pL, -1))
		{
			const char *pType = luaL_checkstring(pL, -1);
			if (!strcmp(pType, "int"))
			{
				protoAttr.eType = PA_INT; 
			}
			else if (!strcmp(pType, "sint"))
			{
				protoAttr.eType = PA_SINT; 
			}
			else if (!strcmp(pType, "string"))
			{
				protoAttr.eType = PA_STRING;
			}
			else
			{
				puts("is string but not int and not short and not char");
				Assert(0);
				return false;
			}
		}
		else if (lua_istable(pL, -1))
		{
			protoAttr.eType = PA_TABLE;
			protoAttr.nSubProtoID = ++m_nMaxProtoID;
			if (!proto_tree(protoAttr.nSubProtoID, pL))
			{
				return false;
			}
		}
		else
		{
			puts("not string and not table");
			Assert(0);
			return false;
		}
		lua_pop(pL, 1);



		


		lua_pop(pL, 1);
	}
	Assert(lua_gettop(pL) == nTopOld);
	return true;
}



unsigned int PackProto::encode(unsigned int nProtoID,unsigned char* buf,lua_State *pL,int nArgOffset)
{
	Assert(nProtoID <= MAX_PROTO_ID);
	//assert(!m_vvp[nProtoID].empty());  for heartbeat packet the vp is empty

	unsigned int uiPackLen = 0;
	//lua args  =  nProtoID,FD,....
	vecProto_t& vp = m_vvp[nProtoID];
	for (unsigned int i = 0;i<vp.size();i++)
	{
		int luaindex = nArgOffset+1+i;
		//proto fields starts at nArgOffset+1+i
		int luatype = lua_type(pL,luaindex);
		bool bMissingField = false;
		if (lua_isnil(pL,luaindex) || luatype == LUA_TNONE)
		{
			bMissingField = true;
		}
		int nFieldNameLen = vp[i].strName.length();
		bool bWithTag = false;
		if (vp[i].bIsHash){
			bWithTag = true;
		}
		//if (nFieldNameLen > 5 && vp[i].strName.substr(nFieldNameLen-5) == "_hash")
		//{
		//	bWithTag = true;
		//}

		if (vp[i].bIsArray )
		{
			int luatype = lua_type(pL,luaindex);
			Assert(luatype == LUA_TTABLE || luatype == LUA_TNIL|| LUA_TNONE);
			if (luatype != LUA_TTABLE && luatype != LUA_TNIL && luatype != LUA_TNONE)
			{
				return 0;
			}
			if (bMissingField)
			{
				uiPackLen += writeUInt(buf+uiPackLen,0);
			}
			else
			{
				lua_pushvalue(pL,luaindex);
				unsigned int objlen = lua_objlen(pL,-1);
				uiPackLen += writeUInt(buf+uiPackLen,objlen);
				for (int j = 0;j < objlen;j++)
				{
					lua_rawgeti(pL,-1,j+1);
					if (vp[i].eType == PA_INT)
					{
						unsigned int luaint = luaL_checkint(pL,-1);
						uiPackLen += writeUInt(buf+uiPackLen,luaint);
						lua_pop(pL,1);
					}
					else if (vp[i].eType == PA_SINT)
					{
						int luaint = luaL_checkint(pL,-1);
						uiPackLen += writeSInt(buf+uiPackLen,luaint);
						lua_pop(pL,1);
					}
					else if (vp[i].eType == PA_STRING)
					{
						const char* luachar = luaL_checkstring(pL,-1);
						unsigned int len = strlen(luachar);
						uiPackLen += writeString(buf+uiPackLen,luachar,len);
						lua_pop(pL,1);
					}
					else if (vp[i].eType == PA_TABLE)
					{
						vecProto_t& vecSubProto = m_vvp[vp[i].nSubProtoID];
						uiPackLen += encode_travel(vecSubProto,buf+uiPackLen,pL,bWithTag);
					}
					else
					{
						puts("field type not valid");
						Assert(0);
						return false;
					}
				}
				lua_pop(pL,1);
			}


		}
		else
		{
			switch (vp[i].eType)
			{
			case PA_INT:
				{
					if (bMissingField)
					{
						uiPackLen += writeUInt(buf+uiPackLen,0);
					}
					else
					{
						if (luatype != LUA_TNUMBER)
						{
							//puts("field type not match");
							//assert(0);
							AssertFt(false,"field type not math type = %d",luatype);
							return false;
						}
						int luaint = luaL_checkint(pL,luaindex);
						uiPackLen += writeUInt(buf+uiPackLen,luaint);
					}
				}
				break;
			case PA_SINT:
				{
					if (bMissingField)
					{
						uiPackLen += writeSInt(buf+uiPackLen,0);
					}
					else
					{
						if (luatype != LUA_TNUMBER)
						{
							puts("field type not match");
							Assert(0);
							return false;
						}
						int luaint = luaL_checkint(pL,luaindex);
						uiPackLen += writeSInt(buf+uiPackLen,luaint);
					}
				}
				break;
			case PA_STRING:
				{
					if (bMissingField)
					{
						uiPackLen += writeUInt(buf+uiPackLen,0);
					}
					else
					{
						if (luatype != LUA_TSTRING)
						{
							puts("field type not match");
							Assert(0);
							return false;
						}
						const char* luachar = luaL_checkstring(pL,luaindex);
						unsigned int len = strlen(luachar);
						uiPackLen += writeString(buf+uiPackLen,luachar,len);
					}
				}
				break;
			case PA_TABLE:
				{
					if (bMissingField)
					{
						lua_createtable(pL,0,0);
					}
					else
					{
						if (luatype != LUA_TTABLE)
						{
							puts("field type not match");
							Assert(0);
							return false;
						}
						lua_pushvalue(pL,luaindex);
					}
					vecProto_t& vecSubProto = m_vvp[vp[i].nSubProtoID];
					uiPackLen += encode_travel(vecSubProto,buf+uiPackLen,pL,bWithTag);
				}
				break;
			default:
				{
					puts("field type not match field num error");
					Assert(0);
					return false;
				}

			}


		}

	}
	return uiPackLen;
}
unsigned int PackProto::decode(unsigned int nProtoID,const unsigned char* buf,unsigned int uiLen,lua_State* pL)
{
	Assert(nProtoID <= MAX_PROTO_ID);
	if (m_vvp.size() - 1 < nProtoID)
	{
		return -1;
	}
	//空协议不适用于下面这条断言，删除之
	//assert(!m_vvp[nProtoID].empty());
	if (m_vip[nProtoID] == 0)
	{
		//未定义的协议，直接返回-1
		return -1;
	}

	unsigned int uiArgNum = 0;
	unsigned int uiPackLen = 0;
	vecProto_t& vp = m_vvp[nProtoID];
	for (unsigned int i = 0;i<vp.size();i++)
	{
		int nFieldNameLen = vp[i].strName.length();
		bool bWithTag = false;
		if (vp[i].bIsHash){
			bWithTag = true;
		}
		//if (nFieldNameLen > 5 && vp[i].strName.substr(nFieldNameLen-5) == "_hash")
		//{
		//	bWithTag = true;
		//}
		if (vp[i].bIsArray)
		{
			unsigned int arrlen = 0;
			uiPackLen += readUInt(buf+uiPackLen,arrlen);
			lua_createtable(pL,arrlen,0);
			for (int j = 0;j < arrlen;j++)
			{
				if (vp[i].eType == PA_TABLE)
				{
					vecProto_t& vecSubProto = m_vvp[vp[i].nSubProtoID];
					lua_createtable(pL,0,0);
					if (bWithTag)
					{
						uiPackLen += decodeWithTag_travel(vecSubProto,buf+uiPackLen,pL);
					}
					else
					{
						uiPackLen += decode_travel(vecSubProto,buf+uiPackLen,pL);
					}
					
				}
				else if (vp[i].eType == PA_INT)
				{
					unsigned int v = 0;
					uiPackLen += readUInt(buf+uiPackLen,v);
					lua_pushinteger(pL,v);
				}
				else if (vp[i].eType == PA_SINT)
				{
					int v = 0;
					uiPackLen += readSInt(buf+uiPackLen,v);
					lua_pushinteger(pL,v);
				}
				else if (vp[i].eType == PA_STRING)
				{
					string v;
					uiPackLen += readString(buf+uiPackLen,v);
					lua_pushstring(pL,v.c_str());
				}
				lua_rawseti(pL,-2,j+1);
			}
		}
		else
		{
			if (vp[i].eType == PA_TABLE)
			{
				vecProto_t& vecSubProto = m_vvp[vp[i].nSubProtoID];
				lua_createtable(pL,0,0);
				if (bWithTag)
				{
					uiPackLen += decodeWithTag_travel(vecSubProto,buf+uiPackLen,pL);
				}
				else
				{
					uiPackLen += decode_travel(vecSubProto,buf+uiPackLen,pL);
				}
			}
			else if (vp[i].eType == PA_INT)
			{
				unsigned int v = 0;
				uiPackLen += readUInt(buf+uiPackLen,v);
				lua_pushinteger(pL,v);
			}
			else if (vp[i].eType == PA_SINT)
			{
				int v = 0;
				uiPackLen += readSInt(buf+uiPackLen,v);
				lua_pushinteger(pL,v);
			}
			else if (vp[i].eType == PA_STRING)
			{
				string v;
				uiPackLen += readString(buf+uiPackLen,v);
				lua_pushstring(pL,v.c_str());
			}
		}
		uiArgNum++;
	}
	if (uiPackLen != uiLen)
	{
		std::string msg = "decode len not match protocol id ="+nProtoID;
		puts(msg.c_str());
		Assert(0);
		return -1;
	}
	return uiArgNum;

	//return bWithTag?decodeWithTag_travel(m_vvp[nProtoID],buf,uiLen,pL):decode_travel(m_vvp[nProtoID],buf,pL);
}
unsigned int PackProto::decodeWithTag_travel(vecProto_t vp,const unsigned char* buf,lua_State *pL)
{
	unsigned int len = 0;
	unsigned int fieldnum=0;
	len += readUInt(buf+len,fieldnum);
	unsigned int index = 0;
	for (unsigned int l = 0;l < fieldnum;l++)
	{
		unsigned int tag = 0;
		len += readUInt(buf+len,tag);
		Assert(tag < vp.size());
		while (index < tag)
		{
			lua_pushstring(pL,vp[index].strName.c_str());
			lua_pushnil(pL);
			lua_rawset(pL,-3);
			index++;
		}
		index = tag+1;
		if (vp[tag].eType == PA_INT)
		{
			if (vp[tag].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int i = 0;i<uiArrSize;i++)
				{
					unsigned int v=0;
					len += readUInt(buf+len,v);
					lua_pushinteger(pL,v);
					lua_rawseti(pL,-2,i+1);
				}
				lua_rawset(pL,-3);
			}
			else
			{
				unsigned int v=0;
				len += readUInt(buf+len,v);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_pushinteger(pL,v);
				lua_rawset(pL,-3);
			}
		}
		else if (vp[tag].eType == PA_SINT)
		{
			if (vp[tag].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int i = 0;i<uiArrSize;i++)
				{
					int v=0;
					len += readSInt(buf+len,v);
					lua_pushinteger(pL,v);
					lua_rawseti(pL,-2,i+1);
				}
				lua_rawset(pL,-3);
			}
			else
			{
				int v=0;
				len += readSInt(buf+len,v);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_pushinteger(pL,v);
				lua_rawset(pL,-3);
			}
		}
		else if (vp[tag].eType == PA_STRING)
		{
			if (vp[tag].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int i = 0;i<uiArrSize;i++)
				{
					string value;
					len += readString(buf+len,value);
					lua_pushstring(pL,value.c_str());
					lua_rawseti(pL,-2,i+1);
				}
				lua_rawset(pL,-3);
			}
			else
			{
				string value;
				len += readString(buf+len,value);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_pushstring(pL,value.c_str());
				lua_rawset(pL,-3);
			}

		}
		else if (vp[tag].eType == PA_TABLE)
		{
			vecProto_t& vecSubProto = m_vvp[vp[tag].nSubProtoID];
			if (vp[tag].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int i = 0;i<uiArrSize;i++)
				{
					lua_createtable(pL,0,vecSubProto.size());
					len += decodeWithTag_travel(vecSubProto,buf+len,pL);
					lua_rawseti(pL,-2,i+1);
				}
				lua_rawset(pL,-3);
			}
			else
			{

				lua_pushstring(pL,vp[tag].strName.c_str());
				lua_createtable(pL,0,vecSubProto.size());
				len += decodeWithTag_travel(vecSubProto,buf+len,pL);
				lua_rawset(pL,-3);
			}
		}

	}
	return len;
}
unsigned int PackProto::decode_travel(vecProto_t vp,const unsigned char* buf,lua_State *pL)
{
	unsigned int len = 0;
	for (unsigned int i =0;i< vp.size();i++)
	{
		if (vp[i].eType == PA_INT)
		{
			if (vp[i].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int j = 0;j<uiArrSize;j++)
				{
					unsigned int v=0;
					len += readUInt(buf+len,v);
					lua_pushinteger(pL,v);
					lua_rawseti(pL,-2,j+1);
				}
				lua_rawset(pL,-3);

			}
			else
			{
				unsigned int v=0;
				len += readUInt(buf+len,v);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_pushinteger(pL,v);
				lua_rawset(pL,-3);
			}

		}
		else if (vp[i].eType == PA_SINT)
		{
			if (vp[i].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int j = 0;j<uiArrSize;j++)
				{
					int v=0;
					len += readSInt(buf+len,v);
					lua_pushinteger(pL,v);
					lua_rawseti(pL,-2,j+1);
				}
				lua_rawset(pL,-3);

			}
			else
			{
				int v=0;
				len += readSInt(buf+len,v);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_pushinteger(pL,v);
				lua_rawset(pL,-3);
			}
		}
		else if (vp[i].eType == PA_STRING)
		{
			if (vp[i].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int j = 0;j<uiArrSize;j++)
				{
					string value;
					len += readString(buf+len,value);
					lua_pushstring(pL,value.c_str());
					lua_rawseti(pL,-2,j+1);
				}
				lua_rawset(pL,-3);

			}
			else
			{
				string value;
				len += readString(buf+len,value);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_pushstring(pL,value.c_str());
				lua_rawset(pL,-3);
			}

		}
		else if (vp[i].eType == PA_TABLE)
		{
			vecProto_t& vecSubProto = m_vvp[vp[i].nSubProtoID];
			if (vp[i].bIsArray)
			{
				unsigned int uiArrSize = 1;
				len+=readUInt(buf+len,uiArrSize);
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_createtable(pL,uiArrSize,0);
				for (unsigned int j = 0;j<uiArrSize;j++)
				{
					lua_createtable(pL,0,vecSubProto.size());
					len += decode_travel(vecSubProto,buf+len,pL);
					lua_rawseti(pL,-2,j+1);
				}
				lua_rawset(pL,-3);
			}
			else
			{
				
				lua_pushstring(pL,vp[i].strName.c_str());
				lua_createtable(pL,0,vecSubProto.size());
				len += decode_travel(vecSubProto,buf+len,pL);
				lua_rawset(pL,-3);
			}
		}
	}
	return len;
}
unsigned int PackProto::encode_travel(vecProto_t vp,unsigned char* buf,lua_State *pL,bool bWithTag)
{
	unsigned int uiPackLen = 0;
	if (bWithTag)
	{
		//withTagÊ±£¬×Ö¶Î¿ÉÒÔ²»È«£¬Òò´ËÐèÒª»ñµÃ×Ö¶Î¸öÊý
		unsigned int l = 0;
		for (unsigned int i = 0;i<vp.size();i++)
		{
			lua_pushfstring(pL,vp[i].strName.c_str());
			lua_gettable(pL,-2);
			if (!lua_isnil(pL,-1))
			{
				l++;
			}
			lua_pop(pL,1);
		}
		
		uiPackLen += writeUInt(buf+uiPackLen,l);
	}
	
	for (unsigned int i = 0;i<vp.size();i++)
	{
		// ÊÇ·ñÓÐ×Ö¶ÎÈ±Ê§
		bool bFieldMissing = false;
		lua_pushfstring(pL,vp[i].strName.c_str());
		lua_gettable(pL,-2);
		if (lua_isnil(pL,-1))
		{
			if (bWithTag)
			{
				lua_pop(pL,1);
				continue;
			}
			else
			{
				bFieldMissing = true;
			}
		}

		if (vp[i].eType == PA_INT)
		{
			if (vp[i].bIsArray)
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_istable(pL,-1))
				{
					unsigned int l = lua_objlen(pL,-1);
					if (bWithTag)
					{
						//WithTagÊ±£¬°Ñ×Ö¶ÎµÄÏÂ±ê£¨0¿ªÊ¼¼ÆÊý£©×÷ÎªTag±àÂëµ½Ð­ÒéÖÐ
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					uiPackLen += writeUInt(buf+uiPackLen,l);
					for (unsigned int j = 0;j < l; j++)
					{
						lua_rawgeti(pL,-1,j+1);
						int luaint = luaL_checkint(pL,-1);
						uiPackLen += writeUInt(buf+uiPackLen,luaint);
						lua_pop(pL, 1);
					}
					
					
				}
				else
				{
					Assert(NULL);
				}
			}
			else
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_isnumber(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					int luaint = luaL_checkint(pL,-1);
					uiPackLen += writeUInt(buf+uiPackLen,luaint);
				}
				else
				{
					Assert(NULL);
				}
			}
			lua_pop(pL, 1);

		}
		else if (vp[i].eType == PA_SINT)
		{
			if (vp[i].bIsArray)
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_istable(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					unsigned int l = lua_objlen(pL,-1);
					uiPackLen += writeUInt(buf+uiPackLen,l);
					for (unsigned int j = 0;j < l; j++)
					{
						lua_rawgeti(pL,-1,j+1);
						int luaint = luaL_checkint(pL,-1);
						uiPackLen += writeSInt(buf+uiPackLen,luaint);
						lua_pop(pL, 1);
					}
					

				}
				else
				{
					Assert(NULL);
				}
			}
			else
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_isnumber(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					int luaint = luaL_checkint(pL,-1);
					uiPackLen += writeSInt(buf+uiPackLen,luaint);
				}
				else
				{
					Assert(NULL);
				}
			}
			lua_pop(pL, 1);
		}
		else if (vp[i].eType == PA_STRING)
		{
			if (vp[i].bIsArray)
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_istable(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					unsigned int l = lua_objlen(pL,-1);
					uiPackLen += writeUInt(buf+uiPackLen,l);
					for (unsigned int j = 0;j < l; j++)
					{
						lua_rawgeti(pL,-1,j+1);
						const char* luachar = luaL_checkstring(pL,-1);
						uiPackLen += writeString(buf+uiPackLen,luachar,strlen(luachar));
						lua_pop(pL, 1);
					}
					

				}
				else
				{
					Assert(NULL);
				}
			}
			else
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_isstring(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					const char* luachar = luaL_checkstring(pL,-1);
					unsigned int len = strlen(luachar);
					uiPackLen += writeString(buf+uiPackLen,luachar,len);
				}
				else
				{
					Assert(NULL);
				}
			}
			lua_pop(pL, 1);
		}
		else if (vp[i].eType == PA_TABLE)
		{
			Assert(vp[i].nSubProtoID != 0);
			vecProto_t& vecSubProto = m_vvp[vp[i].nSubProtoID];
			if (vp[i].bIsArray)
			{
				if (bFieldMissing)
				{
					uiPackLen += writeUInt(buf+uiPackLen,0);
				}
				else if (lua_istable(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					unsigned int l = lua_objlen(pL,-1);
					uiPackLen += writeUInt(buf+uiPackLen,l);
					for (unsigned int j = 0;j < l; j++)
					{
						lua_rawgeti(pL,-1,j+1);
						uiPackLen += encode_travel(vecSubProto,buf+uiPackLen,pL,vp[i].bIsHash);
					}
					

				}
				else
				{
					Assert(NULL);
				}
				lua_pop(pL, 1);
			}
			else
			{
				if (bFieldMissing)
				{
					lua_pop(pL,1);
					lua_createtable(pL,0,0);
				}
				if (lua_istable(pL,-1))
				{
					if (bWithTag)
					{
						uiPackLen += writeUInt(buf+uiPackLen,i);
					}
					uiPackLen += encode_travel(vecSubProto,buf+uiPackLen,pL,vp[i].bIsHash);
				}
				else
				{
					Assert(NULL);
				}
				//by tanjie encode_travel will pop ,so we do not pop here
			}
			
		}
		else
		{
			Assert(0);
		}
	}
	lua_pop(pL,1);
	return uiPackLen;
}
unsigned int PackProto::encodeWithTag(unsigned int nProtoID,unsigned char* buf,lua_State *pL)
{
	Assert(nProtoID <= MAX_PROTO_ID);
	Assert(!m_vvp[nProtoID].empty());
	return encode_travel(m_vvp[nProtoID],buf,pL,true);
}

unsigned int PackProto::readUInt(const unsigned char *buf,unsigned int &value)
{
	const unsigned char* ptr = buf;
	unsigned int b;
	unsigned int result;

	b = *(ptr++); result  = (b & 0x7F)      ; if (!(b & 0x80)) goto done;
	b = *(ptr++); result |= (b & 0x7F) <<  7; if (!(b & 0x80)) goto done;
	b = *(ptr++); result |= (b & 0x7F) << 14; if (!(b & 0x80)) goto done;
	b = *(ptr++); result |= (b & 0x7F) << 21; if (!(b & 0x80)) goto done;
	b = *(ptr++); result |=  b         << 28; if (!(b & 0x80)) goto done;

done:
	value = result;
	return ptr-buf;
}
unsigned int PackProto::writeUInt(unsigned char *target,unsigned int value)
{
	target[0] = static_cast<unsigned char>(value | 0x80);
	if (value >= (1 << 7)) {
		target[1] = static_cast<unsigned char>((value >>  7) | 0x80);
		if (value >= (1 << 14)) {
			target[2] = static_cast<unsigned char>((value >> 14) | 0x80);
			if (value >= (1 << 21)) {
				target[3] = static_cast<unsigned char>((value >> 21) | 0x80);
				if (value >= (1 << 28)) {
					target[4] = static_cast<unsigned char>(value >> 28);
					return 5;
				} else {
					target[3] &= 0x7F;
					return 4;
				}
			} else {
				target[2] &= 0x7F;
				return 3;
			}
		} else {
			target[1] &= 0x7F;
			return 2;
		}
	} else {
		target[0] &= 0x7F;
		return 1;
	}
}
unsigned int PackProto::readSInt(const unsigned char *buf,int &value)
{
	unsigned int nvalue= 0;
	unsigned int uiLen = readUInt(buf,nvalue);
	value = ZigZagDecode32(nvalue);
	return uiLen;
}
unsigned int PackProto::writeSInt(unsigned char *target,int value)
{
	return writeUInt(target,ZigZagEncode32(value));
}
unsigned int PackProto::writeString(unsigned char *target,const char* value,unsigned int uiLen)
{
	unsigned int len = writeUInt(target,uiLen);
	memcpy(target+len,value,uiLen);
	return len + uiLen;
}
unsigned int PackProto::readString(const unsigned char *buf,string& value)
{
	unsigned int uiLenOfBytes = 0;
	unsigned int b = readUInt(buf,uiLenOfBytes);
	value = string((char*)(buf+b),uiLenOfBytes);
	return b+uiLenOfBytes;
}