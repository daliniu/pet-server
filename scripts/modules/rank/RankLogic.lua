module(..., package.seeall)

local RankHero = require("modules.rank.RankHero")
local RankMoney = require("modules.rank.RankMoney")
local RankExp = require("modules.rank.RankExp")

function init()
	RankHero.init()
	RankMoney.init()
	RankExp.init()
end

function addListener()
	RankHero.addListener()
	RankMoney.addListener()
	RankExp.addListener()
end

function saveDB(isSync)
	RankHero.saveDB(isSync)
	RankExp.saveDB(isSync)
	RankMoney.saveDB(isSync)
end

function composeRankList(list)
	local tab = {}
	for _,data in pairs(list) do
		local obj = {}
		obj.name = data.name
		obj.icon = data.bodyId
		obj.lv = data.lv
		obj.fight = data.fightVal
		obj.flowerCount = data.flowerCount or 0
		table.insert(tab, obj)
	end
	return tab
end

function composeGuildFightRankList(list)
	local tab = {}
	for _,data in ipairs(list) do
		local obj = {}
		obj.name = data:getName()
		obj.lv = data:getLv()
		obj.icon = data:getIcon()
		obj.fight = data:getFightVal()
		table.insert(tab, obj)
	end
	return tab
end

function composeGuildData(list, index)
	local data = list[index]
	if data then
		local k,v = data:getLeader()
		local tb = {
			rank = index,
			name = v.name,
			fightVal = data:getFightVal(),
			bodyId = data:getIcon(),
			lv = data:getLv(),
			win = data:getMemCount(),
			guild = data:getName(),
			flowerCount = data:getId(),
			fightList = {},
		}
		return tb
	end
end
