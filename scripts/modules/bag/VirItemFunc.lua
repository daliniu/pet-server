module(...,package.seeall)
local StrengthLogic = require("modules.strength.StrengthLogic")
local HeroDefine = require("modules.hero.HeroDefine")
local PublicLogic = require("modules.public.PublicLogic")
local HeroManager = require("modules.hero.HeroManager")
local BagLogic = require("modules.bag.BagLogic")
local GuildManager = require("modules.guild.GuildManager")
local TexasLogic = require("modules.guild.texas.TexasLogic")
local WineLogic = require("modules.guild.wine.WineLogic")

function addHero(human,addHero,cnt,way)
	local heroDB = human.db.Hero
	local heroName = addHero.name
	if not heroDB[heroName] then
		human:addHero(heroName,0,1,addHero.star,os.time())
		local hero = HeroManager.getHero(human,heroName)
		-- hero:sendHeroAttr()
		HeroManager.sendHeroes(human,{heroName})
		-- StrengthLogic.query(human,heroName)
	else
		local fragnum = addHero.frag
		local cfg = HeroDefine.DefineConfig[heroName]
		local fragId = cfg.fragId
		--local items = {}
		--table.insert(items,{fragId,fragnum})
		--PublicLogic.addItemsBagOrMail(human,items)
		BagLogic.addItem(human,fragId,fragnum,true,way or CommonDefine.ITEM_TYPE.ADD_VIRFUNC)
	end
	return true
end

function addMoney(human,money,cnt,way)
	human:incMoney(money*cnt,way or CommonDefine.MONEY_TYPE.ADD_VIRFUNC)
	human:sendHumanInfo()
	return true
end

function addRmb(human,rmb,cnt,way)
	human:incRmb(rmb*cnt,way or CommonDefine.RMB_TYPE.ADD_VIRFUNC)
	human:sendHumanInfo()
	return true
end

function addPhysics(human,phy,cnt,way)
	human:incPhysics(phy*cnt,way or CommonDefine.PHY_TYPE.ADD_VIRFUNC)
	human:sendHumanInfo()
	return true
end

function addFame(human,fame,cnt,way)
	human:incFame(fame*cnt)
	human:sendHumanInfo()
	return true
end

function addSkillRage(human,rage,cnt,way)
	human:incSkillRage(rage*cnt)
	human:sendHumanInfo()
	return true
end

function addSkillAssist(human,assist,cnt,way)
	human:incSkillAssist(assist*cnt)
	human:sendHumanInfo()
	return true
end

function addTourCoin(human,coin,cnt,way)
	human:incTourCoin(coin*cnt)
	human:sendHumanInfo()
	return true
end

function addPowerCoin(human,coin,cnt,way)
	human:incPowerCoin(coin*cnt)
	human:sendHumanInfo()
	return true
end

function addCharExp(human,exp,cnt,way)
	human:incExp(exp*cnt)
	human:sendHumanInfo()
	return true
end

function addGuildCoin(human,coin,cnt,way)
	human:incGuildCoin(coin*cnt)
	human:sendHumanInfo()
	return true
end

function addExchangeCoin(human,coin,cnt,way)
	human:incExchangeCoin(coin*cnt)
	human:sendHumanInfo()
	return true
end

function addTexasExp(human,exp,cnt,way)
	--human.db.texas:incExp(exp*cnt)
	--human:sendHumanInfo()
	local guildId = human:getGuildId()
	if guildId <= 0 then
		return false
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if not guild then
		return false
	end
	guild:incTexasExp(exp*cnt)
	TexasLogic.query(human)
	GuildManager.setDirty(guildId)
	return true
end

function addWineExp(human,exp,cnt,way)
	--human.db.wine:incExp(exp*cnt)
	--human:sendHumanInfo()
	local guildId = human:getGuildId()
	if guildId <= 0 then
		return false
	end
	local guild = GuildManager.getGuildIdList()[guildId]
	if not guild then
		return false
	end
	guild:incWineExp(exp*cnt)
	WineLogic.query(human)
	GuildManager.setDirty(guildId)
	return true
end
