module(...,package.seeall)
local Guild = require("modules.guild.Guild")
local GuildDefine = require("modules.guild.GuildDefine")
local GUILD_DESTROY_RET = GuildDefine.GUILD_DESTROY_RET
local GuildLvConfig = require("config.GuildLvConfig").Config
local GuildConstConfig = require("config.GuildConstConfig").Config
local SaveQueue = require("modules.guild.GuildSave")
local SensitiveFilter = require("modules.public.SensitiveFilter")
local MailManager = require("modules.mail.MailManager")
local EventHandler = require("modules.guild.EventHandler")
local Boss = require("modules.guild.boss.Boss")
local GUILD_CREATE_RET = GuildDefine.GUILD_CREATE_RET
local GUILD_APPLY_RET = GuildDefine.GUILD_APPLY_RET
local GUILD_APPLY_QUERY = GuildDefine.GUILD_APPLY_QUERY
local GUILD_MEMBER_QUERY= GuildDefine.GUILD_MEMBER_QUERY
local GUILD_ACCEPT = GuildDefine.GUILD_ACCEPT
local GUILD_ACCEPT_RET = GuildDefine.GUILD_ACCEPT_RET
local GUILD_MEM_OPERATE = GuildDefine.GUILD_MEM_OPERATE
local GUILD_MEM_OPERATE_RET = GuildDefine.GUILD_MEM_OPERATE_RET
local GUILD_QUIT_RET = GuildDefine.GUILD_QUIT_RET
local ns = "guild"
GuildList = GuildList or {}
NameList = NameList or {}
IdList = IdList or {}
SortList = SortList or {}
SortFightVal = SortFightVal or {}
GuildCurMaxId = GuildCurMaxId or GuildDefine.GUILD_START_ID
SQ = SQ or SaveQueue.new()

function init()
	loadDB()
	local saveTimer = Timer.new(60*1000,-1)
	saveTimer:setRunner(save)
	saveTimer:start()
	reSortGuildByActive()	
	reSortGuildByFightVal()	
end

function reSortGuild()
	reSortGuildByActive()	
	reSortGuildByFightVal()	
end

function loadDB()
	local pCursor = g_oMongoDB:SyncFind(ns,{});
	if not pCursor then
		return true
	end
	local cursor = MongoDBCursor(pCursor)
	while(true) do
		local guild = Guild.new()
		if not cursor:Next(guild.db) then
			guild:destroy()
			break
		end
		addGuild(guild)
	end
	return true 
end

--创建公会
function createGuild(human,guildName)
	guildName = string.gsub(guildName, " ", "")
	local ret,retCode = checkGuildName(guildName)
	if not ret then
		return false,retCode
	end
	if NameList[guildName] then
		return false,GUILD_CREATE_RET.kNameExist
	end
	if human:getGuildId() ~= 0 then
		return false,GUILD_CREATE_RET.kHasGuild
	end
	local charlv = GuildConstConfig[1].lv
	if human:getLv() < charlv then
		return false,GUILD_CREATE_RET.kNotLv
	end
	local cost = GuildConstConfig[1].cost
	if human:getRmb() < cost then
		return false,GUILD_CREATE_RET.kNotRmb
	end

	local guild = Guild.new()
	guild:setName(guildName)
	guild:setId(GuildCurMaxId+1)
	local icon = math.random(1,26) --公会图标
	guild:setIcon(icon)
	guild:addMember(human,GuildDefine.GUILD_LEADER)
	if not guild:add() then
		guild:destroy()
		return false
	end
	addGuild(guild)
	human:decRmb(cost,nil,CommonDefine.RMB_TYPE.DEC_GUILD_CREATE)
	human:sendHumanInfo()

	reSortGuildByFightVal()

	local logTb = Log.getLogTb(LogId.GUILD_CREATE)
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.costName = "钻石"
	logTb.costNum = cost
	logTb.guildName = guild:getName()
	logTb.guildId = guild:getId()
	logTb:save()

	return true,GUILD_CREATE_RET.kOk
end

function checkGuildName(name)
	local charTab = Util.utf2tb(name)
	local nameLen = #charTab
    if nameLen < 1 then
		return false,GUILD_CREATE_RET.kNameInVaild
	end
	if nameLen > 8 then
		return false,GUILD_CREATE_RET.kNameLen
	end
	if SensitiveFilter.hasSensitiveWord(name) then
		return false,GUILD_CREATE_RET.kNameInVaild
	end
	return true
end

function addGuild(guild)
	if GuildCurMaxId < guild:getId() then
		GuildCurMaxId = guild:getId()
	end
	NameList[guild:getName()] = guild
	IdList[guild:getId()] = guild
	table.insert(GuildList,guild)
end

--搜索公会
function searchGuild(id)
	local ret = {}
	if id == 0 then
		for k,v in pairs(IdList) do
			table.insert(ret,v)
		end
	else
		table.insert(ret,IdList[id])
	end
	return ret
end

--解散公会
function destroyGuild(human)
	if human:getGuildId() == 0 then
		return false,GUILD_DESTROY_RET.kNoGuild
	end
	local guild = IdList[human:getGuildId()]
	local guildId = human:getGuildId()
	local guildName = guild:getName()
	if guild == nil then
		return false,GUILD_DESTROY_RET.kNotExist
	end
	local count = guild:getMemCount()
	if count > 1 then
		return false,GUILD_DESTROY_RET.kHasMember
	end
	local kPos,member = guild:getMemberByAccount(human:getAccount())
	if kPos == nil or member == nil then
		return false,GUILD_DESTROY_RET.kNoMember
	end
	if member.pos ~= GuildDefine.GUILD_LEADER then
		return false,GUILD_DESTROY_RET.kErrLeader
	end
	IdList[guild:getId()] = nil
	NameList[guild:getName()] = nil
	for k,v in pairs(GuildList) do
		if v:getId() == guild:getId() then
			table.remove(GuildList,k)
			break
		end
	end
	reSortGuildByActive()
	reSortGuildByFightVal()
	guild:destroy(true)
	human:sendHumanInfo()

	local logTb = Log.getLogTb(LogId.GUILD)
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.mType= 4
	logTb.guildName = guildName
	logTb.guildId = guildId
	logTb:save()

	return true,GUILD_DESTROY_RET.kOk
end

--退出公会
function quitGuild(human)
	if human:getGuildId() == 0 then
		return false,GUILD_QUIT_RET.kNoGuild
	end
	local guildId = human:getGuildId()
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false,GUILD_QUIT_RET.kNotExist
	end
	local kPos,member = guild:getMemberByAccount(human:getAccount())
	if kPos == nil or member == nil then
		return false,GUILD_QUIT_RET.kNoMember
	end
	if member.pos == GuildDefine.GUILD_LEADER then
		return false,GUILD_QUIT_RET.kErrLeader
	end
	--清boss
	local boss = Boss.getBoss(guildId)
	if boss then
		boss.hurtlist[human:getAccount()] = nil
		boss.hurtRank = nil
	end
	--清红包
	guild:returnPaper(human:getAccount())

	guild:removeMember(kPos)
	human:setGuildId(0)
	human:setGuildCD()
	human:sendHumanInfo()

	local logTb = Log.getLogTb(LogId.GUILD)
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.mType= 3
	logTb.guildName = guild:getName()
	logTb.guildId = guildId
	logTb:save()

	return true,GUILD_QUIT_RET.kOk
end

--取消申请加入公会
function applyGuildCancel(human,guildId)
	if human:getGuildId() ~= 0 then
		return false,GuildDefine.GUILD_APPLY_CANCEL_RET.kHasGuild
	end
	local guild = IdList[guildId]
	if guild == nil then
		return false,GuildDefine.GUILD_APPLY_CANCEL_RET.kNotExist
	end
	guild:delApplyMem(human)

	local memberlist = guild:getMemberList()
	for k,v in pairs(memberlist) do
		if v.pos == GuildDefine.GUILD_LEADER or 
			v.pos == GuildDefine.GUILD_SENIOR then
			local obj = HumanManager.getOnline(v.account) 
			if obj then
				EventHandler.onCGGuildApplyQuery(obj)
			end
		end
	end
	setDirty(guild:getId())
	return true,GuildDefine.GUILD_APPLY_CANCEL_RET.kOk
end

--申请加入公会
function applyGuild(human,guildId)
	if human:getGuildId() ~= 0 then
		return false,GUILD_APPLY_RET.kHasGuild
	end
	local guild = IdList[guildId]
	if guild == nil then
		return false,GUILD_APPLY_RET.kNotExist
	end
	if os.time() - human:getGuildCD() < GuildDefine.QUIT_GUILD_CD then
		return false,GUILD_APPLY_RET.kGuildCD
	end
	if guild:isInApplyList(human) then
		return false,GUILD_APPLY_RET.kHasApply
	end
	guild:addApplyMem(human)
	
	local memberlist = guild:getMemberList()
	for k,v in pairs(memberlist) do
		if v.pos == GuildDefine.GUILD_LEADER or 
			v.pos == GuildDefine.GUILD_SENIOR then
			local obj = HumanManager.getOnline(v.account) 
			if obj then
				EventHandler.onCGGuildApplyQuery(obj)
			end
		end
	end

	setDirty(guild:getId())

	local logTb = Log.getLogTb(LogId.GUILD)
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.mType= 1
	logTb.guildName = guild:getName()
	logTb.guildId = guildId
	logTb:save()

	return true,GUILD_APPLY_RET.kOk
end

--接受申请加入
function acceptJoin(human,id,op)
	if human:getGuildId() == 0 then
		return false,GUILD_ACCEPT_RET.kNoGuild
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false,GUILD_ACCEPT_RET.kNoGuild
	end
	local pos,applyer = guild:getApplyer(id)
	if pos == nil or applyer == nil then
		--return false,GUILD_ACCEPT_RET.kNoMember
		return true,GUILD_ACCEPT_RET.kHasGuild
	end
	local kPos,myMember = guild:getMemberByAccount(human:getAccount())
	if myMember == nil then
		return false,GUILD_ACCEPT_RET.kNoMember
	end
	if myMember.pos ~= GuildDefine.GUILD_LEADER and
		myMember.pos ~= GuildDefine.GUILD_SENIOR then
		return false,GUILD_ACCEPT_RET.kNoAuth
	end
	if op == GUILD_ACCEPT.kAgree then
		local lv = guild:getLv()
		local cfg = GuildLvConfig[lv]
		if guild:getMemCount() >= cfg.memCount then
			return false,GUILD_ACCEPT_RET.kMaxMem
		end
		guild:removeApplyer(pos)
		local obj = HumanManager.getOnline(applyer.account) or HumanManager.loadOffline(applyer.account)
		if obj.db.guildId ~= 0 then
			return true,GUILD_ACCEPT_RET.kHasGuild
		end
		guild:addMember(obj,GuildDefine.GUILD_NORMAL)
		if HumanManager.getOnline(applyer.account) then
			obj:sendHumanInfo()
		end
		MailManager.sysSendMail(obj:getAccount(),"公会","公会申请审核通过")
		--删除其它公会申请列表
		for k,v in pairs(IdList) do
			local kPos,kApplyer = v:getApplyerByAccount(applyer.account)
			if kPos and kApplyer then
				v:removeApplyer(kPos)
			end
		end
	else
		guild:removeApplyer(pos)
	end
	setDirty(guild:getId())

	local logTb = Log.getLogTb(LogId.GUILD)
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.mType= 2
	logTb.guildName = guild:getName()
	logTb.guildId = human:getGuildId()
	logTb:save()

	return true,GUILD_ACCEPT_RET.kOk
end

--成员操作
function memberOperate(human,id,op)
	if human:getGuildId() == 0 then
		return false,GUILD_MEM_OPERATE_RET.kNoGuild
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false,GUILD_MEM_OPERATE_RET.kNoGuild
	end
	local pos,member = guild:getMember(id)
	if pos == nil or member == nil then
		return false,GUILD_MEM_OPERATE_RET.kNoMember
	end
	local kPos,leader = guild:getMemberByAccount(human:getAccount())
	if leader == nil then
		return false,GUILD_MEM_OPERATE_RET.kNoMember
	end
	if leader.id == member.id then
		return false,GUILD_MEM_OPERATE_RET.kNoOperateOwn
	end
	if leader.pos ~= GuildDefine.GUILD_LEADER then
		return false,GUILD_MEM_OPERATE_RET.kNoAuth
	end
	if op == GUILD_MEM_OPERATE.kAppoint then
		local lv = guild:getLv()
		local cfg = GuildLvConfig[lv]
		if guild:getSeniorCount() >= cfg.elderCount then
			return false,GUILD_MEM_OPERATE_RET.kMaxSenior
		end
		member.pos = GuildDefine.GUILD_SENIOR
	elseif op == GUILD_MEM_OPERATE.kPassto then
		leader.pos = GuildDefine.GUILD_NORMAL
		member.pos = GuildDefine.GUILD_LEADER
	elseif op == GUILD_MEM_OPERATE.kKickoff then
		guild:returnPaper(member.account)
		guild:removeMember(pos)
		local obj = HumanManager.getOnline(member.account) or HumanManager.loadOffline(member.account)
		obj.db.guildId = 0
		obj.db.guildCD = os.time()
		if HumanManager.getOnline(member.account) then
			obj:sendHumanInfo()
		end
		MailManager.sysSendMail(obj:getAccount(),"公会","你被踢出了公会")
	elseif op == GUILD_MEM_OPERATE.kRemove then
		member.pos = GuildDefine.GUILD_NORMAL
	end
	setDirty(guild:getId())
	return true,GUILD_MEM_OPERATE_RET.kOk
end

--查询申请列表
function applyQuery(human)
	if human:getGuildId() == 0 then
		return false,GUILD_APPLY_QUERY.kNotGuild
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false,GUILD_APPLY_QUERY.kNotGuild
	end
	local kPos,myMember = guild:getMemberByAccount(human:getAccount())
	if myMember == nil then
		return false,GUILD_APPLY_QUERY.kNotGuild
	end
	--if myMember.pos ~= GuildDefine.GUILD_LEADER and
	--	myMember.pos ~= GuildDefine.GUILD_SENIOR then
	--	return false,GUILD_APPLY_QUERY.kNoAuth
	--end
	local applylist = guild:getApplyList()
	return true,GUILD_APPLY_QUERY.kOk,applylist
end

--查询成员列表
function memberQuery(human)
	if human:getGuildId() == 0 then
		return false,GUILD_MEMBER_QUERY.kNotGuild
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false,GUILD_MEMBER_QUERY.kNotGuild
	end
	local kPos,me = guild:getMemberByAccount(human:getAccount())
	local memberlist = guild:getMemberList()
	return true,GUILD_MEMBER_QUERY.kOk,me,memberlist
end

--查询公会信息
function guildQuery(human)
	if human:getGuildId() == 0 then
		return false
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false
	end
	local kPos,mem = guild:getMemberByAccount(human:getAccount())
	if mem == nil then
		return false
	end
	return true,guild,mem.pos
end

--修改宣言
function guildModAnnounce(human,content)
	if #content > 180 then
		return false,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kFail
	end
	if SensitiveFilter.hasSensitiveWord(content) then
		return false,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kSensitive
	end
	if human:getGuildId() == 0 then
		return false,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kFail
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kFail
	end
	local kPos,myMember = guild:getMemberByAccount(human:getAccount())
	if myMember == nil then
		return false,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kFail
	end
	if myMember.pos ~= GuildDefine.GUILD_LEADER and
		myMember.pos ~= GuildDefine.GUILD_SENIOR then
		return false,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kFail
	end
	guild:setAnnounce(content)
	setDirty(guild:getId())
	return true,GuildDefine.GUILD_MOD_ANNOUNCE_RET.kOk
end

function save(isSync)
	local saveCnt = isSync and -1 or 1
	while(not SQ:empty())do
		local id = SQ:pop()
		local guild = IdList[id]
		if guild then
			guild:save(isSync)
		end
		saveCnt = saveCnt - 1
		if saveCnt == 0 then
			break
		end
	end
end

function onLogin(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return
	end
	local guild = IdList[guildId]
	if guild == nil then
        LogErr("error", string.format("GuildManager onLogin guild account:%s,guildId:%d",human:getAccount(),guildId));
		human:setGuildId(0)
		human:sendHumanInfo()
		return
	end
	local kPos,member = guild:getMemberByAccount(human:getAccount())
	if member == nil then
        LogErr("error", string.format("GuildManager onLogin member account:%s,guildId:%d",human:getAccount(),guildId));
		human:setGuildId(0)
		human:sendHumanInfo()
		return
	end
	member.lastLogin = human.db.lastLogin
	member.icon = human.db.bodyId
end

function onLogout(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		for k,v in pairs(IdList) do
			local kPos,applyer = v:getApplyerByAccount(human:getAccount())
			if kPos and applyer then
				applyer.name = human:getName()
				applyer.lv = human:getLv()
				applyer.icon = human:getBodyId()
			end
		end
	else
		local guild = IdList[guildId]
		if guild then
			local kPos,member = guild:getMemberByAccount(human:getAccount())
			member.name = human:getName()
			member.lv = human:getLv()
			member.icon = human:getBodyId()
		end
	end
end

function onHumanDecPhysics(hm,event)
	addGuildActive(event.obj,event.val)
end

function onHumanDecEnergy(hm,event)
	addGuildActive(event.obj,event.val)
end

function addGuildActive(human,val)
	if human:getGuildId() == 0 then
		return false
	end
	local guild = IdList[human:getGuildId()]
	if guild == nil then
		return false
	end
	guild:incActive(val)
	setDirty(guild:getId())
	return  true
end

function reSortGuildByFightVal()
	--SortFightVal = Util.deepCopy(GuildList)
	SortFightVal = {}
	for i = 1,#GuildList do
		local guild = GuildList[i]
		if guild:getFightVal() > 0 then
			local copy = Util.deepCopy(guild)
			table.insert(SortFightVal,copy)
		end
	end
	for i = 1,#SortFightVal do
		local guild = SortFightVal[i]
		Guild.bind(guild)
		guild.fightVal = guild:getFightVal()
	end
	table.sort(SortFightVal,function(a,b)
		return a.fightVal > b.fightVal
	end)
end

function getSortFightVal()
	return SortFightVal
end

function getSortFightValRank(id)
	local rank = #SortFightVal + 1
	for i = 1,#SortFightVal do
		if SortFightVal[i]:getId() == id then
			rank = i
		end
	end
	return rank
end

function reSortGuildByActive()
	SortList = {}
	--for n = 1,GuildDefine.MAX_ACTIVE_GUILD_RANK do
	--	if not GuildList[n] then
	--		break
	--	end
	--	SortList[n] = GuildList[n]
	--end
	local n = 0
	while true do
		n = n + 1
		if n > #GuildList then 
			break
		end
		if GuildList[n].db.dayActive > 0 then
			table.insert(SortList,GuildList[n])
			if #SortList >= GuildDefine.MAX_ACTIVE_GUILD_RANK then
				break
			end
		end
	end
	if not next(SortList) then
		return 
	end
	table.sort(SortList,function(a,b)return a.db.dayActive > b.db.dayActive end)
	if #SortList <= GuildDefine.MAX_ACTIVE_GUILD_RANK then
		--Util.print_r(SortList)
		return
	end
	for i = GuildDefine.MAX_ACTIVE_GUILD_RANK + 1,#GuildList do
		local insertPos 
		for j = #SortList,1,-1 do
			if SortList[j].db.dayActive >= GuildList[i].db.dayActive then
				break
			end
		end
		insertPos = j
	end
	if insertPos then
		for k = #SortList+1,insertPos+1,-1 do
			SortList[k] = SortList[k-1]
		end
		SortList[insertPos] = GuildList[i]
		SortList[#SortList] = nil
	end
	--Util.print_r(SortList)
end

function getGuildSortList()
	return SortList
end

function getGuildSortRankData()
	local list = {}
	for i = 1,#SortList do
		local guild = SortList[i]
		local data = {}
		data.name = guild.db.name
		data.icon = guild.db.icon
		data.lv = guild.db.lv
		data.fight = guild.db.dayActive
		table.insert(list,data)
	end
	return list
end

function getGuildIdList()
	return IdList
end

function getGuildNameByGuildId(guildId)
	return (IdList[guildId] and IdList[guildId]:getName()) or "暂无公会"
end

function setDirty(guildId)
	SQ:push(guildId)
end

function refreshDayActive()
	for k,v in pairs(GuildList) do
		if v.db.dayActive > 0 then
			v.db.dayActive = 0
			setDirty(v:getId())
		end
	end
end

function getPosName(pos)
	if pos == GuildDefine.GUILD_LEADER then
		return "会长"
	elseif pos == GuildDefine.GUILD_SENIOR then
		return "长老"
	else
		return "帮众"
	end
end
