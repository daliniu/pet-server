module(...,package.seeall)

local VipRechargeConfig = require("config.VipRechargeConfig").Config
local DB = require("modules.vip.VipDB")
local VipConfig = require("config.VipConfig").Config
local Define = require("modules.vip.VipDefine")
local Msg = require("core.net.Msg")
local DotLogic = require("modules.dot.DotLogic")
local DotDefine = require("modules.dot.DotDefine")

function onHumanDBLoad(hm, human)
	DB.resetMetatable(human)
end

function onHumanLogin(hm,human)
	local db = human:getVip()		
	if not Util.IsSameDate(db.nextUpdateTime, os.time()) then
		if human.db.vipLv > 0 then
			db:resetDailyGet(human.db.vipLv)
		end
		db.nextUpdateTime = os.time()
	end
	sendDotMsg(human)
end

function recharge(human, id)
	local config = VipRechargeConfig[id]
	if config ~= nil then
		local db = human.db.vip
		local vipLvBefore = human.db.vipLv
		local rmbSum = 0
		if hasRechargeThatId(human, id) == false then
			rmbSum = config.rmb + config.limitExtraRmb
		else
			rmbSum = config.rmb + config.extraRmb
		end
		if config.rechargeType == 3 then
		else
			human:incRmb(rmbSum, CommonDefine.RMB_TYPE.ADD_VIP)
		end

		local sid = tostring(id)
		if db.rechargeList[sid] == nil then
			db.rechargeList[sid] = 1
		else
			db.rechargeList[sid] = db.rechargeList[sid] + 1
		end

		doRecharge(human, config.cash)

		local logTb = Log.getLogTb(LogId.VIP_LV)
		logTb.channelId = human:getChannelId()
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.recharge = config.cash
		logTb.vipLvBefore = vipLvBefore
		logTb.vipLvAfter = human.db.vipLv
		logTb:save()

		Msg.SendMsg(PacketID.GC_VIP_RECHARGE, human, Define.ERR_CODE.RECHARGE_SUCCESS)
		return rmbSum
	else
		Msg.SendMsg(PacketID.GC_VIP_RECHARGE, human, Define.ERR_CODE.RECHARGE_FAIL)
		return 0
	end
end

function doRecharge(human, cash)
	local vipLvBefore = human.db.vipLv
	human:incRecharge(cash)
	refreshVipLv(human)
	if human.fd then
		human:sendHumanInfo()
	end
	HumanManager:dispatchEvent(HumanManager.Event_RechargeChange,{human=human,curCash=cash})

	if vipLvBefore ~= human.db.vipLv then
		for i=vipLvBefore+1,human.db.vipLv do
			human.db.vip.dailyInfo[i] = Define.VIP_DAILY_NO_GET
		end
		sendDotMsg(human)
	end
end

function sendDotMsg(human)
	local dailyInfo = human.db.vip.dailyInfo
	local hasDaily = false
	for _,v in pairs(dailyInfo) do
		if v == Define.VIP_DAILY_NO_GET then
			hasDaily = true
			break
		end
	end
	if hasDaily then
		DotLogic.sendSysDot(human, DotDefine.DOT_VIP_DAILY)
	end
end

function adminSetVipLv(human, vipLv)
	local cash = 0
	for _,config in ipairs(VipConfig) do
		if config.vipLv > human.db.vipLv and config.vipLv <= vipLv then
			cash = cash + config.needRmb
		end
	end
	if cash > 0 then
		doRecharge(human, cash)
	end
end

function refreshVipLv(human)
	local count = human.db.recharge
	local temp = count * Define.VIP_RECHARGE_EXP
	local vipLv = 0
	for _,config in ipairs(VipConfig) do
		if temp < config.needRmb * Define.VIP_RECHARGE_EXP then
			vipLv = config.vipLv - 1
			break
		end
		temp = temp - config.needRmb * Define.VIP_RECHARGE_EXP
		if config.vipLv == Define.VIP_MAX_LV and temp >=0 then
			vipLv = Define.VIP_MAX_LV
			break
		end
	end
	human.db.vipLv = vipLv
end

function getVipAddCount(human, type)
	local vipLv = human.db.vipLv
	local config = VipConfig[vipLv]
	return config[type]
end

function hasRechargeThatId(human, id)
	local db = human.db.vip
	local sid = tostring(id)
	local config = VipRechargeConfig[id]
	if config == nil or (db.rechargeList[sid] ~= nil and db.rechargeList[sid] >= config.limitCount) then
		return true
	end
	return false
end

function getRechargeList(human)
	local list = {}
	local db = human.db.vip
	for _,config in pairs(VipRechargeConfig) do
		if hasRechargeThatId(human, config.id) == false then
			table.insert(list, config.id)
		end
	end
	table.sort(list)
	return list
end
