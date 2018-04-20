module(...,package.seeall)
local GoldDefine = require("modules.gold.GoldDefine")
local Msg = require("core.net.Msg")
local GoldConfig = require("config.GoldConfig")
local PublicLogic = require("modules.public.PublicLogic")
local GoldCntConfig = GoldConfig.GoldCntConfig
local GoldCostConfig = GoldConfig.GoldCostConfig
local GoldConstConfig = GoldConfig.GoldConstConfig
local GoldRateConfig = GoldConfig.GoldRateConfig
local ShopDefine = require("modules.shop.ShopDefine")
local ShopLogic = require("modules.shop.ShopLogic")
--local TEN = 10

function buy(human)
	local vipLv = human.db.vipLv
	local total = GoldCntConfig[vipLv].cnt
	local cnt = human.db.gold.cnt
	if cnt >= total then
		return false,GoldDefine.GOLD_BUY_RET.kNoCnt
	end
	local costCnt = cnt + 1 > #GoldCostConfig and #GoldCostConfig or cnt + 1
	local cost = GoldCostConfig[costCnt].cost
	if human:getRmb() < cost then
		return false,GoldDefine.GOLD_BUY_RET.kNoRmb
	end
	local pos = PublicLogic.getItemByRand(GoldRateConfig)
	local rate = GoldRateConfig[pos].rate
	local lv = human.db.lv
	local addMoney = GoldConstConfig[lv].money * (1+rate)
	human.db.gold.cnt = human.db.gold.cnt + 1
	human:decRmb(cost,nil,CommonDefine.RMB_TYPE.DEC_GOLD_BUY)
	human:incMoney(addMoney,CommonDefine.MONEY_TYPE.ADD_GOLD_BUY)
	human:sendHumanInfo()
	query(human)
	--ShopLogic.query(human,{ShopDefine.K_SHOP_VIRTUAL_MONEY_ID})
	HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=9901001})
	return true,GoldDefine.GOLD_BUY_RET.kOk,{gold = cost,money=addMoney,rate=rate}
end

function buyTen(human,tenCnt)
	if tenCnt <= 0 then
		return false,GoldDefine.GOLD_BUY_TEN_RET.kDataErr
	end
	local TEN = tenCnt
	local vipLv = human.db.vipLv
	local total = GoldCntConfig[vipLv].cnt
	local cnt = human.db.gold.cnt
	if cnt + TEN > total then
		return false,GoldDefine.GOLD_BUY_TEN_RET.kNoCnt
	end
	local totalRmb = 0
	for i = 1,TEN do
		local costCnt = cnt + i > #GoldCostConfig and #GoldCostConfig or cnt + i
		local cost = GoldCostConfig[costCnt].cost
		totalRmb = totalRmb + cost
	end
	if human:getRmb() < totalRmb then
		return false,GoldDefine.GOLD_BUY_TEN_RET.kNoRmb
	end
	local totalAdd = 0
	local data = {}
	local  lv = human.db.lv
	for i = 1,TEN do
		local pos = PublicLogic.getItemByRand(GoldRateConfig)
		local rate = GoldRateConfig[pos].rate
		local addMoney = GoldConstConfig[lv].money * (1+rate)
		local costCnt = cnt + i > #GoldCostConfig and #GoldCostConfig or cnt + i
		local cost = GoldCostConfig[costCnt].cost
		totalAdd = totalAdd + addMoney
		table.insert(data,{gold = cost,money = addMoney,rate = rate})
	end
	human.db.gold.cnt = human.db.gold.cnt + TEN
	human:decRmb(totalRmb,nil,CommonDefine.RMB_TYPE.DEC_GOLD_BUY_TEN)
	human:incMoney(totalAdd,CommonDefine.MONEY_TYPE.ADD_GOLD_BUY_TEN)
	human:sendHumanInfo()
	query(human)
	HumanManager:dispatchEvent(HumanManager.Event_Shop,{human=human,objId=9901001,objNum=10})
	--ShopLogic.query(human,{ShopDefine.K_SHOP_VIRTUAL_MONEY_ID})
	return true,GoldDefine.GOLD_BUY_TEN_RET.kOk,data
end

function query(human)
	if not Util.IsSameDate(human.db.gold.reset,os.time()) then
		human.db.gold.cnt = 0
		human.db.gold.reset = os.time()
	end
	local cnt = human.db.gold.cnt
	Msg.SendMsg(PacketID.GC_GOLD_BUY_QUERY,human,cnt)
end
