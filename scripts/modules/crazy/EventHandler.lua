module(...,package.seeall)

local PacketID = require("PacketID")
local CrazyDefine = require("config.CrazyDefineConfig").Defined
local Msg = require("core.net.Msg")
local CrazyLogic = require("modules.crazy.CrazyLogic")

function onCGCrazyQuery(human)
	CrazyLogic.sendData(human)
	return true
end

function onCGCrazyRank(human)
	return true
end

function onCGCrazyFight(human)
	CrazyLogic.fight(human)
	return true
end

function onCGCrazySumit(human,isDie,harm,heroList)
	CrazyLogic.sumit(human,isDie == 1,harm,heroList)
	return true
end

function onCGCrazyCheckTeam(human, rank)
	local hasRank,record = CrazyLogic.hasThatRank(rank)
	if hasRank == true then
		local offObj = HumanManager.getOnline(record.account) or HumanManager.loadOffline(record.account)
		return Msg.SendMsg(PacketID.GC_CRAZY_CHECK_TEAM, human, rank, record.fight, offObj.db.flowerCount, record.heroList)
	end
end
