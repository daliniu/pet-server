module(...,package.seeall)

-- 1=八尺琼勾玉   2=草雉剑   3=八尺镜
WEP_NAME =
{
[1] ="八尺琼勾玉",
[2] ="草雉剑",
[3] ="八尺镜",
}

WEP_UPLV_ITEM = 
{
[1] = 1202001, -- 小经验果
[2] = 1202002, -- 大经验果
}

WEAPON_MAX_LV = 80 		--最大等级

WEP_UPQUALITY_COLOR = {"白","绿","蓝","黄","红","紫","橙"}

ERR_CODE = 
{
	Success = 0,
	Null = 1, --对象空，请先激活神兵
	Invalid = 2, --非法请求

	OpenNeedFrag = 11, --缺激活碎片
	OpenNo = 12, --无需激活，已经激活过

	UpLvSuccess = 20,
	UpLvNeedItem = 21, --缺少升级经验道具
	UpLvTop = 22, --已经是最高等级
	UpLvUpLv = 23, --升级了
	UpLvHumanLv = 24, --超过人物等级
	UpLvQualityLv = 25, --等阶对应最大等级限制

	UpQualitySuccess = 30,
	UpQualityNeedFrag = 31, --缺升品碎片
	UpQualityTop = 32, --已经是最高品
}
ERR_TXT =
{
	[ERR_CODE.Success] = "%s激活成功！",
	[ERR_CODE.Null] = "请先激活神兵！",
	[ERR_CODE.Invalid] = "非法请求！",

	[ERR_CODE.OpenNeedFrag] = "%s不足！",
	[ERR_CODE.OpenNo] = "该神兵已经激活！",

	[ERR_CODE.UpLvSuccess] = "增加了%d经验！",
	[ERR_CODE.UpLvNeedItem] = "缺少升级经验道具！",
	[ERR_CODE.UpLvTop] = "已经提升到最高等级！",
	[ERR_CODE.UpLvUpLv] = "增加了%d经验！%s提升至%d级",
	[ERR_CODE.UpLvHumanLv] = "神兵不能超过战队等级",
	[ERR_CODE.UpLvQualityLv] = "已达当前颜色品质所能达到的最大等级",

	[ERR_CODE.UpQualitySuccess] = "%s提升至%s色品质！",
	[ERR_CODE.UpQualityNeedFrag] = "缺少升级品阶碎片！",
	[ERR_CODE.UpQualityTop] = "已经提升到最高品阶！",
}
