module(...,package.seeall)

local HeroHandbookConfig = require("config.HeroHandbookConfig").Config
local ItemHandbookConfig = require("config.ItemHandbookConfig").Config
local HeroManager = require("modules.hero.HeroManager")
local def = require("modules.handbook.HandbookDefine")
local DB = require("core.db.DB")
local ItemConfig = require("config.ItemConfig").Config
local Msg = require("core.net.Msg")
local PublicLogic = require("modules.public.PublicLogic")
function getInfo(human,name)
	local info = {}
	local conf,d,num
	if name == 'hero' then
		d = human.db.Handbook.hero
		conf = HeroHandbookConfig
		num = HeroManager.getHeroCnt(human)
	elseif name == 'item' then
		d = human.db.Handbook.item
		conf = ItemHandbookConfig
		num = getItemNum(human)
	else
		return
	end
	for id,c in ipairs(conf) do
		if d[id] and (d[id] == def.STATUS_REWARDED or d[id] == def.STATUS_NOTREWARDED) then

		elseif num > c.num then
			d[id] = def.STATUS_NOTREWARDED
		else
			d[id] = def.STATUS_NOTCOMPLETE
		end
		info[id] = d[id]
	end
	return info
end

function sendHandbookInfo(human,name)
	local info = {}
	if name == 'hero' then
		table.insert(info,{name=name,status=getInfo(human,"hero")})
	elseif name == 'item' then
		table.insert(info,{name=name,status=getInfo(human,"item")})
	elseif name == nil then
		table.insert(info,{name='hero',status=getInfo(human,"hero")})
		table.insert(info,{name='item',status=getInfo(human,"item")})
	end
	Msg.SendMsg(PacketID.GC_HANDBOOK_INFO,human,info)
end

function getHandbookReward(human,name,id)
	local conf,d
	if name == 'hero' then
		d = human.db.Handbook.hero
		conf = HeroHandbookConfig

	elseif name == 'item' then
		d = human.db.Handbook.item
		conf = ItemHandbookConfig
	else
		return
	end
	if d[id] then
		return d[id]
	else
		return def.STATUS_NOTREWARDED
	end
end

function addItemLib(human,itemId)
	if ItemConfig[itemId] and ItemConfig[itemId].handbookTag > 0 then
		local db = human.db.Handbook
		if db.itemlib == nil then
			db.itemlib = {}
		end
		if db.itemlib[itemId] == nil then
			db.itemlib[itemId] = 1
		end
	end
end
function getItemLib(human)
	local lib = {}
	for itemId,_ in pairs(human.db.Handbook.itemlib) do 
		table.insert(lib,itemId)
	end
	return lib
end
function getItemNum(human)
	local num = 0
	for _,_ in pairs(human.db.Handbook.itemlib) do
		num = num + 1
	end
	return num
end


function setHandbookReward(human,name,id)
	local conf,d,cnt
	if name == 'hero' then
		conf = HeroHandbookConfig
		d = human.db.Handbook.hero
		cnt = HeroManager.getHeroCnt(human)
	elseif name == 'item' then
		conf = ItemHandbookConfig
		d = human.db.Handbook.item
		cnt = getItemNum(human)
	else
		return def.RET_NOTPERMITTED
	end

	-- 判断id是否合法
	if not conf[id] then
		return def.RET_NOTPERMITTED
	end

	-- 判断是否达到领取条件
	if cnt < conf[id].num then
		return def.RET_NOTPERMITTED
	end

	-- 判断是否已经领取
	local status = getHandbookReward(human,name,id)

	if status == def.STATUS_NOTREWARDED then
		d[id] = def.STATUS_REWARDED
		PublicLogic.doReward(human,conf[id].reward)
		-- 给予奖励
		return def.RET_OK
	else
		return def.RET_NOTPERMITTED
	end
end

function onHumanLogin(hm,human)
	sendHandbookInfo(human)
end
function onDBLoaded(hm,human)
	if human.db.Handbook == nil then
		human.db.Handbook = {}
	end
	if human.db.Handbook.itemlib == nil then
		human.db.Handbook.itemlib = {}
	end
	if human.db.Handbook.item == nil then
		human.db.Handbook.item = {}
	end
	if human.db.Handbook.hero == nil then
		human.db.Handbook.hero = {}
	end

	DB.dbSetMetatable(human.db.Handbook.itemlib)
end

