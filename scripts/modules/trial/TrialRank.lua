module(..., package.seeall)

local Define = require("modules.trial.TrialDefine")
local GuildManager = require("modules.guild.GuildManager")

local ns = 'rank'
local modName = "trial"

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

function getById(levelId)
	for _,v in pairs(RankList) do
		if v.levelId == levelId then
			return v
		end
	end
	return
end

function getHumanRank(human)
	for k,v in pairs(RankList) do
		if human:getAccount() == v.account then
			return v,k
		end
	end
	return
end

local setHumanInfo = function(item,fightList,human)
	local guildName = GuildManager.getGuildNameByGuildId(human:getGuildId())
	item.account = human:getAccount()
	item.name = human:getName()
	item.bodyId = human.db.bodyId
	item.lv = human.db.lv
	item.guild = guildName
	item.flowerCount = human.db.flowerCount
	local heroList = {}
	for _,name in ipairs(fightList) do
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
	item.fightVal = human:getTeamFightVal(heroList)
	item.fightList = heroList 
end

--
--首次挑战，才可获得分值，重复挑战，则分值不会增加
--取20级以上通关进度＞0的玩家
--最多取值前30名
--
function updateRank(score,fightList,human)
	--已入榜
	local myRank,myIndex = getHumanRank(human)
	if myRank then
		table.remove(RankList,myIndex)
	end
	--new
	local total = #RankList
	local index
	for k,v in pairs(RankList) do
		if v.score < score then
			index = k
			break
		end
	end
	--榜单未满
	if not index and total < Define.MAX_RANK_NUM then
		index = #RankList + 1
	end
	if index then
		local level = {
			rank = index,
			score = score,
		}
		setHumanInfo(level,fightList,human)
		table.insert(RankList,index,level)
		if #RankList > Define.MAX_RANK_NUM then
			table.remove(RankList,#RankList)
		end
	end
	return index and index > 0 
end


function onHumanLvUp(hm,event)
	local human = event.human
	local myRank = getHumanRank(human)
	if myRank then
		myRank.lv = human:getLv()
	end
end







