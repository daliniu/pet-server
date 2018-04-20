module(...,package.seeall)

local VipRechargeConfig = require("config.VipRechargeConfig").Config
local DB = require("modules.vip.VipDB")
local VipConfig = require("config.VipConfig").Config
local Define = require("modules.vip.VipDefine")
local Msg = require("core.net.Msg")
local DotLogic = require("modules.dot.DotLogic")
local DotDefine = require("modules.dot.DotDefine")

-- function onHumanDBLoad(hm, human)
-- 	DB.resetMetatable(human)
-- end

function onHumanLogin(hm,human)
	sendVipLevelInfo(human)
end


function getVipLevelTimes(human)
	local vipDb = human:getVip()
	if vipDb.lastVipLevel == nil then vipDb.lastVipLevel = 0 end
	if Util.isToday(vipDb.lastVipLevel) then
		return vipDb.levelTimes
	else
		return 0
	end
end

function addVipLevelTimes(human,t)
	local vipDb = human:getVip()
	if vipDb.lastVipLevel == nil then vipDb.lastVipLevel = 0 end
	if Util.isToday(vipDb.lastVipLevel) then
		vipDb.levelTimes = vipDb.levelTimes + 1
	else
		vipDb.levelTimes = 1
	end
	vipDb.lastVipLevel = t
end

function deleteVipLevelTimes(human)
	local times = getVipLevelTimes(human)
	if times > 0 then
		local vipDb = human:getVip()
		vipDb.levelTimes = times - 1
	end
	sendVipLevelInfo(human)
end

function sendVipLevelInfo(human)
	local fightTimes = getVipLevelTimes(human)
	Msg.SendMsg(PacketID.GC_VIP_LEVEL_INFO,human,Define.ERR_CODE.OK, fightTimes)
end