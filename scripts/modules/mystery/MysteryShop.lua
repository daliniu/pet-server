module(...,package.seeall) 
local MysteryShopConfig = require("config.MysteryShopConfig").Config
local MysteryShop2Config = require("config.MysteryShop2Config").Config
local MysteryShopConstConfig = require("config.MysteryShopConstConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local MysteryShopDefine = require("modules.mystery.MysteryShopDefine")
local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local VipLogic = require("modules.vip.VipLogic")

function query(human,mtype)
	local shopData = {}
	local mCfg = getCfgByType(mtype)
	checkShop(human,mtype)
	local mysteryShop = getShopByType(human,mtype)
	for i = 1,#mysteryShop do
		local shopId = mysteryShop[i].id
		local buy = mysteryShop[i].buy
		local cfg = mCfg[shopId]
		local tb = {
			id = shopId,
			itemId = cfg.itemId,
			cnt = cfg.cnt,
			buy = buy,
			price = cfg.cost,
		}
		table.insert(shopData,tb)
	end
	local tag = getTagByType(mtype)
	Msg.SendMsg(PacketID.GC_MYSTERY_SHOP_QUERY,human,shopData,human.db.mystery["refresh"..tag],mtype)
end

function checkShop(human,mtype)
	local cfg = getCfgByType(mtype)
	local tag = getTagByType(mtype)
	for k,v in pairs(human.db.mystery["shop"..tag]) do
		if not cfg[v.id] then
			human.db.mystery["shop"..tag] = {}
			break
		end
	end
	if not next(human.db.mystery["shop"..tag]) then
		human.db.mystery["shop"..tag] = randomItems(human,cfg)
	end
end

function randomItems(human,cfg)
	local tb = {}
	local lv = human:getLv()
	for k,v in pairs(cfg) do
		if lv >= v.lv[1] and lv <= v.lv[2] then
			table.insert(tb,{id = v.id,weight = v.weight})
		end
	end
	local result = {}
	for i = 1,MysteryShopDefine.MAX_MYSTERY_SHOP_LEN do
		if #tb <= MysteryShopDefine.MAX_MYSTERY_SHOP_LEN - i then
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

function getShopByType(human,mtype)
	local mysteryShop = human.db.mystery.shop
	if mtype == MysteryShopDefine.K_SHOP_TAG1 then
	elseif mtype == MysteryShopDefine.K_SHOP_TAG2 then
		mysteryShop = human.db.mystery.shop2
	end
	return mysteryShop
end

function getTagByType(mtype)
	local tag = ""
	if mtype == MysteryShopDefine.K_SHOP_TAG1 then
	elseif mtype == MysteryShopDefine.K_SHOP_TAG2 then
		tag = "2"
	end
	return tag
end

function getCfgByType(mtype)
	local mCfg = MysteryShopConfig
	if mtype == MysteryShopDefine.K_SHOP_TAG1 then
	elseif mtype == MysteryShopDefine.K_SHOP_TAG2 then
		mCfg = MysteryShop2Config
	end
	return mCfg
end

function buy(human,id,mtype)
	local mCfg = getCfgByType(mtype)
	local cfg = mCfg[id]
	if not cfg then
		return false,MysteryShopDefine.MYSTERY_BUY.kErrData
	end
	local buy
	local tag = getTagByType(mtype)
	for k,v in pairs(human.db.mystery["shop"..tag]) do
		if v.id == id then
			buy = v.buy
			break
		end
	end
	if not buy or buy~=0 then
		return false,MysteryShopDefine.MYSTERY_BUY.kHasBuy
	end
	local ret,retCode = checkCoinByType(human,cfg.mtype,cfg.cost)
	if not ret then
		return false,retCode
	end
	decCoinByType(human,cfg.mtype,cfg.cost)
	for k,v in pairs(human.db.mystery["shop"..tag]) do
		if v.id == id then
			v.buy = 1
			break
		end
	end
	BagLogic.addItem(human,cfg.itemId,cfg.cnt,true,CommonDefine.ITEM_TYPE.ADD_MYSTERY_SHOP)
	human:sendHumanInfo()
	local logTb = Log.getLogTb(LogId.MYSTERY_SHOP)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.itemName = ItemConfig[cfg.itemId].name
	logTb.itemNum = cfg.cnt
	logTb.costName = MysteryShopDefine.COST_NAME[cfg.mtype]
	logTb.costNum = cfg.cost
	local costLeft = 0
	if logTb.costName == "钻石" then
		costLeft = human:getRmb()
	elseif logTb.costName == "金币" then
		costLeft = human:getMoney()
	end
	logTb.costLeft = costLeft
	logTb:save()
	return true,MysteryShopDefine.MYSTERY_BUY.kOk
end

function checkCoinByType(human,mtype,cost)
	if mtype == MysteryShopDefine.K_SHOP_BUY_RMB then
		if human:getRmb() < cost then
			return false,MysteryShopDefine.MYSTERY_BUY.kNoRmb
		end
	elseif mtype == MysteryShopDefine.K_SHOP_BUY_MONEY then
		if human:getMoney() < cost then
			return false,MysteryShopDefine.MYSTERY_BUY.kNoMoney
		end
	else
		return false,MysteryShopDefine.MYSTERY_BUY.kErrData
	end
	return true
end

function decCoinByType(human,mtype,cost)
	if mtype == MysteryShopDefine.K_SHOP_BUY_RMB then
		human:decRmb(cost,nil,CommonDefine.RMB_TYPE.DEC_MYSTERY_BUY)
	elseif mtype == MysteryShopDefine.K_SHOP_BUY_MONEY then
		human:decMoney(cost,CommonDefine.MONEY_TYPE.DEC_MYSTERY)
	end
end

function refresh(human,mtype)
	local cfg = MysteryShopConstConfig[1]
	local tag = getTagByType(mtype)
	local times = human.db.mystery["refresh"..tag]
	local itemId = cfg.itemId
	local price
	if times >= VipLogic.getVipAddCount(human,"mysteryShopCount") then
		return false,MysteryShopDefine.MYSTERY_REFRESH.kNoTimes
	end
	if BagLogic.getItemNum(human,itemId) > 0 then
		BagLogic.delItemByItemId(human,itemId,1,true,CommonDefine.ITEM_TYPE.DEC_MYSTERY_REFRESH)
	else
		for i = #cfg.cost,1,-1 do
			if times + 1 >= cfg.cost[i][1] then
				price = cfg.cost[i][2]
				break
			end
		end
		if human:getRmb() < price then
			return false,MysteryShopDefine.MYSTERY_REFRESH.kNoMoney
		end
		human:decRmb(price,nil,CommonDefine.RMB_TYPE.DEC_MYSTERY_REFRESH)
		human.db.mystery["refresh"..tag] = human.db.mystery["refresh"..tag] + 1
	end
	local cfg = getCfgByType(mtype)
	human.db.mystery["shop"..tag]= randomItems(human,cfg)
	human:sendHumanInfo()
	query(human,mtype)

	local logTb = Log.getLogTb(LogId.MYSTERY_SHOP_REFRESH)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.costName = "钻石"
	logTb.costNum = price
	logTb.cnt = human.db.mystery["refresh"..tag]
	logTb:save()

	return true,MysteryShopDefine.MYSTERY_REFRESH.kOk
end
