module(...,package.seeall)

local Handbook = require("modules.handbook.Handbook")
local Def = require("modules.handbook.HandbookDefine")
local ItemHandbookConfig = require("config.ItemHandbookConfig").Config
local HeroHandbookConfig = require("config.HeroHandbookConfig").Config
local Msg = require("core.net.Msg")

function onCGHandbookInfo(human)
	Handbook.sendHandbookInfo(human)
end

function onCGHandbookReward(human,name,id)
	local conf
	if name == 'hero' then
		conf = HeroHandbookConfig
	elseif name == 'item' then
		conf = ItemHandbookConfig
	else
		Msg.SendMsg(PacketID.GC_HANDBOOK_REWARD,human,ret,name,id)
		return
	end
	local ret = Handbook.setHandbookReward(human,name,id)
	if ret ~= Def.RET_OK then
		Msg.SendMsg(PacketID.GC_HANDBOOK_REWARD,human,ret,name,id)
		return
	end
	if conf[id] == nil then
		Msg.SendMsg(PacketID.GC_HANDBOOK_REWARD,human,ret,name,id)
		return
	end

	Handbook.sendHandbookInfo(human,name)

	Msg.SendMsg(PacketID.GC_HANDBOOK_REWARD,human,ret,name,id)
end

function onCGHandbookItemlib(human)
	local lib = Handbook.getItemLib(human)
	Msg.SendMsg(PacketID.GC_HANDBOOK_ITEMLIB,human,lib)
end