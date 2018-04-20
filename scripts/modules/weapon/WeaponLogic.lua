module(...,package.seeall)

local Define = require("modules.weapon.WeaponDefine")
local WeaponQualityConfig = require("config.WeaponQualityConfig").Config
local Msg = require("core.net.Msg")
local HeroManager = require("modules.hero.HeroManager")
local BaseMath = require("modules.public.BaseMath")
local WeaponLvConfig = require("config.WeaponLvConfig").Config
local WeaponNeedConfig = require("config.WeaponNeedConfig").Config
local WeaponConfig = require("config.WeaponConfig").Config

function onHumanLogin(hm,human)
	sendWepList(human)
end

function getWep(human, wid)
	local weps = human.db.wep
	for k, v in pairs(weps) do
		if v.wid == wid then
			return v
		end
	end
end

function sendWepList(human)
	local weps = human.db.wep
	local list = {}
	for k, v in pairs(weps) do
		table.insert(list, {wepId=v.wid, lv=v.lv, exp=v.exp, quality=v.q})
	end
	Msg.SendMsg(PacketID.GC_WEAPON_QUERY, human, list)
end

function addExp(human, wid, exp)
	local hasLvUp = 0
	local wep = getWep(human, wid)
	if wep then
		wep.exp = wep.exp + exp
		local needExp = getLvConfig(wep.lv).exp
		while wep.exp >= needExp do
			wep.exp = wep.exp - needExp
			wep.lv = wep.lv + 1
			local config = getLvConfig(wep.lv)
			if config then
				hasLvUp = 1
				needExp = config.exp
			else
				wep.lv = wep.lv - 1
				break
			end
		end
	end
	return hasLvUp
end

function sendHeroDyAttr(human)
	local heroList = HeroManager.getAllHeroes(human)
	for _,hero in pairs(heroList) do
		hero:resetDyAttr()
	end
	HeroManager.sendAllHeroesAttr(human)
end

function getSumLv(human)
	local sumLv = 0
	local weps = human.db.wep
	for k, v in pairs(weps) do
		sumLv = sumLv + v.lv
	end
	return sumLv
end

function getWeaponConfig(wepId, quailty, lv)
	return WeaponConfig[wepId * 10000 + quailty * 1000 + lv]
end

function getLvConfig(lv)
	return WeaponLvConfig[lv]
end

function getQualityConfig(quality)
	for _,config in pairs(WeaponQualityConfig) do
		if config.quality == quality then
			return config
		end
	end
end

function getNeedConfig(wepId)
	return WeaponNeedConfig[wepId]
end
