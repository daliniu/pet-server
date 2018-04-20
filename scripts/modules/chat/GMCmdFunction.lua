module(...,package.seeall) 
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local ChatDefine = require("modules.chat.ChatDefine")

local CommonDefine = require("core.base.CommonDefine")

--local Bag = require("modules.bag.Bag")
--local BagDefine = require("modules.bag.BagDefine")
--local EquipmentConfig = require("config.EquipmentConfig")
--local ItemConfig = require("config.ItemConfig")
--local Pet = require("modules.pet.Pet")
--local PetConfig = require("config.PetConfig")
local Arena = require("modules.arena.Arena")
--local Copy = require("modules.copy.Copy")
local ChatDefine = require("modules.chat.ChatDefine")
local Character = require("modules.character.Character")
local Chapter = require("modules.chapter.Chapter")
local HeroManager = require("modules.hero.HeroManager")
local HeroDefine = require("modules.hero.HeroDefine")
local BagLogic = require("modules.bag.BagLogic")
local ItemConfig = require("config.ItemConfig").Config
local Treasure = require("modules.treasure.Treasure")
local LevelConfig = require("config.LevelConfig").Config
local PublicLogic = require("modules.public.PublicLogic")
local VipLogic = require("modules.vip.VipLogic")
local BossLogic = require("modules.guild.boss.BossLogic")
--[[
-- GM用法
-- gm_funcname=v1,v2,...
--]]
--
--
--
--
local helpMsg =
[[
help: GM命令帮助信息
ol: 在线玩家查询 v1=玩家名,空则返回所有玩家
gift:超级大礼包
money: 加钱 v1=数量
decMoney: 减钱 v1=数量
exp: 加经验 v1=数量
decExp: 减经验 v1=数量
setLv:战队等级=等级数字
addNum:货币等相关=数量,种类 (1:银币,2:金币,3:体力,4:精力,5:声望,6:力量,7:巡回币,8：技能点,9兑换币)
resetTrial:重置试炼
openChapter:开启(true)/关闭(false) 所有的关卡 
addItem:加道具=道具id,数量
clearBag:清理背包
resetArenaNum:重置当天竞技场的挑战次数
resetArenaCD:重置竞技场的挑战冷却时间
addHero:增加英雄 v1=英雄英文名
setHeroLv:设置英雄等级 v1=英雄英文名 v2=等级
setHeroQuality:设置英雄品阶 v1=英雄英文名 v2=品阶
startBoss:开启boss gm_startBoss=20,05,10(时,分,秒)
endBoss:结束boss
guildBoss:开启公会boss,1:开启2:结束
startThermae:开启温泉
endThermae:结束温泉
startCrazy:开启疯狂之源
endCrazy:结束疯狂之源
guildActive:加帮会活跃度 v1=数量
reset:重置（1:闯关，2大蛇）
setTreasureCnt:cnt(设置宝藏区域数量)
passLevel:自动通关=难度(1,2,3),开始关卡id,结束关卡id
arenaReward:竞技场奖励
kick:让自己掉线
resetExpedition:重置巡回赛重置次数
setVipLv:设置vip等级
startPeak:开启巅峰竞技场 gm_startPeak=20,05,10(时,分,秒)
resetGuildCD:清公会申请CD
addReset:增加重置次数99
]]

function help(human)
	send(human,helpMsg)
end

function send(human,content)
	content = content or "GM OK!"
	Msg.SendMsg(PacketID.GC_CHAT,human,CommonDefine.OK,ChatDefine.TYPE_SYSTEM,human:getName(),human:getAccount(),content)
end

function ol(human,name)
	local str = ""
	local n = 0
	local d = function(human) 
		return string.format("ac:%s  name:%s\n",human:getAccount(),human:getName())
	end
	if name then
		n = HumanManager.countOnline()
		local human = HumanManager.onlineName[name]
		if human then
			str = str .. d(human) 
		end
	else
		for _,human in pairs(HumanManager.online) do
			str = str .. d(human) 
			n = n + 1
		end
	end
	send(human,"total: " .. n .. "\n" .. str)
end

function gift(human)
	local n = 999999
    human:incMoney(n,CommonDefine.MONEY_TYPE.ADD_GM)
    human:incRmb(n,CommonDefine.RMB_TYPE.ADD_GM)
    human:incTourCoin(n)
    human:incFame(n)
    human:incPhysics(n,CommonDefine.PHY_TYPE.ADD_GM)
    human:incPowerCoin(n)
    human:incRecharge(n)
	for itemId,v in pairs(ItemConfig) do
		BagLogic.addItem(human,itemId,999,false,CommonDefine.ITEM_TYPE.ADD_GM)
	end
	BagLogic.sendBagList(human)
	human:sendHumanInfo()
	send(human,"enjoy!!")
end

function setMoney(human,money,rmb)
	human.db.money = tonumber(money) 
	human.db.rmb = tonumber(rmb) or 0
	human:sendHumanInfo()
	send(human,"set money===" .. money)
end

function money(human,money)
    local m = tonumber(money)
    human:incMoney(m,CommonDefine.MONEY_TYPE.ADD_GM)
	human:sendHumanInfo()
	send(human,"add money===" .. money)
end

function rmb(human,val)
    local m = tonumber(val)
    human:incRmb(m,CommonDefine.MONEY_TYPE.ADD_GM)
	human:sendHumanInfo()
	send(human,"add rmb===" .. val)
end

function decMoney(human,money)
    local m = tonumber(money)
    human:decMoney(m,CommonDefine.MONEY_TYPE.DEC_GM)
	human:sendHumanInfo()
	send(human,"dec money===" .. money)
end

function exp(human,exp)
    local e = tonumber(exp)
    human:incExp(e)
	human:sendHumanInfo()
	send(human,"add exp===" .. exp)
end

function decExp(human,exp)
    local e = tonumber(exp)
    human:decExp(e,9)
    Character.sendGCHumanInfo(human)
    send(human,"exp decreased by "..e.." to "..human:getExp())
end

function setLv(human,lv)
	lv = tonumber(lv)
	if lv <= 1 then lv = 1 end
	human.db.lv = lv
	HumanManager:dispatchEvent(HumanManager.Event_HumanLvUp,{human=human,objNum=lv})
	human:sendHumanInfo()
	send(human,"set lv===" .. lv)
end

function addNum(human,num,ctype)
	num = tonumber(num)
	ctype = tonumber(ctype)
	if ctype == 1 then
		human:incMoney(num,CommonDefine.MONEY_TYPE.ADD_GM)
	elseif ctype == 2 then
		human:incRmb(num,CommonDefine.RMB_TYPE.ADD_GM)
	elseif ctype == 3 then
		human:incPhysics(num,CommonDefine.PHY_TYPE.ADD_GM)
	elseif ctype == 4 then
		human:incEnergy(num)
	elseif ctype == 5 then
		human:incFame(num)
	elseif ctype == 6 then
		human:incPowerCoin(num)
	elseif ctype == 7 then
		human:incTourCoin(num)
	elseif ctype == 8 then
		human:incSkillRage(num)
		human:incSkillAssist(num)
	elseif ctype == 9 then
		human:incExchangeCoin(num)
	end
	send(human,"add num===" .. num)
	human:sendHumanInfo()
end

function resetTrial(human)
	local db = human.db.trial 
	db.resetTimes = 0
	db.levelList = {}
	local Logic = require("modules.trial.TrialLogic")
	Logic.sendLevelList(human)
	send(human)
end

function openChapter(human,debugFlag)
	if string.lower(debugFlag) == 'true' then
		Chapter.sendChapterDebugFlag(human,true)
		send(human,'chapter debugflag opened')
	else
		Chapter.sendChapterDebugFlag(human,false)
		send(human,'chapter debugflag closed')
	end
end

function addItem(human,itemId,num)
	itemId = tonumber(itemId)
	num = tonumber(num)
	local BagLogic = require("modules.bag.BagLogic")
	local ret = BagLogic.addItem(human,itemId,num or 1,true,CommonDefine.ITEM_TYPE.ADD_GM)
	send(human,"additem===" .. itemId .. ",num=" .. (num or 1))
end



function clearBag(human)
	local Grid = require("modules.bag.Grid")
	local BagLogic = require("modules.bag.BagLogic")
	--for i = 1,human.db.bag.cap do
	--	human.db.bag.grids[i] = Grid.new()
	--end
    --BagLogic.sendBagList(human,true)
	human.db.bag = {}
    BagLogic.sendBagList(human,true)
	send(human,"clearBag===true")
end

function resetArenaNum(human,num)
	local ArenaLogic = require("modules.arena.ArenaLogic")
	num = num or 0
	human.db.arena.challenge = num
	human.db.arena.nextTime = os.time()
	ArenaLogic.arenaQuery(human)
	send(human,"resetArenaNum===true")
end

function resetArenaCD(human)
	local ArenaLogic = require("modules.arena.ArenaLogic")
	human.db.arena.nextTime = os.time()
	ArenaLogic.arenaQuery(human)
	send(human,"resetArenaCD===true")
end

function addHero(human,heroName)
	if HeroDefine.DefineConfig[heroName] and not human.db.Hero[heroName] then
		HeroManager.addHero(human,heroName,0,1,1,os.time())
		local hero = HeroManager.getHero(human,heroName)
		HeroManager.sendHeroes(human,{hero.name})
		--hero:sendHeroAttr()
		send(human,"addHero success!")
	else
		send(human,"addHero fail! no such heroName:"..heroName)
	end
end

function setHeroLv(human,heroName,lv)
	if HeroDefine.DefineConfig[heroName] then
		local hero = HeroManager.getHero(human,heroName)
		if hero then
			hero:setLv(tonumber(lv))
			-- hero:sendHeroAttr()
			HeroManager.sendHeroes(human,{hero.name})
			send(human,"set hero lv to "..lv)
		end
	else
		send(human,"no such hero:"..heroName)
	end
end

function setHeroQuality(human,heroName,quality)
	if HeroDefine.DefineConfig[heroName] then
		local hero = HeroManager.getHero(human,heroName)
		if hero then
			hero:setQuality(tonumber(quality))
			hero:sendHeroAttr()
			send(human,"set hero quality to "..quality)
		end
	else
		send(human,"no such hero:"..heroName)
	end
end

function startBoss(human, hour, min, second)
	local Logic = require("modules.worldBoss.WorldBossLogic")
	Logic.addWorldBossTimer(hour, min, second)
end

function startThermae(human)
	local logic = require("modules.thermae.ThermaeLogic")
	logic.startThermae()
end

function endThermae(human)
	local logic = require("modules.thermae.ThermaeLogic")
	logic.endThermae()
end

function startCrazy(human)
	local logic = require("modules.crazy.CrazyLogic")
	logic.startCrazy()
end

function endCrazy(human)
	local logic = require("modules.crazy.CrazyLogic")
	logic.endCrazy()
end

function endBoss(human)
	local Logic = require("modules.worldBoss.WorldBossLogic")
	Logic.endWorldBoss()
end

function sendMail(human,id)
	local Logic = require("modules.mail.MailManager")
	Logic.sysSendMailById(human.db.account,tonumber(id))
	send(human,"sendMail===true")
end

function gmMail(human)
	local Logic = require("modules.mail.MailManager")
	Logic.gmSendMail()
	send(human,"gmMail===true")
end

function guildActive(human,val)
	local Logic = require("modules.guild.GuildManager")
	Logic.addGuildActive(human,tonumber(val))
	send(human,"guildActive===true")
end

function reset(human,val)
	val = tonumber(val)	
	if val == 1 then
		local logic = require("modules.trial.TrialLogic")
		logic.resetByDay(human,true)
		Msg.SendMsg(PacketID.GC_TRIAL_RESET, human, 0)
		logic.sendLevelList(human)
	elseif val == 2 then
		local logic = require("modules.orochi.OrochiLogic")
		logic.resetByDay(human,true)
		logic.sendLevelList(human)
		logic.sendRankReward()
	end
	human.db.task.refreshTime = 0
	human.db.physics = 0
	send(human,"ok!")
end

function setTreasureCnt(human,val)
	local TDefine = require("modules.treasure.TreasureDefine")
	local cnt = tonumber(val)
	if cnt < TDefine.MIN_MINE_CNT or cnt > TDefine.MAX_MINE_CNT then
		send(human,string.format("cnt must between %d and %d",TDefine.MIN_MINE_CNT,TDefine.MAX_MINE_CNT))
	else
		Treasure.setTreasureMineCount(cnt)
		send(human,"treasure mine cnt set to "..cnt)
	end
end

function resetGuild(human)
	human.db.wine.cnt = 0
	human.db.texas.count = 0
	human.db.kick.cnt = 0
	send(human,"ok!")
end

function passLevel(human,d,v1,v2)
	local difficulty = tonumber(d)
	local startLevelId = tonumber(v1)
	local endLevelId = tonumber(v2)
	for id = startLevelId,endLevelId do
		if LevelConfig[id] and LevelConfig[id][difficulty] then
			local conf = LevelConfig[id][difficulty]
			if human:getPhysics() < conf.energy then
				send(human,'关卡'..id..' 难度'..difficulty .. '体力不足！')
			elseif conf.limitPerDay > 0 and Chapter.getTimesPerDay(human,id,difficulty) >= conf.limitPerDay then
				send(human,'关卡'..id..' 难度'..difficulty .. '通关次数不足！')
			elseif Chapter.isLevelOpened(human,id,difficulty) then
				local reward = Chapter.levelPassLogic(human,id,difficulty,false,3,1)
				PublicLogic.doReward(human,reward[1],{},CommonDefine.ITEM_TYPE.ADD_GM)
				send(human,'关卡'..id..' 难度'..difficulty .. '成功通关！')
			else
				send(human,'关卡'..id..' 难度'..difficulty .. '未开放！')
			end
		end
	end
	Chapter.sendChapterList(human)
end

function arenaReward(human)
	Arena.rewardRank()
	send(human,"ok!")
end

function kick(human)
	human:release()
    Character.sendGCDisconnect(human)  
end

function recharge(human,val)
	human:incRecharge(val)
	send(human,"ok!")
end

function resetExpedition(human)
	local Logic = require("modules.expedition.ExpeditionLogic")
	Logic.resetExpeditionResetCount(human)
end

function setVipLv(human,val)
	VipLogic.adminSetVipLv(human,tonumber(val))
end

function guildBoss(human,val)
	if tonumber(val) == 1 then
		BossLogic.startBoss()
		send(human,"startBoss ok!")
	elseif tonumber(val) == 2 then
		BossLogic.endBoss()
		send(human,"endBoss ok!")
	else
		send(human,"null")
	end
end

function startPeak(human)
	local Logic = require("modules.peak.PeakLogic")
	Logic.startPeak()
end

function resetGuildCD(human)
	human.db.guildCD = 0
	send(human,"ok!")
end

function addReset(human)
	local db = human.db.orochi
	db.resetCounter = db.resetCounter - 99
	send(human,"ok!")
end






