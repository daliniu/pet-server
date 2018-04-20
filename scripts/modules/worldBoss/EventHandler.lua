module(...,package.seeall)

local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local Logic = require("modules.worldBoss.WorldBossLogic")
local Define = require("modules.worldBoss.WorldBossDefine")
local HumanManager = require("core.managers.HumanManager")
local GuildManager = require("modules.guild.GuildManager")

function onCGWorldBossQuery(human)
	local hasStart = (Logic.hasBossStart() and 1) or 0
	return Msg.SendMsg(PacketID.GC_WORLD_BOSS_QUERY, human, hasStart, Logic.getTimeGap(), human.worldBossCD, Logic.getAcountHurtHp(human))
end

function onCGWorldBossEnter(human, heroNameList)
	if Logic.hasBossStart() == true then
		if Logic.hasSelHero(heroNameList) then
			if Logic.hasEnoughLvToOpen(human) then
				if Logic.isInCoolTime(human) == false then
					Logic.enterWorldBoss(human, heroNameList)
					HumanManager:dispatchEvent(HumanManager.Event_WorldBoss,{human=human})
					Msg.SendMsg(PacketID.GC_WORLD_BOSS_ENTER, human, Define.ERR_CODE.ENTER_SUCCESS, Logic.getBossHp(), heroNameList)
				else
					--冷却时间内
					return Msg.SendMsg(PacketID.GC_WORLD_BOSS_ENTER, human, Define.ERR_CODE.ENTER_COOL_TIME, 0, nil)
				end
			else
				--不够级
				return Msg.SendMsg(PacketID.GC_WORLD_BOSS_ENTER, human, Define.ERR_CODE.ENTER_NO_LV, 0, nil)
			end
		else
			--没选择英雄
			return Msg.SendMsg(PacketID.GC_WORLD_BOSS_ENTER, human, Define.ERR_CODE.ENTER_NO_HERO, 0, nil)
		end
	else
		--还没开始
		return Msg.SendMsg(PacketID.GC_WORLD_BOSS_ENTER, human, Define.ERR_CODE.ENTER_NOT_START, 0, nil)
	end
end

function onCGWorldBossHurtHp(human, hurtHp)
	Logic.hurtHp(human, hurtHp)
end

function onCGWorldBossRank(human)
	local rankList = Logic.getRankList()
	local retTab = {}
	for index,record in pairs(rankList) do
		local offObj = HumanManager.getOnline(record.account) or HumanManager.loadOffline(record.account)
		local tab = {}
		tab.rank = index
		tab.name = record.name
		tab.icon = offObj.db.bodyId
		tab.lv = offObj.db.lv
		tab.hurt = record.hurt
		tab.guild = GuildManager.getGuildNameByGuildId(offObj.db.guildId)
		table.insert(retTab, tab)
	end
	return Msg.SendMsg(PacketID.GC_WORLD_BOSS_RANK, human, retTab)
end

function onCGWorldBossCheckTeam(human, rank)
	local hasRank,record = Logic.hasThatRank(rank)
	if hasRank == true then
		local offObj = HumanManager.getOnline(record.account) or HumanManager.loadOffline(record.account)
		return Msg.SendMsg(PacketID.GC_WORLD_BOSS_CHECK_TEAM, human, rank, record.fight, offObj.db.flowerCount, record.heroList)
	end
end

function onCGWorldBossLeaveCopy(human)
	Logic.removeEnterAccount(human)
end
