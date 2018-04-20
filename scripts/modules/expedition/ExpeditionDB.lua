module(..., package.seeall)

local ResetConfig = require("config.ExpeditionResetConfig").Config[1]
local DB = require("core.db.DB")

function new()
	local tab = {
		hasOpen = 0,										--是否已经自动开启
		curId = 1,											--当前远征编号
		resetCount = ResetConfig.freeResetCount,			--剩余重置次数
		buyResetCount = 0,									--已购重置次数
		hasResetCount = 0,									--已重置次数
		passId = 0,											--可扫荡的最大关卡
		lastResetTime = 0,									--上一次刷新重置次数时间
		treasureList = {},									--每个宝藏的领取状态
		rage = 20,											--自身怒气值
		assist = 0,											--援助值
		heroList = {},										--英雄列表
		copyList = {},
		clearRage = 0,
		clearAssist = 0,
		clearHeroList = {},
		clearCopyList = {},
		shopRefreshCnt = 1,
	}
	return tab
end

function onHumanDBLoad(human)
	setmetatable(human:getExpedition(), {__index = _M})

	--数字做key,需要主动设置
	DB.dbSetMetatable(human:getExpedition().treasureList)
	DB.dbSetMetatable(human:getExpedition().copyList)
	DB.dbSetMetatable(human:getExpedition().clearCopyList)
end
