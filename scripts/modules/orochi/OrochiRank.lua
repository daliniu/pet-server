module(..., package.seeall)

local ns = 'rank'
local modName = "orochi"

local GuildManager = require("modules.guild.GuildManager")
--
--{levelId=1,charName="",entryTime=123}
RankList = RankList or {}

function init()
	loadDB()
	--定时存库
	local timer = Timer.new(900000,-1)	--15分钟
	timer:setRunner(save)
	timer:start()
end

function loadDB()
	local query = {module=modName}
    local pCursor = g_oMongoDB:SyncFind(ns,query)
    if not pCursor then
        return false
    end
    local Cursor = MongoDBCursor(pCursor)
	local row = {}
    if not Cursor:Next(row) then
		g_oMongoDB:SyncInsert(ns,{module=modName,list=RankList})
	else
		RankList = row.list
    end
	return true
end

function save(isSync)
	local query = {module=modName}
	DB.Update(ns,query,{module=modName,list=RankList},isSync)
end

function getRankDataByLevelId(levelId)
	for _,v in pairs(RankList) do
		if v.levelId == levelId then
			return v
		end
	end
	return
end

function getHumanRank(human)
	for index,v in pairs(RankList) do
		if human:getAccount() == v.account then
			return v,index
		end
	end
end

local setHumanInfo = function(level,levelInfo,human)
	local guildName = GuildManager.getGuildNameByGuildId(human:getGuildId())
	level.account = human:getAccount()
	level.name = human:getName()
	level.bodyId = human.db.bodyId
	level.lv = human.db.lv
	level.fightVal = human:getTeamFightVal(levelInfo.fightList)
	level.guild = guildName
	local heroList = {}
	for _,name in ipairs(levelInfo.fightList) do
		local hero = human:getHero(name)
		if hero then
			heroList[#heroList+1] = {
				name = name,
				lv = hero:getLv(),
				quality = hero.quality,
			}
		else
			heroList[#heroList+1] = {}
		end
	end
	level.fightList = heroList 
	level.flowerCount = human.db.flowerCount
end
function updateRank(levelInfo,human)
	local levelId = levelInfo.levelId
	local entryTime = levelInfo.entryTime
	local level = getRankDataByLevelId(levelId)
	local isUpdate = false
	local rank,index = getHumanRank(human)
	--已有名次
	if rank then
		--名次独占
		if rank.levelId > levelId then
			return false
		end
	end
	if not level then
		if rank then
			table.remove(RankList,index)
		end
		isUpdate = true
		level = {
			levelId=levelId,
			entryTime=entryTime,
		}
		RankList[#RankList+1] = level
		setHumanInfo(level,levelInfo,human)
	elseif level.entryTime > entryTime then
		if rank then
			table.remove(RankList,index)
		end
		isUpdate = true
		level.entryTime = entryTime
		setHumanInfo(level,levelInfo,human)
	end
	return isUpdate
end







