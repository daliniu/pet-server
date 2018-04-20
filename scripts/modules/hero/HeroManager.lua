module(...,package.seeall)
local Bag = require("modules.bag.BagLogic")
local Msg = require("core.net.Msg")
local Util = require("core.utils.Util")
local Def = require("modules.hero.HeroDefine")
local Hero = require("modules.hero.Hero")

local SkillLogic = require("modules.skill.SkillLogic")
local StrengthLogic = require("modules.strength.StrengthLogic")
local GiftLogic = require("modules.gift.GiftLogic")
local TrainLogic = require("modules.train.TrainLogic")
local SkillDB = require("modules.skill.SkillDB")
local StrengthDB = require("modules.strength.StrengthDB")
local GiftDB = require("modules.gift.GiftDB")
local ExpConfig = require("config.ExpConfig").Config
local BaseMath = require("modules.public.BaseMath")
local ItemConfig = require("config.ItemConfig").Config
local TrainDB = require("modules.train.TrainDB")
local EquipDB = require("modules.equip.EquipDB")

function init(human)
	if human.db.Hero == nil then
		human.db.Hero = {}
		human.info.Hero = {}
		human.db.HeroExpedition = {}
	end
end

function onHumanCreate(hm,human)
	local now = os.time()
	-- human:addHero('Terry',0,1,1,now)
	-- human:addHero('Ryo',0,1,1,now)
	-- human:addHero('Robert',0,1,1,now)
	-- human:addHero('Iori',0,1,1,now)
	-- human:addHero('Mai',0,1,1,now)
	-- human:addHero('Athena',0,1,1,now)
	-- human:addHero('Clark',0,1,1,now)
	-- human:addHero('Shermie',0,1,1,now)
	--human:addHeroNoSave('Shingo',0,1,1,now)  --- 初始赠送矢吹真吾
	-- human:addHero('Andy',0,1,1,now)
	-- human:addHero('Daimon',0,1,1,now)
	-- human:addHero('Chang',0,1,1,now)
	-- human:addHero('King',0,1,1,now)
	-- human:addHero('Orochi',0,1,1,now)
	sendAllHeroes(human)
end

function newHeroDb(name,exp,lv,quality,ctime,btlv)
	local hero = {}
	hero.name = name
	hero.exp = exp
	hero.lv = lv
	hero.quality = quality
	hero.ctime = ctime
	hero.btlv = btlv or 0
	hero.status = Def.STATUS_NORMAL
	hero.exchange = {}
	for i=1,Def.MAX_QUALITY do 
		hero.exchange[i] = 0
	end
	return hero
end


--对外提供hero对象
function getHero(human,name)
	local db = human.db.Hero
	local info = human.info.Hero
	if not info[name] then
		if not freshHero(human,name) then
			return
		end
	end
	return info[name]
end

function getHeroExpedition(human)
	return human.db.HeroExpedition
end

function getAllHeroes(human)
	local heroes = {}
	for name,h in pairs(human.db.Hero) do 
		local hero = human:getHero(name)
		if hero then
			heroes[#heroes+1] = hero
		end
	end
	return heroes
end

function getHeroCnt(human)
	local cnt = 0
	for _,_ in pairs(human.db.Hero) do
		cnt = cnt + 1
	end
	return cnt 
end

function getHeroCountByQuality(human, quality)
	local count = 0
	local heroList = getAllHeroes(human)
	for _,hero in pairs(heroList) do
		if hero:getQuality() >= quality then
			count = count + 1
		end
	end
	return count
end

function addHero(human,name,exp,lv,quality,ctime,btLv)
	addHeroNoSave(human,name,exp,lv,quality,ctime,btLv)
	human:save()
end

function addHeroNoSave(human,name,exp,lv,quality,ctime,btLv)
	local heroDB = human.db.Hero
	local heroInfo = human.info.Hero
	assert(not heroDB[name],name.." already exists for "..human:getName())
	heroDB[name] = newHeroDb(name,exp,lv,quality,ctime,btLv)
	local hero = getHero(human,name)
	SkillLogic.checkSkillGroupConf(hero,true)
	HumanManager:dispatchEvent(HumanManager.Event_HeroCollect,{human=human,heroName=name,objId=quality})
end

function delHero(human,name)
	local heroDB = human.db.Hero
	local heroInfo = human.info.Hero
	heroDB[name] = nil
	heroInfo[name] = nil
end

function composeHero(human,name)
	local fragNum,star = BaseMath.getHeroRecruitFrag(name)
	local fragId = Def.DefineConfig[name].fragId
	if Bag.getItemNum(human,fragId) >= fragNum then
	 	Bag.delItemByItemId(human,fragId,fragNum,true,CommonDefine.ITEM_TYPE.DEC_HERO_COMPOSE)
		addHero(human,name,0,1,star,os.time())
		local hero = human:getHero(name)
		sendHeroes(human,{name})

		local fragName = ItemConfig[fragId].name
		local logTb = Log.getLogTb(LogId.HERO_COMPOSE)
				logTb.account = human:getAccount()
				logTb.channelId = human:getChannelId()
				logTb.name = human:getName()
				logTb.pAccount = human:getPAccount()
				logTb.heroName = name
				logTb.rmb = 0
				logTb.money = 0
				logTb.fragName = fragName
				logTb.fragNum = fragNum
				logTb:save()
		return true,star
	else
		return false,star
	end
end

function freshHero(human,name)
	local db = human.db.Hero[name]
	local heroInfo = human.info.Hero
	if not db then return end
	if not Def.DefineConfig[name] then return end
	if not heroInfo[name] then
		heroInfo[name] = createInfo(human,db)
	else
		heroInfo[name]:calcDyAttr()
	end
	return true
end

function createInfo(human,db)
	local info = {db=db,human=human}
	setmetatable(info,{__index=Hero})
	--设置静态属性
	local name = db.name
	info.name = name
	-- print('------------name:',name)
	info.cname = Def.DefineConfig[name].cname
	info.career = Def.DefineConfig[name].career
	info.trend = Def.DefineConfig[name].trend
	info.fragId = Def.DefineConfig[name].fragId
	SkillDB.init(db)
	StrengthDB.init(db)
	GiftDB.init(db)
	TrainDB.init(db)
	EquipDB.init(db)
	info:calcDyAttr()
	return info
end

function sendAllHeroes(human)
	sendAllHeroesAttr(human)
	SkillLogic.sendAllSkillList(human)
	StrengthLogic.sendAllStrengthInfo(human)
	GiftLogic.sendAllGiftInfo(human)
	TrainLogic.sendAllTrainInfo(human)
end

function sendAllHeroesAttr(human)
	local heroes = human:getAllHeroes()
	local ret = {}
	for name,h in pairs(heroes) do 
		h:calcDyAttr()
		Hero.dyAttr1(h.dyAttr)
		ret[#ret + 1] = {name=h.name,exp=h:getExp(),lv=h:getLv(),quality=h:getQuality(),ctime=h:getCTime(),btLv=h:getBTLv(),status=h:getStatus(),dyAttr=h.dyAttr,exchange=h.db.exchange}
	end
	Msg.SendMsg(PacketID.GC_ALL_HERO_ATTR,human,ret)
	for name,h in pairs(heroes) do
		Hero.dyAttr2(h.dyAttr)
	end
end

function sendHeroes(human,heroes)
	for i,name in ipairs(heroes) do
		local h = getHero(human,name)
		if h then
			h:sendHeroAttr()
			SkillLogic.sendSkillGroupList(h)
			StrengthLogic.sendStrengthInfo(h)
		end
	end
end

function sendHeroExpedition(human)
	Msg.SendMsg(PacketID.GC_HERO_EXPEDITION,human,human:getHeroExpedition())
end

function onHumanLogin(hm,human)
	local db = human.db.Hero
	-- db.iori = {name='iori',exp=5000,lv=10,quality=3,ctime=1100}
	-- db.kyo = {name='kyo',exp=7000,lv=12,quality=2,ctime=31433}
	-- db.chang = {name='chang',exp=9000,lv=13,quality=4,ctime=322}
	sendAllHeroes(human)
	-- sendHeroExpedition(human)
end
