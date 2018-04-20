module(...,package.seeall) 
local GuildShopConfig = require("config.GuildShopConfig").Config
local GuildShopConstConfig = require("config.GuildShopConstConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local GuildShopDefine = require("modules.guild.shop.GuildShopDefine")
local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local GuildManager = require("modules.guild.GuildManager")
local VipLogic = require("modules.vip.VipLogic")

function query(human)
	local shopData = {}
	checkShop(human)
	local guildShop = human.db.guildShop.shop
	for i = 1,#guildShop do
		local shopId = guildShop[i].id
		local buy = guildShop[i].buy
		local cfg = GuildShopConfig[shopId]
		local tb = {
			id = shopId,
			itemId = cfg.itemId,
			cnt = cfg.cnt,
			buy = buy,
			price = cfg.cost,
		}
		table.insert(shopData,tb)
	end
	Msg.SendMsg(PacketID.GC_GUILD_SHOP_QUERY,human,shopData,human.db.guildShop.refresh)
end

function checkShop(human)
	for k,v in pairs(human.db.guildShop.shop) do
		if not GuildShopConfig[v.id] then
			human.db.guildShop.shop = {}
			break
		end
	end
	if not next(human.db.guildShop.shop) then
		human.db.guildShop.shop = randomItems(human)
	end
end

function randomItems(human)
	local tb = {}
	for k,v in pairs(GuildShopConfig) do
		table.insert(tb,{id = v.id,weight = v.weight})
	end
	local result = {}
	for i = 1,GuildShopDefine.MAX_GUILD_SHOP_LEN do
		if #tb <= GuildShopDefine.MAX_GUILD_SHOP_LEN - i then
			break
		end
		local pos = PublicLogic.getItemByRand(tb)
		if pos and tb[pos] then
			table.insert(result,{id = tb[pos].id,buy = 0})
			tb[pos].weight = 0
		end
	end
	return result
end

function buy(human,id)
	local guildId = human:getGuildId()
	if guildId <= 0 then
		return false,GuildShopDefine.GUILD_SHOP_BUY.kNoGuild
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if not guild then
		return false,GuildShopDefine.GUILD_SHOP_BUY.kNoGuild
	end 
	local cfg = GuildShopConfig[id]
	if not cfg then
		return false,GuildShopDefine.GUILD_SHOP_BUY.kErrData
	end
	local buy
	for k,v in pairs(human.db.guildShop.shop) do
		if v.id == id then
			buy = v.buy
			break
		end
	end
	if not buy or buy~=0 then
		return false,GuildShopDefine.GUILD_SHOP_BUY.kHasBuy
	end
	if human:getGuildCoin() < cfg.cost then
		return false,GuildShopDefine.GUILD_SHOP_BUY.kNoMoney
	end
	human:decGuildCoin(cfg.cost)
	for k,v in pairs(human.db.guildShop.shop) do
		if v.id == id then
			v.buy = 1
			break
		end
	end
	BagLogic.addItem(human,cfg.itemId,cfg.cnt,true,CommonDefine.ITEM_TYPE.ADD_GUILD_SHOP)
	human:sendHumanInfo()
	local logTb = Log.getLogTb(LogId.GUILD_SHOP)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.itemName = ItemConfig[cfg.itemId].name
	logTb.itemNum = cfg.cnt
	logTb.costName = "公会声望"
	logTb.costNum = cfg.cost
	logTb.costLeft = human:getGuildCoin()
	logTb:save()
	return true,GuildShopDefine.GUILD_SHOP_BUY.kOk
end

function refresh(human)
	local cfg = GuildShopConstConfig[1]
	local times = human.db.guildShop.refresh
	local itemId = cfg.itemId
	if times >= VipLogic.getVipAddCount(human,"guildShopCount") then
		return false,GuildShopDefine.GUILD_SHOP_REFRESH.kNoTimes
	end
	if BagLogic.getItemNum(human,itemId) > 0 then
		BagLogic.delItemByItemId(human,itemId,1,true,CommonDefine.ITEM_TYPE.DEC_GUILD_REFRESH)
	else
		local price
		for i = #cfg.cost,1,-1 do
			if times + 1 >= cfg.cost[i][1] then
				price = cfg.cost[i][2]
				break
			end
		end
		if human:getRmb() < price then
			return false,GuildShopDefine.GUILD_SHOP_REFRESH.kNoMoney
		end
		human:decRmb(price,nil,CommonDefine.RMB_TYPE.DEC_GUILD_SHOP_REFRESH)
		human.db.guildShop.refresh = human.db.guildShop.refresh + 1
	end
	human.db.guildShop.shop = randomItems(human)
	human:sendHumanInfo()
	query(human)
	return true,GuildShopDefine.GUILD_SHOP_REFRESH.kOk
end
