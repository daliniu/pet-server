module(...,package.seeall)
local GuildDB = require("modules.guild.GuildDB")
local GuildLvConfig = require("config.GuildLvConfig").Config
local GuildDefine = require("modules.guild.GuildDefine")
local Arena = require("modules.arena.Arena")
local KickDefine = require("modules.guild.kick.KickDefine")
local TexasLvConfig = require("config.TexasLvConfig").Config
local WineLvConfig = require("config.WineConfig").WineLvConfig
local BossDefine = require("modules.guild.boss.BossDefine")

function new()
	local guild = {
		db = GuildDB:new(),
	}
	setmetatable(guild,{__index = _M})
	return guild
end

function bind(guild)
	setmetatable(guild,{__index = _M})
end

function add(self,isSync)
	return self.db:add(isSync)
end

function save(self,isSync)
	self.db:save(isSync)
end

function destroy(self,flag)
	for k,v in pairs(self.db.memList) do
		local human = HumanManager.getOnline(v.account)
		if human then
			human:setGuildId(0)
			human:sendHumanInfo()
		end
	end
	if flag then
		self.db:destroy()
	end
end

function newMember(human,id,pos)
	local member = {
		id = id,
		account = human.db.account,
		name = human.db.name,
		lv = human.db.lv,
		icon = human.db.bodyId,
		pos = pos,
		lastLogin = human.db.lastLogin,
		createDate = os.time(),
	}
	return member
end

function addMember(self,human,pos)
	local genId = self:genMemId()
	local mem = newMember(human,genId,pos)
	table.insert(self.db.memList,mem)
	human.db.guildId = self.db.id
	return true
end

function removeMember(self,pos)
	table.remove(self.db.memList,pos)
end

function genMemId(self)
	self.db.genMemId = self.db.genMemId + 1
	return self.db.genMemId
end

function genApplyId(self)
	self.db.genApplyId = self.db.genApplyId + 1
	return self.db.genApplyId
end

function newApplyer(human,id)
	local applyer= {
		id = id,
		account = human:getAccount(),
		name = human:getName(),
		lv = human:getLv(),
		icon = human.db.bodyId,
	}
	return applyer
end

function addApplyMem(self,human)
	local genId = self:genApplyId()
	local applyer = newApplyer(human,genId)
	table.insert(self.db.applyList,applyer)
	return true
end

function delApplyMem(self,human)
	for k,v in pairs(self.db.applyList) do
		if v.account == human:getAccount() then 
			table.remove(self.db.applyList,k)
			break
		end
	end
end

function removeApplyer(self,pos)
	table.remove(self.db.applyList,pos)
end

function isInApplyList(self,human)
	for k,v in pairs(self.db.applyList) do
		if v.account == human:getAccount() then 
			return true 
		end
	end
end

function getApplyList(self)
	return self.db.applyList
end

function getMemberList(self)
	return self.db.memList
end

function getLv(self)
	return self.db.lv
end

function getMemCount(self)
	return #self.db.memList
end

function getCreateDate(self)
	return self.db.createDate
end

function getSeniorCount(self)
	local count = 0
	for k,v in pairs(self.db.memList) do
		if v.pos == GuildDefine.GUILD_SENIOR then
			count = count + 1
		end
	end
	return count
end

function getMemberByAccount(self,account)
	for k,v in pairs(self.db.memList) do
		if v.account == account then
			return k,v 
		end
	end
end

function getMember(self,id)
	for k,v in pairs(self.db.memList) do
		if v.id == id then
			return k,v 
		end
	end
end

function getLeader(self)
	for k,v in pairs(self.db.memList) do
		if v.pos == GuildDefine.GUILD_LEADER then
			return k,v
		end
	end
end

function getApplyer(self,id)
	for k,v in pairs(self.db.applyList) do
		if v.id == id then
			return k,v 
		end
	end
end

function getApplyerByAccount(self,account)
	for k,v in pairs(self.db.applyList) do
		if v.account == account then
			return k,v 
		end
	end
end

function getName(self)
	return self.db.name
end

function setName(self,name)
	self.db.name = name
end

function getId(self)
	return self.db.id
end

function setId(self,id)
	self.db.id = id 
end

function getAnnounce(self)
	return self.db.announce
end

function setAnnounce(self,content)
	self.db.announce = content
end

function getIcon(self)
	return self.db.icon
end

function setIcon(self,id)
	self.db.icon = id
end

function getActive(self)
	return self.db.active
end

function incActive(self,val)
	assert(val >= 0,"error guild incActive======>>>" .. val)
	self.db.active = self.db.active + val
	self.db.dayActive = self.db.dayActive + val
	self:checkLvUp()
end

function checkLvUp(self)
	local preLv = self:getLv()
	if preLv > #GuildLvConfig then
		return 
	end
	local cfg = GuildLvConfig[preLv]
	if not cfg then
		return
	end
	local active = self:getActive()
	local nextActive = cfg.activeness
	local nextLv = preLv
	while nextActive <= active do
		cfg = GuildLvConfig[nextLv+1]
		if not cfg then
			break
		end
		active = active - nextActive
		nextLv = nextLv + 1
		nextActive = cfg.activeness
	end
	self.db.active = active
	if preLv ~= nextLv then
		self.db.lv = nextLv

		local logTb = Log.getLogTb(LogId.GUILD_LVUP)
		--logTb.account = human:getAccount()
		--logTb.name = human:getName()
		--logTb.pAccount = human:getPAccount()
		logTb.guildName = self:getName()
		logTb.guildId = self:getId()
		logTb.oldLv = preLv
		logTb.newLv = self:getLv()
		logTb:save()
	end
end

function getFightValAve(self)
	local memberList = self:getMemberList()
	local total = 0
	for k,v in pairs(memberList) do
		local val = Arena.getArenaFightVal(v.account)
		total = total + val
	end
	local num = #memberList
	return math.floor(total/num) 
end

function getFightVal(self)
	local memberList = self:getMemberList()
	local total = 0
	for k,v in pairs(memberList) do
		local val = Arena.getArenaFightVal(v.account)
		total = total + val
	end
	return total
end

function getNearOpponent(self,human)
	local selfVal = Arena.getArenaFightVal(human.db.account)
	local rank = {}
	for k,v in pairs(self.db.memList) do
		local val = Arena.getArenaFightVal(v.account)
		if val > 0  then
			local fightlist = Arena.getArenaFightList(v.account)
			table.insert(rank,{mem = v,val = val,fightlist = fightlist})
		end
	end
	table.sort(rank,function(a,b)return a.val > b.val end)
	local selfRank = #rank
	for i = 1,#rank do
		if selfVal < rank[i].val then
			selfRank = i
			break
		end
	end
	local startId = math.max(1,selfRank-KickDefine.KICK_MEMBER_NUM)
	local endId = math.min(selfRank+KickDefine.KICK_MEMBER_NUM,#rank)
	local ret = {}
	local guildId = self:getId()
	for i = startId,endId do
		local member = rank[i].mem
		local list = {}
		local fightlist = rank[i].fightlist
		local human = Arena.getArenaHuman(member.account)
		if human  then
			for k,v in pairs(fightlist) do
				local hero = human:getHero(k)
				table.insert(list,{name = k,pos = v.pos,lv = hero.db.lv,quality=hero.db.quality})
			end
			table.sort(list,function(a,b) return fightlist[a.name].pos < fightlist[b.name].pos end)
			table.insert(ret,{guildId = guildId,memberId = member.id,name = member.name,icon = member.icon,lv = member.lv,fightVal = rank[i].val,fightList = list})
		end
		if i > KickDefine.KICK_MEMBER_NUM then
			break
		end
	end
	return ret
end

function incTexasExp(self,val)
	if self.db.texasLv >= #TexasLvConfig then
		local max = TexasLvConfig[#TexasLvConfig].exp
		self.db.texasExp = math.min(max,self.db.texasExp + val)
	else
		self.db.texasExp = self.db.texasExp + val
		checkTexasLvUp(self)
	end
end

function checkTexasLvUp(self)
	local preLv = self.db.texasLv
	if preLv >= #TexasLvConfig then
		return 
	end
	local cfg = TexasLvConfig[preLv+1]
	if not cfg then
		return
	end
	local exp = self.db.texasExp
	local nextExp = cfg.exp
	local nextLv = preLv
	while nextExp <= exp do
		cfg = TexasLvConfig[nextLv+1]
		if not cfg then
			break
		end
		exp = exp - nextExp
		nextLv = nextLv + 1
		nextExp = cfg.exp
	end
	self.db.texasExp = exp  
	if preLv ~= nextLv then
		self.db.texasLv= nextLv
	end
end

function incWineExp(self,val)
	if self.db.wineLv >= #WineLvConfig then
		local max = WineLvConfig[#TexasLvConfig].exp
		self.db.wineExp = math.min(max,self.db.wineExp + val)
	else
		self.db.wineExp = self.db.wineExp + val
		checkWineLvUp(self)
	end
end

function checkWineLvUp(self)
	local preLv = self.db.wineLv
	if preLv >= #WineLvConfig then
		return 
	end
	local cfg = WineLvConfig[preLv+1]
	if not cfg then
		return
	end
	local exp = self.db.wineExp
	local nextExp = cfg.exp
	local nextLv = preLv
	while nextExp <= exp do
		cfg = WineLvConfig[nextLv+1]
		if not cfg then
			break
		end
		exp = exp - nextExp
		nextLv = nextLv + 1
		nextExp = cfg.exp
	end
	self.db.wineExp = exp  
	if preLv ~= nextLv then
		self.db.wineLv = nextLv
	end
end

function nextBossId(self)
	self.db.bossId = math.min(self.db.bossId+1,BossDefine.GUILD_BOSS_MAX_ID)
end

function getBossId(self)
	return self.db.bossId
end

function returnPaper(self,account)
	local paper = self.db.paper
	for k,v in pairs(paper.list) do
		if v.account == account then
			paper:returnBack(k)
		end
	end
end
