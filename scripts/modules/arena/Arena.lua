module(...,package.seeall)

local ArenaDefine = require("modules.arena.ArenaDefine")
local SaveQueue = require("modules.arena.ArenaSave")
local GuildManager = require("modules.guild.GuildManager")
local ArenaRobotConfig = require("config.ArenaRobotConfig").Config
local ArenaRobot = require("modules.arena.ArenaRobot")
local ArenaEnemyConfig = require("config.ArenaEnemyConfig").Config
local ArenaRewardConfig = require("config.ArenaRewardConfig").Config
local MailManager = require("modules.mail.MailManager")
local ns = 'arena'
RankList = RankList or {}
Account2Rank = Account2Rank or {}
SQ = SQ or SaveQueue.new()
FightValRank = FightValRank or {}
PosRankData = PosRankData or nil
FightRankData = FightRankData or nil
local TEMP_RANGE = {[1]={0.3,0.5},[2]={0.5,0.9},[3]={0.9,1}}
ArenaingAccount = ArenaingAccount or {}

-----db 操作接口 begin--------
function init()
	loadDB()
	local saveTimer = Timer.new(60*1000,-1)
	saveTimer:setRunner(save)
	saveTimer:start()
	coroutine.resume(coroutine.create(refreshRank))
end

function loadDB()
	local pCursor = g_oMongoDB:SyncFind(ns,{});
	if not pCursor then
		return true
	end
	local cursor = MongoDBCursor(pCursor)
	while(true) do
		local tmp = {}
		if not cursor:Next(tmp) then
			break
		end
		table.insert(RankList,tmp)
		Account2Rank[tmp.account] = tmp.rank
	end
	if not next(RankList) then
		initRobot()
	end
	table.sort(RankList,function(a,b)return a.rank < b.rank end)
	refreshRobotFightVal()
	--print("Arena:loadDB::"..(_USec()-begin))
end

function refreshRobotFightVal()
	for k,v in pairs(ArenaRobotConfig) do
		local rank = Account2Rank[v.id]
		if RankList[rank] then
			RankList[rank].fightVal = v.fightVal
		end
	end
end

function initRobot()
	for k,v in pairs(ArenaRobotConfig) do
		local account = v.id
		local fightVal = v.fightVal
		local rank = v.rank
		local data = newRobotRankDB(account,fightVal,rank)
		local ret  = g_oMongoDB:SyncInsert(ns,data)
		table.insert(RankList,data)
		Account2Rank[account] = rank
	end
end

function save(isSync)
	--local begin = _USec()         
	local saveCnt = isSync and -1 or 10
	while(not SQ:empty())do
		local rankArr = SQ:pop()
		for k,v in pairs(rankArr) do
			local data = RankList[v]
			local query = {account = data.account}
			DB.Update(ns,query,data,isSync)
			saveCnt = saveCnt - 1
		end
		if saveCnt <= 0 then
			break
		end
	end
	--print("Arena:save::"..(_USec()-begin))
end

function setDirty(...)
	for k,v in pairs({...}) do
		SQ:push(v)
	end
	SQ:pushEnd()
end

function saveAdd(rank)
	local data = RankList[rank]
	if data then
		return DB.Insert(ns,data)
	else
		return false
	end
end
-----db 操作接口 end--------
function newArenaRankDB(human,fightList,rank)
	local fldb,val = rebuildFightList(human,fightList)
	local db = {
		account = human.db.account,
		fightList = fldb,
		fightVal = val,
		rank = rank,
	}
	return db
end

function newRobotRankDB(account,fightVal,rank)
	local db = {
		account = account,
		fightList = {},
		fightVal = fightVal,
		rank = rank,
	}
	return db
end

function rebuildFightList(human,fightList)
	local data = {}
	local val = 0
	for i = 1,#fightList do
		local hero = human:getHero(fightList[i].name)
		if hero then
			local fightVal = hero:getFight()
			local name = hero:getName()
			if 4 ~= fightList[i].pos then
				val = val + fightVal
			end
			data[name] = {pos = fightList[i].pos,val = fightVal}
		end
	end
	return data,val
end

function newEnemyData(account)
	local data = {
		account = account,
	}
	return data
end

function changeFightList(human,fightList)
	local rankData = getRankData(human)
	if rankData then
		local fl,val = rebuildFightList(human,fightList)
		rankData.fightList = fl
		rankData.fightVal = val
		setDirty(rankData.rank)
	end
end

function getRank(human)
	local rank = Account2Rank[human.db.account] 
	return rank or 0
end

function getRankData(human)
	local rank = Account2Rank[human.db.account] 
	return RankList[rank]
end

function getArenaFightVal(account)
	local rank = Account2Rank[account] 
	if rank then
		local rankData = RankList[rank]
		return rankData.fightVal
	else
		return 0
	end
end

function getRankDataByRank(rank)
	return RankList[rank]
end

function addRank(human,fightList)
	if Account2Rank[human.db.account] then
        LogErr("[error]", string.format("Arena addRank a exist account:%s", human.db.account))
		return
	end
	table.insert(RankList,newArenaRankDB(human,fightList,#RankList+1))
	local rank = #RankList
	Account2Rank[human.db.account] = rank
	refreshEnemy(human)
	if not saveAdd(rank) then
		return 
	end
	return RankList[rank]
end

function refreshEnemy(human)
	local rank = getRank(human)
	local arenaData = human.db.arena
	local enemyList = getEnemyByRank(rank)
	arenaData.enemyList = enemyList
	return enemyList
end

function getEnemyByRank(rank)	
	if rank > #RankList then
		assert(false)
		return
	end
	local enemyPos = {}
	if rank <= 10 then
		for i = 1,3 do
			local range = ArenaEnemyConfig[rank]["range"..i]
			local pos = math.random(range[1],range[2])
			table.insert(enemyPos,pos)
		end
	else
		for i = 1,3 do
			local pos = math.random(math.ceil(rank*TEMP_RANGE[i][1]),math.ceil(rank*TEMP_RANGE[i][2])-1)
			table.insert(enemyPos,pos)
		end
	end
	local enemyList = {}
	for j = 1,#enemyPos do
		local pos = enemyPos[j]
		local enemyData = RankList[pos]
		if enemyData then
			table.insert(enemyList,newEnemyData(enemyData.account))
		end
	end
	return enemyList
end

function getRankDataByAccount(account)
	local rank = Account2Rank[account]
	if rank and RankList[rank] then
		return RankList[rank]
	end
end

function riseRank(human,enemy)
	local rankA = Account2Rank[human:getAccount()]
	local rankB = Account2Rank[enemy.account]
	if rankA and rankB and rankA > rankB then
		if swapRank(rankA,rankB) then
			refreshEnemy(human)
			setDirty(rankA,rankB)
			return rankA - rankB
		end
		return 0
	end
	return 0
end

function swapRank(rankA,rankB)
	if RankList[rankA] and RankList[rankB] then
		local AccountA= RankList[rankA].account
		local AccountB = RankList[rankB].account
		Account2Rank[AccountA],Account2Rank[AccountB] = Account2Rank[AccountB],Account2Rank[AccountA]
		RankList[rankA],RankList[rankB] = RankList[rankB],RankList[rankA]
		RankList[rankA].rank = rankA
		RankList[rankB].rank = rankB
		return true
	end
	return false
end

function getFrontEnemys(account,count)
	function addEnemy(enemyList,account)
		local fightList = getArenaFightList(account)
		table.insert(enemyList,
			{account = account,fightList = Util.deepCopy(fightList)}
		)
	end
	local enemyList = {}
	local myRank = Account2Rank[account]
	if myRank then
		if myRank > count then
			for i = count,1,-1 do
				local enemyRank = myRank - i
				if RankList[enemyRank] then
					addEnemy(enemyList,RankList[enemyRank].account)
				end
			end
		else
			for i = 1, count + 1 do
				local enemyRank = i
				if enemyRank ~= myRank and RankList[enemyRank] then
					addEnemy(enemyList,RankList[enemyRank].account)
				end
			end
		end
	else
		local startPos = #RankList - count > 0  and #RankList - count or 1
		for i = startPos,#RankList do
			addEnemy(enemyList,RankList[i].account)
		end
	end
	return enemyList 	
end

function fightValChange(human,hero,val)
	local rank = Account2Rank[human.db.account]
	if rank and RankList[rank] then
		local oldData = RankList[rank].fightList[hero:getName()]
		if oldData then
			local diff = val - oldData.val
			if diff ~= 0 then
				RankList[rank].fightVal = RankList[rank].fightVal + diff
				oldData.val = val
				setDirty(rank)
			end
		end
	end
end

function rewardRank()
	for i = 1,#ArenaRewardConfig do
		local cfg = ArenaRewardConfig[i]
		for j = cfg.rank[1],cfg.rank[2] do
			if j > #RankList then
				return 
			end
			local rank = RankList[j]
			if rank then
				local account = rank.account
				local robotCfg = ArenaRobotConfig[account]
				if not robotCfg then
					MailManager.sysSendMailById(account,17,cfg.rewards,rank.rank)
				end
			end
		end
	end
end

function refreshRank()
	reSortFightValRank()
	PosRankData = nil
	FightRankData = nil
	reloadPosRankData()
	reloadFightRankData()
end

function isRobot(account)
	local robotCfg = ArenaRobotConfig[account]
	if robotCfg then
		return true
	else
		return false
	end
end

function reSortFightValRank()
		--print("reSortFightValRank")
	FightValRank = {}
	local n = 1
	while(true) do
		if not RankList[n] then
			break
		end
		local account = RankList[n].account
		if not isRobot(account) then
			table.insert(FightValRank,n)
			if #FightValRank >= ArenaDefine.MAX_FIGHTVAL_RANK then
				break
			end
		end
		n = n + 1
	end
	table.sort(FightValRank,function(a,b)return RankList[a].fightVal > RankList[b].fightVal end)
	if not RankList[n] then
		return
	end
	if #RankList <= ArenaDefine.MAX_FIGHTVAL_RANK then
		--Util.print_r(FightValRank)	
		return
	end
	for i = n + 1,#RankList do
		local insertPos
		local account = RankList[i].account
		if not isRobot(account) then
			for j = #FightValRank,1,-1 do
				if RankList[FightValRank[j]].fightVal >= RankList[i].fightVal then
					break
				end
				insertPos = j
			end
			if insertPos then
				for k = #FightValRank+1,insertPos+1,-1 do
					FightValRank[k] = FightValRank[k-1]
				end
				FightValRank[insertPos] = i
				FightValRank[#FightValRank] = nil
			end
		end
	end
		--Util.print_r(FightValRank)	
end

function newHumanInfo(account, rank, bodyId,lv,name,fightVal,flowerCount,win,guildName,fightList)
	local info = {
		account = account,
		rank = rank,
		bodyId = bodyId,
		lv = lv,
		name = name,
		fightVal = fightVal,
		win = win,
		guild = guildName,
		fightList = fightList,
		flowerCount = flowerCount or 0
	}
	return info
end

function reloadFightRankData()
	FightRankData = {}
	local fightRankLen = #FightValRank < ArenaDefine.MAX_POS_RANK and #FightValRank or ArenaDefine.MAX_POS_RANK
	for i = 1,fightRankLen do
		local rank = FightValRank[i]
		local rankData = RankList[rank]
		local human = getArenaHuman(rankData.account)
		if human then
			local IdList = GuildManager.getGuildIdList()
			local guild = IdList[human.db.guildId]
			local guildName = guild and guild.db.name or "暂无公会"
			local fightData = getFightData(rankData)
			local win = human.db.arena and human.db.arena.win or 0
			local info = newHumanInfo(human.db.account, i, human.db.bodyId,human.db.lv,human.db.name,rankData.fightVal,human.db.flowerCount,win,guildName,fightData)
			table.insert(FightRankData,info)
		end
	end
end

function getFightData(rankData)
	local fightData = {}
	local fightList = getArenaFightList(rankData.account)
	local char = getArenaHuman(rankData.account)
	if fightList then
		for k,v in pairs(fightList) do
			local hero = char:getHero(k)
			if hero then
				table.insert(fightData,{name = k,lv = hero:getLv(),quality = hero:getQuality()})
			end
		end
		table.sort(fightData,function(a,b)return fightList[a.name].pos < fightList[b.name].pos end)
	end
	return fightData
end

function reloadPosRankData()
	PosRankData = {}
	local i = 1
	while(true) do
		local rankData = RankList[i]
		if not rankData then
			break
		end
		if not isRobot(rankData.account) then
			local human = getArenaHuman(rankData.account)
			if human then
				local IdList = GuildManager.getGuildIdList()
				local guild = IdList[human.db.guildId]
				local guildName = guild and guild.db.name or "暂无公会"
				local fightData = getFightData(rankData)
				local win = human.db.arena and human.db.arena.win or 0
				local info = newHumanInfo(human.db.account, rankData.rank, human.db.bodyId,human.db.lv,human.db.name,rankData.fightVal,human.db.flowerCount,win,guildName,fightData)
				table.insert(PosRankData,info)
			end
			if #PosRankData >= ArenaDefine.MAX_POS_RANK then
				break
			end
		end
		i = i + 1
	end
end

function getFightRankData()
	if not FightRankData then
		reloadFightRankData()
	end
	return FightRankData
end

function getPosRankData()
	if not PosRankData then
		reloadPosRankData()
	end
	return PosRankData
end

function getArenaHuman(account)
	local human
	if ArenaRobotConfig[account] then
		human = ArenaRobot.getByAccount(account)
	else
		human = HumanManager.getOnline(account) or HumanManager.loadOffline(account)
	end
	return human
end

function getArenaFightList(account)
	local cfg = ArenaRobotConfig[account]
	if cfg then
		local robot = getArenaHuman(account)
		return robot.fightList
	else
		local rank = Account2Rank[account]
		local data = RankList[rank]
		if data then
			return data.fightList
		end
	end
end

function addArenaing(A,B)
	ArenaingAccount[A] = B
	ArenaingAccount[B] = A
end

function delArenaing(A)
	local B = ArenaingAccount[A]
	if B then
		ArenaingAccount[B] = nil 
	end
	ArenaingAccount[A] = nil 
end

function checkArenaing(account)
	if ArenaingAccount[account] then
		return true
	else
		return false
	end
end
