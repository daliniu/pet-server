module(...,package.seeall)
local GuildManager = require("modules.guild.GuildManager")
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local GuildDefine = require("modules.guild.GuildDefine")
local TexasLogic = require("modules.guild.texas.TexasLogic")
local KickLogic = require("modules.guild.kick.KickLogic")
local GuildShopLogic = require("modules.guild.shop.GuildShopLogic")
local WineLogic = require("modules.guild.wine.WineLogic")
local PaperLogic = require("modules.guild.paper.PaperLogic")
local BossLogic = require("modules.guild.boss.BossLogic")
local GUILD_CREATE_RET = GuildDefine.GUILD_CREATE_RET

function onCGGuildSearch(human,id)
	local guildList = GuildManager.searchGuild(id)
	local guildData = makeGuildData(guildList,human)
	Msg.SendMsg(PacketID.GC_GUILD_SEARCH,human,guildData)
end

function onCGGuildCreate(human,name)
	local ret,retCode = GuildManager.createGuild(human,name)
	Msg.SendMsg(PacketID.GC_GUILD_CREATE,human,retCode)
	if ret then
		human:sendHumanInfo()
	end
end

function onCGGuildQuery(human)
	local guildList = GuildManager.searchGuild(0)
	local guildData = makeGuildData(guildList,human)
	Msg.SendMsg(PacketID.GC_GUILD_QUERY,human,guildData)
end

function onCGGuildApplyCancel(human,guildId)
	local ret,retCode = GuildManager.applyGuildCancel(human,guildId)
	Msg.SendMsg(PacketID.GC_GUILD_APPLY_CANCEL,human,guildId,retCode)
end

function onCGGuildApply(human,guildId)
	local ret,retCode = GuildManager.applyGuild(human,guildId)
	Msg.SendMsg(PacketID.GC_GUILD_APPLY,human,guildId,retCode)
end

function onCGGuildApplyQuery(human)
	local ret,retCode,applylist = GuildManager.applyQuery(human)
	if ret then
		local applyData = {}
		for i = 1,#applylist do
			local mem = applylist[i]
			local data = {}
			data.id = mem.id
			local obj = HumanManager.getOnline(mem.account)
			if obj then
				data.name = obj:getName()
				data.lv = obj:getLv()
				data.icon = obj:getBodyId()
			else
				data.name = mem.name
				data.lv = mem.lv
				data.icon = mem.icon
			end
			table.insert(applyData,data)
		end
		Msg.SendMsg(PacketID.GC_GUILD_APPLY_QUERY,human,retCode,applyData)
	else
		Msg.SendMsg(PacketID.GC_GUILD_APPLY_QUERY,human,retCode)
	end
end

function onCGGuildMemberQuery(human)
	local ret,retCode,me,memberlist = GuildManager.memberQuery(human)
	if ret then
		local memberData = {}
		for i = 1,#memberlist do
			local mem = memberlist[i]
			local data = {}
			data.id = mem.id
			data.pos = mem.pos
			local obj = HumanManager.getOnline(mem.account)
			if obj then
				data.name = obj:getName()
				data.account = obj:getAccount()
				data.lv = obj:getLv()
				data.icon = obj:getBodyId()
				if obj.fd then
					data.lastLogin = 0
				else
					data.lastLogin = os.time() - mem.lastLogin
				end
			else
				data.name = mem.name
				data.account = mem.account
				data.lv = mem.lv
				data.icon = mem.icon
				data.lastLogin = os.time() - mem.lastLogin
			end
			table.insert(memberData,data)
		end
		Msg.SendMsg(PacketID.GC_GUILD_MEMBER_QUERY,human,retCode,me.id,memberData)
	else
		Msg.SendMsg(PacketID.GC_GUILD_MEMBER_QUERY,human,retCode)
	end
end

function onCGGuildAccept(human,id,op)
	local ret,retCode = GuildManager.acceptJoin(human,id,op)
	Msg.SendMsg(PacketID.GC_GUILD_ACCEPT,human,retCode)
	if ret then
		onCGGuildApplyQuery(human)
	end
end

function onCGGuildMemOperate(human,id,op)
	local ret,retCode = GuildManager.memberOperate(human,id,op)
	Msg.SendMsg(PacketID.GC_GUILD_MEM_OPERATE,human,retCode)
	if ret then
		onCGGuildMemberQuery(human)
	end
end

function onCGGuildInfoQuery(human)
	local ret,guild,pos = GuildManager.guildQuery(human)
	if ret then
		Msg.SendMsg(PacketID.GC_GUILD_INFO_QUERY,human,guild:getId(),guild:getName(),guild:getLv(),guild:getIcon(),guild:getAnnounce(),guild:getMemCount(),guild:getActive(),pos)
	end
end

function onCGGuildModAnnounce(human,content)
	local ret,retCode = GuildManager.guildModAnnounce(human,content)
	Msg.SendMsg(PacketID.GC_GUILD_MOD_ANNOUNCE,human,content,retCode)
end

function makeGuildData(guildList,human)
	local guildData = {}
	local len = #guildList > 100 and 100 or #guildList
	for i = 1,len do
		local guild = guildList[i]
		local data = {}
		data.id = guild:getId()
		data.name = guild:getName()
		data.icon = guild:getIcon()
		data.lv = guild:getLv()
		data.num = guild:getMemCount()
		data.announce = guild:getAnnounce()
		data.apply = guild:isInApplyList(human) and GuildDefine.GUILD_APPLYING or GuildDefine.GUILD_NOTAPPLY
		table.insert(guildData,data)
	end
	return guildData
end

function onCGGuildQuit(human)
	local ret,retCode = GuildManager.quitGuild(human)
	Msg.SendMsg(PacketID.GC_GUILD_QUIT,human,retCode)
end

function onCGGuildDestroy(human)
	local ret,retCode = GuildManager.destroyGuild(human)
	Msg.SendMsg(PacketID.GC_GUILD_DESTROY,human,retCode)
end

function onCGTexasQuery(human)
	TexasLogic.query(human)
end

function onCGTexasStart(human)
	local ret,retCode = TexasLogic.start(human)
    Msg.SendMsg(PacketID.GC_TEXAS_START,human,retCode)
end

function onCGTexasRank(human)
	TexasLogic.rankQuery(human)
end

function onCGKickGuild(human,id)
	local ret,retCode,data,cnt,fightList = KickLogic.guildQuery(human,id)
	if ret then
		Msg.SendMsg(PacketID.GC_KICK_GUILD,human,data,cnt,fightList)
	else
		Msg.SendMsg(PacketID.GC_KICK_GUILD,human)
	end
end

function onCGKickRecord(human)
	KickLogic.recordQuery(human)
end

function onCGKickMember(human,id)
	local ret,retCode,memberData = KickLogic.memberQuery(human,id)
	Msg.SendMsg(PacketID.GC_KICK_MEMBER,human,memberData)
end

function onCGKickBegin(human,guildId,memberId,fightList)
	local ret,retCode,enemy = KickLogic.fightBegin(human,guildId,memberId,fightList)
	Msg.SendMsg(PacketID.GC_KICK_BEGIN,human,retCode,guildId,memberId,fightList,enemy)
end

function onCGKickEnd(human,result,guildId,memberId)
	KickLogic.fightEnd(human,result,guildId,memberId)
	Msg.SendMsg(PacketID.GC_KICK_END,human,result)
end

function onCGGuildShopQuery(human)
	local function updateGuildData(human)
		human.db.guildShop.lastDate = os.time()
		human.db.guildShop.shop = {}
		human.db.guildShop.refresh = 0
	end
	if not Util.IsSameDate(human.db.guildShop.lastDate,os.time()) then
		updateGuildData(human)
	end
	GuildShopLogic.query(human)
end

function onCGGuildShopRefresh(human)
	local ret,retCode = GuildShopLogic.refresh(human)
	Msg.SendMsg(PacketID.GC_GUILD_SHOP_REFRESH,human,retCode)
end

function onCGGuildShopBuy(human,id)
	local ret,retCode = GuildShopLogic.buy(human,id)
	Msg.SendMsg(PacketID.GC_GUILD_SHOP_BUY,human,id,retCode)
end

function onCGWineQuery(human)
	WineLogic.query(human)
end

function onCGWineStart(human,id)
	local ret,retCode,rewards = WineLogic.start(human,id)
	Msg.SendMsg(PacketID.GC_WINE_START,human,retCode,rewards)
end

function onCGWineDonate(human,id,num)
	local ret,retCode = WineLogic.donate(human,id,num)
	Msg.SendMsg(PacketID.GC_WINE_DONATE,human,retCode)
end

function onCGWineBuffQuery(human)
end

function onCGPaperQuery(human)
	PaperLogic.query(human)
end

function onCGSendPaper(human,sum)
	--local ret,retCode = PaperLogic.send(human,sum)
	--Msg.SendMsg(PacketID.GC_SEND_PAPER,human,retCode)
end

function onCGGetPaper(human,id)
	local ret,retCode,num = PaperLogic.get(human,id)
	Msg.SendMsg(PacketID.GC_GET_PAPER, human, id,1,num)
end

function onCGGuildSceneEnter(human)
	human.db.guildCnt = human.db.guildCnt + 1
	human:sendHumanInfo()
end

function onCGGuildBossQuery(human)
	--print("onCGGuildBossQuery")
	BossLogic.query(human)
end

function onCGGuildBossEnter(human,heroList)
	--print("onCGGuildBossEnter")
	local ret,retCode,bossId,hp = BossLogic.enter(human,heroList)
	Msg.SendMsg(PacketID.GC_GUILD_BOSS_ENTER,human,retCode,bossId,hp)
end

function onCGGuildBossHurt(human,hurt)
	--print("onCGGuildBossHurt")
	local ret,retCode = BossLogic.hurt(human,hurt)
	--Msg.SendMsg(PacketID.GC_GUILD_BOSS_HURT,human,retCode)
end

function onCGGuildBossLeave(human)
	--print("onCGGuildBossLeave")
	local ret,retCode = BossLogic.leave(human)
end

function onCGGuildBossRank(human)
	BossLogic.rankQuery(human)
end

function onCGGuildBossCheckTeam(human,rank)
	BossLogic.checkTeam(human,rank)
end

function onCGGuildBossEnterQuery(human)
	local ret,retCode = BossLogic.enterQuery(human)
	Msg.SendMsg(PacketID.GC_GUILD_BOSS_ENTER_QUERY,human,retCode)
end
