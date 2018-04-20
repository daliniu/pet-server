module(...,package.seeall)
local StrengthDefine = require("modules.strength.StrengthDefine")
local Msg = require("core.net.Msg")
local StrengthConfig = require("config.StrengthConfig").Config
local StrengthCell = require("modules.strength.StrengthCell")
local MaterialConfig = require("config.StrengthMaterialConfig").Config
local ItemConfig = require("config.ItemConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local ShopLogic = require("modules.shop.ShopLogic")
local ShopDefine = require("modules.shop.ShopDefine")
local StrengthAppConfig = StrengthAppConfig or {}

function init()
	initStrengthAppConfig()
end

function query(human,heroName)
	local hero = human:getHero(heroName)
	if not hero then
		return false,StrengthDefine.kDataErr
	end
	sendStrengthInfo(hero)
	return true,StrengthDefine.kOk
end

function makeStrengthData(hero)
	local retMsg = {}
	local strength = hero.db.strength
	retMsg.name = hero:getName() 
	retMsg.transferLv = strength.transferLv
	retMsg.cells = {}
	for i = 1,#strength.cells do
		local grid = strength.cells[i].grids
		local cell = {}
		cell.id = strength.cells[i].id
		cell.lv = strength.cells[i].lv
		cell.grids = {}
		for j = 1,#grid do
			table.insert(cell.grids,{id = grid[j]})
		end
		table.insert(retMsg.cells,cell)	
	end
	return retMsg
end

function sendAllStrengthInfo(human)
	local heroes = human:getAllHeroes()
	local groupMsg = {}
	for _,hero in pairs(heroes) do 
		local retMsg = makeStrengthData(hero)
		table.insert(groupMsg,retMsg)
	end
	Msg.SendMsg(PacketID.GC_STRENGTH_ALL,human,groupMsg)
end

function sendStrengthInfo(hero)
	local retMsg = makeStrengthData(hero)
	--print("sendStrengthInfo::")
	--Util.print_r(retMsg)
	Msg.SendMsg(PacketID.GC_STRENGTH_QUERY, hero:getHuman(),retMsg.name,retMsg.transferLv,retMsg.cells)
end

function lvUp(human,heroName,cellPos)
	local hero = human:getHero(heroName)
	if not hero then
		return false,StrengthDefine.STRENGTH_LV_UP_RET.kClientErr
	end
	local strength = hero.db.strength
	local cell = strength.cells[cellPos]
	if not cell then
		return false,StrengthDefine.STRENGTH_LV_UP_RET.kClientErr
	end
	if cell.lv >= StrengthDefine.kMaxStrengthLv then
		return false,StrengthDefine.STRENGTH_LV_UP_RET.kMaxLv
	end
	if not checkLvUpMaterial(hero,cellPos) then
		return false,StrengthDefine.STRENGTH_LV_UP_RET.kNoMaterial
	end
	cell.lv = cell.lv + 1
	--if not isMaxLv(strength,cellPos) then
	--	StrengthCell.gridInit(cell)
	--end
	--query(human,heroName)
	--hero:resetDyAttr()
	--hero:sendDyAttr()
	return true,StrengthDefine.STRENGTH_LV_UP_RET.kOk
end

function transfer(human,heroName)
	local hero = human:getHero(heroName)
	if not hero then
		return false,StrengthDefine.STRENGTH_TRANSFER_RET.kClientErr
	end
	local strength = hero.db.strength
	if strength.transferLv >= StrengthDefine.kMaxTransferLv then
		return false,StrengthDefine.STRENGTH_TRANSFER_RET.kMaxLv
	end
	local canTransfer = true
	for i = 1,StrengthDefine.kMaxStrengthCellCap do
		if strength.cells[i].lv <= strength.transferLv then
			canTransfer = false
		end
	end
	if not canTransfer then
		return false,StrengthDefine.STRENGTH_TRANSFER_RET.kNotLv
	end
	strength.transferLv = strength.transferLv + 1
	local strength = hero.db.strength
	if strength.transferLv < StrengthDefine.kMaxTransferLv then
		for i = 1,StrengthDefine.kMaxStrengthCellCap do
			local cell = strength.cells[i]
			StrengthCell.gridInit(cell)
		end
	end
	query(human,heroName)
	BagLogic.sendBagList(human)
	hero:resetDyAttr()
	hero:sendDyAttr()

	HumanManager:dispatchEvent(HumanManager.Event_PowerLvUp,{human=human,objNum=getSumTransferLv(human)})

	return true,StrengthDefine.STRENGTH_TRANSFER_RET.kOk
end

function getSumTransferLv(human)
	local heroList = human:getAllHeroes()
	local lv = 0
	for _,hero in pairs(heroList) do
		local strength = hero.db.strength
		lv = lv + strength.transferLv
	end
	return lv
end

function equip(human,heroName,cellPos,gridPos)
	local hero = human:getHero(heroName)
	if not hero then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kClientErr
	end
	local strength = hero.db.strength
	local cell = strength.cells[cellPos]
	if not cell then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kClientErr
	end
	local grid = cell.grids[gridPos]
	if not grid  then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kClientErr
	end
	if grid > 0 then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kClientErr
	end
	local cfg = getStrengthConfig(heroName,cellPos)	
	if not cfg.lvCfg[cell.lv+1] then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kClientErr
	end
	local itemId = cfg.lvCfg[cell.lv+1].need[gridPos]
	local itemCfg = ItemConfig[itemId]
	if not itemCfg then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kDataErr
	end
	--if human.db.lv < itemCfg.lv then
	if hero.db.lv < itemCfg.lv then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kNoLv
	end
	if BagLogic.getItemNum(human,itemId) <= 0 then
		return false,StrengthDefine.STRENGTH_EQUIP_RET.kNoMaterial
	end
	BagLogic.delItemByItemId(human,itemId,1,false,CommonDefine.ITEM_TYPE.DEC_STRENGTH_EQUIP)
	cell.grids[gridPos] = itemId
	lvUp(human,heroName,cellPos)
	query(human,heroName)
	BagLogic.sendBagList(human)
	hero:resetDyAttr()
	--hero:sendDyAttr()
	hero:sendHeroAttr()

	local logTb = Log.getLogTb(LogId.GEM_EQUIP)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.heroName = heroName
	logTb.gemName = itemCfg.name
	logTb.gemNum = 1
	logTb.gemLeft = BagLogic.getItemNum(human,itemId)
	logTb:save()

	return true,StrengthDefine.STRENGTH_EQUIP_RET.kOk
end

function isMaxLv(strength,pos)
	return strength.cells[pos].lv >= StrengthDefine.kMaxStrengthLv
end

function getStrengthConfig(name,cellPos)
	local cfg = {}
	if StrengthConfig[name] and StrengthConfig[name][cellPos] then
		for k,v in pairs(StrengthConfig[name][cellPos]) do
			cfg.id = k
			cfg.lvCfg = v
			break
		end
	end
	return cfg
end

function getStrengthAppConfig(name,cellPos)
	local cfg = {}
	if StrengthAppConfig[name] and StrengthAppConfig[name][cellPos] then
		cfg = StrengthAppConfig[name][cellPos]
	end
	return cfg
end

function initStrengthAppConfig()
	for name,cfg in pairs(StrengthConfig) do
		StrengthAppConfig[name] = {}
		for pos,lvCfg in pairs(cfg) do
			StrengthAppConfig[name][pos] = {}
			for k,v in pairs(lvCfg) do
				StrengthAppConfig[name][pos].id = k
				StrengthAppConfig[name][pos].lvCfg = v
				appendStrengthConfig(StrengthAppConfig[name][pos].lvCfg)
			end
		end
	end
		--print("initStrength2Config")
		--Util.print_r(StrengthAppConfig)
end

function appendStrengthConfig(lvCfg)
	for k,v in pairs(lvCfg) do
		local append = {}
		for i = k,1,-1 do
			local need = lvCfg[i].need
			for j = 1,#need do
				local itemId = need[j]
				local cfg = MaterialConfig[itemId]
				if cfg then
					for attr,val in pairs(cfg.attr) do
						append[attr] = (append[attr] or 0) + val
					end
				end
			end
		end
		lvCfg[k].append = append
	end
end

function checkLvUpMaterial(hero,cellPos)
	local cell = hero.db.strength.cells[cellPos]
	local canLvUp = true
	local cfg = getStrengthConfig(hero:getName(),cellPos)	
	local need = cfg.lvCfg[cell.lv+1].need
	local canLvUp = true
	for i = 1,#need do
		if cell.grids[i] ~= need[i] then
			canLvUp = false
			break
		end
	end
	return canLvUp
end

function compose(human,itemId)
	local itemCfg = ItemConfig[itemId]
	if not itemCfg then
		return false,StrengthDefine.MATERIAL_COMPOSE_RET.kClientErr
	end
	local materialCfg = MaterialConfig[itemId]
	if not materialCfg then
		return false,StrengthDefine.MATERIAL_COMPOSE_RET.kClientErr
	end
	if not next(materialCfg.need) then
		return false,StrengthDefine.MATERIAL_COMPOSE_RET.kAtom
	end
	local cost = composeCost(human,itemId)
	local ret,retCode = ShopLogic.checkCoinByType(human,materialCfg.mtype,cost)
	if not ret then
		return false,StrengthDefine.MATERIAL_COMPOSE_RET.kNoMoney
	end
	if not checkCanCompose(human,itemId,1) then
		return false,StrengthDefine.MATERIAL_COMPOSE_RET.kNoMaterial
	end
	if not BagLogic.checkCanAddItem(human,itemId,1) then
		return false,StrengthDefine.MATERIAL_COMPOSE_RET.kBagFull
	end
	decCoinByType(human,materialCfg.mtype,cost)
	delComposeMaterial(human,itemId,1)
	BagLogic.addItem(human,itemId,1,true,CommonDefine.ITEM_TYPE.ADD_STRENGTH_COMPOSE)
	HumanManager:dispatchEvent(HumanManager.Event_Strength,{human=human})
	human:sendHumanInfo()

	local logTb = Log.getLogTb(LogId.GEM_COMPOSE)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.leftCnt = BagLogic.getItemNum(human,itemId)
	logTb.gemName = itemCfg.name
	logTb:save()

	return true,StrengthDefine.MATERIAL_COMPOSE_RET.kOk
end

function checkCanCompose(human,id,num)
	if not MaterialConfig[id] then
		return false
	end
	local canCompose = true
	local need = MaterialConfig[id].need
	if not next(need) then
		return false
	end
	for k,v in pairs(need) do
		if k == id then
			canCompose = false
			break
		end
		if BagLogic.getItemNum(human,k) < v*num then
			--canCompose = false
			--break
			local ownNum = BagLogic.getItemNum(human,k)
			if not checkCanCompose(human,k,v*num -ownNum) then
				canCompose = false
				break
			end
		end
	end
	return canCompose
end

function delComposeMaterial(human,id,num)
	if not MaterialConfig[id] then
		BagLogic.delItemByItemId(human,id,num,false,DEC_STRENGTH_COMPOSE)
		return
	end
	local need = MaterialConfig[id].need
	for k,v in pairs(need) do
		if BagLogic.getItemNum(human,k) < v*num then
			local ownNum = BagLogic.getItemNum(human,k)
			BagLogic.delItemByItemId(human,k,ownNum,false,CommonDefine.ITEM_TYPE.DEC_STRENGTH_COMPOSE)
			delComposeMaterial(human,k,v*num - ownNum)
		else
			BagLogic.delItemByItemId(human,k,v*num,false,CommonDefine.ITEM_TYPE.DEC_STRENGTH_COMPOSE)
			--delComposeMaterial(human,k,v*num)
		end
	end
end

function composeCost(human,id)
	if not MaterialConfig[id] then
		return 0 
	end
	local need = MaterialConfig[id].need
	local cost = MaterialConfig[id].cost
	for k,v in pairs(need) do
		local num = v - BagLogic.getItemNum(human,k)
		if num > 0 then
			cost = cost + num * composeCost(human,k)
		end
	end
	return cost
end

function fragCompose(human,id)
	local fragConfig = FragConfig[id]
	if not fragConfig then
		return false,StrengthDefine.FRAG_COMPOSE_RET.kClientErr
	end
	if BagLogic.getItemNum(human,id) < fragConfig.num then
		return false,StrengthDefine.FRAG_COMPOSE_RET.kNoMaterial
	end
	BagLogic.delItemByItemId(human,id,fragConfig.num,false,CommonDefine.ITEM_TYPE.DEC_STRENGTH_COMPOSE)
	BagLogic.addItem(human,fragConfig.destId,1,true,CommonDefine.ITEM_TYPE.ADD_STRENGTH_COMPOSE)
	return true,StrengthDefine.FRAG_COMPOSE_RET.kOk
end

function quickEquip(human,heroName)
	local hero = human:getHero(heroName)
	if not hero then
		return false,StrengthDefine.STRENGTH_QUICK_EQUIP_RET.kClientErr
	end
	local strength = hero.db.strength
	local group = {}
	for i = 1,StrengthDefine.kMaxStrengthCellCap do
		local cell = strength.cells[i]
		for j = 1,StrengthDefine.kMaxStrengthGridCap do
			local grid = cell.grids[j]
			if grid <= 0 then
				local cfg = getStrengthConfig(heroName,i)	
				local itemId = cfg.lvCfg[cell.lv+1].need[j]
				local itemCfg = ItemConfig[itemId]
				if hero.db.lv >= itemCfg.lv and BagLogic.getItemNum(human,itemId) > 0 then
					BagLogic.delItemByItemId(human,itemId,1,false,CommonDefine.ITEM_TYPE.DEC_STRENGTH_EQUIP)
					cell.grids[j] = itemId
					lvUp(human,heroName,i)
					table.insert(group,{cell = i,grid = j})
				end
			end
		end
	end
	if not next(group) then
		return false,StrengthDefine.STRENGTH_QUICK_EQUIP_RET.kNoEquip
	end
	query(human,heroName)
	BagLogic.sendBagList(human)
	hero:resetDyAttr()
	--hero:sendDyAttr()
	hero:sendHeroAttr()
	return true,StrengthDefine.STRENGTH_QUICK_EQUIP_RET.kOk,group
end

function decCoinByType(human,mtype,cost)
	if mtype == ShopDefine.K_SHOP_BUY_RMB then
		human:decRmb(cost,nil,CommonDefine.RMB_TYPE.DEC_STR_COMPOSE)
	elseif mtype == ShopDefine.K_SHOP_BUY_MONEY then
		human:decMoney(cost,CommonDefine.MONEY_TYPE.DEC_STR_COMPOSE)
	elseif mtype == ShopDefine.K_SHOP_BUY_POWERCOIN then
		human:decPowerCoin(cost)
	end
end

