module(...,package.seeall)
local ShopConfig = require("config.ShopConfig").Config
local ShopDefine = require("modules.shop.ShopDefine")
local BagLogic = require("modules.bag.BagLogic")
local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local LotteryConfig = require("config.LotteryConfig")
local ConstantConfig = require("config.LotteryConfig").ConstantConfig[1]
local NormalConfig = require("config.LotteryConfig").NormalConfig
local CommonHeroConfig = require("config.LotteryConfig").CommonHeroConfig
local RareConfig = require("config.LotteryConfig").RareConfig
local HeroConfig = require("config.LotteryConfig").HeroConfig
local FirstCostConfig = require("config.LotteryConfig").FirstCostConfig
local PublicLogic = require("modules.public.PublicLogic")
local BagDefine = require("modules.bag.BagDefine")
local ItemConfig = require("config.ItemConfig").Config
local HeroManager = require("modules.hero.HeroManager")
local StrengthLogic = require("modules.strength.StrengthLogic")
local ShopVirtualConfig = require("config.ShopVirtualConfig").Config
local ExchangeShopConfig = require("config.ExchangeShopConfig").Config
local ExchangeShopRefreshConfig = require("config.ExchangeShopRefreshConfig").Config
local VipDefine = require("modules.vip.VipDefine")
local VipLogic = require("modules.vip.VipLogic")
local ShopVirtual = require("modules.shop.ShopVirtual")

function onHumanLogin(hm,human)
	if not Util.IsSameDate(human.db.shop.resetbuy,os.time()) then
		human.db.shop:resetBuy()
		human.db.shop.resetbuy = os.time()
	end
	query(human,{ShopDefine.K_SHOP_VIRTUAL_PHY_ID,ShopDefine.K_SHOP_VIRTUAL_MONEY_ID})
	lotteryQuery(human)
end

function query(human,shopCnt)
	local ret = {}
	for k,v in pairs(shopCnt) do
		local cnt = human.db.shop:getBuyCnt(v)
		table.insert(ret,{shopId=v,cnt = cnt})
	end
	Msg.SendMsg(PacketID.GC_SHOP_QUERY,human,ret)
end

function buy(human,shopId,num)
	local cfg = ShopConfig[shopId]
	if not cfg then
		return false,ShopDefine.SHOP_BUY_RET.kDataErr
	end
	local cnt = human.db.shop:getBuyCnt(shopId)
	if cfg.daylimited >= 0 and cnt + num > getLimitCount(human,cfg) then
		return false,ShopDefine.SHOP_BUY_RET.kDayLimited
	end
	if next(cfg.datelimited) and not checkDate(cfg.datelimited[1],cfg.datelimited[2]) then
		return false,ShopDefine.SHOP_BUY_RET.kDateLimited
	end
    if not BagLogic.checkCanAddItem(human, cfg.itemId, num) then
		return false,ShopDefine.SHOP_BUY_RET.kBagFull
	end
	local ret,retCode = checkCoinByType(human,cfg.mtype,cfg.price*num)
	if not ret then
		return false,retCode
	end
	decCoinByType(human,cfg.mtype,cfg.price*num)
	human.db.shop:setBuyCnt(shopId,cnt+num)
	BagLogic.addItem(human,cfg.itemId,num,true,CommonDefine.ITEM_TYPE.ADD_SHOP_BUY)
	human:sendHumanInfo()
	query(human,{shopId})
	local rewards = {{titleId = BagDefine.REWARD_TIPS.kBuy,id = cfg.itemId,num = num}}
	BagLogic.sendRewardTips(human,rewards)
	local logTb = Log.getLogTb(LogId.SHOP_COST)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.shopName = "商店"
	logTb.itemName = ItemConfig[cfg.itemId].name
	logTb.buyCnt = num
	logTb.costName = ShopDefine.COST_NAME[cfg.mtype]
	logTb.costNum = cfg.price * num
	logTb:save()
	return true,ShopDefine.SHOP_BUY_RET.kOk
end

function getLimitCount(human, cfg)
	if cfg.vipAppend and cfg.vipAppend ~= "" then
		return cfg.daylimited + VipLogic.getVipAddCount(human, cfg.vipAppend)
	end
	return cfg.daylimited
end

function incCoinByType(human,mtype,cost)
	if mtype == ShopDefine.K_SHOP_BUY_RMB then
		human:incRmb(cost)
	elseif mtype == ShopDefine.K_SHOP_BUY_MONEY then
		human:incMoney(cost)
	elseif mtype == ShopDefine.K_SHOP_BUY_POWERCOIN then
		human:incPowerCoin(cost)
	end
end

function decCoinByType(human,mtype,cost)
	if mtype == ShopDefine.K_SHOP_BUY_RMB then
		human:decRmb(cost,nil,CommonDefine.RMB_TYPE.DEC_SHOP_BUY)
	elseif mtype == ShopDefine.K_SHOP_BUY_MONEY then
		human:decMoney(cost,CommonDefine.MONEY_TYPE.DEC_SHOP_BUY)
	elseif mtype == ShopDefine.K_SHOP_BUY_POWERCOIN then
		human:decPowerCoin(cost)
	end
end

function checkCoinByType(human,mtype,cost)
	if mtype == ShopDefine.K_SHOP_BUY_RMB then
		if human:getRmb() < cost then
			return false,ShopDefine.SHOP_BUY_RET.kNotRmb
		end
	elseif mtype == ShopDefine.K_SHOP_BUY_MONEY then
		if human:getMoney() < cost then
			return false,ShopDefine.SHOP_BUY_RET.kNotMoney
		end
	elseif mtype == ShopDefine.K_SHOP_BUY_POWERCOIN then
		if human:getPowerCoin() < cost then
			return false,ShopDefine.SHOP_BUY_RET.kNotPowerCoin
		end
	else
		return false,ShopDefine.SHOP_BUY_RET.kDataErr
	end
	return true
end

function sell(human,shopId,num)
	local cfg = ShopConfig[shopId]
	if not cfg then
		return false,ShopDefine.SHOP_SELL_RET.kDataErr
	end
	if BagLogic.getItemNum(human,cfg.itemId) < num then
		return false,ShopDefine.SHOP_SELL_RET.kNoItem
	end
	BagLogic.delItemByItemId(human,cfg.itemId,num,true,CommonDefine.ITEM_TYPE.DEC_SHOP_SELL)
	incCoinByType(human,cfg.mtype,cfg.sellprice*num)
	human:sendHumanInfo()
	return true,ShopDefine.SHOP_SELL_RET.kOk
end

function checkDate(beginstr,endstr)
	local beginTime = datestr2timestamp(beginstr)
	local endTime = datestr2timestamp(endstr)
	local now = os.time()
	if now > beginTime and now < endTime then
		return true
	end
	return false
end

function datestr2timestamp(str)
	local tb = Util.Split(str,"-")
	local hourTb = Util.Split(tb[4],":")
	local time = os.time({year=tb[1],month=tb[2],day=tb[3],hour=hourTb[1],min=hourTb[2]}) 
	return time
end

function lotteryQuery(human)
	local commonfree = math.max(human.db.shop.commonfree - os.time(),0)
	local rarefree = math.max(human.db.shop.rarefree - os.time(),0)
	local raretimes = human.db.shop.raretimes
	if not Util.IsSameDate(human.db.shop.resetFreeTimes,os.time()) then
		human.db.shop.commonFreeTimes = 0
		human.db.shop.resetFreeTimes = os.time()
	end
	local dayFreeTimes = human.db.shop.commonFreeTimes
	Msg.SendMsg(PacketID.GC_SHOP_LOTTERY_QUERY,human,commonfree,rarefree,raretimes,dayFreeTimes)
end

function commonOnce(human)
	local commonOnceCost = ConstantConfig.commonOnceCost
	local logCost = commonOnceCost
	if human.db.shop.commonfree > os.time() then
		--if BagLogic.getItemNum(human,onceItemId) <= 0 then
		--	return false,ShopDefine.COMMON_ONCE_RET.kNoItem,0
		--end
		--BagLogic.delItemByItemId(human,onceItemId,1)
		if human:getMoney() < commonOnceCost then
			return false,ShopDefine.COMMON_ONCE_RET.kNoItem,0
		end
		human:decMoney(commonOnceCost,CommonDefine.MONEY_TYPE.DEC_SHOP_BUY)
	else
		if human.db.shop.commonFreeTimes >= ConstantConfig.commonDayCnt then
			if human:getMoney() < commonOnceCost then
				return false,ShopDefine.COMMON_ONCE_RET.kNoItem,0
			end
			human:decMoney(commonOnceCost,CommonDefine.MONEY_TYPE.DEC_SHOP_BUY)
		else
			human.db.shop.commonFreeTimes = human.db.shop.commonFreeTimes + 1
			if human.db.shop.commonFreeTimes < ConstantConfig.commonDayCnt then
				local commonCd = ConstantConfig.commonfree
				human.db.shop.commonfree = os.time() + commonCd
			end
			logCost = 0
			lotteryQuery(human)
		end
	end
	local itemId
	local num 
	if human.db.shop.commonFirst == 0 then
		itemId = ConstantConfig.commonFirstId
		num = ConstantConfig.commonFirstNum
		human.db.shop.commonFirst = 1
	else
		itemId = randomItems(NormalConfig)
		local cfg = NormalConfig[itemId]
		num = cfg.num
	end
	--local items = {}
	--table.insert(items,{itemId,cfg.num})
	--PublicLogic.addItemsBagOrMail(human,items)
	BagLogic.addItem(human,itemId,num,true,CommonDefine.ITEM_TYPE.ADD_COMMON_ONCE)
	human:sendHumanInfo()
	HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=1})

	local logTb = Log.getLogTb(LogId.LOTTERY_COMMON)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.itemName = ItemConfig[itemId].name
	logTb.itemNum = num
	logTb.source = 1
	logTb.costName = "金币"
	logTb.costNum = logCost
	logTb:save()

	return true,ShopDefine.COMMON_ONCE_RET.kOk,itemId
end

function commonTen(human)
	local tenGold = ConstantConfig.commonTenCost
	if human:getMoney() < tenGold then
		return false,ShopDefine.RARE_TEN_RET.kNoGold
	end
	human:decMoney(tenGold,CommonDefine.MONEY_TYPE.DEC_SHOP_BUY)
	human:sendHumanInfo()
	local RareConfig = NormalConfig
	local HeroConfig = CommonHeroConfig
	--local CostConfig = LotteryConfig.FirstCostConfig
	local result = {}
	local items = {}
	for i = 1,ShopDefine.RARE_TEN do
		local itemId
		local num
		if human.db.shop.commonFirst == 0 then
			human.db.shop.commonFirst = 1
			itemId = ConstantConfig.commonFirstId
			num = ConstantConfig.commonFirstNum
		--elseif human.db.shop.costFirst == 0 and human.db.shop.rarefree > os.time() then
		--	human.db.shop.costFirst = 1
		--	itemId = randomHero(CostConfig,human)
		--	num = CostConfig[itemId].num
		else
			if human.db.shop.commontimes >= ShopDefine.RARE_TEN-1 then
				itemId = randomHero(HeroConfig,human)
				num = HeroConfig[itemId].num
			else
				itemId = randomItems(RareConfig)
				num = RareConfig[itemId].num
			end
		end
		human.db.shop.commontimes = (human.db.shop.commontimes +1)%ShopDefine.RARE_TEN
		local disFrag = 0
		local itemCfg = ItemConfig[itemId]
		if itemCfg.attr["addHero"] then
			local heroName = itemCfg.attr["addHero"].name
			local heroDB = human.db.Hero
			if heroDB[heroName] then
				disFrag = 1
			end
		end
		table.insert(result,{itemId,num,disFrag})
		BagLogic.addItem(human,itemId,num,false,CommonDefine.ITEM_TYPE.ADD_COMMON_TEN)
	end
	lotteryQuery(human)
	--PublicLogic.addItemsBagOrMail(human,result)
	BagLogic.sendBagList(human)
	HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=1,objNum=10})

	local logTb = Log.getLogTb(LogId.LOTTERY_COMMON)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	local strName = ""
	local strNum = "" 
	for i = 1,#result do
		local name = ItemConfig[result[i][1]].name
		local num = result[i][2]
		local split = ","
		if i == 1 then
			split = ""
		end
		strName = strName..split..name
		strNum = strNum..split..num
	end
	logTb.itemName = strName
	logTb.itemNum = strNum
	logTb.source = 0
	logTb.costName = "金币"
	logTb.costNum = tenGold
	logTb:save()

	return true,ShopDefine.RARE_TEN_RET.kOk,result
end

function rareOnce(human)
	local onceGold = ConstantConfig.onceCost
	if human.db.shop.rarefree > os.time() 
		and human.db.shop.rareFirst >= 2 then
		if human:getRmb() < onceGold then
			return false,ShopDefine.RARE_ONCE_RET.kNoGold
		end
		human:decRmb(onceGold,nil,CommonDefine.RMB_TYPE.DEC_RARE_ONCE)
		human:sendHumanInfo()
	else
		local rareCd = ConstantConfig.rarefree
		human.db.shop.rarefree = os.time() + rareCd
	end
	local RareConfig = RareConfig
	local HeroConfig = HeroConfig
	local CostConfig = FirstCostConfig
	local itemId
	local num
	if human.db.shop.rareFirst == 0 then
		itemId = ConstantConfig.rareFirstId
		num = ConstantConfig.rareFirstNum
		human.db.shop.rareFirst = human.db.shop.rareFirst + 1
	elseif human.db.shop.rareFirst == 1 then
		itemId = ConstantConfig.rareSecondId
		num = ConstantConfig.rareSecondNum
		human.db.shop.rareFirst = human.db.shop.rareFirst + 1
	elseif human.db.shop.costFirst == 0 and human.db.shop.rarefree > os.time() then
		human.db.shop.costFirst = 1
		itemId = randomHero(CostConfig,human)
		num = CostConfig[itemId].num
	else
		if human.db.shop.raretimes >= ShopDefine.RARE_TEN-1 then
			itemId = randomHero(HeroConfig,human)
			num = HeroConfig[itemId].num
		else
			itemId = randomItems(RareConfig)
			num = RareConfig[itemId].num
		end
	end
	human.db.shop.raretimes = (human.db.shop.raretimes+1)%ShopDefine.RARE_TEN
	local disFrag = 0
	local itemCfg = ItemConfig[itemId]
	if itemCfg.attr["addHero"] then
		local heroName = itemCfg.attr["addHero"].name
		local heroDB = human.db.Hero
		if heroDB[heroName] then
			disFrag = 1
		end
	end
	--local items = {}
	--table.insert(items,{itemId,num})
	--PublicLogic.addItemsBagOrMail(human,items)
	BagLogic.addItem(human,itemId,num,true,CommonDefine.ITEM_TYPE.ADD_RARE_ONCE)
	lotteryQuery(human)
	HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=2})

	local logTb = Log.getLogTb(LogId.LOTTERY_RARE)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.itemName = ItemConfig[itemId].name
	logTb.itemNum = num
	logTb.source = 1
	logTb.costName = "钻石"
	logTb.costNum = onceGold
	logTb:save()

	return true,ShopDefine.RARE_ONCE_RET.kOk,{id=itemId,disFrag=disFrag}
end

function rareTen(human,isCertain)
	if (not human.db.shop.certain or human.db.shop.certain == 0) and isCertain == 1 then
	else
		local tenGold = ConstantConfig.tenCost
		if human:getRmb() < tenGold then
			return false,ShopDefine.RARE_TEN_RET.kNoGold
		end
		human:decRmb(tenGold,nil,CommonDefine.RMB_TYPE.DEC_RARE_TEN)
		human:sendHumanInfo()
	end
	local RareConfig = RareConfig
	local HeroConfig = HeroConfig
	local CostConfig = FirstCostConfig
	local result = {}
	local items = {}
	if (not human.db.shop.certain or human.db.shop.certain == 0) and isCertain == 1 then
		human.db.shop.certain = 1
		for k,v in pairs(ConstantConfig.certainIds) do
			local itemId = k
			local num = v
			local disFrag = 0
			local itemCfg = ItemConfig[itemId]
			if itemCfg.attr["addHero"] then
				local heroName = itemCfg.attr["addHero"].name
				local heroDB = human.db.Hero
				if heroDB[heroName] then
					disFrag = 1
				end
			end
			table.insert(result,{itemId,num,disFrag})
			BagLogic.addItem(human,itemId,num,false,CommonDefine.ITEM_TYPE.ADD_RARE_TEN)
		end
	elseif LotteryConfig.RareCertainConfig[human.db.shop.rareTenTimes + 1] then
		for k,v in pairs(LotteryConfig.RareCertainConfig[human.db.shop.rareTenTimes + 1].certainIds) do
			local itemId = k
			local num = v
			local disFrag = 0
			local itemCfg = ItemConfig[itemId]
			if itemCfg.attr["addHero"] then
				local heroName = itemCfg.attr["addHero"].name
				local heroDB = human.db.Hero
				if heroDB[heroName] then
					disFrag = 1
				end
			end
			table.insert(result,{itemId,num,disFrag})
			BagLogic.addItem(human,itemId,num,false,CommonDefine.ITEM_TYPE.ADD_RARE_TEN)
		end
	else
		for i = 1,ShopDefine.RARE_TEN do
			local itemId
			local num
			if human.db.shop.rareFirst == 0 then
				human.db.shop.rareFirst = 1
				itemId = ConstantConfig.rareFirstId
				num = 1
			elseif human.db.shop.costFirst == 0 and human.db.shop.rarefree > os.time() then
				human.db.shop.costFirst = 1
				itemId = randomHero(CostConfig,human)
				num = CostConfig[itemId].num
			else
				if human.db.shop.raretimes >= ShopDefine.RARE_TEN-1 then
					itemId = randomHero(HeroConfig,human)
					num = HeroConfig[itemId].num
				else
					itemId = randomItems(RareConfig)
					num = RareConfig[itemId].num
				end
			end
			human.db.shop.raretimes = (human.db.shop.raretimes+1)%ShopDefine.RARE_TEN
			local disFrag = 0
			local itemCfg = ItemConfig[itemId]
			if itemCfg.attr["addHero"] then
				local heroName = itemCfg.attr["addHero"].name
				local heroDB = human.db.Hero
				if heroDB[heroName] then
					disFrag = 1
				end
			end
			table.insert(result,{itemId,num,disFrag})
			BagLogic.addItem(human,itemId,num,false,CommonDefine.ITEM_TYPE.ADD_RARE_TEN)
		end
	end
	human.db.shop.rareTenTimes = human.db.shop.rareTenTimes + 1
	lotteryQuery(human)
	--PublicLogic.addItemsBagOrMail(human,result)
	BagLogic.sendBagList(human)
	HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=2,objNum=10})

	local logTb = Log.getLogTb(LogId.LOTTERY_RARE)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	local strName = ""
	local strNum = "" 
	for i = 1,#result do
		local name = ItemConfig[result[i][1]].name
		local num = result[i][2]
		local split = ","
		if i == 1 then
			split = ""
		end
		strName = strName..split..name
		strNum = strNum..split..num
	end
	logTb.itemName = strName
	logTb.itemNum = strNum
	logTb.source = 0
	logTb.costName = "钻石"
	logTb.costNum = tenGold or 0
	logTb:save()

	return true,ShopDefine.RARE_TEN_RET.kOk,result
end

function randomItems(cfg)
	local tb = {}
	for k,v in pairs(cfg) do
		table.insert(tb,{id = v.id,weight = v.weight})
	end
	local pos = PublicLogic.getItemByRand(tb)
	if pos and tb[pos] then
		return tb[pos].id
	end
end

function randomHero(cfg,human)
	local tb = {}
	for k,v in pairs(cfg) do
		table.insert(tb,{id = v.id,weight = v.weight})
	end
	local pos = PublicLogic.getItemByRand(tb)
	if pos and tb[pos] then
		return tb[pos].id
	end
end

function buyVirtual(human,shopId,params)
	local cfg = ShopVirtualConfig[shopId]
	if not cfg then
		return false,ShopDefine.SHOP_BUY_RET.kDataErr
	end
	if not ShopVirtual[cfg.func] then
		return false,ShopDefine.SHOP_BUY_RET.kDataErr
	end
	local cnt = human.db.shop:getBuyCnt(shopId)
	if cfg.daylimited >= 0 and cnt + 1 > getLimitCount(human,cfg) then
		return false,ShopDefine.SHOP_BUY_RET.kDayLimited
	end
	local price = getPriceByTimes(shopId,cnt+1)
	local ret,retCode = checkCoinByType(human,cfg.mtype,price)
	if not ret then
		return false,retCode
	end
	decCoinByType(human,cfg.mtype,price)
	human.db.shop:setBuyCnt(shopId,cnt+1)

	ShopVirtual[cfg.func](human,cfg,params)

	human:sendHumanInfo()
	query(human,{shopId})
	if cfg.itemId > 0 then
		HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=cfg.itemId})
		local rewards = {{titleId = BagDefine.REWARD_TIPS.kBuy,id = cfg.itemId,num = cfg.buynum}}
		BagLogic.sendRewardTips(human,rewards)
	end

	local logTb = Log.getLogTb(LogId.SHOP_COST)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.shopName = "虚拟物品购买"
	logTb.itemName = cfg.id
	logTb.buyCnt = cfg.buynum
	logTb.costName = ShopDefine.COST_NAME[cfg.mtype]
	logTb.costNum = price
	logTb:save()

	return true,ShopDefine.SHOP_BUY_RET.kOk
end

function getPriceByTimes(shopId,cnt)
	local cfg = ShopVirtualConfig[shopId]
	local price
	for i = #cfg.price,1,-1 do
		if cnt >= cfg.price[i][1] then
			price = cfg.price[i][2]
			break
		end
	end
	return price
end

function exchangeShopQuery(human)
	if not Util.IsSameDate(human.db.shop.exchangeLastRefresh,os.time()) then
		human.db.shop.exchangeRefresh = 0
		human.db.shop.exchangeShop = {}
		human.db.shop.exchangeLastRefresh = os.time()
	end
	local shopData = {}
	checkShop(human)
	local exchangeShop = human.db.shop.exchangeShop
	for i = 1,#exchangeShop do
		local shopId = exchangeShop[i].id
		local buy = exchangeShop[i].buy
		local cfg = ExchangeShopConfig[shopId]
		local tb = {
			id = shopId,
			itemId = cfg.itemId,
			cnt = cfg.count,
			buy = buy,
			price = cfg.exchangeCoin,
		}
		table.insert(shopData,tb)
	end
	Msg.SendMsg(PacketID.GC_EXCHANGE_SHOP_QUERY,human,shopData,human.db.shop.exchangeRefresh)
end

function checkShop(human)
	for k,v in pairs(human.db.shop.exchangeShop) do
		if not ExchangeShopConfig[v.id] then
			human.db.shop.exchangeShop = {}
			break
		end
	end
	if not next(human.db.shop.exchangeShop) then
		human.db.shop.exchangeShop = randomExchangeItems()
	end
end

function randomExchangeItems()
	local tb = {}
	for k,v in pairs(ExchangeShopConfig) do
		table.insert(tb,{id = v.id,weight = v.weight})
	end
	local result = {}
	for i = 1,ShopDefine.MAX_EXCHANGE_SHOP_NUM do
		if #tb <= ShopDefine.MAX_EXCHANGE_SHOP_NUM - i then
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

function exchangeShopBuy(human,shopId)
	local cfg = ExchangeShopConfig[shopId]
	if not cfg then
		return false,ShopDefine.EXCHANGE_BUY.kErrData
	end
	local buy 
	for k,v in pairs(human.db.shop.exchangeShop) do
		if v.id == shopId then
			buy = v.buy
			break
		end
	end
	if not buy or buy ~= 0 then
		return false,ShopDefine.EXCHANGE_BUY.kHasBuy
	end
	if human:getExchangeCoin() < cfg.exchangeCoin then
		return false,ShopDefine.EXCHANGE_BUY.kNoCoin
	end
	human:decExchangeCoin(cfg.exchangeCoin)
	for k,v in pairs(human.db.shop.exchangeShop) do
		if v.id == shopId then
			v.buy = 1
			break
		end
	end
	BagLogic.addItem(human, cfg.itemId, cfg.count,true,CommonDefine.ITEM_TYPE.ADD_EXCHANGE_SHOP)
	human:sendHumanInfo()
	return true,ShopDefine.EXCHANGE_BUY.kOk
end

function exchangeShopRefresh(human)
	local exchangeRefresh = human.db.shop.exchangeRefresh
	if exchangeRefresh >= VipLogic.getVipAddCount(human, "exchangeShopCount") then
		return false,ShopDefine.EXCHANGE_REFRESH.kNoTimes
	end
	local cfg = ExchangeShopRefreshConfig[exchangeRefresh + 1]
	if not cfg then
		return false,ShopDefine.EXCHANGE_REFRESH.kErrData
	end
	if human:getRmb() < cfg.cost then
		return false,ShopDefine.EXCHANGE_REFRESH.kNoCoin
	end
	human:decRmb(cfg.cost,nil,CommonDefine.RMB_TYPE.DEC_EXCHANGE_SHOP_REFRESH)
	human.db.shop.exchangeShop = randomExchangeItems()
	human.db.shop.exchangeRefresh = human.db.shop.exchangeRefresh + 1
	human:sendHumanInfo()
	exchangeShopQuery(human)
	return true,ShopDefine.EXCHANGE_REFRESH.kOk
end
