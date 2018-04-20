module(...,package.seeall)

MAX_LV = 100

ERR_CODE = 
{
	Success = 0,
	Null = 1, --对象空，请先激活神兵
	Invalid = 2, --非法请求

	OpenNeedStar = 11, --缺激活碎片
	OpenNo = 12, --无需激活，已经激活过

	UpLvSuccess = 20,
	UpLvNeedItem = 21, --缺少升级经验道具
	UpLvTop = 22, --已经是最高等级
	UpLvUpLv = 23, --升级了
	UpLvNeedStar = 24, --缺少星魂
}
ERR_TXT =
{
	[ERR_CODE.Success] = "%s激活成功！",
	[ERR_CODE.Null] = "请先激活神兵！",
	[ERR_CODE.Invalid] = "非法请求！",

	[ERR_CODE.OpenNeedStar] = "%s不足！",
	[ERR_CODE.OpenNo] = "该神兵已经激活！",

	[ERR_CODE.UpLvSuccess] = "增加了%d经验！",
	[ERR_CODE.UpLvNeedItem] = "缺少升级经验道具！",
	[ERR_CODE.UpLvTop] = "已经提升到最高等级！",
	[ERR_CODE.UpLvUpLv] = "增加了%d经验！%s提升至%d级",
}
