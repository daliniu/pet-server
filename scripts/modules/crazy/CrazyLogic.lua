module(...,package.seeall)
local Crontab = require("modules.public.Crontab")
local Msg = require("core.net.Msg")
local CrazyDefine = require("config/CrazyDefineConfig").Defined
local Define = require("modules.crazy.Define")
local GuildManager = require("modules.guild.GuildManager")
local HeroManager = require("modules.hero.HeroManager")
local MailManager = require("modules.mail.MailManager")

_isOpen = _isOpen or false
_timer = _timer or nil
_startTime = _startTime or 0
_rank = _rank or {}
_data = _data or {
	--[account] = {harm=0,boss={}}
}

function startCrontab()
	Crontab.AddEventListener(CrazyDefine.startTimeId, startCrazy)
	initConfig()
end

function initConfig()
end

function onHumanLogin(hm,human)
	sendData(human)
end

function startCrazy()
	if _isOpen then
		return
	end

	_startTime = os.time()
	---[[
	if not _timer then
		_timer = Timer.new(CrazyDefine.lastTime * 1000, 1)
		_timer:setRunner(endCrazy)
		_timer:start()
	end
	--]]
	_isOpen = true
	Msg.WorldBroadCast(PacketID.GC_CRAZY_NOTIFY,Define.CrazyNodity.open)
end

function endCrazy()
	if not _isOpen then
		return
	end
	if _timer ~= nil then
		_timer:stop()
		_timer = nil
	end
	sendReward()

	_isOpen = false
	_data = {}
	_rank = {}

	Msg.WorldBroadCast(PacketID.GC_CRAZY_NOTIFY,Define.CrazyNodity.close)
end

function sendReward()
	for k,v in ipairs(CrazyDefine.reward) do
		for r = v.min,v.max do
			if _rank[r] then
				local human = HumanManager.getOnline(_rank[r].account) or HumanManager.loadOffline(_rank[r].account)
				if human then
					MailManager.sysSendMailById(human:getAccount(), 18, {v.item},r)
				end
			end
		end
	end
end

function getCurrentBossIndex(data)
	for k = 1,Define.MaxBoss do
		if not data.boss[k].isDie then
			return k
		end
	end
	return -1
end

function setData(human,data)
	_data[human:getAccount()] = data
end

function getData(human)
	return _data[human:getAccount()] or {harm = 0,boss={{isDie=false,harm=0},{isDie=false,harm=0},{isDie=false,harm=0},{isDie=false,harm=0},{isDie=false,harm=0}}}
end

function getHarm(human)
	--human.crazy = human.crazy or {}
	--return human.crazy.harm or 0
	return getData(human).harm
end

function getBoss(human)
	local data = getData(human)
	local b = {}
	for k,v in ipairs(data.boss) do
		table.insert(b,{isDie = v.isDie and 1 or 0,harm=v.harm})
	end
	return b
end

function getRank()
	local r = {}
	for k=1,Define.MaxRank do
		if _rank[k] then
			table.insert(r,{name = _rank[k].name,rank=k,icon=_rank[k].icon,lv=_rank[k].lv,harm=_rank[k].harm,guild=_rank[k].guild})
		end
	end
	return r
end

function sendData(human)
	Msg.SendMsg(PacketID.GC_CRAZY_QUERY,human,_isOpen and 1 or 0,getHarm(human),getRank(),getBoss(human))
end

function updateRank(human,harm,heroList)
	local tab = {}
	for i=1,4 do
		local name = heroList[i]
		local hero = HeroManager.getHero(human, name)
		if hero then
			table.insert(tab, {name = name, lv = hero:getLv(), quality=hero.db.quality})
		else
			table.insert(tab, {name = '', lv = 1, quality = 1})
		end
	end
	local index = #_rank + 1
	for k,v in ipairs(_rank) do
		if v.account == human:getAccount() then
			index = k
		end
	end
	_rank[index] = {time = os.clock(),harm = harm,account=human:getAccount(),name = human:getName(),fight = human:getTeamFightVal(tab),heroList = tab,icon=human:getBodyId(),lv=human:getLv(),guild=GuildManager.getGuildNameByGuildId(human:getGuildId())}
	table.sort(_rank,function(a,b) 
		if a.harm ~= b.harm then
			return a.harm >= b.harm 
		else
			return a.time < b.time
		end
	end)
	_rank[Define.MaxRank + 1] = nil

	--[[
	for k = Define.MaxRank,1,-1 do
		if not _rank[k] or _rank[k].harm < harm then
			_rank[k+1] = _rank[k]
		else
			_rank[k+1] = {harm = harm,account=human:getAccount(),name = human:getName(),fight = human:getTeamFightVal(tab),heroList = heroList,icon=human:getBodyId(),lv=human:getLv(),guild=GuildManager.getGuildNameByGuildId(human:getGuildId())}
			break
		end
		if k == 1 then
			_rank[1] = {harm = harm,account=human:getAccount(),name = human:getName(),fight = human:getTeamFightVal(tab),heroList = heroList,icon=human:getBodyId(),lv=human:getLv(),guild=GuildManager.getGuildNameByGuildId(human:getGuildId())}
		end
	end
	--]]
end

-------------------------------------------------------------
function fight(human)
	if not _isOpen then
		return
	end
	local data = getData(human)
	local bossIndex = getCurrentBossIndex(data)
	if bossIndex == -1 then
		return
	end
	data.isFighting = true
	setData(human,data)
end

function sumit(human,isDie,harm,heroList)
	local data = getData(human)
	if not data.isFighting then
		return
	end
	local bossIndex = getCurrentBossIndex(data)
	if bossIndex == -1 then
		return
	end
	data.harm = data.harm + harm
	data.boss[bossIndex].isDie = isDie
	data.boss[bossIndex].harm = data.boss[bossIndex].harm + harm
	data.isFighting = false
	setData(human,data)
	updateRank(human,data.harm,heroList)
	sendData(human)
	HumanManager:dispatchEvent(HumanManager.Event_Crazy,{human=human,objNum = 1})
end

function hasThatRank(rank)
	if _rank[rank] == nil then
		return false,nil
	end
	return true,_rank[rank]
end
