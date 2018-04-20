module(...,package.seeall)

local Define = require("modules.rank.RankDefine")
local Arena = require("modules.arena.Arena")
local Logic = require("modules.rank.RankLogic")
local Msg = require("core.net.Msg")
local GuildManager = require("modules.guild.GuildManager")
local FlowerRank = require("modules.flower.FlowerRank")
local OrochiRank = require("modules.orochi.OrochiRank")
local TrialRank = require("modules.trial.TrialRank")
local RankHero = require("modules.rank.RankHero")
local RankMoney = require("modules.rank.RankMoney")
local RankExp = require("modules.rank.RankExp")

function onCGRankList(human, typeVal)
	if typeVal == Define.RANK_TYPE_ARENA then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, Logic.composeRankList(Arena.getPosRankData()))
	elseif typeVal == Define.RANK_TYPE_FIGHT then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, Logic.composeRankList(Arena.getFightRankData()))
	elseif typeVal == Define.RANK_TYPE_GUILD then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, GuildManager.getGuildSortRankData())
	elseif typeVal == Define.RANK_TYPE_FLOWER then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, Logic.composeRankList(FlowerRank.getTempRankList()))
	elseif typeVal == Define.RANK_TYPE_HERO then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, RankHero.getRankList())
	elseif typeVal == Define.RANK_TYPE_MONEY then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, RankMoney.getRankList())
	elseif typeVal == Define.RANK_TYPE_EXP then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, RankExp.getRankList())
	elseif typeVal == Define.RANK_TYPE_GUILD_FIGHT then
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, Logic.composeGuildFightRankList(GuildManager.getSortFightVal()))
	else
		Msg.SendMsg(PacketID.GC_RANK_LIST, human, {})
	end
end

function onCGRankCheck(human, typeVal, rank)
	local data = nil
	if typeVal == Define.RANK_TYPE_ARENA then
		data = Arena.getPosRankData()[rank]
		data.rank = rank
	elseif typeVal == Define.RANK_TYPE_FIGHT then
		data = Arena.getFightRankData()[rank]
	elseif typeVal == Define.RANK_TYPE_OROCHI then
		data = OrochiRank.getRankDataByLevelId(rank)
	elseif typeVal == Define.RANK_TYPE_FLOWER then
		data = FlowerRank.getTempRankList()[rank]
	elseif typeVal == Define.RANK_TYPE_TRIAL then
		data = TrialRank.RankList[rank]
	elseif typeVal == Define.RANK_TYPE_HERO then
		data = RankHero.getRankData(rank)
	elseif typeVal == Define.RANK_TYPE_GUILD_FIGHT then
		data = Logic.composeGuildData(GuildManager.getSortFightVal(), rank)
	end
	if data ~= nil then
		Msg.SendMsg(PacketID.GC_RANK_CHECK, human, data)
	end
end
