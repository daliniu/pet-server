module(...,package.seeall)
local ShopDefine = require("modules.shop.ShopDefine")
local BagLogic = require("modules.bag.BagLogic")
local ShopLogic = require("modules.shop.ShopLogic")

function addVirItem(human,cfg,params)
	local num = cfg.buynum
	local itemId = cfg.itemId
	BagLogic.addItem(human,itemId,num,false,CommonDefine.ITEM_TYPE.ADD_SHOP_BUY)
	return true
end

function resetBuyCnt(human,cfg,params)
	local shopId = params[1]
	human.db.shop:setBuyCnt(shopId,0)
	ShopLogic.query(human,{shopId})
	return true
end

function addArenaCnt(human)
	local ArenaLogic = require("modules.arena.ArenaLogic")
	human.db.arena.challenge = 0
	ArenaLogic.arenaQuery(human)
	return true
end

function addTreasureDoubleTime(human,cfg,params)
	-- 增加夺宝双倍收益时间
	local Treasure = require("modules.treasure.Treasure")
	local mineId = params[1]
	-- Treasure.addDoubleTime(human,mineId)
	Treasure.deleteDayTimes(human,"double",1)
	Treasure.sendTreasureChar(human)
end

function addTreasureSafeTime(human,cfg,params)
	-- 增加夺宝双倍收益时间
	local Treasure = require("modules.treasure.Treasure")
	local mineId = params[1]
	-- Treasure.addSafeTime(human,mineId)
	Treasure.deleteDayTimes(human,"safe",1)
	Treasure.sendTreasureChar(human)
end

function addTreasureExtendTime(human,cfg,params)
	-- 增加宝藏占领时间
	local Treasure = require("modules.treasure.Treasure")
	-- Treasure.addExtendTime(human,params[1],params[2])
	Treasure.deleteDayTimes(human,"extend",1)
	Treasure.sendTreasureChar(human)
end

function addTreasureGrabCount(human)
	-- 重置夺宝抢夺次数
	local Treasure = require("modules.treasure.Treasure")
	Treasure.clearDayTimes(human,'occupy')
end
function addTreasureFightTime(human)
	local Treasure = require("modules.treasure.Treasure")
	Treasure.addFightTimes(human)
end

function addTreasurerRefreshMapTime(human)
	local Treasure = require("modules.treasure.Treasure")
	Treasure.addRefreshMapTimes(human)
end

function addVipLevelCount(human)
	local VipLevelLogic = require("modules.vip.VipLevelLogic")
	VipLevelLogic.deleteVipLevelTimes(human)
end

function addTrialTime(human,cfg,params)
	local levelType = params[1]
	require("modules.trial.TrialLogic").addTrialTime(human,levelType)
end




