module(...,package.seeall)
local MonsterConfig = require("config.MonsterConfig").Config
local BossDefine = require("modules.guild.boss.BossDefine")
local Crontab = require("modules.public.Crontab")
local Boss = require("modules.guild.boss.Boss")
local Msg = require("core.net.Msg")
local ns = "guildBoss"
local RANK_MODULE_GUILD_BOSS = "guildBoss"

function init()
	loadDB()
	local saveTimer = Timer.new(60*1000, -1)
	saveTimer:setRunner(save)
	saveTimer:start()
end

function loadDB()
	--local pCursor = g_oMongoDB:SyncFind(ns,{})
	--if not pCursor then
	--	return
	--end
	--local cursor = MongoDBCursor(pCursor)
	--while(true) do
	--	local tmp = {}
	--	if not cursor:Next(tmp) then
	--		break
	--	end
	--	RankList[tmp.id] = tmp
	--end
end

function save(isSync)
	--for k,v in pairs(DirtyRank) do
	--	local query = {id = k}
	--	local data = RankList[k]
	--	DB.Update(ns,query,data,isSync)
	--end
	--DirtyRank = {}
end

function startBoss()
	Boss.init()
end

function endBoss()
	Boss.endBoss()
end

function enter(human,heroList)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,BossDefine.BOSS_ENTER_RET.kNoGuild
	end
	if not Boss.isDuring() then
		return false,BossDefine.BOSS_ENTER_RET.kActEnd
	end
	local boss = Boss.getBoss(guildId)
	if not boss then
		boss = Boss.born(guildId)
	end
	if boss.status == BossDefine.BOSS_STATUS_END then
		return false,BossDefine.BOSS_ENTER_RET.kBossDie
	end
	if human.db.guildBossCD > os.time() then
		return false,BossDefine.BOSS_ENTER_RET.kBossEnterCD
	end
	human.db.guildBossCD = os.time() + BossDefine.BOSS_ENTER_CD
	local hp = Boss.enter(human,heroList)
	local bossId = boss.bossId
	return true,BossDefine.BOSS_ENTER_RET.kOk,bossId,hp
end

function hurt(human,hurt)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,BossDefine.BOSS_HURT_RET.kNoGuild
	end
	if not Boss.getBoss(guildId) then
		return false,BossDefine.BOSS_HURT_RET.kNoBoss
	end
	Boss.hurt(human,hurt)
	return true,BossDefine.BOSS_HURT_RET.kOk
end

function leave(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,BossDefine.BOSS_LEAVE_RET.kNoGuild
	end
	local boss = Boss.getBoss(guildId)
	if boss then
		Boss.leave(human)
	end
	return true,BossDefine.BOSS_LEAVE_RET.kOk
end

function query(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false
	end
	local hasStart = 0
	if Boss.isDuring(guildId) then
		hasStart = 1
	end
	local boss = Boss.getBoss(guildId)
	local hurt = 0
	local heroList = {}
	if boss then
		hurt = boss.hurtlist[human:getAccount()] or 0
		heroList = boss.herolist[human:getAccount()] or {}
	end
	local coolTime = math.max(human.db.guildBossCD - os.time(),0)
	Msg.SendMsg(PacketID.GC_GUILD_BOSS_QUERY,human,hasStart,coolTime,hurt,heroList)
end

function rankQuery(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false
	end
	local boss = Boss.getBoss(guildId)
	if boss then
		local ret = {}
		local list = Boss.getSortHurtList(boss)
		for i = 1,#list do
			local data = {}
			local account = list[i].account
			local obj = HumanManager.getOnline(account) or HumanManager.loadOffline(account)
			data.rank = i	
			data.name = obj:getName()
			data.icon = obj:getBodyId()
			data.lv = obj:getLv()
			data.hurt = list[i].val
			table.insert(ret,data)
		end
		--print("GC_GUILD_BOSS_RANK")
		--Util.print_r(ret)
		Msg.SendMsg(PacketID.GC_GUILD_BOSS_RANK,human,ret)
	end
end
function checkTeam(human,rank)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false
	end
	local boss = Boss.getBoss(guildId)
	if boss then
		local list = Boss.getSortHurtList(boss)
		local data = list[rank]
		if data then
			local obj = HumanManager.getOnline(data.account) or HumanManager.loadOffline(data.account)
			local ret = {}
			local heroList = boss.herolist[data.account] or {}
			local val = 0
			for i = 1,#heroList do
				local data = {}
				data.name = heroList[i]
				local hero = obj:getHero(data.name)
				if hero then
					data.quality = hero:getQuality()
					data.lv = hero:getLv()
					val = val + hero:getFight()
				end
				table.insert(ret,data)
			end
			Msg.SendMsg(PacketID.GC_GUILD_BOSS_CHECK_TEAM,human,rank,val,obj.db.flowerCount,ret)
		end
	end
end

function enterQuery(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,BossDefine.BOSS_ENTER_QUERY_RET.kNoGuild
	end
	if not Boss.isDuring() then
		return false,BossDefine.BOSS_ENTER_QUERY_RET.kActEnd
	end
	local boss = Boss.getBoss(guildId)
	if boss and boss.status == BossDefine.BOSS_STATUS_END then
		return false,BossDefine.BOSS_ENTER_QUERY_RET.kBossDie
	end
	if human.db.guildBossCD > os.time() then
		return false,BossDefine.BOSS_ENTER_QUERY_RET.kBossEnterCD
	end
	return true,BossDefine.BOSS_ENTER_QUERY_RET.kOk
end
