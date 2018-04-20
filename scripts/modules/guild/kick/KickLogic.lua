module(...,package.seeall)
local GuildManager = require("modules.guild.GuildManager")
local Msg = require("core.net.Msg")
local KickDefine = require("modules.guild.kick.KickDefine")
local Arena = require("modules.arena.Arena")
local SkillLogic = require("modules.skill.SkillLogic")
local KickConstConfig = require("config.KickConstConfig").Config
local WineLogic = require("modules.guild.wine.WineLogic")
local BagLogic = require("modules.bag.BagLogic")
local Hero = require("modules.hero.Hero")

function onHumanLogin(hm,human)
end

function guildQuery(human)
	if human.db.kick.reset ~= os.date("%d") then 
		human.db.kick.cnt = 0
		human.db.kick.reset = os.date("%d")
	end
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,KickDefine.GUILD_QUERY_RET.kNoGuild
	end
	local myGuild = GuildManager.getGuildIdList()[guildId]
	if not myGuild then
		return false,KickDefine.GUILD_QUERY_RET.kNoGuild
	end
	local sortList = GuildManager.getSortFightVal()
	local rank = GuildManager.getSortFightValRank(guildId)
	local startId = math.max(1,rank-KickDefine.KICK_GUILD_NUM)
	local endId = math.min(rank+KickDefine.KICK_GUILD_NUM,#sortList)
	local temp = {}
	local len = 0
	for i = startId,endId do
		if i ~= rank then
			len = len + 1
			table.insert(temp,{rank=i,val=sortList[i].fightVal})
		end
		if len >= KickDefine.KICK_GUILD_NUM then
			break
		end
	end
	if not next(temp) then
		return false
	end
	table.sort(temp,function(a,b)return a.rank < b.rank end)
	local ret = {}
	for i = 1,#temp do
		local data = {}
		local r = temp[i].rank
		local guild = sortList[r]
		data.id = guild:getId()
		data.name = guild:getName()
		data.rank = r
		data.fightVal = guild.fightVal
		table.insert(ret,data)
	end
	local cnt = human.db.kick.cnt
	local fightList = human.db.kick.fightList
	return true,KickDefine.GUILD_QUERY_RET.kOk,ret,cnt,fightList
end

function memberQuery(human,id)
	local guild = GuildManager.getGuildIdList()[id]
	if not guild then
		return false,KickDefine.MEMBER_QUERY_RET.kNoGuild
	end
	local ret = guild:getNearOpponent(human)
	return true,KickDefine.MEMBER_QUERY_RET.kOk,ret
end

function fightBegin(human,guildId,memberId,fightList)
	local guild = GuildManager.getGuildIdList()[guildId]
	if not guild then
		return false,KickDefine.KICK_BEGIN_RET.kNoGuild
	end
	if human.db.kick.cnt+ 1 > KickConstConfig[1].cnt then
		return false,KickDefine.KICK_BEGIN_RET.kNoCnt
	end
	local pos,member = guild:getMember(memberId)
	local enemyAccount = member.account
	--local fightList = makeFightList(human.db.account)
	local enemy = makeEnemyData(enemyAccount)
	--if not fightList then
	--	return false,KickDefine.KICK_BEGIN_RET.kNoArena
	--end
	if human.info.lastKickTime and os.time() - human.info.lastKickTime < 10 then
		return false,KickDefine.KICK_BEGIN_RET.kKickCD
	end
	human.info.lastKickTime = os.time()
	human.db.kick.cnt = human.db.kick.cnt + 1
	human.db.kick.fightList = fightList
	--return true,KickDefine.KICK_BEGIN_RET.kOk,fightList,enemy
	
	local logTb = Log.getLogTb(LogId.GUILD_KICK)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.charName = member.name
	logTb.charAccount = member.account
	logTb.result = 0
	logTb.startType = 1
	logTb:save()

	return true,KickDefine.KICK_BEGIN_RET.kOk,enemy
end

function makeFightList(account)
	local fightList = Arena.getArenaFightList(account)
	if fightList then
		local fightData = {}
		for k,v in pairs(fightList) do
			table.insert(fightData,{name = k})
		end
		table.sort(fightData,function(a,b)return fightList[a.name].pos < fightList[b.name].pos end)
		return fightData
	end
end


function makeEnemyData(account)
	local enemyData = {}
	local enemy = Arena.getArenaHuman(account)
	if enemy then
		local rankData = Arena.getRankDataByAccount(account)
		if rankData then
			local temp = {}
			local fightList = Arena.getArenaFightList(account)
			for hName,vInfo in pairs(fightList) do
				local hero = enemy:getHero(hName)
				if hero then
					local data = {}
					data.name = hero:getName()
					data.exp = hero:getExp()
					data.quality = hero:getQuality()
					data.lv = hero:getLv()
					data.dyAttr = Util.deepCopy(hero.dyAttr)
					Hero.dyAttr1(data.dyAttr)
					local groupList = hero:getSkillGroupList()
					local groupMsg = {}
					for _,group in pairs(groupList) do
						SkillLogic.makeSkillGroupMsg(group,groupMsg)
					end
					data.skillGroupList = groupMsg 
					data.gift = hero:getGift()
					table.insert(temp,data)
				end
			end
			table.sort(temp,function(a,b) return fightList[a.name].pos < fightList[b.name].pos end)
			enemyData.fightList = temp
		end
	end
	return enemyData
end

function fightEnd(human,result,guildId,memberId)
	local guild = GuildManager.getGuildIdList()[guildId]
	if not guild then
		return false
	end
	local pos,member = guild:getMember(memberId)
	if not member then
		return false
	end
	addKickRecord(human,guild,member,result)
	if result == KickDefine.WIN then
		--加公会声望
		local rewardList = {[9901008]=100}
		rewardList = WineLogic.wineBuffDeal(human,rewardList,"kick")
		for k,v in pairs(rewardList) do
			BagLogic.addItem(human,k,v,false,CommonDefine.ITEM_TYPE.ADD_GUILD_KICK)
		end
		human:sendHumanInfo()
	end
	local logTb = Log.getLogTb(LogId.GUILD_KICK)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.charName = member.name
	logTb.charAccount = member.account
	logTb.result = result
	logTb.startType = 0
	logTb:save()

	return true
end

function addKickRecord(human,guild,member,win)
	local enemy = Arena.getArenaHuman(member.account)
	local enemyFightList = Arena.getArenaFightList(member.account)
	--local fightList = Arena.getArenaFightList(human.db.account)
	local fightList = {}
	local list = human.db.kick.fightList
	for i = 1,#list do
		local name = list[i].name
		fightList[name] = {pos = i}
	end
	local myGuild = GuildManager.getGuildIdList()[human:getGuildId()]
	local pos,myMember = myGuild:getMemberByAccount(human:getAccount())
	local enemyList = {}
	for k,v in pairs(enemyFightList) do
		local hero = enemy:getHero(k)
		if hero then
			table.insert(enemyList,{name=k,pos=v.pos,lv= hero.db.lv,quality = hero.db.quality,transferLv = hero.db.strength.transferLv})
		end
	end
	table.sort(enemyList,function(a,b)return enemyFightList[a.name].pos < enemyFightList[b.name].pos end)
	local charList = {}
	for k,v in pairs(fightList) do
		local hero = human:getHero(k)
		if hero then
			table.insert(charList,{name=k,pos=v.pos,lv= hero.db.lv,quality = hero.db.quality,transferLv = hero.db.strength.transferLv})
		end
	end
	table.sort(charList,function(a,b)return fightList[a.name].pos < fightList[b.name].pos end)
	if myGuild then
		local recordA = {
			guildId = myGuild:getId(),
			memberId = myMember.id,
			enemyGuildId = guild:getId(),
			enemyMemberId = member.id,
			enemyFightList = enemyList,
			fightList = charList,
			result = win == KickDefine.WIN and win or KickDefine.LOSE,
		}
		table.insert(myGuild.db.kickRecord,1,recordA)
		if #myGuild.db.kickRecord > KickDefine.MAX_RECORD then
			table.remove(myGuild.db.kickRecord,#myGuild.db.kickRecord)
		end

		local recordB = {
			guildId = guild:getId(),
			memberId = member.id,
			enemyGuildId = myGuild:getId(),
			enemyMemberId = myMember.id,
			enemyFightList = charList,
			fightList = enemyList,
			result = win == KickDefine.WIN and KickDefine.LOSE or KickDefine.WIN,
		}
		table.insert(guild.db.kickRecord,1,recordB)
		if #guild.db.kickRecord > KickDefine.MAX_RECORD then
			table.remove(guild.db.kickRecord,#guild.db.kickRecord)
		end
		GuildManager.setDirty(myGuild:getId())
		GuildManager.setDirty(guild:getId())
	end
end

function recordQuery(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if not guild then
		return false
	end
	local ret = {}
	for i = 1,#guild.db.kickRecord do
		local record = guild.db.kickRecord[i]
		local myGuild = GuildManager.getGuildIdList()[record.guildId]
		local _,member = myGuild:getMember(record.memberId)
		local enemyGuild = GuildManager.getGuildIdList()[record.enemyGuildId]
		if enemyGuild then
			local _,enemyMember = enemyGuild:getMember(record.enemyMemberId)
			local kickRecord = {}
			kickRecord.myGuildName = myGuild:getName()
			kickRecord.myGuildLv = myGuild:getLv()
			kickRecord.charName = member.name
			kickRecord.charFightlist = record.fightList
			kickRecord.enemyGuildName = enemyGuild:getName()
			kickRecord.enemyGuildLv = enemyGuild:getLv()
			kickRecord.enemyName = enemyMember.name
			kickRecord.enemyFightlist = record.enemyFightList
			kickRecord.result = record.result
			table.insert(ret,kickRecord)
		end
	end
	Msg.SendMsg(PacketID.GC_KICK_RECORD,human,ret)
end
