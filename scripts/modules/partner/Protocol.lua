module(...,package.seeall)

--查询伙伴
Chain = {
	{"chainId",		"int",		"关系链id"},
	{"partnerIds",	"int",		"伙伴id",		"repeated"}
}

CGPartnerQuery = {
}
GCPartnerQuery = {
	{"chain",		Chain,		"拥有的关系链",		"repeated"}
}

--合成伙伴
CGPartnerCompose = {
	{"id",		"int",		"伙伴id"}
}
GCPartnerCompose = {
	{"ret",		"int",		"返回码"}
}

--伙伴装备
CGPartnerEquip = {
	{"chainId",		"int",		"关系链id"},
	{"partnerId",		"int",		"伙伴id"},
}

GCPartnerEquip = {
	{"ret",		"int",		"返回码"},
	{"chainId",		"int",		"关系链id"},
	{"partnerId",		"int",		"伙伴id"},
}

--伙伴激活
CGPartnerActive = {
	{"chainId",		"int",		"关系链id"},
}

AttrChangeInfo = {
	{"name",	"string",	"英雄名"},
	{"attrname",	"string",	"属性名"},
	{"preAttrVal",	"int",	"变化前属性值"},
	{"attrVal",	"int",	"变化后属性值"},
}

GCPartnerActive = {
	{"ret",		"int",		"返回码"},
	{"chainId",		"int",		"关系链id"},
	{"attrs",	AttrChangeInfo,	"属性变化",		"repeated"}
}
