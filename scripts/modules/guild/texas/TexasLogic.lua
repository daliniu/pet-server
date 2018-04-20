module(...,package.seeall)
local Msg = require("core.net.Msg")
local TexasDefine = require("modules.guild.texas.TexasDefine")
local CardLogic = require("modules.guild.texas.CardLogic")
local GuildDefine = require("modules.guild.GuildDefine")
local GuildManager = require("modules.guild.GuildManager")
local TexasConfig = require("config.TexasConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config

function query(human,isRefresh)
	if human.db.texas.reset ~= os.date("%d") then 
		human.db.texas.count = 0
		human.db.texas.reset = os.date("%d")
	end
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,TexasDefine.TEXAS_QUERY_RET.kNoGuild
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return
	end
	if os.date("%w") == 0 then
		if next(guild.db.weekTop) and guild.db.weekTop.time ~= os.date("%d") then
			guild.db.weekTop = {}
		end
	end
	local texas = human.db.texas
	local weekTop = guild.db.weekTop
    Msg.SendMsg(PacketID.GC_TEXAS_QUERY,human,guild.db.texasLv,guild.db.texasExp,texas.count,weekTop,texas.curCards,isRefresh)
end

function start(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,TexasDefine.TEXAS_START_RET.kNoGuild
	end
	local texas = human.db.texas
	if texas.count >= TexasDefine.TEXAS_DAYCNT then
		return false,TexasDefine.TEXAS_START_RET.kNoCnt
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return
	end
	if guild.db.texasRankDay ~= os.date("%d") then
		guild.db.texasRank = {}
		guild.db.texasRankDay = os.date("%d")
	end

	local cards = CardLogic.deal()
	local lv = CardLogic.getCardLv(cards)

	--local cards2 = CardLogic.deal()
	--local ret = CardLogic.compareCards(cards,cards2)
	--print("start::"..tostring(ret))

	texas:setCurCards(cards)
	--排行榜
	if insertTexasRank(human,cards) then
		GuildManager.setDirty(guildId)
	end
	texas.count = texas.count + 1
	local cfg = TexasConfig[lv]
	local logName = ""
	local logNum = ""
	for k,v in pairs(cfg.rewards) do
		BagLogic.addItem(human,v[1],v[2],false,CommonDefine.ITEM_TYPE.ADD_GUILD_TEXAS)
		if logName == "" then
			logName = ItemConfig[v[1]].name
			logNum = v[2]
		else
			logName = logName .. "," .. ItemConfig[v[1]].name
			logNum = logNum .. "," .. v[2]
		end
	end
	BagLogic.sendBagList(human)
	query(human,1)

	local logTb = Log.getLogTb(LogId.TEXAS_DROP)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.cnt = texas.count
	logTb.itemName = logName
	logTb.itemNum = logNum
	logTb.card1 = cards[1]
	logTb.card2 = cards[2]
	logTb.card3 = cards[3]
	logTb.card4 = cards[4]
	logTb.card5 = cards[5]
	logTb:save()

	return true,TexasDefine.TEXAS_START_RET.kOk
end

function insertTexasRank(human,pCards)
	local cards = Util.deepCopy(pCards)
	local temp = {}
	for k,v in pairs(cards) do
		local digit,color = CardLogic.num2DigitColor(v)
		if digit == 1 then
			temp[v] = {d = digit + 13,c = color}
		else
			temp[v] = {d = digit,c = color}
		end
	end
	table.sort(cards,function(a,b) 
		if temp[a].d < temp[b].d then
			return true
		elseif temp[a].d > temp[b].d then
			return false
		else
			return temp[a].c > temp[b].c
		end
	end)
	local isDirty = false
	local function newData(human,cards)
		local ret = {}
		ret.account = human:getAccount()
		ret.name = human:getName()
		ret.cards = cards
		return ret
	end
	local guildId = human:getGuildId()
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return
	end
	local rank = guild.db.texasRank
	local insertPos = #rank + 1
	for i = 1,#rank do
		if CardLogic.compareCards(cards,rank[i].cards) then
			insertPos = i 
			break
		end
	end
	local isExist = false
	for i = #rank,1,-1 do
		if rank[i].account == human:getAccount() then
			if insertPos <= i then
				table.remove(rank,i)
				table.insert(rank,insertPos,newData(human,cards))
				isDirty = true
			end
			isExist = true
			break
		end
	end
	if not isExist then
		if insertPos == #rank + 1 and #rank >= TexasDefine.TEXAS_RANK_LEN then
			isDirty = true
		end
		table.insert(rank,insertPos,newData(human,cards))
		if #rank > TexasDefine.TEXAS_RANK_LEN then
			table.remove(rank,#rank)
		end
	end
	local weekTop = guild.db.weekTop
	if next(weekTop) then
		if CardLogic.compareCards(cards,weekTop.cards) then
			guild.db.weekTop = {name = human:getName(),cards = cards,time = os.date("%d")}
			isDirty = true
		end
	else
		guild.db.weekTop = {name = human:getName(),cards = cards,time = os.date("%d")}
		isDirty = true
	end
	return isDirty
end

function rankQuery(human)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,TexasDefine.TEXAS_RANK_QUERY_RET.kNoGuild
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return false,TexasDefine.TEXAS_RANK_QUERY_RET.kNoGuild
	end
	if guild.db.texasRankDay ~= os.date("%d") then
		guild.db.texasRank = {}
		guild.db.texasRankDay = os.date("%d")
	end
	local rank = guild.db.texasRank
    Msg.SendMsg(PacketID.GC_TEXAS_RANK,human,rank)
end
