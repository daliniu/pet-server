module(...,package.seeall)
local GiftDefine = require("modules.gift.GiftDefine")
local Msg = require("core.net.Msg")
local HeroGiftConfig = require("config.HeroGiftConfig").Config
local HeroDefineConfig = require("config.HeroDefineConfig").Config
local GiftConfig = require("config.GiftConfig").Config
local CommonDefine = require("core.base.CommonDefine")
local GoldLogic = require("modules.gold.GoldLogic")
local HeroDefine = require("modules.hero.HeroDefine")


function getGiftInfo(hero)
	local retMsg = {}
	local gift = hero.db.gift
	retMsg.name = hero:getName() 
	retMsg.id = {}
	for k,v in ipairs(gift) do
		retMsg.id[k] = v
	end
	return retMsg
end

function sendGiftInfo(human,heroName)
	local gift = {}
	local hero = human:getHero(heroName)
	table.insert(gift,getGiftInfo(hero))
	Msg.SendMsg(PacketID.GC_GIFT_QUERY,human,gift)
end


function sendAllGiftInfo(human)
	--local msg = {clear = 1,gift = {}}
	local gift = {}
	local heroes = human:getAllHeroes()
	for name,h in pairs(heroes) do
		table.insert(gift,getGiftInfo(h))
		--sendGiftInfo(h)
	end
	Msg.SendMsg(PacketID.GC_GIFT_QUERY,human,gift)
end

function activate(human,heroName,index,buyCnt)
	if index < 0 or index > GiftDefine.MAX_GIFT then
		return
	end
	local hero = human:getHero(heroName)
	if not hero then
		return
	end
	local gift = hero.db.gift
	if index > #gift + 1 then
		--不按顺序来
		print('------------------------1不按顺序来-----------------')
		return
	end
	local heroGift = HeroGiftConfig[heroName].gift
	local giftCfg = GiftConfig[heroGift[index]]
	local cfg = HeroDefine.DefineConfig[hero.name].giftCondition[index]

	if hero:getQuality() < cfg[2] then
		--星不够
		print('------------------------2星不够-----------------')
		return
	end

	if hero.db.strength.transferLv < cfg[3] then
		--阶不够
		print('------------------------3阶不够-----------------')
		return
	end

	if buyCnt > 0 then
		local ret = GoldLogic.buyTen(human,buyCnt)
	end
	if human:getMoney() < cfg[1] then
		print('------------------------4钱不够-----------------')
		return
	end

	human:decMoney(cfg[1],CommonDefine.MONEY_TYPE.DEC_HERO_GIFT)
	human:sendHumanInfo()

	gift[index] = 1
	sendGiftInfo(human,heroName)
	Msg.SendMsg(PacketID.GC_GIFT_ACTIVATE,human,GiftDefine.ActivateRet.ok)
end
