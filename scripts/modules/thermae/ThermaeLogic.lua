module(...,package.seeall)

local Crontab = require("modules.public.Crontab")
local ThermaeDefine = require("config.ThermaeDefineConfig").Defined
local Msg = require("core.net.Msg")
local Define = require("modules.thermae.Define")
local HeroDefine = require("modules.hero.HeroDefine")
local CommonDefine = require("core.base.CommonDefine")
local BagLogic = require("modules.bag.BagLogic")
local MailManager = require("modules.mail.MailManager")
local MailDefine = require("modules.mail.MailDefine")

_isOpen = _isOpen or false
_timer = _timer or nil
_startTime = _startTime or 0
_data = _data or {
	--[account] = {name="",heroName="",money=0,rmb=0,item={[itemId] = cnt},time=0,dirty=false,isBathing = false}
}

function startCrontab()
	Crontab.AddEventListener(ThermaeDefine.startTimeId, startThermae)
	initConfig()
end

function initConfig()
end

function startThermae()
	if _isOpen then
		return
	end
	--[[
	local tab = {}
	local allOnline = HumanManager.getAllOnline()
	for _,human in pairs(allOnline) do
		if human:getLv() >= ThermaeDefine.level then
			table.insert(tab, human.fd)
		end
		if #tab >= Msg.MSG_USER_BROADCAST_LIMIT_COUNT then
			Msg.UserBroadCast(PacketID.GC_THERMAE_NOTIFY, tab)
			tab = {}
		end
	end
	if #tab > 0 then
		Msg.UserBroadCast(PacketID.GC_THERMAE_NOTIFY, tab)
	end
	--]]
	Msg.WorldBroadCast(PacketID.GC_THERMAE_NOTIFY,Define.ThermaeNodity.open)

	_startTime = os.time()
	if not _timer then
		_timer = Timer.new(1000, -1)
		_timer:setRunner(onRefresh)
		_timer:start()
	end
	_isOpen = true
end

function endThermae()
	if not _isOpen then
		return
	end
	if _timer ~= nil then
		_timer:stop()
		_timer = nil
	end
	_isOpen = false

	for k,v in pairs(_data) do
		local human = HumanManager.getOnline(k,v.name) or HumanManager.loadOffline(k,v.name)
		if human then
			local hero = human:getHero(v.heroName)
			if hero then
				endBath(human,hero,true)
			end
		end
	end
	_data = {}
	Msg.WorldBroadCast(PacketID.GC_THERMAE_NOTIFY,Define.ThermaeNodity.close)
end

function getHuman(account,name)
	return HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
end

function addMoney(human,data)
	if data.time % ThermaeDefine.money[1] == 0 then
		data.money = data.money + ThermaeDefine.money[2]
		data.dirty = true
		human:incMoney(ThermaeDefine.money[2],CommonDefine.MONEY_TYPE.ADD_THERMAE)
		if human.fd then
			human:sendHumanInfo()
		end
	end
end

function addRmb(human,data)
	if data.time % ThermaeDefine.rmb[1] == 0 then
		data.rmb = data.rmb + ThermaeDefine.rmb[2]
		data.dirty = true
		human:incRmb(ThermaeDefine.rmb[2],CommonDefine.RMB_TYPE.ADD_THERMAE)
		if human.fd then
			human:sendHumanInfo()
		end
	end
end

function addItem(human,data)
	if data.time % ThermaeDefine.item[1] == 0 then
		local r = math.random(0,9999)
		for k = 2,#ThermaeDefine.item do
			local cf = ThermaeDefine.item[k]
			if r < cf[1] then
				data.item[cf[2]] = data.item[cf[2]] or 0
				data.item[cf[2]] = data.item[cf[2]] + cf[3]
				data.dirty = true
				BagLogic.addItem(human,cf[2],cf[3],true,CommonDefine.ITEM_TYPE.ADD_THERMAE)
				break
			else
				r = r - cf[1]
			end
		end
	end
end

function onRefresh()
	for k,v in pairs(_data) do
		if v.isBathing then
			v.time = v.time + 1
			local human = getHuman(k,v.name)
			addMoney(human,v)
			addRmb(human,v)
			addItem(human,v)
			if v.dirty and human.fd then
				sendData(human)
				v.dirty = false
			end
		end
	end
	if os.time() - _startTime >= ThermaeDefine.lastTime and _isOpen then
		endThermae()
	end
end

function getBathingHero(human)
	local heros = human:getAllHeroes()
	for k,v in pairs(heros) do
		if v:getStatus() == HeroDefine.STATUS_THERMAE then
			return v
		end
	end
end

function getBathingData(human)
	local data = {}
	for k,v in pairs(_data) do
		if k ~= human:getAccount() then
			table.insert(data,{heroName = v.herName})
		end
		if #data >= 20 then
			break
		end
	end
	return data
end

function isOpen()
	return _isOpen
end
---------------------------------------------------

function onHumanLogin(hm,human)
	sendData(human)
	if not _isOpen then
		local hero = getBathingHero(human)
		if hero then
			hero:setStatus(HeroDefine.STATUS_NORMAL)
			hero:sendHeroAttr()
		end
	end
end

function sendData(human)
	local data = _data[human:getAccount()] or {money=0,rmb=0,item={}}
	local itemData = {}
	for k,v in pairs(data.item) do
		table.insert(itemData,{itemId = k,cnt = v})
	end
	Msg.SendMsg(PacketID.GC_THERMAE_QUERY,human,_isOpen and 1 or 0,ThermaeDefine.lastTime - os.time() + _startTime,getBathingData(human),data.money,data.rmb,itemData)
end

function bath(human,hero)
	hero:setStatus(HeroDefine.STATUS_THERMAE)
	hero:sendHeroAttr()
	local account = human:getAccount()
	_data[account] = _data[account] or {name = human:getName(),heroName=hero:getName(),money = 0,rmb=0,item={},time=0,dirty=false,isBathing = true}
	_data[account].isBathing = true
	HumanManager:dispatchEvent(HumanManager.Event_Spa,{human=human,objNum = 1})
end

function endBath(human,hero,sendMail)
	hero:setStatus(HeroDefine.STATUS_NORMAL)
	hero:sendHeroAttr()
	local data = _data[human:getAccount()]
	if not data then
		return
	end
	data.isBathing = false
	--_data[human:getAccount()] = nil
	if sendMail then
		local title = "温泉提示"

		local needSend = (data.rmb > 0 or data.money > 0 or next(data.item))
		local itemContent = ""
		for itemId,cnt in pairs(data.item) do
			itemContent = itemContent .. string.format(",%s*%d",BagLogic.getItemName(itemId),cnt)
		end
		--local content = string.format("	亲爱的队长：\n您在温泉打盹到打烊时间啦，在此次活动中您共获得金币*%d，钻石*%d%s。\n（奖励在温泉进行中时已自动发送到背包哦^-^)",data.money,data.rmb,itemContent)
		--local content = string.format("亲爱的队长：\n	您在温泉打盹到打烊时间啦，在本次活动中，您共获得：金币*%d，钻石*%d%s。\n（奖励在温泉进行中时已自动发送到背包哦^-^)",data.money,data.rmb,itemContent)
		local content = string.format("亲爱的队长：\n　　\t您在本次温泉活动中，获得的奖励：金币*%d，钻石*%d%s等，已经自动发送到您的账号中",data.money,data.rmb,itemContent)
		if needSend then
			MailManager.sysSendMail(human:getAccount(),title,content)
		end
	end

	--[[
	local dirty = false
	if data.money > 0 then
		human:incMoney(data.money,CommonDefine.MONEY_TYPE.ADD_THERMAE)
		dirty = true
	end

	if data.rmb > 0 then
		human:incRmb(data.rmb,CommonDefine.RMB_TYPE.ADD_THERMAE)
		dirty = true
	end

	if dirty and human.fd then
		human:sendHumanInfo()
	end
	
	dirty = false
	for itemId,cnt in pairs(data.item) do
		BagLogic.addItem(human,itemId,cnt,false,CommonDefine.ITEM_TYPE.ADD_THERMAE)
		dirty = true
	end
	if dirty and human.fd then
		BagLogic.sendBagList(human,true)
	end
	--]]
end

