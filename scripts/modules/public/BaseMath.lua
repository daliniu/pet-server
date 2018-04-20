module(...,package.seeall)

local HeroDefine = require("modules.hero.HeroDefine")
local HeroQualityConfig = require("config.HeroQualityConfig").Config
local ExpConfig = require("config.ExpConfig").Config
-- FragQualityFactor =
-- {
-- 	[1] = 1,
-- 	[2] = 1.1,
-- 	[3] = 1.25,
-- 	[4] = 1.45,
-- 	[5] = 1.7,
-- 	[6] = 2,
-- 	[7] = 2.4,
-- }

COST_FACTOR = math.pow(0.99,0.48)


hp_args = 
{
	[1] = 0,
	[2] = 50,
	[3] = 450,
}

attr_args = 
{
	[1] = 0,
	[2] = 5,
	[3] = 70,
}

cost_args =
{
	[1] = 0,
	[2] = 2,
	[3] = 10,
}

heroExp_args =
{
	[1] = 10,
	[2] = 20,
	[3] = 70, 
}

humanExp_args = 
{
	[1] = 5,
	[2] = 10,
	[3] = 35, 
}




-- human --

--人物升级所需经验
-- int(round(等级*等级*战队经验参数1+等级*战队经验参数2+战队经验参数3,0))
function getHumanLvUpExp(lv)
	-- return math.floor(lv*lv*humanExp_args[1]+lv*humanExp_args[2]+humanExp_args[3])
	if ExpConfig[lv] then
		return ExpConfig[lv].charExp
	end
end


-- skill --
--
--技能属性
function getSkillAttr(lv,val,factor)
	return val + (lv - 1) * factor
end

--技能升级的花费
--INT(0.8^1.02*(当前等级*当前等级+2*当前等级))+80
function getSkillUpgradeCost(lv)
	return math.floor(math.pow(0.8,1.02)*(lv*lv+2*lv)) + 80
end


--- hero ----
-- 获得maxHP
--int(round(等级*等级*血量参数1+等级*血量参数2+血量参数3,0)*资质系数*品质系数)
-- function getHero_maxHp(value,lv,growth,initial,qualityFactor)
-- 	return math.floor((lv*lv*hp_args[1]+lv*hp_args[2]+hp_args[3])*inFactor*qualityFactor)
-- end

--int(round(等级*等级*属性参数1+等级*属性参数2+属性参数3,0)*资质系数*品质系数)
function getHero_attr(value,lv,growth,initial,qualityFactor)
	-- print('attr_value='..math.floor(((lv-1)*growth+initial)*qualityFactor))
	return math.floor(initial + (lv-1)*growth*qualityFactor)
	-- return math.floor((lv*lv*0.2+0.8*lv+4)*inFactor*qualityFactor)
end

function getHero_nochange(value,lv,growth,initial,qualityFactor)
	if value then
		return value
	else
		return 1
	end
end
getHero_atk = getHero_attr
getHero_def = getHero_attr
getHero_atkSpeed = getHero_attr
getHero_crthit = getHero_attr
getHero_antiCrthit = getHero_attr
getHero_block = getHero_attr
getHero_antiBlock = getHero_attr
getHero_damage = getHero_block
getHero_maxHp = getHero_attr
getHero_finalAtk = getHero_attr
getHero_finalDef = getHero_attr
getHero_hpR = getHero_nochange
getHero_rageR = getHero_nochange
getHero_rageRByHp = getHero_nochange
getHero_rageRByWin = getHero_nochange
getHero_assist = getHero_nochange
getHero_initRage = getHero_attr
--int(round(等级*等级*COST参数1+等级*COST参数2+COST参数3,0))
function getHero_cost(value,lv,growth,initial,qualityFactor)
	return math.floor((lv-1)*growth+initial)
	-- if lv == 1 then
	-- 	-- 应仝闯要求，方便测试，cost初始值改成100 
	-- 	--return 30
	-- 	return 100
	-- else
	-- 	return math.floor(math.floor((getHero_cost(value,lv-1,inFactor,qualityFactor)+2)*COST_FACTOR)*inFactor*qualityFactor)
	-- end
end

-- function getHero_hpR(value,lv,growth,initial,qualityFactor)
-- 	if value then
-- 		return value
-- 	else
-- 		return 1
-- 	end
-- end

-- function getHero_rageR(value,lv,growth,initial,qualityFactor)
-- 	if value then
-- 		return value*100
-- 	else
-- 		return 100
-- 	end
-- end

-- function getHero_assist(value,lv,growth,initial,qualityFactor)
-- 	if value then
-- 		return value
-- 	else
-- 		return 1
-- 	end
-- end

-- function getHero_rageRByHp(value,lv,growth,initial,qualityFactor)
-- 	if value then
-- 		return value*100
-- 	else
-- 		return 100
-- 	end
-- end

-- function getHero_rageRByWin(value,lv,growth,initial,qualityFactor)
-- 	if value then
-- 		return value*100
-- 	else
-- 		return 100
-- 	end
-- end

function getHeroExp(lv)
	-- if lv == 1 then
	-- 	return 15
	-- else
	-- 	return math.floor(getHeroExp(lv-1)*1.11 + 13)
	-- end
	-- return math.floor(lv*lv*heroExp_args[1]+lv*heroExp_args[2]+heroExp_args[3])
	if ExpConfig[lv] then
		return ExpConfig[lv].heroExp
	end
end

function getHeroQualityFrag(name,quality)
	-- local frag = HeroDefine.DefineConfig[name].fragment
	-- if HeroQualityConfig[quality] then
	-- 	return HeroQualityConfig[quality].fragRate*frag
	-- end
	return HeroQualityConfig[quality].frag
end

function getHeroRecruitFrag(name)
	--获得招募时所需的碎片数量

	local frag = 0
	local star = math.min(HeroDefine.MAX_QUALITY,HeroDefine.DefineConfig[name].star)
	for i=1,star do
		frag = frag + HeroQualityConfig[i].frag
	end
	return frag,star
end

--- power力量 ---
--力量升级
function getPowerUpExp(lv)
	return math.floor(math.pow(0.5,1.02) * (lv * lv + 2 * lv)) + 15
end

--力量属性
--ROUND(当前等级*当前等级*2.5+0.8*当前等级+80,0)
function getPowerAttr(lv)
	return math.floor(lv * lv * 2.5 + 0.8 * lv + 80)
end
