module(...,package.seeall)

local GuildManager = require("modules.guild.GuildManager")
local Crontab = require("modules.public.Crontab")
local Define = require("modules.flower.FlowerDefine")
local Arena = require("modules.arena.Arena")
local Chapter = require("modules.chapter.Chapter")
local HeroManager = require("modules.hero.HeroManager")
local TABLE_RANK = "rank"
local RANK_MODULE_FLOWER = "flower"
local CRONTAB_FLOWER = 4

_hasSort = _hasSort or false
_tempRankList = _tempRankList or nil
_rankAccountList = _rankAccountList or {}
_rankList = _rankList or {}
_dirtyList = _dirtyList or {}

function init()
	loadRank()
	refreshRank()
	addSaveTimer()
end

function startContab()
	Crontab.AddEventListener(CRONTAB_FLOWER, refreshRank)
end

function loadRank()
	local pCursor = g_oMongoDB:SyncFind(TABLE_RANK,{module=RANK_MODULE_FLOWER})
	if not pCursor then
		return
	end
	local cursor = MongoDBCursor(pCursor)
	local tmp = {}
	if not cursor:Next(tmp) then
		g_oMongoDB:SyncInsert(TABLE_RANK,{module=RANK_MODULE_FLOWER,rankList = _rankList})
		return
	end

	_rankList = tmp.rankList
	initAccountList()
end

function initAccountList()
	for _,data in pairs(_rankList) do
		_rankAccountList[data.account] = 1
	end
end

function refreshRank()
	_tempRankList = nil
end

function addSaveTimer()
	local saveTimer = Timer.new(60*1000, -1)
	saveTimer:setRunner(saveInTimer)
	saveTimer:start()
end

function saveInTimer()
	if _hasSort == true then
		_hasSort = false
		saveDB()
	end
end

function sortRankData()
	for account,record in pairs(_dirtyList) do
		if _rankAccountList[account] == nil then
			local saveData = {account=account,flowerCount=record.flowerCount}
			local len = #_rankList
			if len == 0 then
				table.insert(_rankList, saveData)
				_rankAccountList[account] = 1
			else
				for i=1,len do
					local data = _rankList[i]
					if data.flowerCount < saveData.flowerCount then
						table.insert(_rankList, i, saveData)
						_rankAccountList[account] = 1
						break
					end
				end
				if len == #_rankList then
					table.insert(_rankList, saveData)
					_rankAccountList[account] = 1
				end
				if #_rankList > Define.FLOWER_RANK_COUNT then
					local data = table.remove(_rankList)
					_rankAccountList[data.account] = nil
				end
			end
		else
			for _,data in ipairs(_rankList) do
				if data.account == account and data.flowerCount < record.flowerCount then
					data.flowerCount = record.flowerCount
					break
				end
			end
			local sortFun = function(a,b) return a.flowerCount > b.flowerCount end
			table.sort(_rankList, sortFun)
		end
	end
	_dirtyList = {}
	_hasSort = true
end

function composeTempRankList()
	_tempRankList = {}
	for rank,data in ipairs(_rankList) do
		local player = HumanManager.getOnline(data.account) or HumanManager.loadOffline(data.account)
		local IdList = GuildManager.getGuildIdList()
		local guild = IdList[player.db.guildId]
		local guildName = guild and guild.db.name or "暂无公会"
		local win = player.db.arena and player.db.arena.win or 0
		local arenaData = Arena.getRankData(player)
		local fightVal = 0
		local fightList = {}
		if arenaData ~= nil then
			fightVal = arenaData.fightVal	
			fightList = getChapterFightList(player)
		end
		local tempData = {
			account = data.account,
			rank = rank,
			bodyId = player.db.bodyId,
			lv = player.db.lv,
			name = player.db.name,
			flowerCount = data.flowerCount,
			fightList = fightList,
			guild = guildName,
			fightVal = fightVal,
			win = win,
		}
		table.insert(_tempRankList, tempData)
	end
end

function getChapterFightList(player)
	local heroList = Chapter.getHumanFightHeroes(player)
	local heroDataList = {}
	if heroList ~= nil then
		for i=1,4 do
			local name = heroList[i]
			if name == nil or name == '' then
				table.insert(heroDataList, {name='',lv=1,quality=1})
			else
				local hero = HeroManager.getHero(player, name)
				if hero then
					table.insert(heroDataList, {name=name,lv=hero.db.lv,quality=hero.db.quality})
				end
			end
		end
	end
	return heroDataList
end

function addDirtyRecord(account)
	local player = HumanManager.getOnline(account) or HumanManager.loadOffline(account)
	if player then
		_dirtyList[account] = {
			flowerCount = player.db.flowerCount
		}
	end
end

function saveDB(isSync)
	sortRankData()
	DB.Update(TABLE_RANK,{module=RANK_MODULE_FLOWER},{module=RANK_MODULE_FLOWER,rankList=_rankList},isSync)
end

function getTempRankList()
	if _tempRankList == nil or #_tempRankList == 0 then
		sortRankData()
		composeTempRankList()
	end
	return _tempRankList
end
