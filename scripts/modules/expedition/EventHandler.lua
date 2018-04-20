module(...,package.seeall)

local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local Define = require("modules.expedition.ExpeditionDefine")
local Config = require("config.ExpeditionConfig").Config
local ResetConfig = require("config.ExpeditionResetConfig").Config[1]
local Logic = require("modules.expedition.ExpeditionLogic")
local ItemConfig = require("config.ItemConfig").Config
local ShopConfig = require("config.ExpeditionShopConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local Util = require("core.utils.Util")
local HumanManager = require("core.managers.HumanManager")
local GuildManager = require("modules.guild.GuildManager")
local TreasureConfig = require("config.ExpeditionTreasureConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local Arena = require("modules.arena.Arena")
local WineLogic = require("modules.guild.wine.WineLogic")
local BagDefine = require("modules.bag.BagDefine")

function onCGExpeditionQuery(human)
	local db = human:getExpedition()
	local curEnemy = Logic.getCurExpedition(human)
	--if curEnemy ~= nil then
		Logic.clearYesterdayData(human)
		return Msg.SendMsg(PacketID.GC_EXPEDITION_QUERY, human, db.curId, human:getTourCoin(), db.resetCount, db.buyResetCount, db.hasResetCount, db.passId, Logic.getHasGetTreasureList(human))
	--end
end

function onCGExpeditionChallange(human, next)
	local db = human:getExpedition()
	local curEnemy = Logic.getCurExpedition(human)
	if curEnemy ~= nil then
		local obj = Arena.getArenaHuman(curEnemy.account)
		if obj ~= nil then
			local tab = {}
			for _,hero in pairs(curEnemy.heroList) do
				table.insert(tab, hero)
			end
			Msg.SendMsg(PacketID.GC_EXPEDITION_CHALLANGE, human, obj.db.name, obj.db.lv, obj.db.bodyId, GuildManager.getGuildNameByGuildId(obj.db.guildId), curEnemy.rage, curEnemy.assist, tab, next)

			if next == Define.NEXT_YES then
				Logic.sendHeroListMsg(human)
			end
		end
	end
end

function onCGExpeditionHeroList(human)
	Logic.sendHeroListMsg(human)
end

function onCGExpeditionBuyCount(human)
	local db = human:getExpedition()
	if Logic.hasMaxResetCount(human) == false then
		if Logic.hasMaxBuyResetCount(human) == false then
			--小于最大容纳重置数并且小于最大可购买数
			local cost = ResetConfig.resetList[db.buyResetCount + 1]
			if Logic.hasEnoughMoney(human, cost) == true then
				Logic.incResetAndBuyCount(human)
				human:decRmb(cost, nil, CommonDefine.RMB_TYPE.DEC_EXPEDITION_BUY)
				human:sendHumanInfo()
				return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_COUNT, human, Define.ERR_CODE.BuySuccess)
			else
				--钱不够
				return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_COUNT, human, Define.ERR_CODE.BuyNeedMoney)
			end
		else
			--已达到最大购买次数
			return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_COUNT, human, Define.ERR_CODE.BuyMaxBuyCount)
		end 
	else
		--已达到最大重置数
		return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_COUNT, human, Define.ERR_CODE.BuyMaxGetCount)
	end
end

function onCGExpeditionGetTreasure(human, id)
	if Logic.hasGetThatTheasure(human, id) == false then
		--未领取
		if Logic.hasSuccessExpedition(human, id) == true then
			--已通关
			local config = Logic.getTreasureConfig(human, id)
			if config ~= nil then
				local rewardList = PublicLogic.randReward(config.rewardList)
				rewardList = WineLogic.wineBuffDeal(human,rewardList,"expedition")
				PublicLogic.doReward(human, rewardList, {}, CommonDefine.ITEM_TYPE.ADD_EXPEDITION_REWARD)
				human:sendHumanInfo()

				--领取
				Logic.setHasGetTreasure(human, id)

				local coin = 0
				local money = rewardList.money and rewardList.money or 0
				local itemList = {}
				local db = human:getExpedition()
				local curConfig = Config[id]
				for id,count in pairs(rewardList) do
					local num = tonumber(id)
					if num then
						local item = ItemConfig[num]
						local logTb = Log.getLogTb(LogId.EXPEDITION_DROP)
						logTb.name = human:getName()
						logTb.account = human:getAccount()
						logTb.pAccount = human:getPAccount()
						logTb.expeditionName = curConfig.copyName
						logTb.expeditionId = id
						logTb.itemName = item.name
						logTb.itemCount = count
						logTb:save()

						table.insert(itemList, {itemId=num, count=count})
					end
				end

				if money > 0 then
					local item = ItemConfig[BagDefine.ITEM_MONEY]
					local logTb = Log.getLogTb(LogId.EXPEDITION_DROP)
					logTb.name = human:getName()
					logTb.account = human:getAccount()
					logTb.pAccount = human:getPAccount()
					logTb.expeditionName = curConfig.copyName
					logTb.expeditionId = id
					logTb.itemName = item.name
					logTb.itemCount = money
					logTb:save()
				end

				HumanManager:dispatchEvent(HumanManager.Event_Expedition,{human=human,objId=id})

				return Msg.SendMsg(PacketID.GC_EXPEDITION_GET_TREASURE, human, Define.ERR_CODE.GetTreasureSuccess, id, money, coin, itemList)
			else
				return Msg.SendMsg(PacketID.GC_EXPEDITION_GET_TREASURE, human, Define.ERR_CODE.GetTreasureNoPossible, id, 0, 0, nil)
			end 
		else
			--未通关
			return Msg.SendMsg(PacketID.GC_EXPEDITION_GET_TREASURE, human, Define.ERR_CODE.GetTreasureNoPass, id, 0, 0, nil)
		end
	else
		--已经领取了
		return Msg.SendMsg(PacketID.GC_EXPEDITION_GET_TREASURE, human, Define.ERR_CODE.GetTreasureHasGet, id, 0, 0, nil)
	end
end

function onCGExpeditionReset(human)
	local db = human:getExpedition()
	if Logic.hasResetCountLeft(human) then
		if Logic.hasTreasureNotGet(human) == false then
			Logic.decResetCount(human, 1)
			Logic.clearHasGetTreasureMark(human)
			Logic.resetToFirstExpedition(human)
			Logic.resetHeroAbout(human)
			return Msg.SendMsg(PacketID.GC_EXPEDITION_RESET, human, Define.ERR_CODE.ResetSuccess, 0)
		else
			--还有宝藏未领取
			return Msg.SendMsg(PacketID.GC_EXPEDITION_RESET, human, Define.ERR_CODE.ResetHasTreasureNotGet, 0)
		end
	else
		local cost = ResetConfig.resetList[db.buyResetCount + 1]
		--重置次数不足
		return Msg.SendMsg(PacketID.GC_EXPEDITION_RESET, human, Define.ERR_CODE.ResetHasNotCount, cost)
	end
end

function onCGExpeditionEnter(human, orderList)
	local listLen = #orderList
	if listLen == 0 or listLen > 4 then
		return Msg.SendMsg(PacketID.GC_EXPEDITION_ENTER, human, Define.ERR_CODE.EnterNoPossiblel, nil)
	end

	local db = human:getExpedition()
	local curEnemy = db.copyList[db.curId]
	if curEnemy == nil then
		return Msg.SendMsg(PacketID.GC_EXPEDITION_ENTER, human, Define.ERR_CODE.EnterFinish, nil)
	end

	local assistantCount = 0
	local normalCount = 0
	local db = human:getExpedition()
	for _,orderData in pairs(orderList) do
		local hero = db.heroList[orderData.name]
		if hero ~= nil then
			if hero.hp > 0 then
				-- if orderData.isAssistant == 0 or hero.cd <= 0 then
				-- 	-- if orderData.isAssistant == 0 then
				-- 	-- 	normalCount = normalCount + 1
				-- 	-- else
				-- 	-- 	assistantCount = assistantCount + 1
				-- 	-- end
				-- else
				-- 	--援助cd内不能入阵
				-- 	return Msg.SendMsg(PacketID.GC_EXPEDITION_ENTER, human, Define.ERR_CODE.EnterCD, nil)
				-- end
			else
				--阵亡
				return Msg.SendMsg(PacketID.GC_EXPEDITION_ENTER, human, Define.ERR_CODE.EnterDie, nil)
			end
		else
			--英雄不存在
			return Msg.SendMsg(PacketID.GC_EXPEDITION_ENTER, human, Define.ERR_CODE.EnterNoHero, nil)
		end
	end

	--成功
	return Msg.SendMsg(PacketID.GC_EXPEDITION_ENTER, human, Define.ERR_CODE.EnterSuccess, nil)
end

function onCGExpeditionEnd(human, result, myHeroRage, myHeroAssist, myHeroHpList, enemyHeroRage, enemyHeroAssist, enemyHeroHpList)
	Logic.setMyHeroAttrList(human, myHeroHpList, myHeroRage, myHeroAssist)
	Logic.setEnemyHeroAttrList(human, enemyHeroHpList, enemyHeroRage, enemyHeroAssist)

	local db = human:getExpedition()
	local config = Config[db.curId]
	local logTb = Log.getLogTb(LogId.EXPEDITION)
	logTb.name = human:getName()
	logTb.account = human:getAccount()
	logTb.pAccount = human:getPAccount()
	logTb.expeditionName = config.copyName
	logTb.expeditionId = db.curId
	logTb.result = result
	logTb:save()

	local ret = 0
	if result == Define.COPY_END_SUCCESS then
		if db.curId <= Define.COPY_NUM then
			db.curId = db.curId + 1
			if db.passId < db.curId then
				db.passId = db.curId
				db.clearRage = db.rage
				db.clearAssist = db.assist
				db.clearHeroList = Util.deepCopy(db.heroList)
				db.clearCopyList = Util.deepCopy(db.copyList)
				DB.dbSetMetatable(db.clearCopyList)
			end

			HumanManager:dispatchEvent(HumanManager.Event_Expedition,{human=human,objId=id,oType="fightWin"})
			Msg.SendMsg(PacketID.GC_EXPEDITION_QUERY, human, db.curId, human:getTourCoin(), db.resetCount, db.buyResetCount, db.hasResetCount, db.passId, Logic.getHasGetTreasureList(human))
		end
		ret = Define.ERR_CODE.CopyEndSuccess
	else
		ret = Define.ERR_CODE.CopyEndFail
	end


	return Msg.SendMsg(PacketID.GC_EXPEDITION_END, human, ret)
end

function onCGExpeditionShopList(human)
	--检查远征商城是否需要刷新
	local db = human:getExpeditionShop()
	local cost = Logic.getCurShopRefreshCost(human)
	if db.nextUpdate <= os.time() then
		Logic.refreshShopList(human)
	end
	return Msg.SendMsg(PacketID.GC_EXPEDITION_SHOP_LIST, human, Logic.getShopList(human), db.nextUpdate, cost)
end

function onCGExpeditionBuyItem(human, id)
	local db = human:getExpedition()
	local obj = ShopConfig[id]
	if obj ~= nil then
		local item = ItemConfig[obj.itemId]
		if item ~= nil then
			if Logic.hasItemBuy(human, id) == 0 then
				if human:getTourCoin() >= obj.useGemCount then
					if BagLogic.checkCanAddItem(human,item.id,1) then
						BagLogic.addItem(human, item.id, obj.count, true, CommonDefine.ITEM_TYPE.ADD_EXPEDITION_BUY)
						Logic.setItemBuy(human, id)
						human:decTourCoin(obj.useGemCount)
						human:sendHumanInfo()
							
						
						local coinItem = ItemConfig[Define.ITEM_ID]
						local logTb = Log.getLogTb(LogId.EXPEDITION_SHOP)
						logTb.name = human:getName()
						logTb.account = human:getAccount()
						logTb.pAccount = human:getPAccount()
						logTb.itemName = item.name
						logTb.itemCount = obj.count or 0
						logTb.costName = coinItem.name
						logTb.costNum = obj.useGemCount
						logTb.costLeft = human:getTourCoin()
						logTb:save()

						return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_ITEM, human, Define.ERR_CODE.ShopSuccess, id)
					else
						return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_ITEM, human, Define.ERR_CODE.ShopBagFull, id)
					end
				else
					--宝石不够
					return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_ITEM, human, Define.ERR_CODE.ShopGemNotEnought, id)
				end
			else
				--已经购买过了
				return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_ITEM, human, Define.ERR_CODE.ShopHasBuy, id)
			end
		else
			--物品不存在
			return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_ITEM, human, Define.ERR_CODE.ShopItemNotExist, id)
		end
	else
		--远征商店配置id不存在
		return Msg.SendMsg(PacketID.GC_EXPEDITION_BUY_ITEM, human, Define.ERR_CODE.ShopConfigError, id)
	end
end

function onCGExpeditionShopRefresh(human)
	local db = human:getExpeditionShop()
	local cost = Logic.getCurShopRefreshCost(human)
	if human:getRmb() >= cost then
		human:getExpedition().shopRefreshCnt = human:getExpedition().shopRefreshCnt + 1
		human:decRmb(cost, nil, CommonDefine.RMB_TYPE.DEC_EXPEDITION_SHOP_REFRESH)
		Logic.refreshShopList(human)
		human:sendHumanInfo()

		local nextCost = Logic.getCurShopRefreshCost(human)
		Msg.SendMsg(PacketID.GC_EXPEDITION_SHOP_LIST, human, Logic.getShopList(human), db.nextUpdate, nextCost)

		local item = ItemConfig[BagDefine.ITEM_RMB]
		local logTb = Log.getLogTb(LogId.EXPEDITION_REFRESH)
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.costName = item.name
		logTb.costNum = Define.SHOP_REFRESH_COST
		logTb:save()

		return Msg.SendMsg(PacketID.GC_EXPEDITION_SHOP_REFRESH, human, Define.ERR_CODE.ShopRefreshSuccess)
	else
		return Msg.SendMsg(PacketID.GC_EXPEDITION_SHOP_REFRESH, human, Define.ERR_CODE.ShopRefreshNoMoney)
	end
end

function onCGExpeditionClear(human)
	local db = human:getExpedition()
	if db.hasResetCount ~= 1 then
		if db.passId > 1 and db.curId < db.passId then
			db.curId = db.passId
			db.rage = db.clearRage
			db.assist = db.clearAssist
			db.heroList = Util.deepCopy(db.clearHeroList)
			db.copyList = Util.deepCopy(db.clearCopyList)
			DB.dbSetMetatable(db.copyList)
			Logic.rewardClear(human)
			return Msg.SendMsg(PacketID.GC_EXPEDITION_CLEAR, human, Define.ERR_CODE.ClearSuccess, db.passId)
		end
	end
	return Msg.SendMsg(PacketID.GC_EXPEDITION_CLEAR, human, Define.ERR_CODE.ClearFail, 0)
end
