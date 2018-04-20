module(...,package.seeall)
local RechargeConfig = require("config.RechargeConfig").Config
local RechargeConstConfig = require("config.RechargeConstConfig").Config
local RechargeDefine = require("modules.recharge.RechargeDefine")
local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local ShopLogic = require("modules.shop.ShopLogic")
local ns = "limitact"
LimitAct = LimitAct or {}

function query(human)
	local recharge = human.db.rechargeDB:getNum()
	local status = {}
	for i = 1,#RechargeConfig do
		local data = RechargeConfig[i]
		local state = 0
		if recharge < data.recharge then
			state = 1
		else
			if human.db.rechargeDB.got[data.id] then
				state = 3
			else
				state = 2
			end
		end
		table.insert(status,{id = data.id,state = state})
	end
	Msg.SendMsg(PacketID.GC_RECHARGE_QUERY,human,recharge,status)
end

function get(human,id)
	local data = RechargeConfig[id]
	if not data then
		return false,RechargeDefine.RECHARGE_GET_RET.kDataErr
	end
	local recharge = human.db.rechargeDB:getNum()
	if recharge < data.recharge then
		return false,RechargeDefine.RECHARGE_GET_RET.kNotEnough
	else
		if human.db.rechargeDB.got[data.id] then
			return false,RechargeDefine.RECHARGE_GET_RET.kHasGot
		end
	end
	local now = os.time()
	local endTime = getEndTime()
	--local endTime = ShopLogic.datestr2timestamp(getEndTime)
	if now > endTime then
		return false,RechargeDefine.RECHARGE_GET_RET.kEndTime
	end
	human.db.rechargeDB.got[id] = 1
	for k,v in pairs(data.item) do
		BagLogic.addItem(human,k,v,false,CommonDefine.ITEM_TYPE.ADD_RECHARGE_GET)
	end
	BagLogic.sendBagList(human)
	query(human)
	return true,RechargeDefine.RECHARGE_GET_RET.kOk
end

function getEndTime()
	local getEndTime = RechargeConstConfig[1].getEndTime
	local getEndTime1 = Config.newServerTime + getEndTime * 24 *3600
	return getEndTime1
	--return LimitAct.getEndTime
end

function beginTime()
	return LimitAct.begin
end

function endTime()
	return Config.newServerTime + LimitAct.last
	--return LimitAct.begin + LimitAct.last
end

function getGenId()
	return LimitAct.genId
end

function announcePlayer()
	local beginTime = beginTime()
	local endTime = endTime()
	local getEndTime = getEndTime()
	local isOpen = 0
	if os.time() < getEndTime and os.time() >= beginTime then
		isOpen = 1
	end
	for k,v in pairs(HumanManager.online) do
		Msg.SendMsg(PacketID.GC_RECHARGE_TIME,v,beginTime,endTime,getEndTime,isOpen)
	end
end

function update(begin,last,getEndTime)
	LimitAct.genId = LimitAct.genId + 1
	LimitAct.begin = begin
	LimitAct.last = last
	LimitAct.getEndTime = getEndTime 
	save()
	local beginTime = begin
	local endTime = begin + last
	local getEndTime = getEndTime
	local now = os.time()
	if now < getEndTime then
		local timer = Timer.new((getEndTime - now)*1000,1)
		timer:setRunner(announcePlayer)
		timer:start()
	end
	if now < beginTime then
		local timer = Timer.new((beginTime - now)*1000,1)
		timer:setRunner(announcePlayer)
		timer:start()
	end
	announcePlayer()
end

function init()
	local endTime = RechargeConstConfig[1].endTime
	local last = endTime * 24 *3600
	local getEndTime = RechargeConstConfig[1].getEndTime
	local getEndTime1 = Config.newServerTime + getEndTime * 24 *3600
	LimitAct = {genId = 1,begin = Config.newServerTime,last = last,getEndTime = getEndTime1}
	local count = DB.Count(ns, {},true)
	local cursor = MongoDBCursor(pCursor)
	if count<=0 then
		DB.Insert(ns, LimitAct,true)
	end
	local pCursor = g_oMongoDB:SyncFind(ns,{})
	cursor = MongoDBCursor(pCursor)
	if not cursor:Next(LimitAct) then
		assert(nil, " Init LimitAct err")
		return false
	end
	local beginTime = LimitAct.begin
	if beginTime > os.time() then
		local timer = Timer.new((beginTime - os.time())*1000,1)
		timer:setRunner(announcePlayer)
		timer:start()
	end
	local getEndTime = LimitAct.getEndTime
	if getEndTime > os.time() then
		local timer = Timer.new((getEndTime - os.time())*1000,1)
		timer:setRunner(announcePlayer)
		timer:start()
	end
	return true
end

function save(isSync)
	local query = {}
	query._id = LimitAct._id;
	DB.Update(ns,query,LimitAct,isSync)
end
