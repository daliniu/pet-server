module(...,package.seeall)
local TreasureConfig = require("config.TreasureConfig").Config
local MineConfig = require("config.MineConfig").Config
local TDefine = require("modules.treasure.TreasureDefine")
local Msg = require("core.net.Msg")
local Treasure = require("modules.treasure.Treasure")
local HM = require("core.managers.HumanManager")
local Util = require("core.utils.Util")
local MailManager = require("modules.mail.MailManager")
local PublicLogic = require("modules.public.PublicLogic")
local PublicDefine = require("modules.public.PublicDefine")
local SkillLogic = require("modules.skill.SkillLogic")
function onCGTreasureMapInfo(human,refresh)
	if not PublicLogic.isModuleOpened(human,'treasure') then
		Msg.SendMsg(PacketID.GC_TREASURE_MAP_INFO,human,TDefine.RET_LEVEL)
		return
	end
	Treasure.updateAllMines()
	-- local rFlag = false
	-- if refresh == 1 then rFlag = true end
	Treasure.sendTreasureMapInfo(human,refresh)
	Treasure.sendTreasureChar(human)
end

function onCGTreasureMineInfo(human,mineId)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_MINE_INFO,human,TDefine.RET_NOTPERMITTED)
	end
	local t = os.time()
	mine = Treasure.Treasures[mineId]
	Treasure.updateReward(mine,t)
	Treasure.sendTreasureMineInfo(human,mineId)
	Treasure.sendTreasureChar(human)
end

--[[
function onCGTreasureFindMine(human,rankId)
	if rankId < 1 or rankId > 3 then
		Msg.SendMsg(PacketID.GC_TREASURE_FINE_MINE,human,TDefine.RET_NOTPERMITTED)
	end
	local treasure = Treasure.Treasures
	for districtId,d in ipairs(treasure) do 
		for mineId,m in ipairs(d) do
			if m.rankId == rankId and not m.account then
				-- 找到了匹配的空矿
				Msg.SendMsg(PacketID.GC_TREASURE_FIND_MINE,human,TDefine.RET_OK,rankId,districtId,mineId)
				return
			end
		end
	end
	Msg.SendMsg(PacketID.GC_TREASURE_FIND_MINE,human,TDefine.RET_NOTFOUND)
end
--]]

function onCGTreasureGuard(human,mineId,guard)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_GUARD,human,TDefine.RET_NOTPERMITTED)
	end

	if Treasure.setMineGuard(human,mineId,guard) then
		Msg.SendMsg(PacketID.GC_TREASURE_GUARD,human,TDefine.RET_OK,mineId,guard)
	else
		Msg.SendMsg(PacketID.GC_TREASURE_GUARD,human,TDefine.RET_NOTPERMITTED,mineId,guard)
	end
end

--[[
function onCGTreasureMoreTime(human,mineId)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_MORE_TIME,human,TDefine.RET_NOTPERMITTED)
	end

	local mine = Treasure.Treasures[mineId]
	if mine.account and mine.account == human.db.account then
		local curTimes = Treasure.getDayTimes(human,'extend')
		if curTimes > Treasure.getMaxExtendLimit(human) then
			Msg.SendMsg(PacketID.GC_TREASURE_MORE_TIME,human,TDefine.RET_LIMITED)
			return
		end
		-- 获得本次购买的价格
		local  price = ShopLogic.getPriceByTimes(TDefine.EXTEND_SHOPID,curTimes+1)
		if human:getRmb() < price then
			Msg.SendMsg(PacketID.GC_TREASURE_MORE_TIME,human,TDefine.RET_NOTENOUGH)
			return
		end
		human:decRmb(price)
		mine.endTime = mine.endTime + TDefine.EXTEND_DURATION
		Treasure.setDayTimes(human,'extend',os.time())
		Msg.SendMsg(PacketID.GC_TREASURE_MORE_TIME,human,TDefine.RET_OK)
		human:sendHumanInfo()
	else
		Msg.SendMsg(PacketID.GC_TREASURE_MORE_TIME,human,TDefine.RET_NOTPERMITTED)
	end
end

function onCGTreasureDoubleReward(human)
	local dtimes = Treasure.getDayTimes(human,'double')

	if dtimes >= TDefine.DOUBLE_LIMIT then
		Msg.SendMsg(PacketID.GC_TREASURE_DOUBLE_REWARD,human,TDefine.RET_LIMITED)
	else
		if human:getRmb() < TDefine.DOUBLE_RMB then
			Msg.SendMsg(PacketID.GC_TREASURE_ASSIST_INFO,human,TDefine.RET_NOTENOUGH)
			return
		end
		human:decRmb(TDefine.DOUBLE_RMB)
		local t = os.time()
		Treasure.setDayTimes(human,'double',t)
		Treasure.setVar(human,'double',t,TDefine.DOUBLE_HOUR*3600)
		local dtimes = Treasure.getDayTimes(human,'double')
		Msg.SendMsg(PacketID.GC_TREASURE_DOUBLE_REWARD,human,TDefine.RET_OK,TDefine.DOUBLE_LIMIT - dtimes)
		human:sendHumanInfo()
	end
end
--]]
function onCGTreasureAbandon(human,mineId)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_ABANDON,human,TDefine.RET_NOTPERMITTED)
	end

	local mine = Treasure.Treasures[mineId]
	if human:getAccount() ~= mine.account then
		-- 不是矿主，不能放弃该矿
		Msg.SendMsg(PacketID.GC_TREASURE_ABANDON,human,TDefine.RET_NOTPERMITTED)
		return
	end
	local t = os.time()
	mine.extendEndTime = t
	-- mine.assist[1].endTime = t
	-- mine.assist[2].endTime = t

	Treasure.updateReward(mine,t)
	---------------------
	--此处要发送奖励到邮件系统
	---------------------
	-- local mailTitle = "占领宝藏战利品"
	-- local mailContent = "请查收占领宝藏战利品"
	-- MailManager.sysSendMail(human.db.account,mailTitle,mailContent,mine.reward)

	
	Treasure.clearMine(mine)
	Treasure.sendTreasureMapInfo(human)
	Treasure.sendTreasureChar(human)
	Msg.SendMsg(PacketID.GC_TREASURE_ABANDON,human,TDefine.RET_OK,mineId)
end

function onCGTreasureSafe(human,mineId)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_SAFE,human,TDefine.RET_NOTPERMITTED)
	end
	local mine = Treasure.Treasures[mineId]
	local stimes = Treasure.getDayTimes(human,'safe')
	local  safeTimeLimit = Treasure.getMaxSafeLimit(human)
	if stimes >= safeTimeLimit then
		Msg.SendMsg(PacketID.GC_TREASURE_SAFE,human,TDefine.RET_SAFETIMES)
		return
	else
		-- 免费次数已过，现在要收费了
		local rmb = human:getRmb()
		if rmb < TDefine.SAFE_RMB then
			Msg.SendMsg(PacketID.GC_TREASURE_SAFE,human,TDefine.RET_NOTENOUGH)
			return
		end
		human:decRmb(TDefine.SAFE_RMB)
	end
	local t = os.time()
	Treasure.setDayTimes(human,'safe',t)
	Treasure.setMineVar(mine,'safe',t,TDefine.SAFE_HOUR*3600)
	local safeStartTime,safeEndTime = Treasure.getMineVar(mine,'safe')
	Msg.SendMsg(PacketID.GC_TREASURE_SAFE,human,TDefine.RET_OK,safeStartTime,safeEndTime)
end

function onCGTreasurePrepareOccupy(human,mineId)
	if Treasure.getDayTimes(human,"fight") >= TDefine.FIGHT_TIMES_PER_DAY then
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_FIGHTTIMES)
		return
	end
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_NOTPERMITTED)
		return
	end
	if Treasure.getMineNum(human) >= TDefine.MAX_MINE_PER_PLAYER then
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_LIMITED)
		return
	end
	local t = os.time()
	local mine = Treasure.Treasures[mineId]
	-- if Treasure.isInAssist(human,mine) then
	-- 	Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_ASSIST)
	-- 	return
	-- end
	if mine.status == TDefine.MINE_STATUS.Occupying and t - mine.occupyStartTime > TDefine.OCCUPYING_LIMIT_TIME then
		mine.status = TDefine.MINE_STATUS.Idle
	end


	if mine.status == TDefine.MINE_STATUS.Occupying then
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_OCCUPYING)
		return
	end
	if not mine.account then
		-- 无主之矿 发送怪物就可以了，不需要检查occupyTimes
		Treasure.setPrepareAccount(human,mine.account)
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_OK,mineId)
		return
	end

	Treasure.updateReward(mine,t)
	local miner = HM.getOnline(mine.account) or HM.loadOffline(mine.account)

	local guardList = {}
	-- local assist = {}
	if not miner then
		Treasure.setPrepareAccount(human,mine.account)
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_OK,mineId)
		return
	end
	local _,safeEndTime = Treasure.getMineVar(mine,'safe')
	if safeEndTime > t then
		-- 矿正在被保护
		Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_TARGETPROTECTED)
		return 
	end

	-- 此处是抢夺宝藏，需要处理occupyTimes
	-- 此处不再限制
	-- local occupyTimes = Treasure.getDayTimes(human,'occupy')
	-- if occupyTimes >= TDefine.OCCUPY_LIMIT then
	-- 	Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_OCCUPYTIMES)
	-- 	return 
	-- end
	for i,h in ipairs(mine.hero) do
		if h ~= '' then
			local hero = miner:getHero(h)
			hero:resetDyAttr()
			hero:calcDyAttr()
			local info = {account=mine.account,lv=hero:getLv(),quality=hero:getQuality(),name=h,dyAttr=hero.dyAttr}
			local groupList = hero:getSkillGroupList()
			local groupMsg = {}
			for _,group in pairs(groupList) do
				SkillLogic.makeSkillGroupMsg(group,groupMsg)
			end
			info.skillGroupList = groupMsg
			info.gift = hero:getGift()
			table.insert(guardList,info)
		else
			table.insert(guardList,{})
		end
	end
	-- for i=1,2 do
	-- 	local ainfo = mine.assist[i]
	-- 	if ainfo and ainfo.account then
	-- 		local assister = HM.getOnline(ainfo.account) or HM.loadOffline(ainfo.account)
	-- 		if assister then
	-- 			local hero = assister:getHero(ainfo.heroName)
	-- 			if hero then
	-- 				hero:resetDyAttr()
	-- 				hero:calcDyAttr()
	-- 				assist[i] = {account=ainfo.account,lv=hero:getLv(),quality=hero:getQuality(),
	-- 					name=h,dyAttr=hero.dyAttr}
	-- 			end
	-- 		end
	-- 	end
	-- end

	Msg.SendMsg(PacketID.GC_TREASURE_PREPARE_OCCUPY,human,TDefine.RET_OK,mineId,guardList)
	Treasure.setPrepareAccount(human,mine.account)
	-- mine.status = TDefine.MINE_STATUS.Occupying
	mine.occupyStartTime = t
	HumanManager:dispatchEvent(HumanManager.Event_Treasure,{human=human})
end

function onCGTreasureStartOccupy(human,mineId)
	if Treasure.getDayTimes(human,"fight") >= TDefine.FIGHT_TIMES_PER_DAY then
		Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_FIGHTTIMES)
		return
	end
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_NOTPERMITTED)
		return
	end
	if Treasure.getMineNum(human) >= TDefine.MAX_MINE_PER_PLAYER then
		Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_LIMITED)
		return
	end
	local t = os.time()
	local mine = Treasure.Treasures[mineId]
	-- if Treasure.isInAssist(human,mine) then
	-- 	Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_ASSIST)
	-- 	return
	-- end
	if mine.status == TDefine.MINE_STATUS.Occupying and t - mine.occupyStartTime > TDefine.OCCUPYING_LIMIT_TIME then
		mine.status = TDefine.MINE_STATUS.Idle
	end


	if mine.status == TDefine.MINE_STATUS.Occupying then
		Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_OCCUPYING)
		return
	end

	local _,safeEndTime = Treasure.getMineVar(mine,'safe')
	if safeEndTime > t then
		-- 矿正在被保护
		Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_TARGETPROTECTED)
		return 
	end
	local ret = Treasure.checkPrepareAccount(human,mine.account)
	if not ret then
		Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_PREPARE,mineId)		
		return
	end

	Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_OK,mineId)
	mine.status = TDefine.MINE_STATUS.Occupying
	mine.occupyStartTime = t
	HumanManager:dispatchEvent(HumanManager.Event_Treasure,{human=human})
end

function onCGTreasureEndOccupy(human,result,mineId,heroes)
	if Treasure.getDayTimes(human,"fight") >= TDefine.FIGHT_TIMES_PER_DAY then
		Msg.SendMsg(PacketID.GC_TREASURE_END_OCCUPY,human,TDefine.RET_FIGHTTIMES)
		return
	end
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_END_OCCUPY,human,TDefine.RET_NOTPERMITTED)
		return
	end
	local mine = Treasure.Treasures[mineId]
	local t = os.time()
	if mine.status ~= TDefine.MINE_STATUS.Occupying then
		Msg.SendMsg(PacketID.GC_TREASURE_END_OCCUPY,human,TDefine.RET_NOTPERMITTED)
		return
	end
	local onlineMiner = nil
	local miner = nil
	if mine.account then
		onlineMiner = HM.getOnline(mine.account)
		if onlineMiner then
			miner = onlineMiner
		else
			miner = HM.loadOffline(mine.account)
		end
		local _ ,safeEndTime = Treasure.getMineVar(miner,'safe')
		if safeEndTime > t then
			-- 处在保护期当中，不能被占领
			Msg.SendMsg(PacketID.GC_TREASURE_END_OCCUPY,human,TDefine.RET_TARGETPROTECTED)
			mine.status = TDefine.MINE_STATUS.Idle
			return
		end
	end

	-- 此处是抢夺宝藏，需要处理occupyTimes
	-- local occupyTimesLimit = Treasure.getMaxOccupyLimit(human)
	-- local occupyTimes = Treasure.getDayTimes(human,'occupy')
	-- if occupyTimes >= occupyTimesLimit then
	-- 	Msg.SendMsg(PacketID.GC_TREASURE_START_OCCUPY,human,TDefine.RET_OCCUPYTIMES)
	-- 	return 
	-- else
	-- 	Treasure.setDayTimes(human,'occupy',occupyTimes + 1)
	-- end
	local t = os.time()
	-- 不管成功失败，都要扣减挑战次数

	Treasure.setDayTimes(human,'fight',t)

	human:sendHumanInfo()


	--- 暂时不校验结果
	local attacker = Treasure.getHumanHero(human,heroes)
	if result == TDefine.WIN then
		-- 

		--结算收益
		
		if mine.account and miner then
			mine.extendEndTime = t

			-- 抢夺的情况，需要判断抢夺次数
			-- 取消了抢夺次数
			-- local occupyTimes = Treasure.getDayTimes(human,'occupy')
			-- if occupyTimes > TDefine.OCCUPY_LIMIT then
			-- 	Msg.SendMsg(PacketID.GC_TREASURE_END_OCCUPY,human,TDefine.RET_OCCUPYTIMES)
			-- 	return 
			-- else
			-- 	-- 增加抢夺次数
			-- 	Treasure.setDayTimes(human,'occupy',t)
			-- end

			local guard = Treasure.getHumanHero(miner,mine.hero)
			
			local reward = Treasure.updateReward(mine,t,human)
			local re = {}
			for _,r in ipairs(reward) do
				table.insert(re,{itemId=r[1],cnt=r[2]})
			end
			--矿主防御失败
			Treasure.setRecord(miner,TDefine.REC_DEFENCE_FAIL,mineId,guard,attacker,re,human)

			-- 抢夺成功
			Treasure.setRecord(human,TDefine.REC_ROB_SUCCESS,mineId,attacker,guard,{},miner)
		else
			-- 占领野矿
			Treasure.setRecord(human,TDefine.REC_OCCUPY_SUCCESS,mineId,attacker,{},{})
		end
		Treasure.clearMine(mine)
		mine.hero = heroes
		Treasure.setMineOccupier(human,mine,t,mineId)
		Treasure.sendTreasureMapInfo(human)
		Treasure.sendTreasureMineInfo(human,mineId)
		HumanManager:dispatchEvent(HumanManager.Event_Treasure,{human=human,oType="fightWin"})
	else
		
		if mine.account and miner then
			-- 防御成功
			local guard = Treasure.getHumanHero(miner,mine.hero)
			Treasure.setRecord(miner,TDefine.REC_DEFENCE_SUCCESS,mineId,guard,attacker,{},human)
		end
	end
	mine.status = TDefine.MINE_STATUS.Idle
	Msg.SendMsg(PacketID.GC_TREASURE_END_OCCUPY,human,TDefine.RET_OK,result,mineId,heroes)
	Treasure.sendTreasureChar(human)
end

--[[  策划取消了协助功能
function onCGTreasureAssist(human,cmd,mineId,heroName,assistNo)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_NOTPERMITTED,cmd)
	end
	if cmd == TDefine.CMD_DISPATCH then
		local account = human:getAccount()
		if Treasure.getAssistNum(human) >= TDefine.MAX_ASSIST_PER_PLAYER then
			Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_LIMITED,cmd)
			return
		end
		local t = os.time()
		local mine = Treasure.Treasures[mineId]
		if mine.account == human:getAccount() then 
			Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_ASSIST,cmd)
			return
		end
		if Treasure.isInAssist(human,mine) then
			-- 不能派遣两个英雄协助同一个矿
			Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_INASSIST,cmd)
			return
		end

		local ano = Treasure.getMineEmptyAssist(mine)	
		if ano > 0 then
			Treasure.setMineAssist(human,heroName,mine,ano,t)
			Treasure.sendTreasureChar(human)
			local minfo = Treasure.getMineInfo({mine})
			Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_OK,cmd,mineId,heroName,minfo[1])
			return
		else
			-- 本宝藏协助数量超过限制
			-- local acct = mine.assist[assistNo].account
			-- local heroName = mine.assist[assistNo].heroName
			-- local hero = Treasure.getHero(account,heroName)
			Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_LIMITED,cmd)
		end
	elseif cmd == TDefine.CMD_RETURN then
		local mine = Treasure.Treasures[mineId]
		local t = os.time()
		for i=1,TDefine.MAX_ASSIST_PER_MINE do
			if mine.assist[i] and mine.assist[i].account == human:getAccount() then
				Treasure.getAssistReward(mine,t,i,true)
				Treasures.clearAssist(mine,i)
			end
		end
		Msg.SendMsg(PacketID.GC_TREASURE_ASSIST,human,TDefine.RET_OK,cmd)
	end
end
--]]

function onCGTreasureChar(human)
	Treasure.sendTreasureChar(human)
end

function onCGTreasureStatus(human,mineId,status)
	if mineId < 1 or mineId > #Treasure.Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_STATUS,human,TDefine.RET_NOTPERMITTED)
		return
	end
	local mine = Treasure.Treasures[mineId]
	if not mine  then
		Msg.SendMsg(PacketID.GC_TREASURE_STATUS,human,TDefine.RET_NOTPERMITTED)
		return
	end
	
	if mine then
		if status == TDefine.MINE_STATUS.Occupying and mine.status == TDefine.MINE_STATUS.Occupying then
			Msg.SendMsg(PacketID.GC_TREASURE_STATUS,human,TDefine.RET_OCCUPYING)
		else
			mine.status = status
			if status == TDefine.MINE_STATUS.Occupying then
				mine.occupyStartTime = os.time()
			end
			Msg.SendMsg(PacketID.GC_TREASURE_STATUS,human,TDefine.RET_OK)
		end
	else
		Msg.SendMsg(PacketID.GC_TREASURE_STATUS,human,TDefine.RET_NOTPERMITTED)
	end
end

function onCGTreasureQueryOccupied(human)
	Treasure.sendOccupiedMineInfo(human)
end

function onCGTreasureRecord(human)
	Treasure.sendRecord(human)
end

function onCGTreasureMsg(human)
	
end

function onCGTreasureConsume(human,consumeId,mineId)
	local mine = Treasure.Treasures[mineId]
	if mine == nil then
		Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_NOTPERMITTED,consumeId,mineId)
		return
	end
	if mine.status == TDefine.MINE_STATUS.Occupying then
		Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_OCCUPYING,consumeId,mineId)
		return
	end
	if consumeId == TDefine.Consume.EXTEND then
		if Treasure.getDayTimes(human,"extend") >= TDefine.EXTEND_TIMES_PER_DAY then
			Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_LIMITED,consumeId,mineId)
			return
		else
			Treasure.addExtendTime(human,mineId)
			Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_OK,consumeId,mineId)
		end
	elseif consumeId == TDefine.Consume.SAFE then
		if Treasure.getDayTimes(human,"safe") >= TDefine.SAFE_TIMES_PER_DAY then
			Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_LIMITED,consumeId,mineId)
			return
		else
			Treasure.addSafeTime(human,mineId)
			Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_OK,consumeId,mineId)
		end
	elseif consumeId == TDefine.Consume.DOUBLE then
		if Treasure.getDayTimes(human,"double") >= TDefine.DOUBLE_TIMES_PER_DAY then
			Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_LIMITED,consumeId,mineId)
			return
		else
			Treasure.addDoubleTime(human,mineId)
			Msg.SendMsg(PacketID.GC_TREASURE_CONSUME,human,TDefine.RET_OK,consumeId,mineId)
		end
	end
end