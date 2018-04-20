module(...,package.seeall)

local Defined = require("config.OrochiDefinedConfig").Defined

MAX_COUNTER = Defined.MAX_COUNTER
MAX_LEVEL_COUNTER = Defined.MAX_LEVEL_COUNTER
MAX_RESET_COUNTER = Defined.MAX_RESET_COUNTER

FIGHT_SUCCESS = 1	--挑战成功
FIGHT_FAIL = 2		--挑战失败
--STATUS
STATUS = {
	CAN_FIGHT = 1,	--可挑战
	CLOSED = 2,		--关闭的
	HAD_PASS = 3,	--已通关
}

RANK_MAIL_ID = 15  --排行榜奖励邮件

ERR_CODE = 
{
	MAX_COUNTER = 1,	--超过挑战次数
	MAX_LEVEL_COUNTER = 2,	--超过关卡挑战次数
	INVALID_LEVEL = 3,		--无效关卡
	NOT_OPEN_LV = 4,	--未达到开启lv
	NOT_PRE_LEVEL = 5,	--前置关卡未开
	HAD_PASS = 6,	
}
ERR_TXT =
{
	[ERR_CODE.MAX_COUNTER] = "超过挑战次数",
	[ERR_CODE.MAX_LEVEL_COUNTER] = "超过关卡挑战次数",
	[ERR_CODE.INVALID_LEVEL] = "无效关卡",
	[ERR_CODE.NOT_OPEN_LV] = "未达到开启等级",
	[ERR_CODE.NOT_PRE_LEVEL] = "前置关卡未开",
	[ERR_CODE.HAD_PASS] = "已通关",
}
