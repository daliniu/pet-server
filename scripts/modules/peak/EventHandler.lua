module(...,package.seeall)

local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local Define = require("modules.peak.PeakDefine")
local Logic = require("modules.peak.PeakLogic")
local ShopConfig = require("config.PeakShopConfig").Config
local ItemConfig = require("config.ItemConfig").Config
local BagLogic = require("modules.bag.BagLogic")

function onCGPeakTeamCheck(human)
	local db = human:getPeak()
	local leftTime = db:getCoolTime() - os.time()
	if leftTime < 0 then
		leftTime = 0
	end
	local isStart = Logic.isStart() and 1 or 0
	local cost = Logic.getCurResetCost(human)
	Logic.clearYesterdayData(human)
	return Msg.SendMsg(PacketID.GC_PEAK_TEAM_CHECK, human, isStart, db:getTeam(), leftTime, human:getPeakCoin(), cost)
end

function onCGPeakTeamConfirm(human, heroNameList)
	local db = human:getPeak()
	if #heroNameList == Define.HERO_COUNT then
		db:setTeam(heroNameList)
		Logic.addPlayerToFightList(human, heroNameList)
		return Msg.SendMsg(PacketID.GC_PEAK_TEAM_CONFIRM, human, Define.ERR_CODE.CONFIRM_SUCCESS, db:getTeam())
	else
		return Msg.SendMsg(PacketID.GC_PEAK_TEAM_CONFIRM, human, Define.ERR_CODE.CONFIRM_FAIL, '')
	end
end

function onCGPeakSearch(human)
	if Logic.isInCoolTime(human) == false and Logic.isStart() == true then
		local target = Logic.getSearchingPlayer(human)
		if target then
			local enemy = HumanManager.getOnline(target.account)
			if enemy and enemy.db.isOnline == 1 then
				Logic.refreshCoolTime(human)
				Logic.refreshCoolTime(enemy)

				local enemyTarget = Logic.getCurTarget(enemy)
				Msg.SendMsg(PacketID.GC_PEAK_SEARCH, human, target.name, target.enemyInfoList)
				Msg.SendMsg(PacketID.GC_PEAK_SEARCH, enemy, enemyTarget.name, enemyTarget.enemyInfoList)
				HumanManager:dispatchEvent(HumanManager.Event_TopArena,{human=human,objNum = 1})
				HumanManager:dispatchEvent(HumanManager.Event_TopArena,{human=enemy,objNum = 1})
			end
		end
	end
end

function onCGPeakCancel(human)
	Logic.delPlayerToSearchList(human)
	return Msg.SendMsg(PacketID.GC_PEAK_CANCEL, human)
end

function onCGPeakResetSearch(human)
	if Logic.isInCoolTime(human) == true then
		local cost = Logic.getCurResetCost(human)
		if human:getRmb() >= cost then
			human:decRmb(cost,'', CommonDefine.RMB_TYPE.DEC_PEAK_RESET_SEARCH)
			human:sendHumanInfo()
			human:getPeak():setCoolTime(0)
			human:getPeak():setResetCount(human:getPeak():getResetCount() + 1)
			local nextCost = Logic.getCurResetCost(human)
			return Msg.SendMsg(PacketID.GC_PEAK_RESET_SEARCH, human, Define.ERR_CODE.RESET_SUCCESS, nextCost)
		else
			return Msg.SendMsg(PacketID.GC_PEAK_RESET_SEARCH, human, Define.ERR_CODE.RESET_NO_MONEY, 0)
		end
	else
		return Msg.SendMsg(PacketID.GC_PEAK_RESET_SEARCH, human, Define.ERR_CODE.RESET_NO_IN_COOL_TIME)
	end
end

function onCGPeakCtrlEnemy(human, heroNameList)
	if #heroNameList == Define.HERO_COUNT - Define.HERO_DEL_COUNT then
		local target = Logic.getCurTarget(human)
		target.enemyNameList = heroNameList
		if target.isRobot == Define.ROBOT then
			local enemy = HumanManager.getOnline(target.account)
			if enemy and enemy.db.isOnline == 1 then
				local enemyTarget = Logic.getCurTarget(enemy)
				enemyTarget.heroNameList = heroNameList
			end
		end
	end
end

function onCGPeakCtrlEnemyConfirm(human, heroNameList)
	local target = Logic.getCurTarget(human)
	if target.isRobot == Define.ROBOT then
		print('onCGPeakCtrlEnemyConfirm ============================= ')
		target.heroNameList = Logic.getHumanRandomNameList(human)
		target.enemyNameList = heroNameList
		Msg.SendMsg(PacketID.GC_PEAK_CTRL_ENEMY_CONFIRM, human, Define.ROBOT, target.heroNameList, target.enemyNameList)
	else
		target.enemyNameList = heroNameList
		local enemy = HumanManager.getOnline(target.account)
		if enemy and enemy.db.isOnline == 1 then
			local enemyTarget = Logic.getCurTarget(enemy)
			enemyTarget.heroNameList = heroNameList	
			Msg.SendMsg(PacketID.GC_PEAK_CTRL_ENEMY_CONFIRM, human, Define.HUMAN, target.heroNameList, target.enemyNameList)
			Msg.SendMsg(PacketID.GC_PEAK_CTRL_ENEMY_CONFIRM, enemy, Define.HUMAN, enemyTarget.heroNameList, enemyTarget.enemyNameList)
		end
	end
end

function onCGPeakReadyGo(human, heroNameList)
	print('readyGo heronamelist ==========================')
	Util.print_r(heroNameList)
	local target = Logic.getCurTarget(human)
	target.heroNameList = heroNameList
	if target.isRobot == Define.ROBOT then
		if #heroNameList <= Define.TEAM_HERO_COUNT then
			print('fuck robot ================')
			local enemyHeroList = Logic.getRobotHeroList(target)
			local seed = math.ceil(math.random(1, 10000))
			Msg.SendMsg(PacketID.GC_PEAK_READY_GO, human, seed, Define.DIR_LEFT, target.heroNameList, enemyHeroList)
		end
	else
		local enemy = HumanManager.getOnline(target.account)
		print('target.account = ===============' .. target.account)
		if enemy and enemy.db.isOnline == 1 then
			print('enemy account ==================' .. enemy:getAccount())
			print('human account ================' .. human:getAccount())
			local enemyTarget = Logic.getCurTarget(enemy)
			enemyTarget.enemyNameList = heroNameList	

			local seed = math.ceil(math.random(1, 10000))
			local humanHeroList = Logic.getHumanHeroList(human)
			local enemyHeroList = Logic.getHumanHeroList(enemy)
			Msg.SendMsg(PacketID.GC_PEAK_READY_GO, human, seed, Define.DIR_LEFT, target.heroNameList, enemyHeroList)
			Msg.SendMsg(PacketID.GC_PEAK_READY_GO, enemy, seed, Define.DIR_RIGHT, enemyTarget.heroNameList, humanHeroList)
		end
	end
end

function onCGPeakFail(human)
	local target = Logic.getCurTarget(human)
	if target then
		if target.result == Define.RESULT_ING then
			target.result = Define.RESULT_FAIL
			Logic.dealWithScore(human, Define.RESULT_RUN)
			if target.isRobot ~= Define.ROBOT then
				local enemy = HumanManager.getOnline(target.account)
				if enemy and enemy.db.isOnline == 1 then
					local enemyTarget = Logic.getCurTarget(enemy)
					if enemyTarget.result == Define.RESULT_ING then
						enemyTarget.result = Define.RESULT_SUCCESS
						Logic.dealWithScore(enemy, Define.RESULT_SUCCESS)
						Msg.SendMsg(PacketID.GC_PEAK_FAIL, enemy)
					end
				end
			end
		end
	end
end

function onCGPeakEnd(human, isSuccess)
	local target = Logic.getCurTarget(human)
	if target then
		if target.result == Define.RESULT_ING then
			local result = Define.RESULT_FAIL
			local enemyResult = Define.RESULT_SUCCESS
			if isSuccess == Define.END_SUCCESS then
				result = Define.RESULT_SUCCESS
				enemyResult = Define.RESULT_FAIL
			end
			target.result = result
			Logic.dealWithScore(human, result)
			if target.isRobot ~= Define.ROBOT then
				local enemy = HumanManager.getOnline(target.account)
				if enemy and enemy.db.isOnline == 1 then
					local enemyTarget = Logic.getCurTarget(enemy)
					if enemyTarget.result == Define.RESULT_ING then
						enemyTarget.result = enemyResult
						Logic.dealWithScore(enemy, enemyResult)
						Msg.SendMsg(PacketID.GC_PEAK_END, enemy, enemyResult)
					end
				end
			end
		end
	end
end

function onCGPeakFightRecord(human)
	local recordList = Logic.getFightRecordList(human)
	return Msg.SendMsg(PacketID.GC_PEAK_FIGHT_RECORD, human, recordList)
end

function onCGPeakShopList(human)
	local db = human:getPeak()
	local cost = Logic.getCurShopRefreshCost(human)
	if db.nextUpdate <= os.time() then
		Logic.refreshShopList(human)
	end
	return Msg.SendMsg(PacketID.GC_PEAK_SHOP_LIST, human, Logic.getShopList(human), db.nextUpdate, cost)	
end

function onCGPeakBuyItem(human, id)
	local db = human:getPeak()
	local obj = ShopConfig[id]
	if obj ~= nil then
		local item = ItemConfig[obj.itemId]
		if item ~= nil then
			if Logic.hasItemBuy(human, id) == 0 then
				if human:getPeakCoin() >= obj.score then
					if BagLogic.checkCanAddItem(human,item.id,1) then
						BagLogic.addItem(human, item.id, obj.count, true, CommonDefine.ITEM_TYPE.ADD_PEAK_SHOP)
						Logic.setItemBuy(human, id)
						human:decPeakCoin(obj.score)
						human:sendHumanInfo()
						
						--local coinItem = ItemConfig[Define.ITEM_ID]
						--local logTb = Log.getLogTb(LogId.EXPEDITION_SHOP)
						--logTb.name = human:getName()
						--logTb.account = human:getAccount()
						--logTb.pAccount = human:getPAccount()
						--logTb.itemName = item.name
						--logTb.itemCount = obj.count
						--logTb.costName = coinItem.name
						--logTb.costNum = obj.useGemCount
						--logTb.costLeft = human:getTourCoin()
						--logTb:save()

						return Msg.SendMsg(PacketID.GC_PEAK_BUY_ITEM, human, Define.ERR_CODE.ShopSuccess, id, human:getPeakCoin())
					else
						return Msg.SendMsg(PacketID.GC_PEAK_BUY_ITEM, human, Define.ERR_CODE.ShopBagFull, id, human:getPeakCoin())
					end
				else
					--宝石不够
					return Msg.SendMsg(PacketID.GC_PEAK_BUY_ITEM, human, Define.ERR_CODE.ShopGemNotEnought, id, human:getPeakCoin())
				end
			else
				--已经购买过了
				return Msg.SendMsg(PacketID.GC_PEAK_BUY_ITEM, human, Define.ERR_CODE.ShopHasBuy, id, human:getPeakCoin())
			end
		else
			--物品不存在
			return Msg.SendMsg(PacketID.GC_PEAK_BUY_ITEM, human, Define.ERR_CODE.ShopItemNotExist, id, human:getPeakCoin())
		end
	else
		--商店配置id不存在
		return Msg.SendMsg(PacketID.GC_PEAK_BUY_ITEM, human, Define.ERR_CODE.ShopConfigError, id, human:getPeakCoin())
	end
end

function onCGPeakShopRefresh(human)
	local db = human:getPeak()
	local cost = Logic.getCurShopRefreshCost(human)
	if human:getRmb() >= cost then
		human:getPeak().shopRefreshCnt = human:getPeak().shopRefreshCnt + 1
		human:decRmb(cost, nil, CommonDefine.RMB_TYPE.DEC_PEAK_SHOP_REFRESH)
		Logic.refreshShopList(human)
		human:sendHumanInfo()

		local nextCost = Logic.getCurShopRefreshCost(human)
		Msg.SendMsg(PacketID.GC_PEAK_SHOP_LIST, human, Logic.getShopList(human), db.nextUpdate, nextCost)

		--local item = ItemConfig[BagDefine.ITEM_RMB]
		--local logTb = Log.getLogTb(LogId.EXPEDITION_REFRESH)
		--logTb.name = human:getName()
		--logTb.account = human:getAccount()
		--logTb.pAccount = human:getPAccount()
		--logTb.costName = item.name
		--logTb.costNum = Define.SHOP_REFRESH_COST
		--logTb:save()

		return Msg.SendMsg(PacketID.GC_PEAK_SHOP_REFRESH, human, Define.ERR_CODE.ShopRefreshSuccess)
	else
		return Msg.SendMsg(PacketID.GC_PEAK_SHOP_REFRESH, human, Define.ERR_CODE.ShopRefreshNoMoney)
	end
end
