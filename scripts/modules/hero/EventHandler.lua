module(...,package.seeall)

local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local Hero = require("modules.hero.Hero")
local HeroManager = require("modules.hero.HeroManager")
local HeroDefine = require("modules.hero.HeroDefine")
local Util = require("core.utils.Util")
local BagLogic = require("modules.bag.BagLogic")


function onCGHeroAttr(human,name)
    local hero = human:getHero(name)
    hero:calcDyAttr()
    Msg.SendMsg(PacketID.GC_HERO_ATTR,human,name,hero.db.exp,hero.db.level,hero.db.quality,hero.db.ctime,hero.DyAttr,hero.db.exchange)
end

function onCGAllHeroAttr(human,placeholder)
	HeroManager.sendAllHeroes(human)
end

function onCGHeroDyattr(human,name)
	local hero = human:getHero(name)
	if hero then
		hero:resetDyAttr()
		hero:sendDyAttr()
	end
end


function onCGHeroCompose(human,name)
	local ret,star = HeroManager.composeHero(human,name)
	if ret then
		ret = HeroDefine.RET_OK
	else
		ret = HeroDefine.RET_FRAG_NOTENOUGH
	end
	Msg.SendMsg(PacketID.GC_HERO_COMPOSE,human,name,ret,star)
end


function onCGHeroRecruit(human,name)
	local ret = Hero.heroRecuit(human,name) and HeroDefine.RET_OK or HeroDefine.RET_FRAG_NOTENOUGH
	Msg.SendMsg(PacketID.GC_HERO_RECRUIT,human,name,ret)
end

function onCGHeroQualityUp(human,name,goldBuyTimes)
	local hero = human:getHero(name)
	if not hero then
		Msg.SendMsg(PacketID.RET_NOSUCH_HERO,human,name,HeroDefine.RET_NOSUCH_HERO)
	else
		-- local ret = hero:incQuality(frag,coinFrag,goldBuyTimes)
		local ret = hero:incQuality(goldBuyTimes)
		if ret == HeroDefine.RET_OK then
			hero:sendHeroAttr()
			human:sendHumanInfo()
			HumanManager:dispatchEvent(HumanManager.Event_HeroQualityUp,{human=human,heroName=hero:getName(),objId=hero:getQuality()})
			HumanManager:dispatchEvent(HumanManager.Event_HeroStar,{human=human,objId=hero:getQuality()})
		end
		hero:sendQualityUp(ret)
	end
end

function onCGHeroExpedition(human,name)
	human.db.HeroExpedition = name
end


function onCGHeroBreakthrough(human,name)
	local hero = HeroManager.getHero(human,name)
	if hero then
		btLv = hero:getBTLv()
		if btLv >= HeroDefine.MAX_BT then
			Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_MAXLIMIT)
			return
		end
		local targetLv = btLv + 1
		local heroLvRequired,stoneCntRequired,moneyRequired,heroStarRequired = Hero.getBTLvInfo(targetLv)
		if hero:getLv() < heroLvRequired then
			Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_HEROLV)
			return
		end
		if hero:getQuality() < heroStarRequired then
			Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_HEROSTAR)
			return
		end
		local stoneCnt = BagLogic.getItemNum(human,HeroDefine.BREAK_STONE_ID)
		if stoneCnt < stoneCntRequired then
			Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_FRAG_NOTENOUGH)
			return
		end
		if human:getMoney() < moneyRequired then
			Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_MONEY_NOTENOUGH)
			return
		end
		BagLogic.delItemByItemId(human,HeroDefine.BREAK_STONE_ID,stoneCntRequired,true,CommonDefine.ITEM_TYPE.DEC_HERO_BT)
		human:decMoney(moneyRequired,CommonDefine.MONEY_TYPE.DEC_HERO_BT)
		hero:setBTLv(targetLv)
		hero:resetDyAttr()
		hero:sendHeroAttr()
		human:sendHumanInfo()
		Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_OK,targetLv)
		HumanManager:dispatchEvent(HumanManager.Event_HeroBreak,{human=human,objId=targetLv})

	else
		Msg.SendMsg(PacketID.GC_HERO_BREAKTHROUGH,human,name,HeroDefine.RET_NOSUCH_HERO)
	end

end

function onCGHeroTopLvup(human,name)
	local hero = HeroManager.getHero(human,name)
	if not hero then
		Msg.SendMsg(PacketID.GC_HERO_TOP_LVUP,human,HeroDefine.RET_NOSUCH_HERO,name)
		return
	end
	local exp = hero:getTopExp()
	hero:addTopExp(exp)
	Msg.SendMsg(PacketID.GC_HERO_TOP_LVUP,human,HeroDefine.RET_OK,name)
end


function onCGHeroStarAttr(human,name,star)
	local hero = HeroManager.getHero(human,name)
	if not hero then
		Msg.SendMsg(PacketID.GC_HERO_STAR_ATTR,human,HeroDefine.RET_NOSUCH_HERO,name)
		return
	end
	local oldStar = hero:getQuality()
	hero:setQuality(star)
	hero:resetDyAttr()
	hero:calcDyAttr(false)
	Msg.SendMsg(PacketID.GC_HERO_STAR_ATTR,human,HeroDefine.RET_OK,name,star,hero.dyAttr)
	hero:setQuality(oldStar)
	hero:resetDyAttr()
end

function onCGHeroExchange(human,name,frag)
	local conf = HeroDefine.DefineConfig[name]
	if conf == nil then
		Msg.SendMsg(PacketID.GC_HERO_EXCHANGE,human,HeroDefine.RET_NOSUCH_HERO,name)
		return
	end
	local hero = HeroManager.getHero(human,name)
	local star = hero:getQuality() + 1
	if star > HeroDefine.MAX_QUALITY then
		star = HeroDefine.MAX_QUALITY
	end
	local curFrag = hero:getExchange(star)
	local rate = conf.exchangeCoin[1]
	if frag + curFrag > conf.exchangeCoin[star] then
		Msg.SendMsg(PacketID.GC_HERO_EXCHANGE,human,HeroDefine.RET_MAXLIMIT,name)
		return
	end
	local coin = human:getExchangeCoin()
	if coin < frag * rate then
		Msg.SendMsg(PacketID.GC_HERO_EXCHANGE,human,HeroDefine.RET_FRAG_NOTENOUGH,name)
		return
	end
	hero:setExchange(star,curFrag + frag)

	human:decExchangeCoin(frag*rate)
	local fragId = conf.fragId
	BagLogic.addItem(human,fragId,frag,true,CommonDefine.ITEM_TYPE.ADD_HERO_EXCHANGE)
	human:sendHumanInfo()
	Msg.SendMsg(PacketID.GC_HERO_EXCHANGE,human,HeroDefine.RET_OK,name,star,curFrag+frag)
end