module(...,package.seeall)
local TreasureConfig = require("config.TreasureConfig").Config
local MonsterConfig = require("config.MonsterConfig").Config
local TreasureMonsterConfig = require("config.TreasureMonsterConfig").Config
local DB = require("core.db.DB")
local Util = require("core.utils.Util")
local Msg = require("core.net.Msg")
local TDefine = require("modules.treasure.TreasureDefine")
local SkillLogic = require("modules.skill.SkillLogic")
local ItemConfig = require("config.ItemConfig").Config
local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")
local MailManager = require("modules.mail.MailManager")
local HeroManager = require("modules.hero.HeroManager")
local PublicLogic = require("modules.public.PublicLogic")

Treasures = Treasures or {}
MineCnt = MineCnt or 100
local ns = 'treasure'

function onHumanLogin(hm,human)
	sendTreasureChar(human,0)
end
function onHumanDBLoad(hm,human)

end
local HM = require("core.managers.HumanManager")
HM:addEventListener(HM.Event_HumanLogin,onHumanLogin)
HM:addEventListener(HM.Event_HumanDBLoad,onHumanDBLoad)


function init()
	loadDB()
	MineCnt = getTreasureMineCount()
	setTreasureMineCount(MineCnt,true)
	local timer = Timer.new(10*60*1000,-1)
	timer:setRunner(save)
	timer:start()
end

function inDBcheck()
	for _,mine in ipairs(Treasures) do 
		if mine.reward then
			local ids = {}
			for itemId,cnt in pairs(mine.reward) do
				if type(itemId) == 'number' then
					table.insert(ids,itemId)
				end
			end
			for _,id in ipairs(ids) do 
				mine.reward[tostring(id)] = mine.reward[id]
				mine.reward[id] = nil
			end
		end
		-- if mine.assist then
		-- 	for _,a in ipairs(mine.assist) do
		-- 		if a.reward then
		-- 			for itemId,cnt in pairs(a.reward) do
		-- 				if type(itemId) == 'number' then
		-- 					a.reward[tostring(itemId)] = cnt
		-- 					a.reward[itemId] = nil
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		-- end
	end
end

function outDBcheck()
	for _,mine in ipairs(Treasures) do 
		if mine.reward then
			local ids = {}
			for itemId,cnt in pairs(mine.reward) do
				if type(itemId) == 'string' then
					table.insert(ids,itemId)
				end
			end
			for _,id in ipairs(ids) do
				mine.reward[tonumber(id)] = mine.reward[id]
				mine.reward[id] = nil
			end 
		end
		-- if mine.assist then
		-- 	for _,a in ipairs(mine.assist) do
		-- 		if a.reward then
		-- 			for itemId,cnt in pairs(a.reward) do
		-- 				if type(itemId) == 'string' then
		-- 					a.reward[tonumber(itemId)] = cnt
		-- 					a.reward[itemId] = nil
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		-- end
	end
end


function save(isSync)
	-- updateAllMines()
	if isSync == nil then
		updateAllMines()
	end
	inDBcheck()
	local query = {module='treasure'}
	DB.Update(ns,query,{module='treasure',db=Treasures},isSync)
	outDBcheck()
end

function setTreasureMineCount(cnt,noUpdate)
	local c = math.min(math.max(cnt,TDefine.MIN_MINE_CNT),TDefine.MAX_MINE_CNT)
	MineCnt = c
	if not noUpdate then
		DB.Update(ns,{module='treasure_mine'},{cnt=c,module='treasure_mine'})
	end
	local t = os.time()
	local tre = Treasures
	local targetCnt = MineCnt
	print('targetCnt='..targetCnt.." #tre="..#tre)
	if targetCnt >= #tre then
		-- 需要扩充区域
		for i=1,targetCnt do
			if tre[i] == nil or not next(tre[i]) then
				tre[i] = {}
				createMine(i,tre[i])
			else
				local mine = tre[i]
				if isMineOccupied(mine) and noUpdate == nil  then
					updateReward(mine,t)
				end
			end
		end
	else
		-- 需要减少区域
		for i=1,#tre do
			if tre[i] == nil or not next(tre[i]) then
				tre[i] = {}
				createMine(i,tre[i])
			else
				local mine = tre[i]
				if isMineOccupied(mine) and noUpdate == nil then
					updateReward(mine,t)
				end
			end
		end
		for i = #tre,targetCnt+1,-1 do 
			local emptyFlag = true
			local mine = tre[i]
			if isMineOccupied(mine) then
				break
			else
				tre[i] = nil
			end
		end
	end
end

function getTreasureMineCount()
	local query = {module='treasure_mine'}
    local pCursor = g_oMongoDB:SyncFind(ns,query)
    if not pCursor then
        return false
    end
    local Cursor = MongoDBCursor(pCursor)
	local row = {}
    if Cursor:Next(row) then
		return row.cnt
    else
    	g_oMongoDB:SyncInsert(ns,{module='treasure_mine',cnt=TDefine.DEF_MINE_CNT})
    	return TDefine.DEF_MINE_CNT
    end
end


function loadDB()
	local query = {module='treasure'}
    local pCursor = g_oMongoDB:SyncFind(ns,query)
    if not pCursor then
        return false
    end
    local Cursor = MongoDBCursor(pCursor)
	local row = {}
    if not Cursor:Next(row) then
		g_oMongoDB:SyncInsert(ns,{module='treasure',db=Treasures})
	else
		Treasures = row.db
    end
    if Treasures == nil then Treasures = {} end
    outDBcheck()
	return true
end




function initHuman(human)
	if human.db.Treasure == nil then
		human.db.Treasure = {extendTimes=0,lastExtend=0}
	end
end

function isInSafe(human,t)
	local _,etime = getVar(human,'safe')
	return etime > t
end

function getMineVar(mine,var)
	mine[var..'StartTime'] = mine[var..'StartTime'] or 0
	mine[var..'EndTime'] = mine[var..'EndTime'] or 0
	return mine[var..'StartTime'],mine[var..'EndTime']
end
function setMineVar(mine,var,t,moresec)
	mine[var..'EndTime'] = mine[var..'EndTime'] or 0
	mine[var..'StartTime'] = mine[var..'StartTime'] or 0
	if mine[var..'EndTime'] > t then
		mine[var..'EndTime'] = mine[var..'EndTime'] + moresec
	else
		mine[var..'EndTime'] = t + moresec
		mine[var..'StartTime'] = t
	end
end

function clearMineVar(mine,var)
	mine[var..'EndTime'] = 0
	mine[var..'StartTime'] = 0
end

function clearDayTimes(human,var)
	local db = human.db.Treasure
	db[var..'Times'] = 0
	-- db['last'..var] = 0
end

function setDayTimes(human,var,t)
	local db = human.db.Treasure
	if Util.isToday(db['last'..var]) then
		db[var..'Times'] = db[var..'Times'] + 1
		db['last'..var] = t
	else
		db[var..'Times'] = 1
		db['last'..var] = t
	end
end

function deleteDayTimes(human,var,times)
	local db = human.db.Treasure
	local curT = getDayTimes(human,var)
	db[var.."Times"] = curT - times
end

-- 支持三种次数  
-- extend 延长占领次数
-- double 双倍收益次数
-- rob    当天占领次数
function getDayTimes(human,var)
	local db = human.db.Treasure
	if Util.isToday(db['last'..var]) then
		return db[var..'Times']
	else
		db['last'..var] = os.time()
		db[var.."Times"] = 0
		return 0
	end
end

function addFightTimes(human)
	deleteDayTimes(human,"fight",1)
	sendTreasureChar(human)
end

function addRefreshMapTimes(human)
	deleteDayTimes(human,"refreshMap",1)
	sendTreasureChar(human)
end

function addDoubleTime(human,mineId)
	-- 增加一次双倍收益时间
	local t = os.time()
	local mine = Treasures[mineId]
	if mine then
		setDayTimes(human,'double',t)
		setMineVar(mine,'double',t,TDefine.DOUBLE_DURATION)
		sendTreasureChar(human)
		sendTreasureMineInfo(human,mineId)
	end
end

function addSafeTime(human,mineId)
	local t = os.time()
	local mine = Treasures[mineId]
	if mine then
		setDayTimes(human,'safe',t)
		setMineVar(mine,'safe',t,TDefine.SAFE_DURATION)
		sendTreasureChar(human)
		sendTreasureMineInfo(human,mineId)
	end
end

function addExtendTime(human,mineId)
	local t = os.time()
	local mine = Treasures[mineId]
	if mine then
		if mine.extend == nil then mine.extend = 0 end
		setDayTimes(human,'extend',t)
		setMineVar(mine,'extend',t,TDefine.SAFE_DURATION)
		sendTreasureChar(human)
		sendTreasureMineInfo(human,mineId)
		mine.extend = mine.extend + 1
	end
end

-- function setStartDoubleTime(human,t)
-- 	local db = human.db.Treasure
-- 	db.Treasure.startDoubleTime = t
-- end

--[[ 取消协助
function getAssistReward(mine,t,no,bFinish)
	if mine.assist[no].rewardTime == 0 or (t - mine.assist[no].rewardTime < TDefine.REWARD_CYCLE and bFinish==false) then
		return
	end
	function calcAssistReward(assist,times)
		local rewardConf = mine.product
		if assist.reward == nil then assist.reward = {} end
		for itemId,cnt in pairs(rewardConf.exp) do
			if assist.reward[itemId] then
				assist.reward[itemId] = assist.reward[itemId] + cnt*times*TDefine.ASSIST_REWARD_RATE
			else
				assist.reward[itemId] = cnt*times*TDefine.ASSIST_REWARD_RATE
			end
		end
		for itemId,rate in pairs(rewardConf.frag) do 
			local rand = math.random(1,100)
			if rand < rate*times*TDefine.ASSIST_REWARD_RATE then
				if assist.reward[itemId] then
					assist.reward[itemId] = assist.reward[itemId] + 1
				else
					assist.reward[itemId] = 1
				end
			end
		end
	end
	local dur = t - mine.assist[no].rewardTime
	while dur > TDefine.REWARD_CYCLE do
		dur = dur - TDefine.REWARD_CYCLE
		calcAssistReward(mine.assist[no],1)
		mine.assist[no].rewardTime = mine.assist[no].rewardTime +  TDefine.REWARD_CYCLE
	end
	if bFinish then
		-- 占领到期
		calcAssistReward(mine.assist[no],dur/ TDefine.REWARD_CYCLE)
		mine.assist[no].rewardTime = mine.assist[no].endTime
		local assistHuman = HM.getOnline(mine.assist[no].account) or HM.loadOffline(mine.assist[no].account)
		local title = '协助宝藏战利品'
		local content = '领取协助宝藏战利品'
		MailManager.sysSendMail(assistHuman:getAccount(),title,content,rewardList(mine.assist[no].reward))
		clearAssist(assistHuman,mine)
	end
end
function isInAssist(human,mine)
	--本玩家是否正在协助这个宝藏
	for a=1,2 do
		if mine and mine.assist and mine.assist[a].account == human:getAccount() then
			return true
		end
	end
	return false
end
--]]

function getHero(account,name)
	-- 返回account玩家的name英雄
	local human = HM.getOnline(account) or HM.loadOffline(account)
	if human then
		local hero = human:getHero(name)
		if hero then
			hero:resetDyAttr()
			hero:calcDyAttr()
			local groupList = hero:getSkillGroupList()
			local groupListMsg = {}
			for _,group in pairs(groupList) do
				SkillLogic.makeSkillGroupMsg(group,groupListMsg)
			end
			return {account=account,lv=hero:getLv(),quality=hero:getQuality(),
					name=name,dyAttr=hero.dyAttr,skillGroupList=groupListMsg}
		end
	end
end

function rewardList(reward,rate)
	if rate == nil then rate = 1 end
	local r = {}
	for itemId,cnt in pairs(reward) do 
		table.insert(r,{itemId,math.floor(cnt*rate)})
	end
	return r
end
function rewardListMinute(reward1,reward2)
	local r = {}
	for itemId,cnt in pairs(reward1) do
		if reward2[itemId] and cnt > reward2[itemId] then
			table.insert(r,{itemId,cnt > reward2[itemId]})
		end
	end
	return r
end

-- function getReward(mine,t,occupier)
-- 	if mine.rewardTime == 0 or (t - mine.rewardTime <  TDefine.REWARD_CYCLE and t < mine.extendEndTime) then
-- 		return
-- 	end
-- 	local miner = HM.getOnline(mine.account) or HM.loadOffline(mine.account)
-- 	local dur = mine.extendEndTime - mine.rewardTime
-- 	local function calcReward(mine,times)
-- 		local rewardConf = mine.product
-- 		-- local extraGain = TDefine.MINE_RANK[mine.rankId].rate
-- 		for itemId,cnt in pairs(rewardConf.exp) do
-- 			if ItemConfig[itemId] then
-- 				local gain = cnt*times
-- 				if mine.reward[itemId] then
-- 					mine.reward[itemId] = mine.reward[itemId] + gain
-- 				else
-- 					mine.reward[itemId] = gain
-- 				end
-- 			end
-- 		end
-- 		for itemId,rate in pairs(rewardConf.frag) do 
-- 			if ItemConfig[itemId] then
-- 				local rand = math.random(1,100)
-- 				if rand < rate*times then
-- 					if mine.reward[itemId] then
-- 						mine.reward[itemId] = mine.reward[itemId] + 1
-- 					else
-- 						mine.reward[itemId] = 1
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end

-- 	local function calcRewardByDuration(mine,stime,etime)
-- 		-- stime 开始时间
-- 		-- etime 结束时间
-- 		-- 根据时间段计算收益

-- 		--计算这一个时段内的双倍收益时长
-- 		local s,e = getMineVar(mine,'double')
-- 		local maxS = math.max(s,stime)
-- 		local minE = math.min(e,etime)
-- 		local doubleDur = minE - maxS
-- 		local d = etime - stime
-- 		if doubleDur > 0 then
-- 			d = d + doubleDur
-- 		end
-- 		calcReward(mine,d/ TDefine.REWARD_CYCLE)
-- 	end

-- 	while dur >  TDefine.REWARD_CYCLE do
-- 		dur = dur -  TDefine.REWARD_CYCLE
-- 		calcRewardByDuration(mine,mine.rewardTime,mine.rewardTime+ TDefine.REWARD_CYCLE)
-- 		mine.rewardTime = mine.rewardTime +  TDefine.REWARD_CYCLE
-- 	end

-- 	if t >= mine.extendEndTime then
-- 		-- 占领到期
-- 		calcRewardByDuration(mine,mine.rewardTime,mine.extendEndTime)
-- 		mine.rewardTime = mine.extendEndTime


-- 		local mailTitle = "宝藏占领到期"
-- 		if occupier then
-- 			mailTitle = "宝藏被别人占领"
-- 		end
-- 		local my_reward = rewardList(mine.reward)
-- 		MailManager.sysSendMail(miner:getAccount(),mailTitle,'领取宝藏战利品',my_reward)

-- 		-- for i=1,2 do
-- 		-- 	if mine.assist[i] and mine.assist[i].account then
-- 		-- 		local assister = HM.getOnline(mine.assist[i].account) or HM.loadOffline(mine.assist[i].account)
-- 		-- 		if assister then
-- 		-- 			-------------------------------
-- 		-- 			--  此处要发送邮件，但是邮件系统还没有，暂时空着
-- 		-- 			-------------------------------
-- 		-- 			local mailTitle = "协助宝藏战利品"
-- 		-- 			local mailContent = "请查收协助宝藏战利品"
-- 		-- 			MailManager.sysSendMail(assister.db.account,mailTitle,mailContent,rewardList(mine.assist[i].reward))
-- 		-- 		end
-- 		-- 	end
-- 		-- end

-- 		clearMine(mine)
-- 	end
-- end

-- function getAssistNo(mine,districtId,mineId)
-- 	-- 获得第几个assist对应这个宝藏
-- 	local no = 0
-- 	for i=1,2 do
-- 		if mine.assist[i] and mine.assist[i].districtId and mine.assist[i].districtId==districtId and mine.assist[i].mineId and mine.assist[i].mineId == mineId then
-- 			dd = i
-- 			break
-- 		end
-- 	end
-- 	return no
-- end

--[[取消协助
function getAssistNum(human)
	local num = 0
	local account = human.db.account
	for i,mine in Treasures do
		if mine.assist and #mine.assist > 0 then
			for a =1,TDefine.MAX_ASSIST_PER_PLAYER do
				if mine.assist[a] and mine.assist[a].account and mine.assist[a].account == account then
					num = num + 1
				end
			end
		end
	end
	return num
end

function getAssistList(human)
	local assistList = {}
	local account = human.db.account
	for i,mine in ipairs(Treasures) do
		if mine.assist and #mine.assist > 0 then
			for a =1,TDefine.MAX_ASSIST_PER_PLAYER do
				if mine.assist[a] and mine.assist[a].account and mine.assist[a].account == account then
					assistList[#assist+1] = mine
				end
			end
		end
	end
	return assistList
end

-- function getAssistNum(account)
-- 	local anum = 0
-- 	for i=1,3 do 
-- 		for districtId,d in ipairs(Treasures[i]) do 
-- 			for mineId,m in ipairs(Treasures[i][districtId]) do
-- 				for a=1,2 do 
-- 					if m.assist[a] and m.assist[a].account == account then
-- 						anum = anum + 1
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return anum
-- end
--]]


function updateReward(mine,t,occupier)
	if mine.rewardTime == nil or mine.rewardTime == 0 then mine.rewardTime = mine.extendStartTime end
	if mine.rewardTime == 0 or (t - mine.rewardTime <  TDefine.REWARD_CYCLE and t < mine.extendEndTime) then
		return
	end
	local mineId = mine.mineId
	local miner = HM.getOnline(mine.account) or HM.loadOffline(mine.account)
	local dur = mine.extendEndTime - mine.rewardTime

	-- 计算奖励
	local cfg = TreasureConfig[mineId]
	local function calcReward()
		-- local extraGain = TDefine.MINE_RANK[mine.rankId].rate
		local rr = PublicLogic.randReward(cfg.randomProduct)
		for itemId,item in pairs(cfg.fixProduct) do 
			if rr[itemId] then
				rr[itemId] = rr[itemId] + item[1] 
			else
				rr[itemId] = item[1] 
			end
		end
		return rr
	end

	local function doubleReward(reward)
		for itemId,cnt in pairs(reward) do
			reward[itemId] = 2*reward[itemId]
		end
	end
	local function isInDouble(mine,t)
		local s,e = getMineVar(mine,"double")
		if s > 0 and e > 0 and t >= s and t <= e then
			return true
		else
			return false
		end
	end

	local function addReward(mine,reward)
		if mine.reward == nil then mine.reward = {} end
		for itemId,cnt in pairs(reward) do 
			if mine.reward[itemId] then
				mine.reward[itemId] = mine.reward[itemId] + cnt
			else
				mine.reward[itemId] = cnt
			end
		end
	end

	while mine.rewardTime + TDefine.REWARD_CYCLE <= t do
		mine.rewardTime = mine.rewardTime + TDefine.REWARD_CYCLE
		local r = calcReward()
		if isInDouble(mine,mine.rewardTime) then
			doubleReward(r)
		end
		addReward(mine,r)
	end
	local my_reward = rewardList(mine.reward)
	local function getRecordReward(r)
		local reward = {}
		for itemId,cnt in pairs(r) do 
			table.insert(reward,{itemId=itemId,cnt=cnt})
		end
		return reward
	end
	if t >= mine.extendEndTime then
		-- 占领到期
		local mineName = TDefine.MINE_RANK[mine.mineType].name
		if occupier then
			if #my_reward > 0 then
				-- MailManager.sysSendMail(miner:getAccount(),'宝藏被他人占领','领取宝藏战利品',my_reward)
				MailManager.sysSendMailById(mine.account, TDefine.DEFEATED_MAIL_ID, my_reward,mineName, occupier:getName())
			end
		else
			if #my_reward > 0 then
				-- MailManager.sysSendMail(miner:getAccount(),'宝藏占领到期','领取宝藏战利品',my_reward)
				MailManager.sysSendMailById(mine.account, TDefine.FINISH_MAIL_ID, my_reward,mineName)
			end
			local guard = getHumanHero(miner,mine.hero)
			local r = getRecordReward(mine.reward)
			setRecord(miner,TDefine.REC_FINISH,mine.mineId,guard,{},r)
		end
		clearMine(mine)
		return my_reward
	end
	
end


-- function updateMineById(districtId,mineId)
-- 	local t = os.time()
-- 	if Treasures[districtId] == nil or Treasures[districtId][mineId] == nil then
-- 		return
-- 	end
-- 	local mine = Treasures[districtId][mineId]
-- 	updateReward(mine,t)
-- end
function clearTable(tbl)
	if tbl then
		for k,_ in pairs(tbl) do
			tbl[k] = nil
		end
	end
end

--[[取消协助
function clearAssist(mine,no)
	--回收mine的第no个协助
	if mine.assist and #mine.assist>= no then
		mine.assist[no].account = 0
		mine.rewardTime = 0
		mine.heroName = nil
		clearTable(mine.reward)
	end
end
--]]


function clearMine(mine)
	local miner
	if mine.account and mine.account ~= "" then
		miner = HM.getOnline(mine.account)
	end
	mine.extendStartTime = 0
	mine.extendEndTime = 0
	clearMineVar(mine,"double")
	clearMineVar(mine,"extend")
	clearMineVar(mine,"safe")
	mine.account = nil
	mine.charName = nil 
	mine.rewardTime = 0
	mine.extend = 0
	mine.lv = 0
	clearTable(mine.reward)
	clearTable(mine.hero)
	if miner then
		sendTreasureChar(miner)
	end
	--[[取消协助
	for a=1,2 do
		clearAssist(mine,a)
	end
	--]]
end



function setMineOccupier(human,mine,t)
	clearMineVar(mine,"extend")
	setMineVar(mine,"extend",t,TDefine.EXTEND_DURATION)
	clearMineVar(mine,"double")
	clearMineVar(mine,"safe")
	mine.account = human:getAccount()
	mine.charName = human:getName()
	mine.rewardTime = t
	mine.lv = human:getLv()
	mine.time = t
end
--[[取消协助
function setMineAssist(human,heroName,mine,ano,t)
	if not mine.assist[ano] then
		mine.assist[ano] = {startTime=0,account=nil,heroName=nil,rewardTime=0,reward={},lv=0}
	end
	local miner = HM.getOnline(mine.account) or HM.loadOffline(mine.account)
	mine.assist[ano].account = human:getAccount()
	local charName = string.format("%s 等级 %d %s",TDefine.MINE_RANK[mine.rankId].name,miner:getLv(),miner:getName())
	mine.assist[ano].startTime = t
	mine.assist[ano].rewardTime = t
	mine.assist[ano].reward = {}
	mine.assist[ano].charName = human:getName()
	local hero = human:getHero(heroName)
	if hero then
		mine.assist[ano].heroName = heroName
		mine.assist[ano].lv = hero:getLv()
	end
end
function getMineEmptyAssist(mine)
	local ano = 0
	for i=1,TDefine.MAX_ASSIST_PER_MINE do
		if not mine.assist[i] or not mine.assist[i].account or mine.assist[i].account == '' then
			ano = i
			break
		end
	end
	return ano
end
--]]

function createMine(mineId,mine)
	local id = mineId % #TreasureConfig
	if id == 0 then
		id = #TreasureConfig
	end
	local conf = TreasureConfig[id]
	mine.rankId = conf.rankId
	mine.mineType = conf.mineType
	mine.status = TDefine.MINE_STATUS.Idle
	mine.mineId = mineId
	mine.reward = {}
	mine.hero = {}
	clearMineVar(mine,"extend")
	mine.rewardTime = 0
	mine.extend = 0
end

function isMineOccupied(mine)
	if mine.account and mine.account ~= '' then
		return true
	else
		return false
	end
end


function updateAllMines()
	local t = os.time()
	for _,m in ipairs(Treasures) do 
		if isMineOccupied(m) then
			updateReward(m,t)
		end
	end
end

function getSingleMineInfo(mine)
	local info = {}
	info.mineType = mine.mineType
	info.mineId = mine.mineId
	info.rankId = mine.rankId
	local reward = {}
	if mine.reward then
		for itemId,cnt in pairs(mine.reward) do
			table.insert(reward,{itemId=itemId,cnt=cnt})
		end
	end
	info.reward = reward

	--[[取消协助
	local assist = {}
	if mine.assist then
		for _,a in ipairs(mine.assist) do
			if a.charName then
				table.insert(assist,a.charName)
			end
		end
	end
	--]]
	local miner,lv,safeEndTime
	if mine.account then
		miner = HM.getOnline(mine.account) or HM.loadOffline(mine.account)
		lv = miner:getLv()
	else
		lv = 0
	end

	info.startTime = mine.extendStartTime
	info.endTime = mine.extendEndTime
	info.account = mine.account
	info.charName = mine.charName
	info.extend = mine.extend
	info.lv = lv
	-- info.assist = assist
	info.safeStartTime = mine.safeStartTime
	info.safeEndTime = mine.safeEndTime
	info.doubleStartTime = mine.doubleStartTime
	info.doubleEndTime = mine.doubleEndTime
	info.guard = getHumanHero(miner,mine.hero)
	-- if mine.hero then
	-- 	for i,h in ipairs(mine.hero) do
	-- 		if h ~= '' and miner then
	-- 			local hero = miner:getHero(h)
	-- 			local g = {name=h,lv=hero:getLv(),quality=hero:getQuality(),power=hero:getFight()}
	-- 			table.insert(info.guard,g)
	-- 		else
	-- 			table.insert(info.guard,{name=""})
	-- 		end
	-- 	end
	-- end

	return info
end


function getHumanHero(human,heroes)
	local guard = {}
	if heroes then
		for i,h in ipairs(heroes) do
			if h ~= '' and human then
				local hero = human:getHero(h)
				local g = {name=h,lv=hero:getLv(),quality=hero:getQuality(),power=hero:getFight()}
				table.insert(guard,g)
			else
				table.insert(guard,{name=""})
			end
		end
	end
	return guard
end

function getSimpleMineInfo(mineList)
	local mlist = {}
	for i,mine in ipairs(mineList) do
		local info = {}
		local s,e = getMineVar(mine,"safe")
		info.safeStartTime = s
		info.safeEndTime = e
		info.account = mine.account
		info.charName = mine.charName
		info.mineType = mine.mineType
		info.rankId = mine.rankId
		info.mineId = mine.mineId
		info.extend = mine.extend
		info.startTime = mine.extendStartTime
		info.endTime = mine.extendEndTime
		table.insert(mlist,info)
	end
	return mlist
end

function getMineInfo(mineList)
	local mlist = {}
	for i,mine in ipairs(mineList) do
		local info = getSingleMineInfo(mine)
		table.insert(mlist,info)
	end
	return mlist
end




-- function sendMineInfo(human,mineList)
-- 	local mlist = getMineInfo(mineList)
-- 	Msg.SendMsg(PacketID.GC_TREASURE_MINE_INFO,human,TDefine.RET_OK,mlist)
-- end

function getMineNum(human)
	local num = 0
	for _,mine in ipairs(Treasures) do
		if mine.account and mine.account == human:getAccount() then
			num = num + 1
		end
	end
	return num
end

function getMineListByHuman(human)
	-- local mineList = {}
	-- local dd = human.db.Treasure
	-- for i=1,TDefine.MAX_MINE_PER_PLAYER do
	-- 	if dd.mine and dd.mine[i] and dd.mine[i].districtId and dd.mine[i].districtId > 0 and dd.mine[i].mineId and dd.mine[i].mineId > 0 then
	-- 		local districtId = dd.mine[i].districtId
	-- 		local mineId = dd.mine[i].mineId
	-- 		if Treasures[districtId] and Treasures[districtId][mineId] and Treasures[districtId][mineId].account == human:getAccount() then
	-- 			table.insert(mineList,Treasures[districtId][mineId])
	-- 		else
	-- 			dd.mine[i].districtId = 0 
	-- 			dd.mine[i].mineId = 0
	-- 		end
	-- 	end
	-- end
	-- return mineList

	local mineList = {}
	local t = Treasures
	for _,mine in ipairs(Treasures) do
		if mine.account and mine.account == human:getAccount() then
			table.insert(mineList,mine)
		end
	end
	return mineList
end

function sendOccupiedMineInfo(human)
	local mineList = getMineListByHuman(human)
	local mlist = getMineInfo(mineList)
	Msg.SendMsg(PacketID.GC_TREASURE_QUERY_OCCUPIED,human,TDefine.RET_OK,mlist)
end

function sendTreasureMineInfo(human,mineId)
	if mineId < 1 or mineId > #Treasures then
		Msg.SendMsg(PacketID.GC_TREASURE_MINE_INFO,human,TDefine.RET_NOTPERMITTED)
		return
	end
	local mine = Treasures[mineId]
	local mineInfo = getSingleMineInfo(mine)

	Msg.SendMsg(PacketID.GC_TREASURE_MINE_INFO,human,TDefine.RET_OK,mineInfo)
end

function getMaxExtendLimit(human)
	return VipLogic.getVipAddCount(human, VipDefine.VIP_TREASURE_EXTEND)
end

function getMaxDoubleLimit(human)
	return VipLogic.getVipAddCount(human, VipDefine.VIP_TREASURE_DOUBLE)
end

function getMaxOccupyLimit(human)
	return VipLogic.getVipAddCount(human, VipDefine.VIP_TREASURE_DOUBLE)
end

function getMaxSafeLimit(human)
	return VipLogic.getVipAddCount(human, VipDefine.VIP_TREASURE_DOUBLE)
end



function getRandomMine(self)
	local mineNum = #Treasures
	local lastId = 0
	local mList = {}
	local arr = {}
	for i=1,mineNum do 
		arr[i] = i
	end
	for i=1,TDefine.MINE_NUM_PER_BATCH do
		table.insert(mList,table.remove(arr,math.random(#arr)))
	end
	-- for i=1,TDefine.MINE_NUM_PER_BATCH do
	-- 	local rand = math.random(mineNum)
	-- 	if lastId == 0 then 
	-- 		mDict[rand] = 1
	-- 	else
	-- 		if rand +lastId <= mineNum then
	-- 			rand = rand + lastId
	-- 		else
	-- 			rand = (lastId + rand)%mineNum
	-- 		end
	-- 		local r = 0
	-- 		for k=0,mineNum-1 do 
	-- 			r  = (rand + k)%mineNum
	-- 			if r == 0 then r = mineNum end
	-- 			if mDict[r] == nil then
	-- 				break
	-- 			end
	-- 		end
	-- 		mDict[r] = 1
	-- 	end
	-- 	lastId = rand
	-- end
	-- for id,_ in pairs(mDict) do 
	-- 	table.insert(mList,id)
	-- end

	-- local sMine = math.random(mineNum)
	-- local sMine = math.random(10)
	
	-- for i=1,TDefine.MINE_NUM_PER_BATCH do
	-- 	mlist[#mlist+1] = math.max(1,(sMine+i)%mineNum)
	-- end
	return mList
end

function sendTreasureMapInfo(human,refresh)
	local t = os.time()
	local tdb = human.db.Treasure
	if tdb.mapList == nil then
		tdb.mapList = {}
	end
	local mineInfoList
	if tdb.mapInfoTime == nil then tdb.mapInfoTime = 0 end
	local function mapListValid()
		if #tdb.mapList == 0 then
			return false
		end
		for _,mid in ipairs(tdb.mapList) do
			if mid > #Treasures then
				return false
			end
		end
		return true
	end
	if not mapListValid() then
		tdb.mapList = getRandomMine()
		tdb.mapInfoTime = t
	end
	if refresh == 1 then
		tdb.mapList = getRandomMine()
		tdb.mapInfoTime = t
		setDayTimes(human,'refreshMap',t)
	end
	if t - tdb.mapInfoTime >TDefine.FORCE_REFRESH_INTERVAL then
		tdb.mapList = getRandomMine()
		tdb.mapInfoTime = t
	end

	local function getMineListById(mineList)
		local list = {}
		for i,mineId in ipairs(mineList) do
			local mine = Treasures[mineId]
			table.insert(list,mine)
		end
		return getSimpleMineInfo(list)

	end
	mineInfoList = getMineListById(tdb.mapList)
	Msg.SendMsg(PacketID.GC_TREASURE_MAP_INFO,human,TDefine.RET_OK,refresh,tdb.mapInfoTime,mineInfoList)
end

function setMineGuard(human,mineId,guard)
	-- for _,name in ipairs(guard) do
	-- 	if name ~= "" and (not HeroManager.getHero(human,name)) then
	-- 		return false
	-- 	end
	-- end
	local mine = Treasures[mineId]
	if mine and mine.account and mine.account == human:getAccount() then
		mine.hero = guard
		return true
	else
		return false
	end
end

function sendTreasureMsg(human,msg)
	Msg.SendMsg(PacketID.GC_TREASURE_MSG,human,msg)
end
function sendTreasureChar(human)
	local db = human.db.Treasure
	local mineInfoList = {}
	local mineList = getMineListByHuman(human)
	mineInfoList = getMineInfo(mineList)
	local fightTimes = getDayTimes(human,"fight")
	local extendTimes = getDayTimes(human,"extend")
	local safeTimes = getDayTimes(human,"safe")
	local doubleTimes = getDayTimes(human,"double")
	local refreshMapTimes = getDayTimes(human,"refreshMap")
	-- local assistInfoList = {}
	-- local assistList = getAssistList(human)

	Msg.SendMsg(PacketID.GC_TREASURE_CHAR,human,fightTimes,extendTimes,safeTimes,doubleTimes,refreshMapTimes,mineInfoList)
end

function shrinkRecord(human)
	-- 根据指定的条件，缩减对战记录
	local db = human.db.Treasure
	if db.record == nil then db.record = {} end
	local cnt= 0
	local time = os.time() - TDefine.REC_RESERVE_DAY*24*3600
	if #db.record > TDefine.REC_RESERVE_CNT then
		cnt = #db.record - TDefine.REC_RESERVE_CNT
	end

	for i,rec in ipairs(db.record) do 
		if rec.dt < time or i <= cnt then
			table.remove(db.record,1)
		end
	end
end

function setRecord(human,recType,mineId,hero1,hero2,reward,ohuman)
	local db = human.db.Treasure
	if db.record == nil then db.record = {} end
	-- if recType == TDefine.REC_FINISH or recType == TDefine.REC_DEFENCE_FAIL or  then
	if recType ~= TDefine.REC_DEFENCE_SUCCESS then
		for _,rec in ipairs(db.record) do 
			if rec.mineId == mineId then
				rec.closed = 1
			end
		end
	end
	if ohuman == nil then
		table.insert(db.record,{dt=os.time(),body1=human:getBodyId(), recType=recType,mineId=mineId,hero1=hero1,lv1=human:getLv(),name1=human:getName(),reward=reward,closed=0})
	else
		table.insert(db.record,{dt=os.time(),body1=human:getBodyId(),body2=ohuman:getBodyId(),recType=recType,mineId=mineId,hero1=hero1,hero2=hero2,lv1=human:getLv(),lv2=ohuman:getLv(),name1=human:getName(),name2=ohuman:getName(),reward=reward,closed=0})
	end
end

function sendRecord(human)
	shrinkRecord(human)
	local db = human.db.Treasure
	if db.record == nil then db.record = {} end
	local record = {}
	for i=#db.record,1,-1 do 
		local rec = db.record[i]
		table.insert(record,{recType=rec.recType,dt=rec.dt,mineId = rec.mineId,lv1=rec.lv1,lv2=rec.lv2,name1=rec.name1,name2=rec.name2,hero1=rec.hero1,hero2=rec.hero2,reward = rec.reward,body1=rec.body1,body2=rec.body2,closed=rec.closed})
	end
	Msg.SendMsg(PacketID.GC_TREASURE_RECORD,human,record)
end

function setPrepareAccount(human,account)
	if account == nil then account = "" end
	human.db.Treasure.prepareAccount = account
end

function checkPrepareAccount(human,account)
	if account == nil then account = "" end
	return human.db.Treasure.prepareAccount == account
end