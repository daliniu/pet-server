module(...,package.seeall)

local Define = require("modules.flower.FlowerDefine")

function new()
	local instance = {
		sendCount = 0,									--已经送花奖励次数
		showTip = 0,									--今日提示
		giveList = {},									--当天赠送玩家列表
		sendRecordList = {},							--赠送记录{account,flowerType,giveTime}
		receiveRecordList = {}, 						--收到记录{account,flowerType,giveTime}
		lastRefresh = 0,								--上一次刷新时间
		phy = 0,										--已获得体力
		sendCntList = {1,1,1},							--赠送次数列表
	}
	setmetatable(instance,{__index = _M})
	return instance
end
