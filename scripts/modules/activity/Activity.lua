module(...,package.seeall)

local ActivityConfig = require("config.ActivityConfig").Config
local LoginActivityConfig = require("config.LoginActivityConfig").Config
local LevelActivityConfig = require("config.LevelActivityConfig").Config
local TestDiamondActivityConfig = require("config.TestDiamondActivityConfig").Config
local TestHeroActivityConfig = require("config.TestHeroActivityConfig").Config
local MonthCardActivityConfig = require("config.MonthCardActivityConfig").Config
local SingleRechargeConfig = require("config.SingleRechargeActivityConfig").Config
local FoundationConfig = require("config.FoundationActivityConfig").Config
local WheelActivityConfig = require("config.WheelActivityConfig").Config
local def = require("modules.activity.ActivityDefine")
local Msg = require("core.net.Msg")
local Hm = require("core.managers.HumanManager")
local Util = require("core.utils.Util")
local PublicLogic = require("modules.public.PublicLogic")
local BagLogic = require("modules.bag.BagLogic")
local ShopDefine = require("modules.shop.ShopDefine")
local MailManager = require("modules.mail.MailManager")
local VipRechargeConfig = require("config.VipRechargeConfig").Config
local VipActivityConfig = require("config.VipActivityConfig").Config
local VipLogic = require("modules.vip.VipLogic")

local ns = "activity"
ActivityList = ActivityList or {}  --互动列表
ActivityDB = ActivityDB or {}
-- function loadActivityList()
-- 	for i,act in pairs(ActivityConfig) do
-- 		if act.type == 1 then
-- 			-- 时间格式 '20141001 08:00:00'
-- 			if  act.startTime and act.startTime ~= '' then
-- 				act.startTime = Util.getTimeByStr2(act.startTime)
-- 			end
-- 			if  act.endTime and act.endTime ~= '' then
-- 				act.endTime = Util.getTimeByStr2(act.endTime)
-- 			end
-- 		end
-- 		if act.type == 2 then
-- 			if  act.startTime and act.startTime ~= '' then
-- 				act.startTime = Util.getTimeByStr(act.startTime)
-- 			end
-- 			if  act.endTime and act.endTime ~= '' then
-- 				act.endTime = Util.getTimeByStr(act.endTime)
-- 			end
-- 		end
-- 	end
-- end

function getConfigById(activityId)
	if not def.ActivityDefineList[activityId] then return end
	local confName = def.ActivityDefineList[activityId].conf
	return require("config."..confName).Config
end

function checkActivity(human,activityId)
	local act = ActivityList[activityId]
	if act == nil then
		return def.RET_NOSUCHACTIVITY
	end
	-- 等级限制
	local lv = human:getLv()
	if lv < act.lv[1] or lv > act.v[2] then
		return def.RET_LEVEL
	end

	if act.stop and act.stop == true then
		-- 活动被强制终止
		return def.RET_CLOSED
	end

	-- 时间限制
	local t = os.time()

	if act.type == 1 then
		-- 限时活动
		if t < act.startTime or t > act.endTime  then
			return def.RET_CLOSED
		end
	end
	if act.type == 2 then
		-- 周期活动
		local ti = os.time() - Util.GetTodayTime()
		if ti < act.startTime or ti > act.endTime then
			return def.RET_CLOSED
		end
	end
	return true
end

function getActivity(human,aid)
	local adb = human.db.Activity
	local act = adb.actList[aid]
	local info = {}

	if act then
		if aid == def.PHYSICS_ACT then
			for i,_ in ipairs(def.PHYSICS_PERIODS) do
				local lastTime = 0
				if act[1] and act[1][tostring(i)] then
					lastTime = act[1][tostring(i)]
				end
				if Util.isToday(lastTime) then
					table.insert(info,{status=def.STATUS_REWARDED})
				else
					table.insert(info,{status=def.STATUS_NOTCOMPLETED})
				end
			end
		else
			for i,a in ipairs(act) do
				if aid == def.FOUNDATION_ACT and adb.foundationBought ~= 1 then
					a.status =def.STATUS_NOTCOMPLETED
				end
				table.insert(info,{status=a.status})
			end
		end
	end
	return info
end

-- function getActivityInfo(human)
-- 	local adb = human.db.Activity
-- 	local actInfo = {}
-- 	for id,a in ipairs(def.ActivityDefineList) do
-- 		actInfo[id] = getActivity(human,id)
-- 	end
-- 	return actInfo
-- end

function sendActivityInfo(human,activityId)
	if activityId == 0 then
		for aid,a in pairs(def.ActivityDefineList) do
			if aid == def.LEVEL_ACT then
				for id,_ in ipairs(LevelActivityConfig) do
					getActivityStatus(human,aid,id)
				end
			end
			local info = getActivity(human,aid)
			Msg.SendMsg(PacketID.GC_ACTIVITY_INFO,human,def.RET_OK,aid,info)
		end
	else

		local info = getActivity(human,activityId)
		Msg.SendMsg(PacketID.GC_ACTIVITY_INFO,human,def.RET_OK,activityId,info)
	end
end

function physicsReward(human)
	local t = os.time()
	local pno = 0
	for i,p in ipairs(def.PHYSICS_PERIODS) do
		if Util.getTimeByStr(p.stime) <= t and Util.getTimeByStr(p.etime) >= t then
			pno = i
			break
		end
	end
	local adb = human.db.Activity
	if pno == 0 then
		return def.RET_NOINTIME,pno
	else
		if adb.actList[def.PHYSICS_ACT] == nil then adb.actList[def.PHYSICS_ACT] = {} end
		local lastTime
		if adb.actList[def.PHYSICS_ACT][1] == nil then
			lastTime = 0
			adb.actList[def.PHYSICS_ACT][1] = {}
		else
			lastTime = adb.actList[def.PHYSICS_ACT][1][tostring(pno)] or 0
		end

		if not Util.isToday(lastTime) then
			adb.actList[def.PHYSICS_ACT][1][tostring(pno)] = t
			-- 给奖励
			local conf = require('config.'..def.ActivityDefineList[def.PHYSICS_ACT].conf).Config
			local reward = Util.deepCopy(conf[pno].reward)
			local randvalue = math.random(100)
			local rand = 0
			for i,r in ipairs(conf[pno].randReward) do
				rand =rand + r[2]
				if rand >= randvalue then
					reward[r[3]] = r[1] + (reward[r[3]] or 0)
					break
				end
			end
			PublicLogic.doReward(human,reward,nil,CommonDefine.ITEM_TYPE.ADD_ACTIVITY,CommonDefine.MONEY_TYPE.ADD_ACTIVITY,CommonDefine.RMB_TYPE.ADD_ACTIVITY)
			BagLogic.sendRewardTipsEx(human,reward)
			return def.RET_OK,pno
		else
			return def.RET_REWARDED,pno
		end
	end
end
	
	

function setActivityStatus(human,activityId,id,status)
	local adb = human.db.Activity
	-- if not def.ActivityDefineList[activityId] then
	-- 	return def.RET_NOTPERMITTED
	-- end
	if not adb.actList[activityId] then
		adb.actList[activityId] = {}
	end
	for i=1,id do 
		if not adb.actList[activityId][i] then
			adb.actList[activityId][i] = {}
		end
	end
	adb.actList[activityId][id].status = status
end

function getActivityStatus(human,activityId,id)
	local adb = human.db.Activity
	local status
	if not adb.actList[activityId] or not adb.actList[activityId][id] or not adb.actList[activityId][id].status then
		status = def.STATUS_NOTCOMPLETED
	else
		status = adb.actList[activityId][id].status
	end

	if status == def.STATUS_REWARDED then
		return def.STATUS_REWARDED
	end

	if activityId == def.FOUNDATION_ACT then
		if adb.foundationBought ~= 1 then
			--未购买开服基金
			return def.STATUS_NOTCOMPLETED
		else
			local cfg = FoundationConfig[id]
			if cfg then
				if human:getLv() < cfg.lv then
					return def.STATUS_NOTCOMPLETED
				else
					setActivityStatus(human,activityId,id,def.STATUS_COMPLETED)
					return def.STATUS_COMPLETED
				end
			end

		end
	elseif activityId == def.FIRSTCHARGE_ACT then
		if human:getRecharge() > 0 then
			setActivityStatus(human,activityId,1,def.STATUS_COMPLETED)
			return def.STATUS_COMPLETED
		else
			return def.STATUS_NOTCOMPLETED
		end
	elseif activityId == def.LEVEL_ACT then
		local cfg = LevelActivityConfig[id]
		if cfg then
			if human:getLv() < cfg.lv then
				return def.STATUS_NOTCOMPLETED
			else
				setActivityStatus(human,activityId,id,def.STATUS_COMPLETED)
				return def.STATUS_COMPLETED
			end
		end
	end
	return status
end

function sendActivityTip(human,activityId,id)
	Msg.SendMsg(PacketID.GC_ACTIVITY_TIP,human,activityId,id)
end

function init()
	loadActivityDB()
	-- 服务器初始化时执行
	-- loadActivityList()
end
-- function onAskMail(hm,event)
-- 	local human = event.human
-- 	monthCardEmail(human)
-- 	sendMonthCardInfo(human)
-- end

function onHumanLogin(hm,human)
	local adb = human.db.Activity
	if not adb.actList then 
		adb.actList = {} 
	end
	for aid,_ in ipairs(ActivityConfig) do
		if adb.actList[aid] == nil then
			adb.actList[aid] = {}
		end
	end
	
	if not adb.loginDays then
		adb.loginDays = 0 
		adb.lastLoginTime = 0
	end
	if not Util.isToday(adb.lastLoginTime) then
		adb.loginDays = adb.loginDays + 1
		adb.lastLoginTime = os.time()
	end
	for id,a in ipairs(LoginActivityConfig) do
		if not adb.actList[def.DAY_ACT] then
			adb.actList[def.DAY_ACT] = {}
		end
		-- if not adb[def.DAY_ACT][id] then
		-- 	adb[def.DAY_ACT][id] = def.STATUS_NOTCOMPLETED
		-- end
		if a.day == adb.loginDays then
			local status = getActivityStatus(human,def.DAY_ACT,id)
			if status == def.STATUS_NOTCOMPLETED then
				setActivityStatus(human,def.DAY_ACT,id,def.STATUS_COMPLETED)
			end
			sendActivityTip(human,def.DAY_ACT,id)
			break
		end
	end
	
	
	-- 首测登陆送钻石
	-- if ActivityConfig[def.TESTDIAMOND_ACT].opened == 1 then
	if isActivityOpened(human,def.TESTDIAMOND_ACT) then
		for id,a in ipairs(TestDiamondActivityConfig) do
			if not adb.actList[def.TESTDIAMOND_ACT] then
				adb.actList[def.TESTDIAMOND_ACT] = {}
			end
			if a.day == adb.loginDays then
				local status = getActivityStatus(human,def.TESTDIAMOND_ACT,id)
				if status == def.STATUS_NOTCOMPLETED then
					local reward = TestDiamondActivityConfig[id].reward
					local title = '第'..a.day..'天登陆钻石奖励'
					local content = '带你装B带你飞！这是给大爷您第'..a.day..'日的登陆工资'
					local rewardList = mailRewardList(reward)
					if #rewardList > 0 then
						MailManager.sysSendMail(human:getAccount(),title,content,rewardList)
					end
					setActivityStatus(human,def.TESTDIAMOND_ACT,id,def.STATUS_COMPLETED)
				end
				break
			end
		end
	end

	-- 首测第二天登陆送三星八神活动
	-- 20150415  取消这个活动
	if ActivityConfig[def.TESTHERO_ACT].opened == 1 then
		for id,a in ipairs(TestHeroActivityConfig) do
			if not adb.actList[def.TESTHERO_ACT] then
				adb.actList[def.TESTHERO_ACT] = {}
			end
			if a.day == adb.loginDays then
				local status = getActivityStatus(human,def.TESTHERO_ACT,id)
				if status == def.STATUS_NOTCOMPLETED then
					local reward = TestHeroActivityConfig[id].reward
					local title = '第二天登陆送你三星八神'
					local content = '全世界最具人气的八神今天就免费送给你啦！'
					local rewardList = mailRewardList(reward)
					if #rewardList > 0 then
						MailManager.sysSendMail(human:getAccount(),title,content,rewardList)
					end
					setActivityStatus(human,def.TESTHERO_ACT,id,def.STATUS_COMPLETED)
				end
				break
			end
		end
	end

	-- 首测登陆就送vip5
	-- 20150415  取消这个活动
	if ActivityConfig[def.TESTVIP_ACT].opened == 1 then
		if human.db.vipLv < 5 then
			-- human.db.vipLv = 5
			VipLogic.adminSetVipLv(human,5)
		end
	end

	-- 月卡
	-- monthCardEmail(human)
	sendMonthCardInfo(human)



	sendActivityInfo(human,0)
	sendFoundation(human)
	sendVipGift(human)
	sendActDb(human)

end

function mailRewardList(r)
	local rr = {}
	for itemId,cnt in pairs(r) do
		table.insert(rr,{itemId,cnt})
	end
	return rr
end

function onHumanLvUp(hm,event)
	local human = event.human
	if not human.db.Activity.actList then 
		human.db.Activity.actList = {} 
	end
	local adb = human.db.Activity
	for id,a in ipairs(LevelActivityConfig) do
		if not adb.actList[def.LEVEL_ACT] then
			adb.actList[def.LEVEL_ACT] = {}
		end
		if getActivityStatus(human,def.LEVEL_ACT,id) == def.STATUS_NOTCOMPLETED and a.lv <= human:getLv() then
			setActivityStatus(human,def.LEVEL_ACT,id,def.STATUS_COMPLETED)
			-- sendActivityInfoActivityTip(human,def.LEVEL_ACT,id)
		end
	end
	for id,a in ipairs(FoundationConfig) do
		if not adb.actList[def.FOUNDATION_ACT] then
			adb.actList[def.FOUNDATION_ACT] = {}
		end
		if getActivityStatus(human,def.FOUNDATION_ACT,id) == def.STATUS_NOTCOMPLETED and a.lv <= human:getLv() then
			setActivityStatus(human,def.FOUNDATION_ACT,id,def.STATUS_COMPLETED)
			-- sendActivityInfoActivityTip(human,def.LEVEL_ACT,id)
		end
	end
	sendActivityInfo(human,def.LEVEL_ACT)
	sendActivityInfo(human,def.FOUNDATION_ACT)
end

function onHumanRecharge(hm,event)
	local human = event.human
	if not human.db.Activity.actList then 
		human.db.Activity.actList = {} 
	end
	local adb = human.db.Activity
	if not adb.actList[def.FIRSTCHARGE_ACT] then
		adb.actList[def.FIRSTCHARGE_ACT] = {}
	end
	if getActivityStatus(human,def.FIRSTCHARGE_ACT,1) == def.STATUS_NOTCOMPLETED then
		setActivityStatus(human,def.FIRSTCHARGE_ACT,1,def.STATUS_COMPLETED)
		sendActivityTip(human,def.FIRSTCHARGE_ACT,1)
	end
	sendActivityInfo(human,def.FIRSTCHARGE_ACT)

	singleRecharge(human,event.curCash)
end


function singleRecharge(human,cash)
	-- 单笔充值活动
	local now = os.time()
	if isActivityOpened(human,def.SINGLERECHARGE_ACT) then
		for id,cfg in ipairs(SingleRechargeConfig) do
			local status = getActivityStatus(human,def.SINGLERECHARGE_ACT,id)
			if status == def.STATUS_NOTCOMPLETED and cash >= cfg.min and cash <= cfg.max then
				setActivityStatus(human,def.SINGLERECHARGE_ACT,id,def.STATUS_COMPLETED)
				sendActivityInfo(human,def.SINGLERECHARGE_ACT)
				break
			end
		end
	end
end


function monthCardReward(human,id)
	local adb = human.db.Activity
	local monthCardId = def.MONTHCARD_RECHARGE_ID[id]
	local cfg = VipRechargeConfig[monthCardId]
	if cfg then
		local now = os.time()
		local rmb = cfg.dayRmb
		local reward = {[9901002]=rmb}
		PublicLogic.doReward(human,reward,nil,CommonDefine.ITEM_TYPE.ADD_ACTIVITY,CommonDefine.MONEY_TYPE.ADD_ACTIVITY,CommonDefine.RMB_TYPE.ADD_ACTIVITY)
		BagLogic.sendRewardTipsEx(human,reward)
		adb.monthCardInfo[id].lastReceiveTime = Util.GetTodayTime() + 24*3600
	end	
end

function sendFoundation(human)
	local adb = human.db.Activity
	Msg.SendMsg(PacketID.GC_ACTIVITY_FOUNDATION_BUY,human,def.RET_OK,adb.foundationBought)
end

function buyFoundation(human)
	local adb = human.db.Activity
	if adb.foundationBought and adb.foundationBought == 1 then
		Msg.SendMsg(PacketID.GC_ACTIVITY_FOUNDATION_BUY,human,def.RET_REPEAT)
		return
	end
	local rmb = ActivityConfig[def.FOUNDATION_ACT].args.fundInvest 
	if human:getRmb() < rmb then
		Msg.SendMsg(PacketID.GC_ACTIVITY_FOUNDATION_BUY,human,def.RET_RMB)
		return
	end
	if human.db.vipLv < ActivityConfig[def.FOUNDATION_ACT].args.fundVipLv then
		Msg.SendMsg(PacketID.GC_ACTIVITY_FOUNDATION_BUY,human,def.RET_LEVEL)
		return
	end
	human:decRmb(rmb,nil,CommonDefine.RMB_TYPE.DEC_ACTIVITY_FOUNDATION)
	adb.foundationBought = 1
	human:sendHumanInfo()
	for id,a in ipairs(FoundationConfig) do
		if not adb.actList[def.FOUNDATION_ACT] then
			adb.actList[def.FOUNDATION_ACT] = {}
		end
		if getActivityStatus(human,def.FOUNDATION_ACT,id) == def.STATUS_NOTCOMPLETED and a.lv <= human:getLv() then
			setActivityStatus(human,def.FOUNDATION_ACT,id,def.STATUS_COMPLETED)
			-- sendActivityInfoActivityTip(human,def.LEVEL_ACT,id)
		end
	end

	sendActivityInfo(human,def.FOUNDATION_ACT)
	
	sendFoundation(human)
end

function buyMonthCard(human,cfg)
	-- 需要充值
	local monthCardId = 1
	if cfg.name == "月卡2" then 
		monthCardId = 2
	end
	local adb = human.db.Activity
	if adb.monthCardInfo == nil then adb.monthCardInfo = {{lastReceiveTime=0,monthCardEndDay=0},{lastReceiveTime=0,monthCardEndDay=0}} end
	-- if adb.monthCardInfo[monthCardId] and  adb.monthCardInfo[monthCardId].monthCardRewardDay and adb.monthCardInfo[monthCardId].monthCardRewardDay >= adb.monthCardInfo[monthCardId].monthCardEndDay then
	-- 	adb.monthCardInfo[monthCardId].monthCardRewardDay = nil
	-- end
	local now = os.time()
	local beginToday = Util.GetTodayTime()
	if adb.monthCardInfo[monthCardId] and adb.monthCardInfo[monthCardId].monthCardEndDay and adb.monthCardInfo[monthCardId].monthCardEndDay > 0 and adb.monthCardInfo[monthCardId].monthCardEndDay >= adb.monthCardInfo[monthCardId].lastReceiveTime then
		--原来的月卡没到期，延长
		adb.monthCardInfo[monthCardId].monthCardEndDay = adb.monthCardInfo[monthCardId].monthCardEndDay + 24*3600*def.MONTHCARD_DAYS
	else
		adb.monthCardInfo[monthCardId].monthCardEndDay = beginToday + 24*3600*def.MONTHCARD_DAYS
		adb.monthCardInfo[monthCardId].lastReceiveTime = Util.GetTodayTime()
	end
	
	-- if adb.monthCardInfo[monthCardId].monthCardRewardDay == nil then
	-- 	adb.monthCardInfo[monthCardId].monthCardRewardDay = beginToday
	-- end

	-- 赠送钻石
	-- local cfg = VipRechargeConfig[def.MONTHCARD_RECHARGE_ID]
	-- if cfg then
	-- 	human:incRecharge(cfg.cash)
	-- 	human:incRmb(cfg.rmb,CommonDefine.RMB_TYPE.ADD_ACTIVITY_MONTHCARD)
	-- end
	if human.fd then
		sendMonthCardInfo(human,1)
		-- HumanManager:dispatchEvent(HumanManager.Event_RechargeChange,{human=human,curCash=cfg.cash})
	end
	return cfg.rmb
end
function receiveMonthCard(human,monthCardId)
	local now = Util.GetTodayTime()
	local adb = human.db.Activity
	if adb.monthCardInfo == nil then adb.monthCardInfo = {{monthCardEndDay=0,lastReceiveTime=0},{monthCardEndDay=0,lastReceiveTime=0}} end
	local info = adb.monthCardInfo[monthCardId]
	if info then
		if info.monthCardEndDay < now then
			Msg.SendMsg(PacketID.GC_ACTIVITY_MONTHCARD_RECEIVE,human,def.RET_CLOSED,monthCardId)
			return
		end
		if info.lastReceiveTime > Util.GetTodayTime() then
			Msg.SendMsg(PacketID.GC_ACTIVITY_MONTHCARD_RECEIVE,human,def.RET_REPEAT,monthCardId)
			return
		end
		if info.lastReceiveTime > info.monthCardEndDay then
			Msg.SendMsg(PacketID.GC_ACTIVITY_MONTHCARD_RECEIVE,human,def.RET_CLOSED,monthCardId)
			return
		end
		monthCardReward(human,monthCardId)
		Msg.SendMsg(PacketID.GC_ACTIVITY_MONTHCARD_RECEIVE,human,def.RET_OK,monthCardId)
		sendMonthCardInfo(human)
		return
	end

end
function sendMonthCardInfo(human,newBuy)
	local adb = human.db.Activity
	if adb.monthCardInfo == nil then adb.monthCardInfo = {{lastReceiveTime=0,monthCardEndDay=0},{lastReceiveTime=0,monthCardEndDay=0}} end
	Msg.SendMsg(PacketID.GC_ACTIVITY_MONTHCARD_INFO,human,adb.monthCardInfo,newBuy)
	human:sendHumanInfo()
end
function buyVipGift(human,id)
	local cfg = VipActivityConfig[id]
	local adb = human.db.Activity
	if cfg then
		if human.db.vipLv < cfg.vipLv then
			Msg.SendMsg(PacketID.GC_ACTIVITY_VIP_BUY,human,id,def.RET_LEVEL)
			return
		end
		if human:getRmb() < cfg.price then
			Msg.SendMsg(PacketID.GC_ACTIVITY_VIP_BUY,human,id,def.RET_RMB)
			return
		end
		if adb.vipGift == nil then
			adb.vipGift = {}
		end
		local vipName = 'vip'..cfg.vipLv
		if adb.vipGift[vipName] and adb.vipGift[vipName] == 1 then
			Msg.SendMsg(PacketID.GC_ACTIVITY_VIP_BUY,human,id,def.RET_REPEAT)
			return
		end
		adb.vipGift[vipName] = 1
		human:decRmb(cfg.price,nil,CommonDefine.RMB_TYPE.DEC_ACTIVITY_VIPGIFT)
		PublicLogic.doReward(human,cfg.reward,nil,CommonDefine.ITEM_TYPE.ADD_ACTIVITY,CommonDefine.MONEY_TYPE.ADD_ACTIVITY,CommonDefine.RMB_TYPE.ADD_ACTIVITY)
		BagLogic.sendRewardTipsEx(human,cfg.reward)
		sendVipGift(human,id)
		Msg.SendMsg(PacketID.GC_ACTIVITY_VIP_BUY,human,id,def.RET_OK)
	end
end

function getVipGift(human,id)
	local adb = human.db.Activity
	if adb.vipGift and adb.vipGift['vip'..id] and adb.vipGift['vip'..id] == 1 then
		return 1
	else
		return 0
	end
end

function sendVipGift(human,id)
	if id == nil then
		for _,cfg in ipairs(VipActivityConfig) do
			sendVipGift(human,cfg.id)
		end
	else
		local status = getVipGift(human,id)
		Msg.SendMsg(PacketID.GC_ACTIVITY_VIP,human,id,status)
	end
end

function isActivityOpened(human,activityId)
	local cfg = ActivityDB[activityId]
	if cfg == nil or next(cfg) == nil or cfg.type == nil or cfg.type == 0 then
		cfg = ActivityConfig[activityId]
	end

	if cfg.opened == 2 then
		return false
	end

	-- 等级限制
	local lv = human:getLv()
	if cfg.minLv and cfg.minLv ~= 0 and lv < cfg.minLv then
		return false
	end
	if cfg.maxLv and cfg.maxLv ~= 0 and lv > cfg.maxLv then
		return false
	end

	--　时间限制
	local now = os.time()
	if cfg.type == 1 then
		return true
	elseif cfg.type == 2 then
		local stime,stimeTable = Util.getTimeByString(cfg.startTime)
		local etime,etimeTable = Util.getTimeByString(cfg.endTime)
		if now < stime or now > etime then
			return false
		end
	elseif cfg.type == 3 then
		if now >= human.db.createDate +cfg.openDay*24*3600 then
			return false
		end
	elseif cfg.type == 4 then
		if now - Config.newServerTime > cfg.openDay*24*3600 then
			return false
		end
	else
		return false
	end
	return true
end

function wheelOpen(human)
	if human:getRmb() < 50 then
		return 0 -- 钻石不够 
	end


--[[
	local cfg = ActivityConfig[def.WHEEL_ACT]
	print("stime ==> ",cfg.name, cfg.startTime .. "+", cfg.endTime .. "+")
	for k, v in pairs(cfg) do
		print(k, v)
	end
	local stime,stimeTable = Util.getTimeByString(ActivityConfig[def.WHEEL_ACT].startTime)
	local etime,etimeTable = Util.getTimeByString(ActivityConfig[def.WHEEL_ACT].endTime)
	local now = os.time()
	if now < stime or now > etime then 
		return -1 -- 活动已经结束
	end
]]
	if human._wheelId then
		return human._wheelId 
	end
	local id = 1
	local rate = math.random(1, 10000)
	for k, v in ipairs(WheelActivityConfig) do 
		rate = rate - v.rate
		if rate < 0 then
			id = k
			break 
		end
	end
	human._wheelId = id 
	return id 
end

wheelInfo = wheelInfo or {}
function wheelClose(human)
	local id = wheelOpen(human)
	human._wheelId = nil
	if id > 0 then
		human:decRmb(50,nil,CommonDefine.RMB_TYPE.DEC_ACTIVITY_WHEEL)
		human:sendHumanInfo()
		-- 给奖励
		local cfg = WheelActivityConfig[id]
		if cfg then
			PublicLogic.doReward(human, cfg.reward,nil,CommonDefine.ITEM_TYPE.ADD_ACTIVITY,CommonDefine.MONEY_TYPE.ADD_ACTIVITY,CommonDefine.RMB_TYPE.ADD_ACTIVITY)
			BagLogic.sendRewardTipsEx(human,cfg.reward)
		end

		if cfg.rare == 1 then
			if #wheelInfo >= 6 then
				table.remove(wheelInfo, 1)
			end
			table.insert(wheelInfo, {cname = human:getName(), id = id})
			sendWheelInfo(human)
		end
	end
end

function sendWheelInfo(human)
	Msg.SendMsg(PacketID.GC_WHEEL_INFO,human, wheelInfo)
end

function loadActivityDB()
	local function loadActDB(actId)
		local actDb = {}
		local query = {actId=actId}
	    local pCursor = g_oMongoDB:SyncFind(ns,query)
	    if not pCursor then
	        return false
	    end
    	local Cursor = MongoDBCursor(pCursor)
		local row = {}
	    if not Cursor:Next(row) then
			g_oMongoDB:SyncInsert(ns,{actId=actId,db={}})
		else
			actDb = row.db
	    end
	    return actDb
	end
	for actId,_ in pairs(def.ActivityDefineList) do
		local actDb = loadActDB(actId)
		ActivityDB[actId] = actDb
	end
	return true
end

function save(isSync)
	saveActivityDB(isSync)
end
function saveActivityDB(isSync)
	for actId,_ in pairs(def.ActivityDefineList) do
		local query = {actId=actId}
		DB.Update(ns,query,{actId=actId,db=ActivityDB[actId]},isSync)
	end
end
function getActivityDB(activityId)
	return ActivityDB[activityId]
end

function setActivityDB(activityId,actDb)
	for i,item in ipairs(def.ActivityDBDefine) do
		if actDb[item] and actDb[item] ~= 0 and actDb[item] ~= "" then
			ActivityDB[activityId][item] = actDb[item]
		end
	end
end

function sendActDb(human,actId)
	if actId ==nil or actId == 0 then
		for actId,_ in pairs(def.ActivityDefineList) do
			sendActDb(human,actId)
		end
	else
		local actDb = ActivityDB[actId]
		if actDb and actDb.type and actDb.type ~= 0 then
			Msg.SendMsg(PacketID.GC_ACTIVITY_DB,human,actId,actDb)
		end
	end
end

Hm:addEventListener(Hm.Event_HumanLogin,onHumanLogin)
Hm:addEventListener(Hm.Event_HumanLvUp,onHumanLvUp)
Hm:addEventListener(Hm.Event_RechargeChange,onHumanRecharge)
-- Hm:addEventListener(Hm.Event_AskMail,onAskMail)


