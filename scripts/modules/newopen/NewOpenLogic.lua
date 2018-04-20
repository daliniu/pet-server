module(...,package.seeall)
local Msg = require("core.net.Msg")
local NewOpenConfig = require("config.NewOpenConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local NewOpenDefine = require("modules.newopen.NewOpenDefine")
local BagDefine = require("modules.bag.BagDefine")
local NewOpenConstConfig = require("config.NewOpenConstConfig").Config
local ns = "newopen"
function newNewOpen()
	local o = {}
	DB.dbSetMetatable(o)
	for i = 1,7 do
		o[i] = {discountNum = 0}
	end
	return o
end

NewOpen = NewOpen or newNewOpen()

function onHumanLogin(hm,human)
	if human.db.newopenDB:getCurStatus("loginGet") == 0 then
		human.db.newopenDB:setCurStatus("loginGet",1)
	end
end

function query(human)
	local day = getCurOpenDay()
	local rewards = {}
	local newopen = human.db.newopenDB
	for i = 1,#newopen do
		local loginGet = newopen:getStatus(i,"loginGet")
		local rechargeNum = newopen:getStatus(i,"rechargeNum")
		local rechargeGet = newopen:getStatus(i,"rechargeGet")
		local discountGet = newopen:getStatus(i,"discountGet")
		local discountNum = NewOpen[i] and NewOpen[i].discountNum or 0
		table.insert(rewards,{day = i,loginGet = loginGet,rechargeNum = rechargeNum,rechargeGet = rechargeGet,discountGet = discountGet,discountNum = discountNum})
	end
	Msg.SendMsg(PacketID.GC_NEW_OPEN_QUERY,human,day,rewards)
end

function getCurOpenDay()
	local time = Util.getToday0Clock(Config.newServerTime)
	local curTime = Util.getToday0Clock(os.time())
	local day = (curTime - time) / (24*3600)+ 1
	--local day = math.ceil((os.time() - Config.newServerTime) / (24 * 3600))
	return day
end

function loginGetFunc(human,day)
	if day > getCurOpenDay() then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kDataErr
	end
	local cfg = NewOpenConfig[day]
	if not cfg then
		return false,NewOpenDefine.LOGIN_GET_RET.kDataErr
	end
	local newopen = human.db.newopenDB
	local loginGet = newopen:getStatus(day,"loginGet")
	if loginGet ~= 1 then
		return false,NewOpenDefine.LOGIN_GET_RET.kHasGot
	end
	local rewards = {}
	for k,v in pairs(cfg.loginReward) do
		BagLogic.addItem(human,k,v,false,CommonDefine.ITEM_TYPE.ADD_NEW_OPEN_LOGIN)
		table.insert(rewards,{titleId = BagDefine.REWARD_TIPS.kGet,id = k,num = v})
	end
	BagLogic.sendBagList(human)
	BagLogic.sendRewardTips(human,rewards)

	newopen:setStatus(day,"loginGet",2)
	query(human)
	return true,NewOpenDefine.LOGIN_GET_RET.kOk
end

function rechargeGetFunc(human,day)
	if day > getCurOpenDay() then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kDataErr
	end
	local cfg = NewOpenConfig[day]
	if not cfg then
		return false,NewOpenDefine.RECHARGE_GET_RET.kDataErr
	end
	local newopen = human.db.newopenDB
	if newopen:getStatus(day,"rechargeNum") < cfg.rechargeNum then
		return false,NewOpenDefine.RECHARGE_GET_RET.kNotEnough
	end
	if newopen:getStatus(day,"rechargeGet") ~= 0 then
		return false,NewOpenDefine.RECHARGE_GET_RET.kHasGot
	end
	local rewards = {}
	for k,v in pairs(cfg.rechargeReward) do
		BagLogic.addItem(human,k,v,false,CommonDefine.ITEM_TYPE.ADD_NEW_OPEN_RECHARGE)
		table.insert(rewards,{titleId = BagDefine.REWARD_TIPS.kGet,id = k,num = v})
	end
	BagLogic.sendBagList(human)
	BagLogic.sendRewardTips(human,rewards)

	newopen:setStatus(day,"rechargeGet",1)
	query(human)
	return true,NewOpenDefine.RECHARGE_GET_RET.kOk
end

function discountBuy(human,day)
	if day > getCurOpenDay() then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kDataErr
	end
	local cfg = NewOpenConfig[day]
	if not cfg then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kDataErr
	end
	if getCurOpenDay() > NewOpenConstConfig[1].endTime then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kTimeOut
	end
	local newopen = human.db.newopenDB
	if newopen:getStatus(day,"discountGet") ~= 0 then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kHasBuy
	end
	if human:getRmb() < cfg.newprice then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kNoRmb
	end
	if not NewOpen[day] then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kDataErr
	end
	if NewOpen[day].discountNum >= cfg.limit then
		return false,NewOpenDefine.DISCOUNT_BUY_RET.kLimit
	end
	NewOpen[day].discountNum = NewOpen[day].discountNum + 1
	human:decRmb(cfg.newprice,nil,CommonDefine.RMB_TYPE.DEC_NEW_OPEN_DISCOUNT)
	human:sendHumanInfo()

	local rewards = {}
	for k,v in pairs(cfg.discount) do
		BagLogic.addItem(human,k,v,false,CommonDefine.ITEM_TYPE.ADD_NEW_OPEN_DISCOUNT)
		table.insert(rewards,{titleId = BagDefine.REWARD_TIPS.kGet,id = k,num = v})
	end
	BagLogic.sendBagList(human)
	BagLogic.sendRewardTips(human,rewards)

	newopen:setStatus(day,"discountGet",1)
	query(human)
	return true,NewOpenDefine.DISCOUNT_BUY_RET.kOk
end

function init()
	loadDB()
	local saveTimer = Timer.new(300*1000,-1)
	saveTimer:setRunner(save)
	saveTimer:start()
end

function loadDB()
	local count = DB.Count(ns, {},true)
	local cursor = MongoDBCursor(pCursor)
	if count<=0 then
		NewOpen = newNewOpen()
		DB.Insert(ns,NewOpen,true)
	end
	local pCursor = g_oMongoDB:SyncFind(ns,{})
	cursor = MongoDBCursor(pCursor)
	if not cursor:Next(NewOpen) then
		assert(nil, " Init NewOpen err")
		return false
	end
	DB.dbSetMetatable(NewOpen)
	return true
end

function save(isSync)
	local query = {}
	query._id = NewOpen._id;
	DB.Update(ns,query,NewOpen,isSync)
end
