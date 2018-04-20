module(...,package.seeall)

local VipLogic = require("modules.vip.VipLogic")
local Define = require("modules.vip.VipDefine")
local VipConfig = require("config.VipConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local Msg = require("core.net.Msg")
local VipRechargeConfig = require("config.VipRechargeConfig").Config
local HumanManager = require("core.managers.HumanManager")
local VipLevelConfig = require("config.VipLevelConfig").Config
local VipLevelLogic = require("modules.vip.VipLevelLogic")
local PublicLogic = require("modules.public.PublicLogic")
function onCGVipRecharge(human, id)
	--VipLogic.recharge(human, id)
end

function onCGVipBuyGift(human, vipLv)
	if vipLv > 0 and human.db.vipLv >= vipLv then
		if human.db.vip:hasGiftBuy(vipLv) == false then
			local config = VipConfig[vipLv]
			if human:getRmb() >= config.newPrice then
				--扣钱
				human:decRmb(config.newPrice, nil, CommonDefine.RMB_TYPE.DEC_VIP_GIFT)
				human:sendHumanInfo()
				--发礼包
				for _,item in ipairs(config.gift) do
					BagLogic.addItem(human, item[1], item[2], true, CommonDefine.ITEM_TYPE.ADD_VIP_GIFT)
				end
				--标记领取
				human.db.vip:setGiftBuy(vipLv)

				return Msg.SendMsg(PacketID.GC_VIP_BUY_GIFT, human, Define.ERR_CODE.BUY_SUCCESS, vipLv)
			else
				--钱不够
				return Msg.SendMsg(PacketID.GC_VIP_BUY_GIFT, human, Define.ERR_CODE.BUY_NO_MONEY, vipLv)
			end
		else
			--购买过了
			return Msg.SendMsg(PacketID.GC_VIP_BUY_GIFT, human, Define.ERR_CODE.BUY_GET, vipLv)
		end
	else
		--未达到vip等级
		return Msg.SendMsg(PacketID.GC_VIP_BUY_GIFT, human, Define.ERR_CODE.BUY_FAIL, vipLv)
	end
end

function onCGVipCheck(human)
	local giftList = human.db.vip:getGiftBuyList()
	local recharge = human:getRecharge()
	local rechargeList = VipLogic.getRechargeList(human)
	local db = human:getVip()
	return Msg.SendMsg(PacketID.GC_VIP_CHECK, human, recharge * 100, rechargeList, giftList, db.dailyInfo)
end

function onCGVipGetDaily(human, vipLv)
	local vipConfig = VipConfig[vipLv]
	local db = human:getVip()
	if vipConfig and db:hasGetDailyGift(vipLv) == false then
		BagLogic.addItem(human, vipConfig.dailyGift, 1, true, CommonDefine.ITEM_TYPE.ADD_VIP_GIFT)
		db:setDailyGet(vipLv)
		VipLogic.sendDotMsg(human)
		return Msg.SendMsg(PacketID.GC_VIP_GET_DAILY, human, Define.ERR_CODE.DAILY_SUCCESS, vipLv)
	else
		return Msg.SendMsg(PacketID.GC_VIP_GET_DAILY, human, Define.ERR_CODE.DAILY_FAIL, vipLv)
	end
end

function onCGVipLevelStart(human,levelId,heroes)
	local vipDb = human:getVip()
	if VipLevelConfig[levelId] == nil then
		Msg.SendMsg(PacketID.GC_VIP_LEVEL_START,human,Define.ERR_CODE.NOTPERMITTED,levelId)
		return
	end
	if VipLevelLogic.getVipLevelTimes(human) > Define.VIP_LEVEL_TIMES then
		Msg.SendMsg(PacketID.GC_VIP_LEVEL_START,human,Define.ERR_CODE.LIMIT,levelId)
		return
	end

	Msg.SendMsg(PacketID.GC_VIP_LEVEL_START,human,Define.ERR_CODE.OK,levelId)


end

function onCGVipLevelEnd(human,levelId,result,heroes)
	local vipDb = human:getVip()
	local cfg = VipLevelConfig[levelId]
	if cfg == nil then
		Msg.SendMsg(PacketID.GC_VIP_LEVEL_END,human,Define.ERR_CODE.NOTPERMITTED,levelId)
		return
	end
	if VipLevelLogic.getVipLevelTimes(human) > Define.VIP_LEVEL_TIMES then
		Msg.SendMsg(PacketID.GC_VIP_LEVEL_END,human,Define.ERR_CODE.LIMIT,levelId)
		return
	end
	local t = os.time()
	local function addReward(rtb,reward)
		for n,r in pairs(reward) do 
			if rtb[n] == nil then rtb[n] = 0 end
			rtb[n] = rtb[n] + r
		end
	end
	VipLevelLogic.addVipLevelTimes(human,t)
	if result == Define.WIN then
		local rtb = {}
		addReward(rtb,cfg.fixReward)
		local randReward = PublicLogic.randReward(cfg.randReward)
		addReward(rtb,randReward)
		local reward = {}
		for itemId,cnt in pairs(rtb) do 
			table.insert(reward,{rewardName=tostring(itemId),cnt=cnt})
		end
		PublicLogic.doReward(human,rtb,{},CommonDefine.ITEM_TYPE.ADD_VIPLEVEL_REWARD)
		Msg.SendMsg(PacketID.GC_VIP_LEVEL_END,human,Define.ERR_CODE.OK,levelId,Define.WIN,reward,heroes)
	else
		Msg.SendMsg(PacketID.GC_VIP_LEVEL_END,human,Define.ERR_CODE.OK,levelId,Define.DEFEATED)
	end
	VipLevelLogic.sendVipLevelInfo(human)
end

function onCGVipLevelInfo(human)

end