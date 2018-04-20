module("ObjHuman", package.seeall)
setmetatable(ObjHuman, {__index = Object}) 
local NewOpenDB = require("modules.newopen.NewOpenDB")
local ExpConfig = require("config.ExpConfig").Config
local RechargeDB = require("modules.recharge.RechargeDB")

TYPE_HUMAN = "human"

local ObjectManager = require("core.managers.ObjectManager")
local HeroManager = require("modules.hero.HeroManager")
local BaseMath = require("modules.public.BaseMath")

local Msg = require("core.net.Msg")
local Json = require("core.utils.Json")
local Util = require("core.utils.Util")
local PacketID = require("PacketID")
local CommonDefine = require("core.base.CommonDefine")

local CharDB = require("modules.character.CharDB")
local Character = require("modules.character.Character")
local CharacterDefine = require("modules.character.CharacterDefine")


local BagLogic = require("modules.bag.BagLogic")
local Chapter = require("modules.chapter.Chapter")
local Treasure = require("modules.treasure.Treasure")
local GuildManager = require("modules.guild.GuildManager")
local ArenaLogic = require("modules.arena.ArenaLogic")
local Define = require("core.base.CommonDefine")
local WineDefine = require("modules.guild.wine.WineDefine")
local WineItemConfig = require("config.WineItemConfig").Config
local WineLogic = require("modules.guild.wine.WineLogic")
local ShopLogic = require("modules.shop.ShopLogic")
local RechargeLogic = require("modules.recharge.RechargeLogic")

function new(fd, sn)
    local human = {
		id = ObjectManager.newId(),
		otype = TYPE_HUMAN,
		typeId = ObjectManager.OBJ_TYPE_HUMAN,
		fd = fd, 
		sn = sn,
		timerList = {},
		token = nil,		--登录序列
		reloginTimer = nil,

		--人物基本消息
		infoMsg = {},
		--聊天系统
		lastChat = {},	
		--世界boss
		worldBossCD = 0,
		--背包
		bagDirty = {},
		bagSeq = {},
		--引导
		finishGuideMap = {},

		info = {},
	}

	setmetatable(human, {__index = ObjHuman})
	ObjectManager.add(human)
    human.db = CharDB.new()
	human:init()


	-- by tanjie  hero模块注册几个方法到human，方便使用
	human.getHero = HeroManager.getHero
	human.getAllHeroes = HeroManager.getAllHeroes
	human.addHero = HeroManager.addHero
	human.addHeroNoSave = HeroManager.addHeroNoSave
	human.delHero = HeroManager.delHero
	human.getHeroExpedition = HeroManager.getHeroExpedition
	HeroManager.init(human)
	Treasure.initHuman(human)

    return human 
end

function init(self)
end

function sendHumanInfo(self)
	local msg = {}
	msg.name = self.name
	msg.timeServer = os.time()
	msg.createServer = Config.newServerTime 
	msg.createDate = self.db.createDate
	msg.bodyId = self.db.bodyId
	msg.lv = self.db.lv
	msg.exp = self.db.exp
	msg.money = self.db.money
	msg.rmb = self.db.rmb
	msg.energy = self.db.energy
	msg.physics = self.db.physics
	msg.star = self.db.star
	msg.fame = self.db.fame
	msg.powerCoin = self.db.powerCoin
	msg.tourCoin = self.db.tourCoin
	msg.flowerCount = self.db.flowerCount
	msg.guildCoin = self.db.guildCoin
	msg.exchangeCoin = self.db.exchangeCoin
	msg.peakCoin = self.db.peakCoin
	msg.guildId = self.db.guildId
	msg.guildCnt = self.db.guildCnt
	msg.vipLv = self.db.vipLv
	--msg.settings = self.db.settings
	msg.recharge = self.db.recharge * 100
	msg.renameCnt = self.db.renameCnt
	msg.skillRage = self.db.skillRage 
	msg.skillAssist = self.db.skillAssist 
	local sendMsg = {}
	if next(self.infoMsg) then
		for k,v in pairs(msg) do
			if not self.infoMsg[k] or self.infoMsg[k] ~= v then
				sendMsg[k] = v
			end
		end
	else
		sendMsg = msg
	end
	self.infoMsg = msg
	if next(sendMsg) then
    	Msg.SendMsg(PacketID.GC_HUMAN_INFO,self,sendMsg)
	end
end

function sendSettings(self)
	local settings = self.db.settings
	Msg.SendMsg(PacketID.GC_SETTINGS,self,settings.music,settings.effect,settings.pushSettings)
end

function resetMeta(self) 
	setmetatable(self, {__index = ObjHuman})
    self.db:resetMeta();
end

function load(self, account )
    local ret = self.db:loadByAccount(account)
	HumanManager:dispatchEvent(HumanManager.Event_HumanDBLoad,self)
    return ret
end

function addTimer(self,timer)
	self.timerList[#self.timerList+1] = timer 
end

function stopTimer(self)
	for _,timer in pairs(self.timerList) do
		--@todo 设置了maxtimes的timer可能已停止
		--maxtimes跑完前玩家已释放
		timer:stop()
	end
	self:stopPhysicsTimer()
	self:stopReloginTimer()
end

function disconnect(self, reason )
	print("ObjHuman:disconnect")
	--服务端不主动断开
    --Character.sendGCDisconnect(self)  
	Msg.SendMsg(PacketID.GC_KICK,self,reason)
	self:release(reason)
end

function exit(self)
	self:disconnect(Define.DISCONNECT_REASON_SERVER_CLOSE)
end

function startReloginTimer(self)
	self:stopReloginTimer()
	self.reloginTimer = Timer.new(CharacterDefine.TIMER_RE_LOGIN_TIMEOUT,1)
	self.reloginTimer:setRunner(onCheckReLogin,self)
	self.reloginTimer:start()
end

function stopReloginTimer(self)
	if self.reloginTimer then
		self.reloginTimer:stop()
		self.reloginTimer = nil
	end
end

function onDisconnect(self,reason)
	--重新登录
	--断线重连
	--玩家主动断开,还是会保持？
	--c++层已释放fd
	ObjectManager.removeFd(self)
	HumanManager:dispatchEvent(HumanManager.Event_HumanDisconnect, self)
	if true or reason == CommonDefine.DISCONNECT_REASON_TIMEOUT then
		self:startReloginTimer()
	else
		--self:release(reason)
	end
end

function onCheckReLogin(self)
	--有效时间内重新连上
	if not self.fd then
		self:release()
	end
end

function release(self, reason)
	self:stopTimer()
	ObjectManager.remove(self)
	HumanManager.delOnline(self.db.account)
	
	GuildManager.onLogout(self)
	ArenaLogic.onLogout(self)
    self.db.lastLogout = os.time()
    local aliveTime = self.db.lastLogout - self:getLoginTime()
    self.db.olDayTime = self.db.olDayTime+aliveTime
    self.db.olTime = self.db.olTime+aliveTime
    self.db.isOnline = 0
    self:save()
   	--后台日志
    local logTb = Log.getLogTb(LogId.LOGOUT)
	logTb.channelId = self:getChannelId()
    logTb.name = self:getName()
    logTb.account = self:getAccount()
    logTb.pAccount = self:getPAccount()
    logTb.level = self:getLv() or 1
    logTb.reason = reason or 0
    logTb.loginTime = self.db.lastLogin
    logTb.dayTime = self.db.olDayTime
    logTb.aliveTime = aliveTime 
    logTb.recharge = self.db.recharge
    logTb.leftRmb = self:getRmb()
    logTb.leftMoney = self:getMoney()
	logTb:save()
end

function save(self,isSync)
	self.db.lastSaveTime = os.time()
	local ret = self.db:save(isSync)
    print("ObjHuman save ok:", self:getAccount())
    return ret
end

--by Arokenda
function getBag(self)
	return self.db.bag
end

function getExpedition(self)
	return self.db.expedition
end

function getExpeditionShop(self)
	return self.db.expeditionShop
end

function getAccumulateDays(self)
    return self.db.accumulateDays
end

function incAccumulateDays(self)
    self.db.accumulateDays = self.db.accumulateDays + 1
end

function getLoginTime(self)
    return self.db.lastLogin
end

function setSvrName(self,svrName)
    self.db.svrName = svrName
end

function getSvrName(self)
    return self.db.svrName
end

function setAccount(self,account)
    self.db.account = account
end

function getAccount(self)
	return self.db.account 
end

function getPAccount(self)
	return self.db.pAccount 
end


function setName(self,name)
	self.db.name = name
end

function getName(self)
	return self.db.name
end

function getToken(self,token)
	return self.token
end

function setToken(self,token)
	self.token = token
end

function addUser(self)
    return self.db:add()
end

function getLastChat(self, chatType)
    return self.lastChat[chatType] or 0
end

function setLastChat(self, chatType)
    self.lastChat[chatType] = os.time()
end

function getSex(self)
	return self.db.sex
end

function setSex(self,val)
	self.db.sex = val
end

function getExp(self)
	return self.db.exp
end
function incExp(self,val)
	assert(val >= 0,"error incExp======>>>" .. val)
	self.db.exp = self.db.exp + val
	self.db.expSum = self.db.expSum + val
	self:checkLvUp()
	HumanManager:dispatchEvent(HumanManager.Event_HumanExpChange,{human=self})
end

function getExpSum(self)
	return self.db.expSum
end

function incRecharge(self, val)
	self.db.recharge = self.db.recharge + val
	local beginTime = RechargeLogic.beginTime()
	local endTime = RechargeLogic.endTime()
	if os.time() > beginTime and os.time() < endTime then
		RechargeDB.nextAct(self.db.rechargeDB,RechargeLogic.getGenId())
		RechargeDB.addNum(self.db.rechargeDB,val)
	end
	for i = 1,7 do
		local num = NewOpenDB.getStatus(self.db.newopenDB,i,"rechargeNum")
		if num then
			NewOpenDB.setStatus(self.db.newopenDB,i,"rechargeNum",num+val)
		end
	end
end

function getRecharge(self)
	return self.db.recharge
end

function incTourCoin(self, val)
	self.db.tourCoin = self.db.tourCoin + val
end

function decTourCoin(self, val)
	self.db.tourCoin = self.db.tourCoin - val
end

function getTourCoin(self)
	return self.db.tourCoin
end

function incPeakCoin(self, val)
	self.db.peakCoin = self.db.peakCoin + val
end

function decPeakCoin(self, val)
	self.db.peakCoin = self.db.peakCoin - val
end

function getPeakCoin(self)
	return self.db.peakCoin
end

function checkLvUp(self)
	local preLv = self:getLv()
	if preLv == CharacterDefine.MAX_LV then
		return 
	end
	local exp = self:getExp()
	local nextExp = BaseMath.getHumanLvUpExp(preLv + 1)
	if not nextExp then
		return
	end
	local nextLv = preLv
	local addPhysics = 0
	while nextExp <= exp do
		nextLv = nextLv + 1
		exp = exp - nextExp
		nextExp = BaseMath.getHumanLvUpExp(nextLv)
		if not nextExp then
			nextLv = nextLv - 1
			break
		else
			addPhysics = addPhysics + ExpConfig[nextLv].addPhysics
		end
	end
	self.db.exp = exp 
	if preLv ~= nextLv then
		--升级了
		self:incPhysics(addPhysics,CommonDefine.PHY_TYPE.ADD_HUMAN_UP)
		self.db.lv = nextLv
		HumanManager:dispatchEvent(HumanManager.Event_HumanLvUp,{human=self,objNum=nextLv})
		self:sendHumanInfo()
		self:checkPhysics()
	end
	--
	local logTb = Log.getLogTb(LogId.LV_UP)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.lastLevel = preLv
	logTb.level = self:getLv()
	logTb:save()
end

function getBodyId(self)
	return self.db.bodyId
end

function getLv(self)
	return self.db.lv
end

function getMoney(self)
	return self.db.money
end

function getMoneySum(self)
	return self.db.moneySum
end

function incMoney(self,val,way)
	assert(val >= 0,"error incMoney======>>>" .. val)
	assert(way,"error need way!!!!")
	self.db.money = self.db.money + val
	self.db.moneySum = self.db.moneySum + val
	HumanManager:dispatchEvent(HumanManager.Event_HumanMoneySumChange,{human=self})
	--
	local logTb = Log.getLogTb(LogId.INC_MONEY)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.money = val 
	logTb.leftMoney = self.db.money
	logTb.way = way or CommonDefine.MONEY_TYPE.ADD
	logTb:save()
end

function decMoney(self,val,way)
	assert(val >= 0,"error decMoney======>>>" .. val)
	assert(self.db.money >= val,"error decMoney  < val")
	assert(way,"error need way!!!!")
	self.db.money = self.db.money - val
	--
	local logTb = Log.getLogTb(LogId.DEC_MONEY)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.money = val 
	logTb.leftMoney = self.db.money
	logTb.way = way or CommonDefine.MONEY_TYPE.DEC
	logTb:save()
end

function getRmb(self)
	return self.db.rmb
end

function incRmb(self,val,way)
	assert(val >= 0,"error incMoney======>>>" .. val)
	assert(way,"error need way!!!!")
	self.db.rmb = self.db.rmb + val
	--
	local logTb = Log.getLogTb(LogId.INC_RMB)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.rmb = val 
	logTb.leftRmb = self.db.rmb
	logTb.way = way or CommonDefine.RMB_TYPE.ADD
	logTb:save()
end

function decRmb(self,val,note,way)
	assert(val >= 0,"error decRmb======>>>" .. val)
	assert(self.db.rmb >= val,"error decRmb  < val")
	assert(way,"error need way!!!!")
	self.db.rmb = self.db.rmb - val
	--
	local logTb = Log.getLogTb(LogId.DEC_RMB)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.rmb = val 
	logTb.leftRmb = self.db.rmb
	logTb.way = way or CommonDefine.RMB_TYPE.DEC
	logTb.note = note or ""
	logTb:save()
end

--精力
function getEnergy(self)
	return self.db.energy
end

function incEnergy(self,val)
	assert(val >= 0,"error ======>>>" .. val)
	self.db.energy = self.db.energy + val
end

function decEnergy(self,val)
	assert(val >= 0,"error ======>>>" .. val)
	assert(self.db.energy >= val,"error   < val")
	self.db.energy = self.db.energy - val
	HumanManager:dispatchEvent(HumanManager.Event_DecEnergy,{obj = self,val = val,ctype="enery"})
end

--体力
function getPhysics(self)
	return self.db.physics
end

function incPhysics(self,val,way)
	assert(val >= 0,"error incPhysics======>>>" .. val)
	assert(way,"error need way!!!!")
	self.db.physics = self.db.physics + val
	self:checkPhysics()
	--
	local logTb = Log.getLogTb(LogId.INC_PHY)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.phy = val
	logTb.leftPhy = self.db.physics
	logTb.way = way or CommonDefine.PHY_TYPE.ADD
	logTb:save()
end

function decPhysics(self,val,way)
	assert(val >= 0,"error decPhysics======>>>" .. val)
	assert(self.db.physics >= val,"error decPhysics  < val")
	assert(way,"error need way!!!!")
	self.db.physics = self.db.physics - val
	HumanManager:dispatchEvent(HumanManager.Event_DecPhysics,{obj = self,val = val})
	self:checkPhysics()
	--
	local logTb = Log.getLogTb(LogId.DEC_PHY)
	logTb.channelId = self:getChannelId()
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.phy = val
	logTb.leftPhy = self.db.physics
	logTb.way = way or CommonDefine.PHY_TYPE.DEC
	logTb:save()
end

function addOfflinePhysics(self)
	local offlinePhy = math.max(0,math.floor((os.time()-self.db.lastLogout)/(CharacterDefine.TIMER_ADD_PHYSICS/1000)))
	local phy = math.min(offlinePhy, math.max(0,ExpConfig[self.db.lv].physics - self:getPhysics()))
	self:incPhysics(phy,CommonDefine.PHY_TYPE.ADD_OFFLINE)
end

function checkPhysics(self)
	if ExpConfig[self:getLv()].physics > self:getPhysics() then
		if not self.physicsTimer then
			--定时加体力
			local physicsTimer = Timer.new(CharacterDefine.TIMER_ADD_PHYSICS,1)
			physicsTimer:setRunner(onAddPhysics,self)
			physicsTimer:start()
			self:stopPhysicsTimer()
			self.physicsTimer = physicsTimer
		end
	else
		--体力满，停掉定时器
		self:stopPhysicsTimer()
	end
end

function stopPhysicsTimer(self)
	if self.physicsTimer then
		self.physicsTimer:stop()
		self.physicsTimer = nil
	end
end

function onAddPhysics(self)
	if ExpConfig[self:getLv()].physics > self:getPhysics() then
		self:incPhysics(1,CommonDefine.PHY_TYPE.ADD_TIMER)
    	Msg.SendMsg(PacketID.GC_ADD_PHYSICS,self,self:getPhysics(),os.time())
		self:stopPhysicsTimer()
		self:checkPhysics()
	end
end


--星魂
function getStar(self)
	return self.db.star
end

function incStar(self,val)
	assert(val >= 0,"error ======>>>" .. val)
	self.db.star = self.db.star + val
end

function decStar(self,val)
	assert(val >= 0,"error ======>>>" .. val)
	assert(self.db.star >= val,"error   < val")
	self.db.star = self.db.star - val
end

--声望
function getFame(self)
	return self.db.fame
end

function incFame(self,val)
	assert(val >= 0,"error incfame======>>>" .. val)
	self.db.fame= self.db.fame+ val
end

function decFame(self,val)
	assert(val >= 0,"error decfame======>>>" .. val)
	assert(self.db.fame >= val,"error decfame < val")
	self.db.fame = self.db.fame - val
end

--力量兑换币
function getPowerCoin(self)
	return self.db.powerCoin
end

function incPowerCoin(self,val)
	assert(val >= 0,"error incpowerCoin======>>>" .. val)
	self.db.powerCoin= self.db.powerCoin + val
end

function decPowerCoin(self,val)
	assert(val >= 0,"error decpowerCoin======>>>" .. val)
	assert(self.db.powerCoin>= val,"error decpowerCoin < val")
	self.db.powerCoin = self.db.powerCoin - val
end

--兑换积分
function getExchangeCoin(self)
	return self.db.exchangeCoin
end

function incExchangeCoin(self,val)
	assert(val >= 0,"error incExchangeCoin======>>>" .. val)
	self.db.exchangeCoin = self.db.exchangeCoin + val
end

function decExchangeCoin(self,val)
	assert(val >= 0,"error decExchangeCoin ======>>>" .. val)
	assert(self.db.exchangeCoin >= val,"error decExchangeCoin < val")
	self.db.exchangeCoin = self.db.exchangeCoin - val
end

--公会声望
function getGuildCoin(self)
	return self.db.guildCoin
end

function incGuildCoin(self,val)
	assert(val >= 0,"error incGuildCoin======>>>" .. val)
	self.db.guildCoin = self.db.guildCoin + val
end

function decGuildCoin(self,val)
	assert(val >= 0,"error decpowerCoin======>>>" .. val)
	assert(self.db.guildCoin>= val,"error decGuildCoin< val")
	self.db.guildCoin = self.db.guildCoin - val
end

function getArena(self)
	return self.db.arena
end

function getAchieve(self)
	return self.db.achieve
end

function getTeamFightVal(self,fightList)
	local fightVal = 0
	--不算援助
	for i=1,#fightList-1 do
		local v = fightList[i]
    	local hero = self:getHero(v.name)
		if hero then
			fightVal = fightVal + hero:getFight()
		end
	end
	return fightVal 
end

function getGuildId(self)
	return self.db.guildId
end

function setGuildId(self,id)
	self.db.guildId = id	
end

function getGuildCD(self)
	return self.db.guildCD
end

function setGuildCD(self)
	self.db.guildCD = os.time()
end

function getVip(self)
	return self.db.vip
end

function getPeak(self)
	return self.db.peak
end

function getFlower(self)
	return self.db.flower
end

function startWineBuff(self)
	self.info.wineBuff = {}
	DB.dbSetMetatable(self.info.wineBuff)
	cleanWineBuff(self)
	for k,v in pairs(self.db.wine.buff) do
		local lastTime = WineItemConfig[tonumber(k)].last
		local leftTime = lastTime - (os.time() - v.start)
		if leftTime > 0 then
			local timer = Timer.new(leftTime*1000,1)
			timer:setRunner(delWineBuff,self)
			timer:start()
			timer.buffid = k
			self.info.wineBuff[k] = {timer = timer}
		end
	end
end

function cleanWineBuff(self)
	local clean = {}
	for k,v in pairs(self.db.wine.buff) do
		local lastTime = WineItemConfig[tonumber(k)].last
		if os.time() - v.start >= lastTime then
			table.insert(clean,k)
		end
	end
	for i = 1,#clean do
		local id = clean[i]
		self.db.wine.buff[id] = nil
	end
end

function delWineBuff(self,timer)
	local id = timer.buffid
	self.db.wine.buff[id] = nil
	self.info.wineBuff[id] = nil
	WineLogic.wineBuffQuery(self)
	local heroList = HeroManager.getAllHeroes(self)
	for _,hero in pairs(heroList) do
		hero:resetDyAttr()
	end
	HeroManager.sendAllHeroesAttr(self)
end

function addWineBuff(self,id)
	--if self.info.wineBuff[id] then
	--	local timer = self.info.wineBuff[id].timer
	--	timer:stop()
	--end
	--同时只能有一个buff
	for k,v in pairs(self.info.wineBuff) do
		local timer = v.timer
		timer:stop()
	end
	self.info.wineBuff = {}
	self.db.wine.buff = {}
	DB.dbSetMetatable(self.db.wine.buff)
	DB.dbSetMetatable(self.info.wineBuff)
	--
	local lastTime = WineItemConfig[id].last
	local timer = Timer.new(lastTime*1000,1)
	self.db.wine.buff[id] = {start = os.time()}
	timer:setRunner(delWineBuff,self)
	timer:start()
	timer.buffid = id
	self.info.wineBuff[id] = {timer = timer}
	WineLogic.wineBuffQuery(self)
	local heroList = HeroManager.getAllHeroes(self)
	for _,hero in pairs(heroList) do
		hero:resetDyAttr()
	end
	HeroManager.sendAllHeroesAttr(self)
end

function incSkillRage(self,val)
	assert(val >= 0,"error incSkillRage======>>>" .. val)
	--assert(way,"error need way!!!!")
	self.db.skillRage = self.db.skillRage + val
	--[[
	local logTb = Log.getLogTb(LogId.INC_MONEY)
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.money = val 
	logTb.leftMoney = self.db.money
	logTb.way = way or CommonDefine.MONEY_TYPE.ADD
	logTb:save()
	--]]
end
function decSkillRage(self,val,way)
	assert(val >= 0,"error dec======>>>" .. val)
	assert(self.db.skillRage >= val,"error dec  < val")
	--assert(way,"error need way!!!!")
	self.db.skillRage = self.db.skillRage - val
	--[[
	local logTb = Log.getLogTb(LogId.DEC_MONEY)
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.money = val 
	logTb.leftMoney = self.db.money
	logTb.way = way or CommonDefine.MONEY_TYPE.DEC
	logTb:save()
	--]]
end

function incSkillAssist(self,val)
	assert(val >= 0,"error incSkillRage======>>>" .. val)
	--assert(way,"error need way!!!!")
	self.db.skillAssist = self.db.skillAssist + val
	--[[
	local logTb = Log.getLogTb(LogId.INC_MONEY)
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.money = val 
	logTb.leftMoney = self.db.money
	logTb.way = way or CommonDefine.MONEY_TYPE.ADD
	logTb:save()
	--]]
end
function decSkillAssist(self,val,way)
	assert(val >= 0,"error dec======>>>" .. val)
	assert(self.db.skillAssist >= val,"error dec  < val")
	--assert(way,"error need way!!!!")
	self.db.skillAssist = self.db.skillAssist - val
	--[[
	local logTb = Log.getLogTb(LogId.DEC_MONEY)
	logTb.account = self:getAccount()
	logTb.name = self:getName()
	logTb.pAccount = self:getPAccount()
	logTb.money = val 
	logTb.leftMoney = self.db.money
	logTb.way = way or CommonDefine.MONEY_TYPE.DEC
	logTb:save()
	--]]
end

function setChannelId(self,channelId)
	self.db.channelId = channelId
end
function getChannelId(self,channelId)
	return self.db.channelId
end

function getGuildName(self)
	local guildId = self:getGuildId()
	return GuildManager.getGuildNameByGuildId(guildId)
end

return ObjHuman
