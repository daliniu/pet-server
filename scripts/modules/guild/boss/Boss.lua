module(...,package.seeall)
local Msg = require("core.net.Msg")
local MonsterConfig = require("config.MonsterConfig").Config
local BossDefine = require("modules.guild.boss.BossDefine")
local RewardConfig = require("config.GuildBossRewardConfig").Config
local MailManager = require("modules.mail.MailManager")
local GuildManager = require("modules.guild.GuildManager")

RefreshTimer = RefreshTimer or nil
HurtRankTimer = HurtRankTimer or nil
EndTimer = EndTimer or nil
IsDuringBoss = IsDuringBoss or false
BossGroup = BossGroup or {}
HurtRewardConfig = HurtRewardConfig or {}
RankRewardConfig = RankRewardConfig or {}
LastRewardConfig = LastRewardConfig or {}

function initConfig()
	HurtRewardConfig = {}
	RankRewardConfig = {}
	LastRewardConfig = {}
	for _,config in pairs(RewardConfig) do
		if config.type == BossDefine.BOSS_REWARD_TYPE_HURT then
			table.insert(HurtRewardConfig, config)
		elseif config.type == BossDefine.BOSS_REWARD_TYPE_RANK then
			RankRewardConfig[config.param[1]] = config
		elseif config.type == BossDefine.BOSS_REWARD_TYPE_LAST then
			table.insert(LastRewardConfig, config)
		end
	end
end

function init()
	BossGroup = {}
	IsDuringBoss = true
	if RefreshTimer then
		RefreshTimer:stop()
		RefreshTimer = nil
	end
	if HurtRankTimer then
		HurtRankTimer:stop()
		HurtRankTimer = nil
	end
	if EndTimer then
		EndTimer:stop()
		EndTimer = nil
	end
	RefreshTimer = Timer.new(BossDefine.BOSS_REFRESH_HP_RATE, -1)
	RefreshTimer:setRunner(refreshHp)
	RefreshTimer:start()

	HurtRankTimer = Timer.new(BossDefine.BOSS_HURT_RANK_RATE, -1)
	HurtRankTimer:setRunner(refreshHurtRank)
	HurtRankTimer:start()

	EndTimer = Timer.new(BossDefine.BOSS_DURING_TIME*1000,1)
	EndTimer:setRunner(endBoss)
	EndTimer:start()
end

function isDuring(guildId)
	local boss = getBoss(guildId)
	if IsDuringBoss then
		if boss and boss.status == BossDefine.BOSS_STATUS_END then
			return false
		else
			return true
		end
	else
		return false
	end
end

function endBoss()
	for id,boss in pairs(BossGroup) do
		if boss.hp > 0 then
			sendReward(boss)
			boss.status = BossDefine.BOSS_STATUS_END
			boss.hp = 0
			boss.hpDirty = true
		end
	end
	refreshHp()

	--BossGroup = {}
	IsDuringBoss = false
	if RefreshTimer then
		RefreshTimer:stop()
		RefreshTimer = nil
	end
	if HurtRankTimer then
		HurtRankTimer:stop()
		HurtRankTimer = nil
	end
	if EndTimer then
		EndTimer:stop()
		EndTimer = nil
	end
end

function sendReward(boss)
	sendHurtReward(boss)
	sendRankReward(boss)
	sendLastReward(boss)
end

function sendHurtReward(boss)
	for account,val in pairs(boss.hurtlist) do
		local human = HumanManager.getOnline(account) or HumanManager.loadOffline(account)
		if human then
			for _,config in ipairs(HurtRewardConfig) do
				if val >= config.param[1] and (config.param[2] == nil or val <= config.param[2]) then
					MailManager.sysSendMailById(human.db.account, BossDefine.BOSS_MAIL_HURT, config.reward, human.db.name)
					break
				end
			end
		end
	end
end

function sendRankReward(boss)
end

function sendLastReward(boss)
	local config = LastRewardConfig[1]
	if config then
		if boss.lastHit then
			local human = HumanManager.getOnline(boss.lastHit) or HumanManager.loadOffline(boss.lastHit)
			if human then
				MailManager.sysSendMailById(human.db.account, BossDefine.BOSS_MAIL_LAST, config.reward, human.db.name)
			end
		end
	end
end

function die(guildId)
	local boss = getBoss(guildId)
	boss.status = BossDefine.BOSS_STATUS_END
	sendReward(boss)
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild then
		guild:nextBossId()
	end
end

function born(guildId)
	local bossId = BossDefine.GUILD_BOSS_ID
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild then
		bossId = guild:getBossId()
	end
	local data = {
		guildId = guildId,
		enterlist = {},
		herolist = {},
		hurtlist = {},
		lastHit = nil,
		bossId = bossId,
		hp = MonsterConfig[bossId].maxHp,
		hpDirty = false,
		status = BossDefine.BOSS_STATUS_START,
	}
	BossGroup[guildId] = data
	setmetatable(data,{__index = _M})
	return data
end

function setEnterList(guildId,k,v)
	local boss = BossGroup[guildId]
	boss.enterlist[k] = v
	return true
end

function setHeroList(guildId,k,v)
	local boss = BossGroup[guildId]
	boss.herolist[k] = v
	return true
end

local function incHurt(guildId,k,hurt)
	local boss = BossGroup[guildId]
	boss.hurtlist[k] = (boss.hurtlist[k] or 0) + hurt
	boss.lastHit = k
	return true
end

local MAX_HURT_RANK = 10
function getSortHurtList(boss)
	if not boss.hurtRank then
		local list = {}
		for k,v in pairs(boss.hurtlist) do
			table.insert(list,{account = k,val = v})
		end
		table.sort(list,function(a,b)return a.val > b.val end)
		boss.hurtRank = list
	end
	return boss.hurtRank
end

function refreshHurtRank()
	for id,boss in pairs(BossGroup) do
		boss.hurtRank = nil
	end
end

local function decBossHp(guildId,val)
	local boss = BossGroup[guildId]
	boss.hp = math.max(boss.hp - val,0)
	boss.hpDirty = true 
	return boss.hp
end

function getBoss(guildId)
	return BossGroup[guildId]
end

function hurt(human,val)
	local guildId = human:getGuildId()
	local account = human:getAccount()
	local boss =  getBoss(guildId) 
	if boss.hp <= 0 then
		return false
	else
		val = math.min(boss.hp,val)
		incHurt(guildId,account,val)
		if decBossHp(guildId,val) <= 0 then
			die(guildId)
		end
		return true
	end
end

function enter(human,heroList)
	local guildId = human:getGuildId()
	local account = human:getAccount()
	setEnterList(guildId,account,1)
	setHeroList(guildId,account,heroList)
	local boss = getBoss(guildId)
	return boss.hp
end

function leave(human)
	local guildId = human:getGuildId()
	local account = human:getAccount()
	setEnterList(guildId,account,nil)
	return true
end

function refreshHp()
	for id,boss in pairs(BossGroup) do
		if boss.hpDirty then
			local hp = boss.hp
			local ret = {}
			for k,v in pairs(boss.enterlist) do
				local human = HumanManager.getOnline(k)
				if human then
					table.insert(ret,human.fd)
				else
					setEnterList(id,k,nil)
				end
				if #ret >= Msg.MSG_USER_BROADCAST_LIMIT_COUNT then
					Msg.UserBroadCast(PacketID.GC_GUILD_BOSS_HURT,ret,hp)
					ret = {}
				end
			end
			if #ret > 0 then
				Msg.UserBroadCast(PacketID.GC_GUILD_BOSS_HURT,ret,hp)
			end
			boss.hpDirty = false
		end
	end
end
