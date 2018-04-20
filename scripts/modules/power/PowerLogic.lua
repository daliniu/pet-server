module(...,package.seeall)

local Msg = require("core.net.Msg")
local BaseMath = require("modules.public.BaseMath")

local Define = require("modules.power.PowerDefine")
local PowerConfig = require("config.PowerConfig").Config

function onHumanLogin(hm,human)
	sendPowerList(human)
end

function getPower(human, powerId)
	local list = human.db.power
	for k, v in pairs(list) do
		if v.powerId == powerId then
			return v
		end
	end
end

function addPower(human,powerId)
	local list = human.db.power
	list[#list+1] = {
		powerId = powerId,
		lv = 1,
		exp = 0,
	}
end

function sendPowerList(human)
	local power = human.db.power
	local list = {}
	for k, v in pairs(power) do
		list[#list+1] = {
			powerId = v.powerId,
			lv = v.lv,
			exp = v.exp,
		}
	end
	Msg.SendMsg(PacketID.GC_POWER_QUERY, human, list)
end

function addExp(human, powerId , exp)
	local hasLvUp = 0
	local power = getPower(human, powerId)
	if power then
		power.exp = power.exp + exp
		--local cfg = PowerConfig[power.powerId]
		--local maxExp = calMaxExp(power.lv,cfg.exp,cfg.factor)
		local maxExp = BaseMath.getPowerUpExp(power.lv) 
		while maxExp <= power.exp do
			if (power.lv + 1) <= Define.MAX_LV then
				power.lv = power.lv + 1
				power.exp = power.exp - maxExp
				--maxExp = calMaxExp(power.lv,cfg.exp,cfg.factor)
				maxExp = BaseMath.getPowerUpExp(power.lv)
				hasLvUp = 1
			else
				break
			end
		end
	end
	return hasLvUp
end

function refreshHero(human,powerId)
	local power = getPower(human,powerId)
	local conf = PowerConfig[power.powerId]
	for _,heroName in pairs(conf.hero) do
    	local hero = human:getHero(heroName)
		if hero then 
			hero:resetDyAttr()
			hero:sendHeroAttr()
		end
	end
end







