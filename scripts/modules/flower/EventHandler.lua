module(...,package.seeall)

local Logic = require("modules.flower.FlowerLogic")
local Define = require("modules.flower.FlowerDefine")
local Msg = require("core.net.Msg")
local Arena = require("modules.arena.Arena")
local Config = require("config.FlowerConfig").Config
local Announce = require("modules.announce.Announce")
local AnnounceDefine = require("modules.announce.AnnounceDefine")
local PublicLogic = require("modules.public.PublicLogic")
local FlowerRank = require("modules.flower.FlowerRank")
local MailManager = require("modules.mail.MailManager")
local BagDefine = require("modules.bag.BagDefine")

function onCGFlowerGiveOpen(human, index, fromType)
	Logic.sendOpenMsg(human, index, fromType)
end

function onCGFlowerGive(human, index, fromType, flowerType, tipShow)
	if human:getLv() < Define.FLOWER_LIMIT_LV then
		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveFailNoLv, '')
	end
	human:getFlower().tipShow = tipShow
	local config = Config[flowerType]
	if config == nil then
		--鲜花类型错误
		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveFailNoFlowerType, '')
	end
	if human.db.vipLv < config.openNeed then
		--Vip等级不够
		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveFailVipNoLevel, '')
	end
	local hasEnoughCost,err = Logic.hasEnoughCost(human, flowerType)
	if hasEnoughCost == false then
		--钱不够
		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, err, '')
	end

	local player = Logic.getReceiver(index, fromType)
	if player == nil then
		--不存在该玩家
		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveFailNoPlayer, '')
	end

	local account = player.db.account
	if account == human:getAccount() then
		--不能给自己赠送
		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveFailNoSelf, '')
	end

	--是否赠送过
	if Logic.hasGiveThatAccount(human, account) == 1 then
		if flowerType == Define.FLOWER_TYPE_NINE_N then
			--无限送
			--扣钱
			Logic.decCost(human, flowerType)
			if player.db.flowerCount then
				player.db.flowerCount = player.db.flowerCount + config.flowerCount
				if HumanManager.getOnline(account) ~= nil then
					player:sendHumanInfo()
					Msg.SendMsg(PacketID.GC_FLOWER_GET, player)
				end
			end
			Announce.addAnnounceById(nil, AnnounceDefine.ANNOUNCE_FLOWER_ALL, human:getName(), player.db.name)

			--添加记录
			Logic.addSendRecord(human, account, flowerType)
			Logic.addReceiveRecord(player, human:getAccount(), flowerType)

			--刷新
			Logic.sendOpenMsg(human, index, fromType)

			--加入排行榜脏数据
			FlowerRank.addDirtyRecord(account)	

			human:sendHumanInfo()
			
			--加log
			local logTb = Log.getLogTb(LogId.FLOWER_SEND)
			logTb.name = human:getName()
			logTb.account = human:getAccount()
			logTb.pAccount = human:getPAccount()
			logTb.receiverName = player.db.name
			logTb.receiverAccount = account
			logTb.costName = '钻石'
			logTb.costNum = config.cost.rmb or 0
			logTb.leftCount = Logic.getLeftSendFlowerCount(human)
			logTb:save()

			local logTb = Log.getLogTb(LogId.FLOWER_RECEIVE)
			logTb.name = human:getName()
			logTb.account = human:getAccount()
			logTb.pAccount = human:getPAccount()
			logTb.senderName = human:getName()
			logTb.senderAccount = human:getAccount()
			logTb.flowerNum = config.flowerCount
			logTb:save()

			local msg = '向%s赠送%d朵鲜花'
			msg = string.format(msg, player.db.name, config.flowerCount)
			return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveSuccess, msg)
		else
			--只能送一次
			return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveFailNoGive, '')
		end
	else
		--对该玩家首次赠送
		--赠送者奖励
		Logic.decCost(human, flowerType)
		if player.db.flowerCount then
			player.db.flowerCount = player.db.flowerCount + config.flowerCount
		end

		if flowerType == Define.FLOWER_TYPE_NINE_N then
			Announce.addAnnounceById(nil, AnnounceDefine.ANNOUNCE_FLOWER_ALL, human:getName(), player.db.name)
		else
			if HumanManager.getOnline(account) ~= nil then
				Announce.addAnnounceById(player, AnnounceDefine.ANNOUNCE_FLOWER_PERSONAL, human:getName(), config.flowerCount)
			end
		end

		local msg = ''
		--判断是否还有奖励次数
		if Logic.getLeftSendFlowerCount(human) > 0 then
			local rewardList = PublicLogic.randReward(config.senderReward)
			local desc = PublicLogic.getRewardDes(rewardList)
			PublicLogic.doReward(human, rewardList, {}, CommonDefine.ITEM_TYPE.ADD_FLOWER_REWARD)

			--获赠者奖励,排除电脑数据
			if player.db.flowerCount then
				if player.db.flower.phy == nil then
					player.db.flower.phy = 0
				end
				if config.receiverReward > 0 and player.db.flower.phy < Define.FLOWER_PHY_MAX then
					local tb = {}
					local left = config.receiverReward
					if Define.FLOWER_PHY_MAX - player.db.flower.phy < left then
						left = Define.FLOWER_PHY_MAX - player.db.flower.phy
					end
					player.db.flower.phy = player.db.flower.phy + left
					table.insert(tb, {BagDefine.ITEM_PHY,left})
					MailManager.sysSendMailById(account, Define.FLOWER_MAIL_ID, tb, human:getName(), config.flowerCount)
				end
				if HumanManager.getOnline(account) ~= nil then
					player:sendHumanInfo()
					Msg.SendMsg(PacketID.GC_FLOWER_GET, player)
				end
			end

			--减少奖励次数
			Logic.decSendCount(human)

			msg = '向%s赠送%d朵鲜花!你获得%s'
			msg = string.format(msg, player.db.name, config.flowerCount, desc)
		else
			msg = '向%s赠送%d朵鲜花'
			msg = string.format(msg, player.db.name, config.flowerCount)
		end

		--添加记录
		Logic.addSendRecord(human, account, flowerType)
		Logic.addReceiveRecord(player, human:getAccount(), flowerType)

		--刷新
		Logic.sendOpenMsg(human, index, fromType)
		--加入排行榜脏数据
		FlowerRank.addDirtyRecord(account)	

		human:sendHumanInfo()

		local logTb = Log.getLogTb(LogId.FLOWER_SEND)
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.receiverName = player.db.name
		logTb.receiverAccount = account
		if config.cost.rmb then
			logTb.costName = '钻石'
			logTb.costNum = config.cost.rmb or 0
		elseif config.cost.money then
			logTb.costName = '金币'
			logTb.costNum = config.cost.money or 0
		end
		logTb.leftCount = Logic.getLeftSendFlowerCount(human)
		logTb:save()

		local logTb = Log.getLogTb(LogId.FLOWER_RECEIVE)
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.senderName = human:getName()
		logTb.senderAccount = human:getAccount()
		logTb.flowerNum = config.flowerCount
		logTb:save()

		return Msg.SendMsg(PacketID.GC_FLOWER_GIVE, human, Define.ERR_CODE.GiveSuccess, msg)
	end
end

function onCGFlowerPersonal(human)
	local db = human:getFlower()
	local sendRecordList = Logic.getPersonalGiveRecordList(human)
	local receiveRecordList = Logic.getPersonalReceiveRecordList(human)
	local sendCount = Logic.getLeftSendFlowerCount(human)
	return Msg.SendMsg(PacketID.GC_FLOWER_PERSONAL, human, sendCount, sendRecordList, receiveRecordList)
end
