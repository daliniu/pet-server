module(...,package.seeall)
local Msg = require("core.net.Msg")
local TrainConstConfig = require("config.TrainConstConfig").Config
local TrainLimitConfig = require("config.TrainLimitConfig").Config
local TrainDefine = require("modules.train.TrainDefine")
local BagDefine = require("modules.bag.BagDefine")
local BagLogic = require("modules.bag.BagLogic")
local PublicLogic = require("modules.public.PublicLogic")
local HumanManager = require("core.managers.HumanManager")
LimitConfig = {}

function query(human,name)
	local base = {}
	local current = {}
	local hero = human:getHero(name)
	if not hero then
		return 
	end
	local train = hero.db.train
	local base = train.base
	--local current = train.current
	--for k,v in pairs(train.base) do
	--	table.insert(base,{name = k,val = v})
	--end
	--for k,v in pairs(train.current) do
	--	table.insert(current,{name = k,val = v})
	--end
	local current = {}
	for k,v in pairs(train.current) do
		local val1
		if v.val < 0 then
			val1 = v.val + 100000
		else
			val1 = v.val
		end
		table.insert(current,{name = v.name,val = val1})
	end
	Msg.SendMsg(PacketID.GC_TRAIN_QUERY, human,name,base,current)
end

function add(human,name)
	local hero = human:getHero(name)
	if not hero then
		return false,TrainDefine.TRAIN_ADD_RET.kNoHero
	end
	if not getTrainLimitConfig()[name] then
		return false,TrainDefine.TRAIN_ADD_RET.kDataErr
	end
	local train = hero.db.train
	local isEmpty = true
	for i = 1,#train.current do
		if train.current[i].val > 0 then
			isEmpty = false
			break
		end
	end
	if isEmpty then
		return false,TrainDefine.TRAIN_ADD_RET.kEmpty
	end

	local cfg = getTrainLimitConfig()[name][hero.db.lv]
	for i = 1,#train.base do
		local attr = TrainDefine.ATTRS[i]
		local max = cfg.limit[attr]
		if train.base[i].val < max then
			train.base[i].val = math.max(0,math.min(train.base[i].val + train.current[i].val,max))
		end
	end
	for i = 1,#train.current do
		train.current[i].val = 0
	end
	hero:resetDyAttr()
	hero:sendDyAttr()
	query(human,name)
	return true,TrainDefine.TRAIN_ADD_RET.kOk
end

function train(human,name,mtype,cnt)
	if human:getLv() < PublicLogic.getOpenLv("train") then
		return false,TrainDefine.TRAIN_RET.kNoLv
	end
	local hero = human:getHero(name)
	if not hero then
		return false,TrainDefine.TRAIN_RET.kNoHero
	end
	if not getTrainLimitConfig()[name] then
		return false,TrainDefine.TRAIN_RET.kDataErr
	end
	local isMax = true
	local cfg = getTrainLimitConfig()[name][hero.db.lv]
	for i = 1,#TrainDefine.ATTRS do
		local attr = TrainDefine.ATTRS[i]
		local max = cfg.limit[attr]
		local base = hero.db.train.base
		if base[i].val < max then
			isMax = false
			break
		end
	end
	if isMax then
		return false,TrainDefine.TRAIN_RET.kMax
	end
	if not(cnt == 1 or cnt == 5 or cnt == 10) then
		return false,TrainDefine.TRAIN_RET.kDataErr
	end
	local constCfg = TrainConstConfig[1]
	if not constCfg['material'..mtype] then
		return false,TrainDefine.TRAIN_RET.kDataErr
	end
	for k,v in pairs(constCfg['material'..mtype]) do
		if k == BagDefine.ITEM_MONEY then
			if human:getMoney() < v*cnt then
				return false,TrainDefine.TRAIN_RET.kNoMoney
			end
		elseif k == BagDefine.ITEM_RMB then
			if human:getRmb() < v*cnt then
				return false,TrainDefine.TRAIN_RET.kNoRmb
			end
		elseif BagLogic.getItemNum(human,k) < v*cnt then
			return false,TrainDefine.TRAIN_RET.kNoItem
		end
	end

	for k,v in pairs(constCfg['material'..mtype]) do
		if k == BagDefine.ITEM_MONEY then
			human:decMoney(v*cnt,CommonDefine.MONEY_TYPE.DEC_TRAIN)
		elseif k == BagDefine.ITEM_RMB then
			human:decRmb(v*cnt,nil,CommonDefine.RMB_TYPE.DEC_TRAIN)
		else
			BagLogic.delItemByItemId(human,k,v*cnt,false,CommonDefine.ITEM_TYPE.DEC_TRAIN)
		end
	end
	local current = {}
	--新手培养特写
	if human.db.trainCnt > 1 then
		for i = 1,#TrainDefine.ATTRS do

			local attrname = TrainDefine.ATTRS[i]
			local max = cfg.limit[attrname]
			local base = hero.db.train.base
			local val = 0 
			if base[i].val < max then
				local ceil = constCfg.nCeil[attrname]
				local floor = constCfg.nFloor[attrname]
				for n = 1,cnt do
					val = val + math.random(floor,ceil)
				end
			end
			table.insert(current,{name = TrainDefine.ATTRS[i],val = val})
		end
	else
		if human.db.trainCnt == 0 then
			for i = 1,#TrainDefine.ATTRS do
				table.insert(current,{name = TrainDefine.ATTRS[i],val = -5})
			end
		--elseif human.db.trainCnt == 1 then
		--	for i = 1,#TrainDefine.ATTRS do
		--		if i <= 3 then
		--			table.insert(current,{name = TrainDefine.ATTRS[i],val = -5})
		--		else
		--			table.insert(current,{name = TrainDefine.ATTRS[i],val = 5})
		--		end
		--	end
		elseif human.db.trainCnt == 1 then
			for i = 1,#TrainDefine.ATTRS do
				table.insert(current,{name = TrainDefine.ATTRS[i],val = 5})
			end
		end
	end
	BagLogic.sendBagList(human)
	human:sendHumanInfo()
	hero.db.train.current = current
	human.db.trainCnt = human.db.trainCnt + cnt
	query(human,name)
	HumanManager:dispatchEvent(HumanManager.Event_Train,{human=human,objNum = cnt})
	HumanManager:dispatchEvent(HumanManager.Event_TrainUp,{human=human,objId = mtype,objNum = cnt})
	return true,TrainDefine.TRAIN_RET.kOk
end

function sendTrainInfo(human,hero)
	local train = hero.db.train
	local base = train.base
	local current = train.current
	--local base = {}
	--for k,v in pairs(train.base) do
	--	table.insert(base,{name = k,val = v})
	--end
	--local current = {}
	--for k,v in pairs(train.current) do
	--	table.insert(current,{name = k,val = v})
	--end
	Msg.SendMsg(PacketID.GC_TRAIN_QUERY, human,base,current)
end

function sendAllTrainInfo(human)
	local heroes = human:getAllHeroes()
	local ret = {}
	for _,hero in pairs(heroes) do
		local train = hero.db.train
		local name = hero.name
		local base = train.base
		local current = train.current
		--local base = {}
		--for k,v in pairs(train.base) do
		--	table.insert(base,{name = k,val = v})
		--end
		--local current = {}
		--for k,v in pairs(train.current) do
		--	table.insert(current,{name = k,val = v})
		--end
		table.insert(ret,{base = base,current = current,name = name})
	end
	Msg.SendMsg(PacketID.GC_TRAIN_QUERY_ALL,human,ret)
end

function getTrainLimitConfig()
	if not next(LimitConfig) then
		initTrainLimitConfig()
	end
	return LimitConfig
end

function initTrainLimitConfig()
	for i = 1,#TrainLimitConfig do
		local name = TrainLimitConfig[i].hero
		local lv = TrainLimitConfig[i].lv
		LimitConfig[name] = LimitConfig[name] or {}
		LimitConfig[name][lv] = TrainLimitConfig[i]
	end
end
