module(...,package.seeall)
local GuildManager = require("modules.guild.GuildManager")
local Msg = require("core.net.Msg")
local PaperDefine = require("modules.guild.paper.PaperDefine")

function send(human,sum)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,PaperDefine.PAPER_SEND_RET.kNoGuild
	end
	local guild = GuildManager.IdList[guildId]
	if not guild then
		return false,PaperDefine.PAPER_SEND_RET.kNoGuild
	end
	if human.db.vipLv < PaperDefine.VIP_LV_NEED then
		return false,PaperDefine.PAPER_SEND_RET.kNotVip
	end
	if sum < guild:getMemCount() then
		return false,PaperDefine.PAPER_SEND_RET.kSumMin
	end
	--if sum > human:getRmb() then
	--	return false,PaperDefine.PAPER_SEND_RET.kSumMax
	--end
	--human:decRmb(sum,nil,CommonDefine.RMB_TYPE.DEC_GUILD_PAPER_SEND)
	local paper = guild.db.paper
	local count = guild:getMemCount()
	paper:sendPaper(human,guild,sum,count)
	local memberList = guild:getMemberList()
	for k,v in pairs(memberList) do
		if v.account ~= human:getAccount() then
			local obj = HumanManager.getOnline(v.account) 
			if obj then
				Msg.SendMsg(PacketID.GC_NEW_PAPER,obj)
			end
		end
	end
	GuildManager.setDirty(guildId)
	if human.fd then
		human:sendHumanInfo()
		query(human)
	end
	return true,PaperDefine.PAPER_SEND_RET.kOk
end

function get(human,id)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,PaperDefine.PAPER_GET_RET.kNoGuild
	end
	local guild = GuildManager.IdList[guildId]
	if not guild then
		return false,PaperDefine.PAPER_GET_RET.kNoGuild
	end
	local paper = guild.db.paper
	local num = paper:getPaper(human,id)
	if num == 0 then
		return false,PaperDefine.PAPER_GET_RET.kNotGet
	end
	human:incRmb(num,CommonDefine.RMB_TYPE.ADD_GUILD_PAPER)
	human:sendHumanInfo()
	query(human)
	GuildManager.setDirty(guildId)
	return true,PaperDefine.PAPER_GET_RET.kOk,num
end

function query(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false
	end
	local guild = GuildManager.IdList[guildId]
	if not guild then
		return false
	end
	local ret = {}
	local paper = guild.db.paper
	paper:checkOutOfDate()
	for k,v in pairs(paper.list) do
		if v.got[human:getAccount()] then
			local data = {}
			data.id = v.id
			data.account = v.account
			data.name = v.name
			data.sum = v.sum
			local get = v.got[human:getAccount()]
			data.get = get
			table.insert(ret,data)
		end
	end
	table.sort(ret,function(a,b)return a.id > b.id end)
	Msg.SendMsg(PacketID.GC_PAPER_QUERY, human, ret)
end
