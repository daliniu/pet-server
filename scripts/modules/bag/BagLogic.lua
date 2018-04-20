module(...,package.seeall)
local BagDefine = require("modules.bag.BagDefine")
local BAG_OP = BagDefine.BAG_OP
local BAG_GRID_OP = BagDefine.BAG_GRID_OP
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local ItemConfig = require("config.ItemConfig").Config
local Grid = require("modules.bag.Grid")
local Handbook = require("modules.handbook.Handbook")
local VirItemFunc= require("modules.bag.VirItemFunc")
local InitItemsConfig = require("config.InitItemsConfig").Config

function onHumanLogin(hm,human)
	sendBagList(human,true)
end

function onHumanCreate(hm,human)
	local items = InitItemsConfig[1].items
	for k,v in pairs(items) do
		addItem(human,k,v)
	end
	--addItem(human,1308001,99)
	--addItem(human,1701001,11)
	--addItem(human,1701002,11)
	--addItem(human,1701003,11)
	--addItem(human,1701004,11)
	--addItem(human,1701005,11)
	--addItem(human,1701006,11)
	--sendBagList(human,true)
end

function sendBagList(human,sendAll)
	local bag = human:getBag()
	local op = BAG_OP.kSendLocal
	if sendAll then
		--排序
		local dirtys = {}
		for i = 1,#bag do
			table.insert(dirtys,{pos = i,mtype = BAG_GRID_OP.kChange})
		end
		human.bagDirty = {}
		human.bagSeq = {}
		setGridsDirty(human,dirtys)
		op = BAG_OP.kSendAll
	end
	local needSend,bagData = makeBagList(human)
	if op == BAG_OP.kSendAll or needSend then
		Msg.SendMsg(PacketID.GC_BAG_LIST,human,op,bagData)
	end
end

function setGridsDirty(human,dirtys)
	human.bagDirty = human.bagDirty or {}
	human.bagSeq = human.bagSeq or {}
	local bagDirty = human.bagDirty
	local bagSeq = human.bagSeq
	for i = 1,#dirtys do
		local pos = dirtys[i].pos
		local mtype = dirtys[i].mtype
		local id = dirtys[i].id
		local cnt = dirtys[i].cnt
		--if mtype == BAG_GRID_OP.kChange and bagDirty[pos] then
		--	table.remove(bagSeq,bagDirty[pos])
		--end
		table.insert(bagSeq,{pos = pos,mtype = mtype,id = id,cnt = cnt})
		bagDirty[pos] = #bagSeq
	end
end

function makeBagList(human)
	local bag = human:getBag()
	local bagData = {}
	local needSend = false
	for i = 1,#human.bagSeq do
		needSend = true
		local pos = human.bagSeq[i].pos
		local mtype = human.bagSeq[i].mtype
		local grid = bag[pos]
		local id = grid and grid.id or 0
		id = human.bagSeq[i].id or id
		local cnt = grid and grid.cnt or 0
		cnt = human.bagSeq[i].cnt or cnt
		table.insert(bagData,{id = id,pos = pos,cnt = cnt,mtype = mtype})
	end
	human.bagDirty = {}
	human.bagSeq = {}
	return needSend,bagData
end

function checkCanAddItem(human,itemId,cnt)
	if cnt < 1 then
		return false
	end
	local cfg = ItemConfig[itemId]
	if not cfg then
		assert(false,"lost ItemConfig====>" .. itemId)
		return false
	end
	return true
end

function dealVirItem(human,itemId,cnt,way)
	local cfg = ItemConfig[itemId]
	if not cfg then
		return false
	end
	local isVirtual = false
	for k,v in pairs(cfg.attr) do
		if VirItemFunc[k] then
			VirItemFunc[k](human,v,cnt,way)
			isVirtual = true
		end
	end
	return isVirtual
end

function addItem(human,itemId,cnt,refresh,way)
	if dealVirItem(human,itemId,cnt,way) then
		return true
	end
	local retCode = checkCanAddItem(human,itemId,cnt)
	if not retCode then
		return false
	end
	local bag = human:getBag()
	local appendPos = 0
	local grid
	local dirtyCnt
	for i = 1,#bag do
		grid = bag[i]
    	local itemCfg = ItemConfig[itemId] 
    	local cap = itemCfg.cap
		if canGridAppendItem(grid,itemId,cap) then
			dirtyCnt = grid.cnt + cnt
			Grid.addItem(grid,itemId,grid.cnt+cnt)
			appendPos = i
			break
		end
	end
	if appendPos <= 0 then
		grid = Grid.new()
		grid.id = itemId
		grid.cnt = cnt
		table.insert(bag,grid)
		appendPos = #bag
	end
	dirtyCnt = dirtyCnt or cnt
	local dirtys = {}
	table.insert(dirtys,{pos = appendPos,mtype = BAG_GRID_OP.kAdd,id=itemId,cnt=dirtyCnt})
	setGridsDirty(human,dirtys)
	if refresh then
		sendBagList(human)
	end
	Handbook.addItemLib(human,itemId)
	--
	assert(way,"error need way!!!!")

	local logTb = Log.getLogTb(LogId.ADD_ITEM)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.level = human:getLv()
	logTb.itemId = itemId
	logTb.cnt = cnt
	logTb.leftCnt = grid.cnt 
	logTb.way = way or CommonDefine.ITEM_TYPE.ADD
	logTb:save()
	return true
end

function canGridAppendItem(grid,itemId,cap)
	if grid.id == itemId then
		return true
	end
	return false
end

function isValidPos(human, pos)
	local bag = human:getBag()
    return pos and 0 < pos and pos <= #bag
end

function delItemByPos(human,pos,cnt,refresh)
	if not isValidPos(human,pos) then
		return false
	end
	local bag = human:getBag()
	local grid = bag[pos]
	assert(grid.cnt > 0)
	grid.cnt = grid.cnt - cnt
	local mtype = BAG_GRID_OP.kChange
	if grid.cnt <= 0 then
		table.remove(bag,pos)
		mtype = BAG_GRID_OP.kDel
	end
	local dirtys = {}
	table.insert(dirtys,{pos=pos,mtype=mtype,cnt=grid.cnt,id=grid.id})
	setGridsDirty(human,dirtys)
	if refresh then
		sendBagList(human)
	end
	--
	return true
end

function delItemByItemId(human,itemId,cnt,refresh,way) --删除一定数量物品
	if cnt < 1 then
		return false, cnt
	end
	local bag = human:getBag()
	local pos = 0 
	local grid 
	for i = 1,#bag do
		if bag[i].id == itemId then
			grid = bag[i]
			pos = i
			break
		end
	end
	if pos <= 0 then
		return false,cnt
	else
		delItemByPos(human,pos,cnt,refresh)
		--
		assert(way,"error need way!!!!")
		local logTb = Log.getLogTb(LogId.DEC_ITEM)
		logTb.channelId = human:getChannelId()
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.level = human:getLv()
		logTb.itemId = itemId
		logTb.cnt = cnt
		logTb.leftCnt = grid.cnt
		logTb.way = way or CommonDefine.ITEM_TYPE.DEC
		logTb:save()
    	return true, cnt
	end
end

function sellItem(human,pos,cnt,way)
	local bag = human:getBag()
	if pos < 1 or pos > #bag then
		return false
	end
	if bag[pos].cnt < cnt then
		return false
	end
	local grid = bag[pos]
	local itemId = grid.id
	local cfg = ItemConfig[itemId]
	local money = cfg.price * cnt
	delItemByPos(human,pos,cnt,true)
	--
	assert(way,"error need way!!!!")
	local logTb = Log.getLogTb(LogId.DEC_ITEM)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.level = human:getLv()
	logTb.itemId = grid.id
	logTb.cnt = cnt
	logTb.leftCnt = grid.cnt 
	logTb.way = way or CommonDefine.ITEM_TYPE.DEC
	logTb:save()

	human:incMoney(money,CommonDefine.MONEY_TYPE.ADD_SELL_ITEM)
	human:sendHumanInfo()
	Msg.SendMsg(PacketID.GC_ITEM_SELL,human,money)
	local rewards = {{titleId = BagDefine.REWARD_TIPS.kSell,id = 9901001,num = money}}
	sendRewardTips(human,rewards)
end

function getItemNum(human,itemId)
	local bag = human:getBag()
	local res = 0
	for k = 1,#bag do
		if bag[k].id == itemId then
			res = res + bag[k].cnt
		end
	end
	return res
end

function isVirItem(itemId)
	local cfg = ItemConfig[itemId]
	for k,v in pairs(cfg.attr) do
		if VirItemFunc[k] then
			return true
		end
	end
	return false
end

function sendRewardTipsEx(human,rewards)
	local ret = {}
	for k,v in pairs(rewards) do
		local itemId = tonumber(k)
		if type(itemId) == 'number' then
			table.insert(ret,{titleId = BagDefine.REWARD_TIPS.kGet,id = itemId,num = v})
		elseif k == 'money' then
			table.insert(ret,{titleId = BagDefine.REWARD_TIPS.kGet,id = 9901001,num = v})
		elseif k == 'rmb' then
			table.insert(ret,{titleId = BagDefine.REWARD_TIPS.kGet,id = 9901002,num = v})
		end
	end
	sendRewardTips(human,ret)
end

function sendRewardTips(human,rewards)
	Msg.SendMsg(PacketID.GC_REWARD_TIPS,human,rewards)
end

function getItemName(itemId)
	return ItemConfig[itemId].name
end
