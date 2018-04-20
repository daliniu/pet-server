module(...,package.seeall)

local Arena = require("modules.arena.Arena")
local Define = require("modules.flower.FlowerDefine")
local WorldBossLogic = require("modules.worldBoss.WorldBossLogic")
local CrazyLogic = require("modules.crazy.CrazyLogic")
local Msg = require("core.net.Msg")
local FlowerRank = require("modules.flower.FlowerRank")
local TrialRank = require("modules.trial.TrialRank")
local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")
--local FlowerDB = require("modules.flower.FlowerDB")
local Config = require("config.FlowerConfig").Config
local Hm = require("core.managers.HumanManager")

function init()
	--Hm:addEventListener(Hm.Event_HumanDBLoad, FlowerDB.resetMeta)
	Hm:addEventListener(Hm.Event_HumanLogin, onHumanLogin)
end

function onHumanLogin(hm,human)
	resetDayRecord(human)
end

function resetDayRecord(human)
	local db = human:getFlower()		
	if not Util.IsSameDate(db.lastRefresh, os.time()) then
		human:getFlower().lastRefresh = os.time()
		human:getFlower().sendCount = 0
		human:getFlower().tipShow = 0
		human:getFlower().phy = 0
		human:getFlower().giveList = {}
		human:getFlower().sendCntList = {1,1,1}
	end
end

function sendOpenMsg(human, index, fromType)
	local receiver = getReceiver(index, fromType)
	if receiver then
		local account = receiver.db.account
		local hasGive = hasGiveThatAccount(human, account)
		local sendCount = getLeftSendFlowerCount(human)
		local recordList = getTargetReceiveRecordList(account)
		local costList = getCostList(human)
		resetDayRecord(human)
		Msg.SendMsg(PacketID.GC_FLOWER_GIVE_OPEN, human, index, fromType, receiver.db.bodyId, receiver.db.name, receiver.db.flowerCount or 0, hasGive, sendCount, human:getFlower().tipShow, recordList, costList)
	end
end

function getReceiver(index, fromType)
	local receiver = nil
	local data = nil
	if fromType == Define.FLOWER_FROM_TYPE_TALK then
		data = HumanManager.getCharDBByName(index)
	elseif fromType == Define.FLOWER_FROM_TYPE_GUILD then
		data = HumanManager.getCharDBByName(index)
	elseif fromType == Define.FLOWER_FROM_TYPE_RANK_ARENA then
		data = Arena.getPosRankData()[tonumber(index)]
	elseif fromType == Define.FLOWER_FROM_TYPE_RANK_FIGHT then
		data = Arena.getFightRankData()[tonumber(index)]
	elseif fromType == Define.FLOWER_FROM_TYPE_RANK_FLOWER then
		data = FlowerRank.getTempRankList()[tonumber(index)]
	elseif fromType == Define.FLOWER_FROM_TYPE_BOSS then
		local hasRank,rank = WorldBossLogic.hasThatRank(tonumber(index))
		data = rank
	elseif fromType == Define.FLOWER_FROM_TYPE_CRAZY then
		local hasRank,rank = CrazyLogic.hasThatRank(tonumber(index))
		data = rank
	elseif fromType == Define.FLOWER_FROM_TYPE_TRIAL then
		data = TrialRank.RankList[tonumber(index)]
	elseif fromType == Define.FLOWER_FROM_TYPE_ARENA then
		data = Arena.getRankDataByRank(tonumber(index))
	elseif fromType == Define.FLOWER_FROM_TYPE_ACC then
		data = {}
		data.account = index
	end
	if data then
		receiver = Arena.getArenaHuman(data.account)
	end
	return receiver
end

function getCostList(human)
	local one = getCurFlowerCost(human, Define.FLOWER_TYPE_ONE)
	local nine = getCurFlowerCost(human, Define.FLOWER_TYPE_NINE)
	local nineNine = getCurFlowerCost(human, Define.FLOWER_TYPE_NINE_N)
	local tb = {}
	table.insert(tb, {cost=one[Define.FLOWER_COST_COST], costType=one[Define.FLOWER_COST_CURRENCY]})
	table.insert(tb, {cost=nine[Define.FLOWER_COST_COST], costType=nine[Define.FLOWER_COST_CURRENCY]})
	table.insert(tb, {cost=nineNine[Define.FLOWER_COST_COST], costType=nineNine[Define.FLOWER_COST_CURRENCY]})
	return tb
end

function getMailReward(rewardList)
	local tab = {}
	for id,count in pairs(rewardList) do
		table.insert(tab, {id,count})	
	end
	return tab
end

--是否赠送过该玩家
function hasGiveThatAccount(human, account)
	local db = human:getFlower()		
	local giveList = db.giveList or {}
	for _,giveAccount in pairs(giveList) do
		if account == giveAccount then
			return 1
		end
	end
	return 0
end

--获取对应玩家送花列表
function getTargetReceiveRecordList(account)
	local target = Arena.getArenaHuman(account)
	local tab = {}
	if target ~= nil then
		local db = target.db.flower
		if db ~= nil then
			local list = {}
			local len = #db.receiveRecordList
			if len < Define.FLOWER_LIMIT_SHOW_COUNT then
				for _,record in ipairs(db.receiveRecordList) do
					local player = Arena.getArenaHuman(record.account)
					if player ~= nil then
						table.insert(tab, {name=player.db.name,flowerType=record.flowerType,giveTime=record.giveTime})
					end
				end
			else
				local startIndex = len - Define.FLOWER_LIMIT_SHOW_COUNT + 1
				for i=startIndex,len do
					local record = db.receiveRecordList[i]
					local player = Arena.getArenaHuman(record.account)
					if player ~= nil then
						table.insert(tab, {name=player.db.name,flowerType=record.flowerType,giveTime=record.giveTime})
					end
				end
			end
		end
	end
	return tab
end

function getPersonalGiveRecordList(human)
	local db = human:getFlower()
	local tab = {}
	for _,record in ipairs(db.sendRecordList) do
		local player = Arena.getArenaHuman(record.account)
		if player ~= nil then
			table.insert(tab, {name=player.db.name,flowerType=record.flowerType,giveTime=record.giveTime})
		end
	end
	return tab
end

function getPersonalReceiveRecordList(human)
	local db = human:getFlower()
	local tab = {}
	for _,record in ipairs(db.receiveRecordList) do
		local player = Arena.getArenaHuman(record.account)
		if player ~= nil then
			table.insert(tab, {name=player.db.name,flowerType=record.flowerType,giveTime=record.giveTime})
		end
	end
	return tab
end

function addSendRecord(human, account, flowerType)
	local db = human:getFlower()
	local sendRecordList = db.sendRecordList
	table.insert(sendRecordList, {account=account,flowerType=flowerType,giveTime=os.time()})
	table.insert(db.giveList, account)
	db.sendCntList[flowerType] = db.sendCntList[flowerType] + 1
	Hm:dispatchEvent(Hm.Event_SendFlower,{human=human})
end

function addReceiveRecord(receiver, account, flowerType)
	local db = receiver.db.flower
	if db then
		local receiveRecordList = db.receiveRecordList
		table.insert(receiveRecordList, {account=account,flowerType=flowerType,giveTime=os.time()})
		Hm:dispatchEvent(Hm.Event_GetFlower,{human=receiver})
		if #receiveRecordList > Define.FLOWER_LIMIT_RECEIVE_COUNT then
			table.remove(receiveRecordList, 1)
		end
	end
end

function getLeftSendFlowerCount(human)
	local db = human:getFlower()
	return getMaxSendFlowerCount(human) - db.sendCount
end

function getMaxSendFlowerCount(human)
	return Define.FLOWER_SEND_COUNT + VipLogic.getVipAddCount(human, VipDefine.VIP_FLOWER)
end

function hasEnoughCost(human, flowerType)
	local last = getCurFlowerCost(human, flowerType)
	if last[Define.FLOWER_COST_CURRENCY] == Define.FLOWER_COST_TYPE_MONEY then
		if human:getMoney() < last[Define.FLOWER_COST_COST] then
			return false,Define.ERR_CODE.GiveFailMoney
		end
	end
	if last[Define.FLOWER_COST_CURRENCY] == Define.FLOWER_COST_TYPE_RMB then
		if human:getRmb() < last[Define.FLOWER_COST_COST] then
			return false,Define.ERR_CODE.GiveFailRmb
		end
	end
	return true
end

function getCurFlowerCost(human, flowerType)
	local cost = Config[flowerType].cost
	local last = nil
	local len = #cost
	for i=1,len do
		local v = cost[i]
		if human:getFlower().sendCntList[flowerType] < v[Define.FLOWER_COST_SECTION] then
			break
		end
		last = v
	end
	return last
end

function decCost(human, flowerType)
	local last = getCurFlowerCost(human, flowerType)
	if last[Define.FLOWER_COST_CURRENCY] == Define.FLOWER_COST_TYPE_MONEY then
		human:decMoney(last[Define.FLOWER_COST_COST], CommonDefine.MONEY_TYPE.DEC_FLOWER_SEND)
	end
	if last[Define.FLOWER_COST_CURRENCY] == Define.FLOWER_COST_TYPE_RMB then
		human:decRmb(last[Define.FLOWER_COST_COST], nil, CommonDefine.RMB_TYPE.DEC_FLOWER_SEND)
	end
end

function decSendCount(human)
	local db = human:getFlower()
	db.sendCount = db.sendCount + 1
end
