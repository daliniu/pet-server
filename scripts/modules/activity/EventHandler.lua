module(...,package.seeall)

local Activity = require('modules.activity.Activity')
local Msg = require("core.net.Msg")
local def = require("modules.activity.ActivityDefine")
local PublicLogic = require("modules.public.PublicLogic")
local BagLogic = require("modules.bag.BagLogic")
local ActivityConfig = require("config.ActivityConfig").Config

function onCGActivityInfo(human,activityId)
	-- if not Activity.checkLv(human,activityId) then
		Msg.SendMsg(PacketID.RET_CLOSED,human,def.RET_CLOSED)
	-- end
	Activity.sendActivityInfo(human,activityId)
end

function onCGActivityReward(human,activityId,id)
	if not ActivityConfig[activityId] then
		Msg.SendMsg(PacketID.GC_ACTIVITY_REWARD,human,def.RET_NOTPERMITTED,activityId)
		return
	end
	if Activity.isActivityOpened(human,activityId) == false then
		Msg.SendMsg(PacketID.GC_ACTIVITY_REWARD,human,def.RET_CLOSED)
		return
	end
	if activityId == def.PHYSICS_ACT then
		local t = os.time()
		local ret ,pno = Activity.physicsReward(human)
		Msg.SendMsg(PacketID.GC_ACTIVITY_REWARD,human,ret,activityId,pno,def.STATUS_REWARDED)
	else
		local status = Activity.getActivityStatus(human,activityId,id)
		if status == def.STATUS_COMPLETED then
			Activity.setActivityStatus(human,activityId,id,def.STATUS_REWARDED)
			Activity.sendActivityInfo(human,activityId)
			Msg.SendMsg(PacketID.GC_ACTIVITY_REWARD,human,def.RET_OK,activityId,id)

			-- 给奖励
			local conf = require('config.'..def.ActivityDefineList[activityId].conf).Config
			if conf[id] and conf[id].reward then
				PublicLogic.doReward(human,conf[id].reward,nil,CommonDefine.ITEM_TYPE.ADD_ACTIVITY,CommonDefine.MONEY_TYPE.ADD_ACTIVITY,CommonDefine.RMB_TYPE.ADD_ACTIVITY)
				BagLogic.sendRewardTipsEx(human,conf[id].reward)
			end
		elseif status == def.STATUS_REWARDED then
			Msg.SendMsg(PacketID.GC_ACTIVITY_REWARD,human,def.RET_REWARDED,activityId)
		else
			Msg.SendMsg(PacketID.GC_ACTIVITY_REWARD,human,def.RET_NOTPERMITTED,activityId)
		end
	end
end

function onCGActivityTip(human)
end

function onCGActivityMonthcardbuy(human)
	-- Activity.buyMonthCard(human)
	-- Activity.sendMonthCardInfo(human)
	-- Msg.SendMsg(PacketID.GC_ACTIVITY_MONTHCARDBUY,human,def.RET_OK)
end

function onCGActivityMonthcardInfo(human)
	Activity.sendMonthCardInfo(human)
end

function onCGActivityFoundationBuy(human)
	if Activity.isActivityOpened(human,def.FOUNDATION_ACT) then
		Activity.buyFoundation(human)
	else
		Msg.SendMsg(PacketID.GC_ACTIVITY_FOUNDATION_BUY,human,def.RET_CLOSED)
	end
end


function onCGActivityVipBuy(human,id)
	Activity.buyVipGift(human,id)

end

function onCGActivityVip(human,id)
	Activity.sendVipGift(human,id)
end


function onCGWheelOpen(human)
	Msg.SendMsg(PacketID.GC_WHEEL_RET, human, Activity.wheelOpen(human)) 
end

function onCGWheelClose(human)
	Activity.wheelClose(human)
end

function onCGWheelQuery(human)
	Activity.sendWheelInfo(human)
end

function onCGActivityMonthcardReceive(human,monthCardId)
	Activity.receiveMonthCard(human,monthCardId)
end

function onCGActivityDb(human,actId)
	Activity.sendActDb(human,actId)
end

