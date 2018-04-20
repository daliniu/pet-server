module(...,package.seeall)
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local ArenaLogic = require("modules.arena.ArenaLogic")
local Arena = require("modules.arena.Arena")

function onCGArenaQuery(human)
	ArenaLogic.arenaQuery(human)
end

function onCGArenaChangeHero(human,fightlist)
	ArenaLogic.changeHero(human,fightlist)	
end

function onCGArenaChangeEnemy(human)
	ArenaLogic.changeEnemy(human)	
end

function onCGArenaFightBegin(human,enemyPos)
	local ret = ArenaLogic.fightBegin(human,enemyPos)
	Msg.SendMsg(PacketID.GC_ARENA_FIGHT_BEGIN,human,ret,enemyPos)
end

function onCGArenaFightEnd(human,result,enemyPos)
	local rewards = ArenaLogic.fightEnd(human,result,enemyPos)
	Msg.SendMsg(PacketID.GC_ARENA_FIGHT_END,human,result,rewards)
end

function onCGArenaFightRecord(human)
	ArenaLogic.fightRecord(human)
end

function onCGArenaShopQuery(human)
	ArenaLogic.shopQuery(human)
end

function onCGArenaShopRefresh(human)
	local canRefresh,retCode = ArenaLogic.shopRefresh(human)
    Msg.SendMsg(PacketID.GC_ARENA_SHOP_REFRESH,human,retCode)
end

function onCGArenaShopBuy(human,shopId)
	local canBuy,retCode = ArenaLogic.shopBuy(human,shopId)
    Msg.SendMsg(PacketID.GC_ARENA_SHOP_BUY,human,shopId,retCode)
end

function onCGArenaResetCd(human)
	local ret,retCode = ArenaLogic.resetCd(human)
    Msg.SendMsg(PacketID.GC_ARENA_RESET_CD,human,retCode)
end
