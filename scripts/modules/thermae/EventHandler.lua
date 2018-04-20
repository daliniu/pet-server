module(...,package.seeall)

local PacketID = require("PacketID")
local ThermaeDefine = require("config.ThermaeDefineConfig").Defined
local Msg = require("core.net.Msg")
local ThermaeLogic = require("modules.thermae.ThermaeLogic")
local HeroDefine = require("modules.hero.HeroDefine")

function onCGThermaeQuery(human)
	ThermaeLogic.sendData(human)
	return true
end

function onCGThermaeBath(human,heroName)
	if ThermaeLogic.getBathingHero(human) then
		return
	end
	local hero = human:getHero(heroName)
	if not hero then
		return
	end
	if not ThermaeLogic.isOpen() then
		return false
	end

	if human:getLv() < ThermaeDefine.level then
		return false
	end
	ThermaeLogic.bath(human,hero)
	Msg.SendMsg(PacketID.GC_THERMAE_BATH,human)
	return true
end

function onCGThermaeEndBath(human)
	local hero = ThermaeLogic.getBathingHero(human)
	if not hero then
		return
	end
	if not ThermaeLogic.isOpen() then
		return false
	end
	ThermaeLogic.endBath(human,hero)
	Msg.SendMsg(PacketID.GC_THERMAE_END_BATH,human)
	return true
end
