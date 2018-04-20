module(...,package.seeall)

local Msg = require("core.net.Msg")
local BagLogic = require("modules.bag.BagLogic")
local HeroManager = require("modules.hero.HeroManager")
local OpenLvConfig = require("config.OpenLvConfig").Config
local ItemConfig = require("config.ItemConfig").Config
local ExpConfig = require("config.ExpConfig").Config

OpenLvData = {}
-- 随机配置格式为 {randType=1,money={100,30},heroExp={300,30},charExp={400,20},[105001]={2,10},[105002]={1,10}}
-- randType 配置随机类型 1：随机出单个物品；2：随机出多个物品
-- 其他的key-value对为可能随机出现的物品  money={100,10} 其中的10表示概率为10%
-- 返回值是
-- Table
-- (
--     [105001] => 1
-- )
function randReward(r)
    local rewardList = {}
    
    --print("randvalue="..randvalue)
    if r.randType and r.randType==2 then
        for n,rr in pairs(r) do
            if n ~= 'randType' then
            	local randvalue = math.random(100)
                if rr[2] >= randvalue then
                    rewardList[n] = rr[1]
                end
            end
        end
        return rewardList
    elseif r.randType and r.randType==4 then
        for n,rr in pairs(r) do
            if n ~= 'randType' then
            	local randvalue = math.random(10000)
                if rr[2] >= randvalue then
                    rewardList[n] = rr[1]
                end
            end
        end
        return rewardList
    elseif r.randType and r.randType == 1 then
        local rand = 0
        local randvalue = math.random(100)
        for n,rr in pairs(r) do
            if n ~= 'randType' then
                rand =rand + rr[2]
                if rand >= randvalue then
                    rewardList[n] = rr[1]
                    return rewardList
                end
            end
        end
    elseif r.randType and r.randType == 3 then
    	-- type 3 和 type 1 完全一致，只是概率改成10000
        local rand = 0
        local randvalue = math.random(10000)
        for n,rr in pairs(r) do
            if n ~= 'randType' then
                rand =rand + rr[2]
                if rand >= randvalue then
                    rewardList[n] = rr[1]
                    return rewardList
                end
            end
        end
    else
    	return {}
    end
    return rewardList
end

--发奖励
--rewardList是randReward产生的table
function doReward(human,rewardList,heroes,itemType,moneyType,rmbType)
	moneyType = moneyType or itemType
	rmbType = rmbType or itemType
	if rewardList.charExp then
		human:incExp(rewardList.charExp)
	end
	for n,cnt in pairs(rewardList) do
		itemId = tonumber(n)
		if type(itemId) == 'number' then
			BagLogic.addItem(human,itemId,cnt,true,itemType)
		elseif n == 'money' then
			human:incMoney(cnt,moneyType)
		elseif n == 'rmb' then
			human:incRmb(cnt,rmbType)
		elseif n == 'tourCoin' then
			human:incTourCoin(cnt)
		elseif n == 'heroExp' and heroes then
			for _,name in ipairs(heroes) do 
				local hero = HeroManager.getHero(human,name)
				if hero then
					hero:addExp(cnt)
				end
			end
		end
	end
	-- 返回等级
	local percent = 100*human:getExp()/ExpConfig[human:getLv()].charExp
	return human:getLv(),percent
end

function getRewardDes(rewardList)
	local des = ''
	for n,cnt in pairs(rewardList) do
		itemId = tonumber(n)
		if type(itemId) == 'number' then
			local config = ItemConfig[itemId]
			if config then
				des = des .. config.name .. '*' .. cnt .. ' '
			end
		elseif n == 'money' then
			des = des .. '金币+' .. cnt .. ' '
		elseif n == 'rmb' then
			des = des .. '钻石+' .. cnt .. ' '
		elseif n == 'tourCoin' then
			des = des .. '巡回积分+' .. cnt .. ' '
		end
	end
	return des
end

--items: {{itemId,num},{itemId,num},...}
function addItemsBagOrMail(human,items,way)
	print("addItemsBagOrMail")
	Util.print_r(items)
	local mailItems = {}
	for k,v in pairs(items) do
    	local retCode = BagLogic.checkCanAddItem(human, v[1],v[2])
		if retCode then
			BagLogic.addItem(human,v[1],v[2],false,way)
		else
			table.insert(mailItems,{v[1],v[2]})
		end
	end
	BagLogic.sendBagList(human)
	if next(mailItems) then
		local MailManager = require("modules.mail.MailManager")
		MailManager.sysSendMail(human.db.account,"背包空间不足","背包空间不足",mailItems,0,0)
	end
end

--ex:tb = {[1] = {weight = 2000},[2] = {weight = 3000},[3] = {weight = 5000}}
function getItemByRand(tb)
	local total = 0
	for i = 1,#tb do
		total = total + tb[i].weight
	end
	if total <= 0 then
		return
	end
	local randvalue = math.random(1,total)
	local sum = 0
	for i = 1,#tb do
		sum = sum + tb[i].weight
		if randvalue <= sum then
			return i
		end
	end
end

function onNextDayLogic()
	print("onNextDayLogic>>>>")
end


function returnCode(human,retCode) 
	return Msg.SendMsg(PacketID.GC_RETURN_CODE,human,retCode)
end


function loadOpenLvConfig()
	for id,conf in ipairs(OpenLvConfig) do
		OpenLvData[conf.moduleName] = conf.charLv
	end
end

loadOpenLvConfig()

function isModuleOpened(human,moduleName)
	local lv = OpenLvData[moduleName]
	if lv then
		if human:getLv() >= lv then
			return true
		else
			return false
		end
	else
		return true
	end
end

function getOpenLv(moduleName)
	return OpenLvData[moduleName] or 0
end

function on1MinRecord() 
    local logTb = Log.getLogTb(LogId.ONLINE)
    logTb.online = HumanManager.countOnline(true)
	logTb:save()
end

function cycleReward(human,rewardList,cycleReward)
	local reward = {}
	for itemId,cycle in pairs(rewardList) do
		if cycleReward[itemId] == nil then
			local randNo = math.random(1,cycle)
			cycleReward[itemId] = {0,randNo}
		end
		if cycleReward[itemId][1] >= cycle then
			cycleReward[itemId][1] = 0
			local randNo = math.random(1,cycle)
			cycleReward[itemId][2] = randNo
		end

		cycleReward[itemId][1] = cycleReward[itemId][1] + 1
		if cycleReward[itemId][1] == cycleReward[itemId][2] then
			-- 命中，需要赠送奖励
			if reward[itemId] == nil then reward[itemId] = 0 end
			reward[itemId] = reward[itemId] + 1
		end
	end
	return reward
end
