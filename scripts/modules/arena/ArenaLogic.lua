module(...,package.seeall)

local Arena = require("modules.arena.Arena")
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local SkillLogic = require("modules.skill.SkillLogic")
local ArenaDefine = require("modules.arena.ArenaDefine")
local ArenaShopConfig = require("config.ArenaShopConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local ArenaShopRefreshConfig  = require("config.ArenaShopRefreshConfig").Config
local ArenaConstConfig = require("config.ArenaConstConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local Hero = require("modules.hero.Hero")
local HeroManager = require("modules.hero.HeroManager")
local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")
local ItemConfig = require("config.ItemConfig").Config

function onHumanLogin(hm,human)
	--if not Util.IsSameDate(human.db.lastLogout,os.time()) then
	--	human.db.arena.challenge = 0
	--end
	if human.db.arena.arenaing > 0 then
		fightEnd(human,ArenaDefine.LOSE,human.db.arena.arenaing)
	end
end

function onLogout(human)
	Arena.delArenaing(human:getAccount())
end

function updateArenaNextDay(human)
	human.db.arena.shopRefresh = 0
	human.db.arena.shop = {}
	human.db.arena.lastRefresh = os.time()
end

function arenaQuery(human)
	if not Util.IsSameDate(human.db.arena.challengeRefresh,os.time()) then
		human.db.arena.challenge = 0
		human.db.arena.challengeRefresh = os.time()
	end
	local rank = Arena.getRank(human)
	if rank <= 0 then
    	Msg.SendMsg(PacketID.GC_ARENA_QUERY,human,0)
		return 
	else
		local rankData = Arena.getRankData(human)
		if rankData then
			local arenaData = human:getArena()
			if not next(arenaData.enemyList) then
				Arena.refreshEnemy(human)
				arenaData = human:getArena()
			end
			local enemyData = makeEnemyData(arenaData.enemyList)
			for k,v in pairs(rankData.fightList) do
				local hero = human:getHero(k)
				if not hero then
					rankData.fightList[k] = nil
				end
			end
			local fightData = makeFightList(rankData.fightList)
			local leftTimes = getLeftChallenge(human)
			local maxTimes = getMaxChallenge(human)
			Msg.SendMsg(PacketID.GC_ARENA_QUERY,human,rankData.rank,fightData,leftTimes,maxTimes,math.max(arenaData.nextTime-os.time(),0),enemyData)
		else
    		Msg.SendMsg(PacketID.GC_ARENA_QUERY,human,0)
		end
	end
end

function changeHero(human,fightlist)
	for i = 1,4 do
		if fightlist[i] and fightlist[i].name then
			local hero = human:getHero(fightlist[i].name)
			if not hero then
				return false
			end
		end
	end
	if #fightlist < 2 or #fightlist > 4 then
		return false
	end
	local flag = false
	for k,v in pairs(fightlist) do
		if v.pos == 4 then
			flag = true
			break
		end
	end
	if not flag then
		return false
	end
	local arenaData = human:getArena()
	local rank = Arena.getRank(human)
	if rank <= 0 then
		local rankData = Arena.addRank(human,fightlist)
		if rankData then
			local arenaData = human.db.arena
			local enemyData = makeEnemyData(arenaData.enemyList)
			local fightData = makeFightList(rankData.fightList)
			local leftTimes = getLeftChallenge(human)
			local maxTimes = getMaxChallenge(human)
			Msg.SendMsg(PacketID.GC_ARENA_QUERY,human,rankData.rank,fightData,leftTimes,maxTimes,math.max(arenaData.nextTime-os.time(),0),enemyData)
			HumanManager:dispatchEvent(HumanManager.Event_Arena,{human=human,objNum=rank})
		end
	else
		Arena.changeFightList(human,fightlist)
		Msg.SendMsg(PacketID.GC_ARENA_CHANGE_HERO,human,fightlist)
	end
end

function makeFightList(fightList)
	local fightData = {}
	for k,v in pairs(fightList) do
		table.insert(fightData,{name = k,pos = v.pos})
	end
	table.sort(fightData,function(a,b)return fightList[a.name].pos < fightList[b.name].pos end)
	return fightData
end

function makeEnemyData(enemyList)
	local enemyData = {}
	for k,v in pairs(enemyList) do
		enemyData[k] = {}
		local enemy = Arena.getArenaHuman(v.account)
		if enemy then
			enemyData[k].name = enemy.db.name
			enemyData[k].flowerCount= enemy.db.flowerCount
			enemyData[k].lv = enemy.db.lv
			enemyData[k].icon = enemy.db.bodyId
			enemyData[k].win = enemy.db.arena and enemy.db.arena.win or 0
			local rankData = Arena.getRankDataByAccount(enemy.db.account)
			if rankData then
				enemyData[k].rank = rankData.rank
				enemyData[k].fightVal = rankData.fightVal
				enemyData[k].fightList = {}
				local temp = {}
				local fightList = Arena.getArenaFightList(v.account)
				for hName,vInfo in pairs(fightList) do
					local hero = enemy:getHero(hName)
					if hero then
						local data = {}
						data.name = hero:getName()
						data.exp = hero:getExp()
						data.quality = hero:getQuality()
						data.lv = hero:getLv()
						data.dyAttr = Util.deepCopy(hero.dyAttr)
						Hero.dyAttr1(data.dyAttr)
						local groupList = hero:getSkillGroupList()
						local groupMsg = {}
						for _,group in pairs(groupList) do
							SkillLogic.makeSkillGroupMsg(group,groupMsg)
						end
						data.skillGroupList = groupMsg 
						data.gift = hero:getGift()
						table.insert(temp,data)
					end
				end
				table.sort(temp,function(a,b) return fightList[a.name].pos < fightList[b.name].pos end)
				enemyData[k].fightList = temp
			end
		end
	end
	return enemyData
end

function makeByIdEnemyData(account)
	local enemyData = {}
	local enemy = Arena.getArenaHuman(account)

		if enemy then
			enemyData.name = enemy.db.name
			enemyData.lv = enemy.db.lv
			enemyData.icon = enemy.db.bodyId
			enemyData.win = enemy.db.arena and enemy.db.arena.win or 0
			enemyData.flowerCount = enemy.db.flowerCount
			local rankData = Arena.getRankDataByAccount(enemy.db.account)
			if rankData then
				enemyData.rank = rankData.rank
				enemyData.fightVal = rankData.fightVal
				enemyData.fightList = {}
				local temp = {}
				local fightList = Arena.getArenaFightList(account)
				for hName,vInfo in pairs(fightList) do
					local hero = enemy:getHero(hName)
					if hero then
						local data = {}
						data.name = hero:getName()
						data.exp = hero:getExp()
						data.quality = hero:getQuality()
						data.lv = hero:getLv()
						table.insert(temp,data)
					end
				end
				table.sort(temp,function(a,b) return fightList[a.name].pos < fightList[b.name].pos end)
				enemyData.fightList = temp
			end
		end


	return enemyData
end

function changeEnemy(human)
	local arenaData = human:getArena()
	local rank = Arena.getRank(human)
	if rank > 0 then
		Arena.refreshEnemy(human)
		local enemyData = makeEnemyData(arenaData.enemyList)
		Msg.SendMsg(PacketID.GC_ARENA_CHANGE_ENEMY,human,enemyData)
	end
end

function fightBegin(human,enemyPos)
	local arenaData = human:getArena()
	local enemy = arenaData.enemyList[enemyPos]
	if not enemy then
		ret = ArenaDefine.ARENA_BEGIN.kNoEnemy
	end
	local ret
	local maxTimes = getMaxChallenge(human)
	if arenaData.challenge >= maxTimes then
		ret = ArenaDefine.ARENA_BEGIN.kLeftTimes
	elseif arenaData.nextTime > os.time() then
		ret = ArenaDefine.ARENA_BEGIN.kCdTime
	--elseif Arena.checkArenaing(enemy.account) then
	--	ret = ArenaDefine.ARENA_BEGIN.kEnemying
	else
		ret = ArenaDefine.ARENA_BEGIN.kOk
		human.db.arena.challenge = human.db.arena.challenge + 1
		human.db.arena.nextTime = os.time() + ArenaConstConfig[1].reset
		human.db.arena.arenaing = enemyPos
		Arena.addArenaing(human:getAccount(),enemy.account)
	end
	return ret
end

function fightEnd(human,result,enemyPos)
	human.db.arena.arenaing = 0
	local arenaData = human:getArena()
	local enemy = arenaData.enemyList[enemyPos]
	local rank = Arena.getRank(human)
	if not enemy then
		return false
	end
	local rewards = {}
	local addFame = 0
	if ArenaDefine.WIN == result then
		local rise = Arena.riseRank(human,enemy)
		human.db.arena.win = human.db.arena.win + 1
		addArenaRecord(human,enemy.account,result,rise)

		local cnt = human:getLv()*2
		rewards = {[1] = {rewardName = "heroExp",cnt = cnt},}

		local fightList = Arena.getArenaFightList(human.db.account)
		local heroes = {}
		for k,v in pairs(fightList) do
			table.insert(heroes,k)
		end
		PublicLogic.doReward(human,{["heroExp"]=cnt},heroes)
		HeroManager.sendHeroes(human,heroes)
		addFame = ArenaConstConfig[1].win

		HumanManager:dispatchEvent(HumanManager.Event_Arena,{human=human,objNum=1,oType="fightWin"})
	elseif ArenaDefine.LOSE == result then
		addArenaRecord(human,enemy.account,result,0)
		addFame = ArenaConstConfig[1].lose
		HumanManager:dispatchEvent(HumanManager.Event_Arena,{human=human,objNum=1,oType="fightLose"})
	end
	--local addFame = ArenaDefine.REWARD[result] or 0
	human:incFame(addFame)
	human.db.arena.nextTime = os.time() + ArenaConstConfig[1].reset
	human:sendHumanInfo()
	Arena.delArenaing(human:getAccount())
	return rewards
end

function addArenaRecord(human,account,win,rise)
	local enemy = Arena.getArenaHuman(account)
	if enemy then
		local arenaData = human:getArena()
		local fightList = Arena.getArenaFightList(human.db.account)
		local fightList2 = {}
		for k,v in pairs(fightList) do
			local hero = human:getHero(k)
			if hero then
				table.insert(fightList2,{name = k,pos = v.pos,lv = hero:getLv(),quality = hero:getQuality(),transferLv = hero:getTransferLv()})
			end
		end
		local enemyList = Arena.getArenaFightList(account)
		local enemyList2 = {}
		for k,v in pairs(enemyList) do
			local hero = enemy:getHero(k)
			if hero then
				table.insert(enemyList2,{name = k,pos = v.pos,lv = hero:getLv(),quality = hero:getQuality(),transferLv = hero:getTransferLv()})
			end
		end
		local recordA = {
			happenTime = os.time(),
			name = enemy.db.name,
			lv = enemy.db.lv,
			icon = enemy.db.bodyId,
			rise = rise,
			result = win == ArenaDefine.WIN and win or ArenaDefine.LOSE,
			lead = ArenaDefine.LEAD,
			fightList = fightList2,
			enemyList = enemyList2
		}
		if #human.db.arena.record >= ArenaDefine.MAX_ARENA_RECORD then
			human.db.arena.record[ArenaDefine.MAX_ARENA_RECORD] = recordA
		else
			table.insert(human.db.arena.record,recordA)
		end
		table.sort(human.db.arena.record,function(a,b) return a.happenTime > b.happenTime end)
		if enemy.db.arena then
			local recordB = {
				happenTime = os.time(),
				name = human.db.name,
				lv = human.db.lv,
				icon = human.db.bodyId,
				rise = rise,
				result = win == ArenaDefine.WIN and ArenaDefine.LOSE or ArenaDefine.WIN,
				lead = ArenaDefine.PASSIVE,
				fightList = enemyList2,
				enemyList = fightList2
			}
			if win == ArenaDefine.LOSE then
				enemy.db.arena.win = enemy.db.arena.win + 1
			end
			if #enemy.db.arena.record >= ArenaDefine.MAX_ARENA_RECORD then
				enemy.db.arena.record[ArenaDefine.MAX_ARENA_RECORD] = recordB
			else
				table.insert(enemy.db.arena.record,recordB) 
			end
			table.sort(enemy.db.arena.record,function(a,b) return a.happenTime > b.happenTime end)
		end
	end
end

function fightRecord(human)
	local recordData = {}
	for i = 1,#human.db.arena.record do
		local v = human.db.arena.record[i]
		local record = {
			icon = v.icon,
			name = v.name,
			lv = v.lv,
			happened = os.time() - v.happenTime,
			lead = v.lead,
			result = v.result,
			rise = v.rise,
			fightList = v.fightList,
			enemyList = v.enemyList
		}
		table.insert(recordData,record)
	end
    Msg.SendMsg(PacketID.GC_ARENA_FIGHT_RECORD,human,recordData)
end

function checkShop(human)
	for k,v in pairs(human.db.arena.shop) do
		if not ArenaShopConfig[v.id] then
			human.db.arena.shop = {}
			break
		end
	end
	if not next(human.db.arena.shop) then
		human.db.arena.shop = randomItems()
	end
end

function shopQuery(human)
	if not Util.IsSameDate(human.db.arena.lastRefresh,os.time()) then
		updateArenaNextDay(human)
	end
	local shopData = {}
	checkShop(human)
	local arenaShop = human.db.arena.shop
	for i = 1,#arenaShop do
		local shopId = arenaShop[i].id
		local buy = arenaShop[i].buy
		local cfg = ArenaShopConfig[shopId]
		local tb = {
			id = shopId,
			itemId = cfg.itemId,
			cnt = cfg.count,
			buy = buy,
			price = cfg.fame,
		}
		table.insert(shopData,tb)
	end
	Msg.SendMsg(PacketID.GC_ARENA_SHOP_QUERY,human,shopData,human.db.arena.shopRefresh)
end

function shopRefresh(human)
	local arenaData = human:getArena()
	if arenaData.shopRefresh >= VipLogic.getVipAddCount(human,"arenaShopCount") then
		return false,ArenaDefine.ARENA_REFRESH.kNoTimes
	end
	local cfg = ArenaShopRefreshConfig[arenaData.shopRefresh + 1]
	if not cfg then
		return false,ArenaDefine.ARENA_REFRESH.kErrData
	end
	--if human:getFame() < cfg.cost then
	--	return false,ArenaDefine.ARENA_REFRESH.kNoFame
	--end
	--human:decFame(cfg.cost)
	if human:getRmb() < cfg.cost then
		return false,ArenaDefine.ARENA_REFRESH.kNoFame
	end
	human:decRmb(cfg.cost,nil,CommonDefine.RMB_TYPE.DEC_ARENA_SHOP_REFRESH)
	human.db.arena.shop = randomItems()
	human.db.arena.shopRefresh = math.max(human.db.arena.shopRefresh + 1,0)
	human:sendHumanInfo()
	shopQuery(human)
	return true,ArenaDefine.ARENA_REFRESH.kOk
end

function shopBuy(human,shopId)
	local cfg = ArenaShopConfig[shopId]
	if not cfg then
		return false,ArenaDefine.ARENA_BUY.kErrData
	end
	local buy
	for k,v in pairs(human.db.arena.shop) do
		if v.id == shopId then
			buy = v.buy
			break
		end
	end
	if not buy or buy ~= 0  then
		return false,ArenaDefine.ARENA_BUY.kHasBuy
	end
	if human:getFame() < cfg.fame then
		return false,ArenaDefine.ARENA_BUY.kNoFame
	end
    if not BagLogic.checkCanAddItem(human, cfg.itemId, cfg.count) then
		return false,ArenaDefine.ARENA_BUY.kFullBag
	end
	human:decFame(cfg.fame)
	for k,v in pairs(human.db.arena.shop) do
		if v.id == shopId then
			v.buy = 1
			break
		end
	end
	local ret = BagLogic.addItem(human, cfg.itemId, cfg.count,true,CommonDefine.ITEM_TYPE.ADD_ARENA_SHOP)
	human:sendHumanInfo()
	local logTb = Log.getLogTb(LogId.SHOP_COST)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.shopName = "竞技场商店"
	logTb.itemName = ItemConfig[cfg.itemId].name
	logTb.buyCnt = cfg.count
	logTb.costName = "竞技场声望"
	logTb.costNum = cfg.fame
	logTb:save()
	return true,ArenaDefine.ARENA_BUY.kOk
end

function randomItems()
	local tb = {}
	for k,v in pairs(ArenaShopConfig) do
		table.insert(tb,{id = v.id,weight = v.weight})
	end
	local result = {}
	for i = 1,ArenaDefine.MAX_ARENA_SHOP_NUM do
		if #tb <= ArenaDefine.MAX_ARENA_SHOP_NUM - i then
			break
		end
		local pos = PublicLogic.getItemByRand(tb)
		if pos and tb[pos] then
			table.insert(result,{id = tb[pos].id,buy = 0})
			tb[pos].weight = 0
		end
	end
	return result
end

function onFightValChange(hm,event)
	Arena.fightValChange(event.obj,event.hero,event.val)
end

function getLeftChallenge(human)
	local max = getMaxChallenge(human)
	return max - human.db.arena.challenge
end

function getMaxChallenge(human)
	local cnt = ArenaConstConfig[1].cnt
	return cnt
end

function resetCd(human)
	local cost = ArenaConstConfig[1].cost
	--if human:getFame() < cost then
	--	return false,ArenaDefine.ARENA_RESETCD.kNoFame
	--end
	--human:decFame(cost)
	if human:getRmb() < cost then
		return false,ArenaDefine.ARENA_RESETCD.kNoFame
	end
	human:decRmb(cost,nil,CommonDefine.RMB_TYPE.DEC_ARENA_SHOP_REFRESH)
	human.db.arena.nextTime = os.time()
	arenaQuery(human)
	human:sendHumanInfo()
	return true,ArenaDefine.ARENA_RESETCD.kOk
end
