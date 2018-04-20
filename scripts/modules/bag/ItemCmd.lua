module(..., package.seeall)
local BagLogic = require("modules.bag.BagLogic")
local BagDefine = require("modules.bag.BagDefine")
local ItemConfig = require("config.ItemConfig").Config
local HeroManager = require("modules.hero.HeroManager")
local PublicLogic = require("modules.public.PublicLogic")
local USE_ITEM = BagDefine.USE_ITEM

local RET_SUCCESS_AND_CAN_CONTINUE_NO_DELITEM = 0 
local RET_SUCCESS_AND_CAN_CONTINUE = 1
local RET_FAIL_BUT_CAN_CONTINUE = 2
local RET_FAIL_AND_MUST_BREAK = 3
local rewards = {}

function useItem(human,pos,cnt,argList)
	local grids = human:getBag()
	if cnt < 0 then
        return 0,USE_ITEM.kItemNotExist
    end
	if not BagLogic.isValidPos(human,pos) then
		return 0,USE_ITEM.kItemNotExist
	end
    local grid = grids[pos]
    if not grid then
        return 0, USE_ITEM.kItemNotExist
    end
    if grid.cnt < cnt then 
        return 0, USE_ITEM.kItemNotExist
    end

    local cfg = ItemConfig[grid.id]
    if not cfg then
        return 0, USE_ITEM.kItemNotExist
    end

    if not cfg.cmd or not next(cfg.cmd) then
        return grid.id,USE_ITEM.kItemCanNotUse
    end

    local err = USE_ITEM.kItemCanNotUse
    
	rewards = {}
    for _=1,cnt do
        local ret
        local hasDel
        for k,v in ipairs(cfg.cmd) do
            for kk,vv in pairs(v) do
                if _M[kk] then
                    ret,err = _M[kk](human,vv,argList,cfg)
                    if ret == RET_SUCCESS_AND_CAN_CONTINUE then
                        if not hasDel then
                            hasDel = true
                            BagLogic.delItemByPos(human,pos,1)
						end
                    elseif ret == RET_FAIL_AND_MUST_BREAK then
                    	break
                    end
                end
            end
            if ret == RET_FAIL_AND_MUST_BREAK then
				break
			end
        end
    end
    BagLogic.sendBagList(human)
	local rewardRet = {}
	for k,v in pairs(rewards) do
		table.insert(rewardRet,{titleId = BagDefine.REWARD_TIPS.kGet,id = k,num = v})
	end
	if next(rewardRet) then
		BagLogic.sendRewardTips(human,rewardRet)
	end
	--
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

    return grid.id, err or USE_ITEM.kItemUseOk
end

function checkGrid(human,val,clientArgList)  --检查背包剩余格数
    return RET_SUCCESS_AND_CAN_CONTINUE
end

function item(human,val,clientArgList)
	local itemId = val[1]
	local cnt = val[2]
	local ret = BagLogic.addItem(human,itemId,cnt,false,CommonDefine.ITEM_TYPE.ADD_USE_ITEM)
	if ret then
		rewards[itemId] = rewards[itemId] and rewards[itemId] + cnt or cnt
		return RET_SUCCESS_AND_CAN_CONTINUE
	else
		return RET_FAIL_AND_MUST_BREAK,USE_ITEM.kItemNotEnoughGrid
	end
end


function addExp(human,val,clientArgList)
    local exp = val[1]
    local heroName = clientArgList[1]
    local hero = human:getHero(heroName)
    if hero and hero:addExp(exp) then
        return RET_SUCCESS_AND_CAN_CONTINUE
    else
        return RET_FAIL_AND_MUST_BREAK,USE_ITEM.kItemCanNotUse
    end
end

function randItem(human,val,clientArgList)
	local randItems = val
	local tb = {}
	local sumRand = 0
	local totalRand = 10000
	for k,v in pairs(randItems) do
		tb[#tb+1] = {weight = v[3]}
		sumRand = sumRand + v[3]
	end
	if totalRand - sumRand > 0 then
		tb[#tb+1] = {weight = totalRand - sumRand}
	end
	local pos = PublicLogic.getItemByRand(tb)
	if pos and randItems[pos] then
		local addItemId = randItems[pos][1]
		local cnt = randItems[pos][2]
		local ret = BagLogic.addItem(human,addItemId,cnt,false,CommonDefine.ITEM_TYPE.ADD_USE_ITEM)
		if ret then
			rewards[addItemId] = rewards[addItemId] and rewards[addItemId] + cnt or cnt
			return RET_SUCCESS_AND_CAN_CONTINUE
		else
			return RET_FAIL_AND_MUST_BREAK,USE_ITEM.kItemNotEnoughGrid
		end
	else
		return RET_SUCCESS_AND_CAN_CONTINUE
	end
end

function addMoney(human,val,clientArgList)
	local moneyId = BagDefine.ITEM_MONEY
	human:incMoney(val,CommonDefine.MONEY_TYPE.ADD_USE_ITEM)
	human:sendHumanInfo()
	rewards[moneyId] = rewards[moneyId] and rewards[moneyId] + val or val
	return RET_SUCCESS_AND_CAN_CONTINUE
end

function addPhysics(human,val,clientArgList)
	local phyId = BagDefine.ITEM_PHY
	human:incPhysics(val,CommonDefine.PHY_TYPE.ADD_USE_ITEM)
	human:sendHumanInfo()
	rewards[phyId] = rewards[phyId] and rewards[phyId] + val or val
	return RET_SUCCESS_AND_CAN_CONTINUE
end

function addWineBuff(human,val,clientArgList)
	human:addWineBuff(val)
	return RET_SUCCESS_AND_CAN_CONTINUE
end

function openBox(human,val,clientArgList,cfg)
	local boxId = cfg.clientCmd[1].oBoxOpen[1]
	local keyId= cfg.clientCmd[1].oBoxOpen[2]
	local cfg = ItemConfig[boxId]
	if not cfg then
		return RET_FAIL_AND_MUST_BREAK
	end
	if BagLogic.getItemNum(human,boxId) <= 0 then
		return RET_FAIL_AND_MUST_BREAK
	end
	if BagLogic.getItemNum(human,keyId) <= 0 then
		return RET_FAIL_AND_MUST_BREAK
	end
	BagLogic.delItemByItemId(human,boxId,1,nil,CommonDefine.ITEM_TYPE.DEC_USE_ITEM)
	BagLogic.delItemByItemId(human,keyId,1,nil,CommonDefine.ITEM_TYPE.DEC_USE_ITEM)

	local randItems = val
	local tb = {}
	local sumRand = 0
	local totalRand = 10000
	for k,v in pairs(randItems) do
		tb[#tb+1] = {weight = v[3]}
		sumRand = sumRand + v[3]
	end
	if totalRand - sumRand > 0 then
		tb[#tb+1] = {weight = totalRand - sumRand}
	end
	local pos = PublicLogic.getItemByRand(tb)
	if pos and randItems[pos] then
		local addItemId = randItems[pos][1]
		local cnt = randItems[pos][2]
		BagLogic.addItem(human,addItemId,cnt,false,CommonDefine.ITEM_TYPE.ADD_USE_ITEM)
		rewards[addItemId] = rewards[addItemId] and rewards[addItemId] + cnt or cnt
	end
	return RET_FAIL_BUT_CAN_CONTINUE
end
