module(...,package.seeall)
local WineDefine = require("modules.guild.wine.WineDefine")
local GuildManager = require("modules.guild.GuildManager")
local WineConfig = require("config.WineConfig")
local WineItemConfig = require("config.WineItemConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local BagLogic = require("modules.bag.BagLogic")
local Msg = require("core.net.Msg")
local BagDefine = require("modules.bag.BagDefine")
local DB = require("core.db.DB")
local ItemConfig = require("config.ItemConfig").Config

function onHumanDBLoad(hm,human)
	DB.dbSetMetatable(human.db.wine.buff)
end

function onHumanLogin(hm,human)
	human:startWineBuff()
	wineBuffQuery(human)
end

function query(human)
	if human.db.wine.reset ~= os.date("%d") then 
		human.db.wine.cnt = 0
		human.db.wine.reset = os.date("%d")
	end
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,WineDefine.WINE_QUERY_RET.kNoGuild
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return
	end
	local wine = human.db.wine
    Msg.SendMsg(PacketID.GC_WINE_QUERY,human,guild.db.wineLv,guild.db.wineExp,wine.cnt)
end

function start(human,id)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,WineDefine.WINE_START_RET.kNoGuild
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return false,WineDefine.WINE_START_RET.kNoGuild
	end
	if id <= 0 or id > 3 then
		return false,WineDefine.WINE_START_RET.kDataErr
	end

	local wine = human.db.wine
	local lv  = guild.db.wineLv
	local cfg = WineConfig["Wine"..id.."Config"][lv]
	if not cfg then
		return false,WineDefine.WINE_START_RET.kDataErr
	end
	if wine.cnt >= WineConfig.WineLvConfig[lv].cnt then
		return false,WineDefine.WINE_START_RET.kNoCnt
	end
	local itemId = randomItems(cfg)
	local cost = WineConfig.WineConstConfig[1]["cost"..id]
	if human:getMoney() < cost then
		return false,WineDefine.WINE_START_RET.kNoMoney
	end
	human:decMoney(cost,CommonDefine.MONEY_TYPE.DEC_GUILD_WINE)
	local itemCfg = WineItemConfig[itemId]
	local rewards = {}
	for k,v in pairs(itemCfg.rewards) do
		BagLogic.addItem(human,k,v,false,CommonDefine.ITEM_TYPE.ADD_GUILD_WINE)
		table.insert(rewards,{titleId = BagDefine.REWARD_TIPS.kGuildWine,id = k,num = v})
	end
	BagLogic.addItem(human,itemId,1,true,CommonDefine.ITEM_TYPE.ADD_GUILD_WINE)
	table.insert(rewards,{titleId = BagDefine.REWARD_TIPS.kGuildWine,id = itemId,num = 1})
	wine.cnt = wine.cnt + 1
	human:sendHumanInfo()
	query(human)
	--BagLogic.sendRewardTips(human,rewards)
	
	local logTb = Log.getLogTb(LogId.WINE_COST)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.cnt = wine.cnt
	logTb.mType = id
	logTb.costName = "金币"
	logTb.costNum = cost
	logTb.itemName = ItemConfig[itemId]
	logTb.itemNum = 1
	logTb:save()

	return true,WineDefine.WINE_START_RET.kOk,rewards
end

function donate(human,itemId,cnt)
	local guildId = human:getGuildId()
	if guildId == 0 then
		return false,WineDefine.WINE_DONATE_RET.kNoGuild
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if guild == nil then
		return false,WineDefine.WINE_DONATE_RET.kNoGuild
	end
	local cfg = WineItemConfig[itemId]
	if not cfg then
		return false,WineDefine.WINE_DONATE_RET.kDataErr
	end
	if BagLogic.getItemNum(human,itemId) < cnt then
		return false,WineDefine.WINE_DONATE_RET.kDataErr
	end
	BagLogic.delItemByItemId(human,itemId,cnt,false,CommonDefine.ITEM_TYPE.DEC_GUILD_WINE)
	local rewards = {}
	for k,v in pairs(cfg.donate) do
		BagLogic.addItem(human,k,v*cnt,true,CommonDefine.ITEM_TYPE.ADD_GUILD_WINE_DONATE)
		table.insert(rewards,{titleId = BagDefine.REWARD_TIPS.kGuildDonate,id = k,num = v*cnt})
	end
	BagLogic.sendBagList(human)
	human:sendHumanInfo()
	query(human)
	BagLogic.sendRewardTips(human,rewards)

	local logTb = Log.getLogTb(LogId.WINE_DONATE)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.guildName = guild:getName()
	logTb.guildId = guild:getId()
	local wine = human.db.wine
	logTb.lv = wine.lv
	logTb.exp = wine.exp
	logTb:save()

	return true,WineDefine.WINE_DONATE_RET.kOk
end

function randomItems(cfg)
	local tb = {}
	for k,v in pairs(cfg.output) do
		table.insert(tb,{id=k,weight=v})
	end
	local pos = PublicLogic.getItemByRand(tb)
	return tb[pos].id
end

local id2name = {
	[9901001] = "money",
	[9901007] = "charExp",
	--[9901008] = "",
}

function wineBuffDeal(human,rewards,mtype)
	for k,v in pairs(human.db.wine.buff) do
		local cfg = WineItemConfig[tonumber(k)]
		if cfg then
			local data = cfg.buff[mtype]
			if data then
				for id,val in pairs(data) do
					local name = id2name[id]
					if rewards[id] then
						rewards[id] = math.floor(rewards[id] * (1+val/100))
					end
					if rewards[name] then
						rewards[name] = math.floor(rewards[name] * (1+val/100))
					end
				end
				--local id = data[1]
				--local val = data[2]
				--local name = id2name[id]
				--if rewards[id] then
				--	rewards[id] = math.floor(rewards[id] * (1+val/100))
				--end
				--if rewards[name] then
				--	rewards[name] = math.floor(rewards[name] * (1+val/100))
				--end
			end
		end
	end
	return rewards
end

function wineBuffQuery(human)
	local ret = {}
	for k,v in pairs(human.db.wine.buff) do
		--local lastTime = WineItemConfig[tonumber(k)].last
		--local leftTime = lastTime - (os.time() - v.start)
		table.insert(ret,{id = k,time = v.start})
	end
    Msg.SendMsg(PacketID.GC_WINE_BUFF_QUERY,human,ret)
end
