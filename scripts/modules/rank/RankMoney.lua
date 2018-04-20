module(..., package.seeall)

local Crontab = require("modules.public.Crontab")
local Define = require("modules.rank.RankDefine")

local MODULE_NAME = "money"
local TABLE_RANK = "rank"
local CRONTAB_ID = 3

_dirtyList = _dirtyList or {}
_rankAccountList = _rankAccountList or{}
_rankList = _rankList or {}

function init(moduleName, sortName)
	loadRank()
	addSaveTimer()
end

function loadRank()
	local pCursor = g_oMongoDB:SyncFind(TABLE_RANK,{module=MODULE_NAME})
	if not pCursor then
		return
	end
	local cursor = MongoDBCursor(pCursor)
	local tmp = {}
	if not cursor:Next(tmp) then
		g_oMongoDB:SyncInsert(TABLE_RANK,{module=MODULE_NAME,rankList=_rankList})
		return
	end

	_rankList = tmp.rankList
	initAccountList()
end

function initAccountList()
	_rankAccountList = {}
	for _,data in pairs(_rankList) do
		_rankAccountList[data.account] = 1
	end
end

function addListener()
	Crontab.AddEventListener(CRONTAB_ID, refreshRank)
	HumanManager:addEventListener(HumanManager.Event_HumanMoneySumChange, onMoneyChange)
end

function addSaveTimer()
	local saveTimer = Timer.new(60*1000, -1)
	saveTimer:setRunner(saveInTimer)
	saveTimer:start()
end

function saveInTimer()
	saveDB()
end

function saveDB(isSync)
	sortRankData()
	DB.Update(TABLE_RANK,{module=MODULE_NAME},{module=MODULE_NAME,rankList=_rankList},isSync)
end

function refreshRank()
	sortRankData()
end

function sortRankData()
	for account,record in pairs(_dirtyList) do
		local len = #_rankList
		local saveData = Util.deepCopy(record)
		if _rankAccountList[account] == nil then
			if len == 0 then
				table.insert(_rankList, saveData)
				_rankAccountList[account] = 1
			else
				for i=1,len do
					local data = _rankList[i]
					if data.money < saveData.money then
						table.insert(_rankList, i, saveData)
						_rankAccountList[account] = 1
						break
					end
				end
				if len == #_rankList then
					table.insert(_rankList, saveData)
					_rankAccountList[account] = 1
				end
				if #_rankList > Define.RANK_COUNT then
					local data = table.remove(_rankList)
					_rankAccountList[data.account] = nil
				end
			end
		else
			for i=1,len do
				if _rankList[i].account == account and _rankList[i].money < saveData.money then
					_rankList[i] = saveData
					break
				end
			end
			local sortFun = function(a,b) return a.money > b.money end
			table.sort(_rankList, sortFun)
		end
	end
	_dirtyList = {}
end

function onMoneyChange(hm, event)
	local human = event.human
	local moneyVal = human:getMoneySum()
	local tb = _dirtyList[human:getAccount()]
	if tb then
		Util.print_r(tb)
	end
	if not tb or tb.money < moneyVal then
		_dirtyList[human:getAccount()] = {
			account=human:getAccount(),
			name=human:getName(),
			lv=human:getLv(),
			bodyId=human:getBodyId(),
			money=moneyVal,
		}	
	end
end

function getRankList()
	local list = {}
	for _,record in ipairs(_rankList) do
		local tb = {}
		tb.name = record.name
		tb.lv = record.lv
		tb.icon = record.bodyId
		tb.fight = record.money
		table.insert(list, tb)
	end
	return list
end
