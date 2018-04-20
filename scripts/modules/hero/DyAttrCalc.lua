module(..., package.seeall)
local HeroDefine = require("modules.hero.HeroDefine")
local HeroQualityConfig = require("config.HeroQualityConfig").Config
local HeroCapacityConfig = require("config.HeroCapacityConfig").Config
local SkillMasterConfig = require("config.SkillMasterConfig").Config
local DyAttrName = HeroDefine.DyAttrName
local DyAttrName2Enum = HeroDefine.DyAttrName2Enum
local HeroConfig = HeroDefine.DefineConfig
local HeroAttrConfig = HeroDefine.AttrConfig
local BaseMath = require("modules.public.BaseMath")
local WeaponConfig = require("config.WeaponConfig").Config
local PartnerLogic = require("modules.partner.PartnerLogic")
local ChainConfig = require("config.PartnerChainConfig").Config
local StrengthDefine = require("modules.strength.StrengthDefine")
local StrengthLogic = require("modules.strength.StrengthLogic")
local MaterialConfig = require("config.StrengthMaterialConfig").Config
local TransferConfig = require("config.StrengthTransferConfig").Config
local WineItemConfig = require("config.WineItemConfig").Config
local Hero = require("modules.hero.Hero")
local SkillLogic = require("modules.skill.SkillLogic")
local SkillDefine = require("modules.skill.SkillDefine")
local EquipDefine = require("modules.equip.EquipDefine")
local EquipConfig = require("config.EquipConfig").Config
local EquipOpenLvConfig = require("config.EquipOpenLvConfig").Config

-- inFactor = {
-- 	atkA = {5.5,3,3.2},
-- 	defA = {4.3,3.2,2.8},
-- 	atkB = {3.4,5,2.6},
-- 	defB = {2.8,4.5,2.4},
-- 	atkC = {3.5,2.4,4.9},
-- 	defC = {4.1,2.7,4.7},
-- 	maxHp = {2.5,2.5,2.5},
-- 	cost = {1.2,1.2,1.2},
-- }

--资质系数已经不再使用了
-- inFactor = {
-- 	atkA = {1,1,1},
-- 	defA = {0.67,0.67,0.67},
-- 	atkB = {1,1,1},
-- 	defB = {0.67,0.67,0.67},
-- 	atkC = {1,1,1},
-- 	defC = {0.67,0.67,0.67},
-- 	maxHp = {1,1,1},
-- 	cost = {1,1,1},
-- }

qualityFactor = {
	[1] = 1,     -- 白
	[2] = 1.1,   -- 绿
	[3] = 1.2,   -- 蓝
	[4] = 1.3,   -- 黄
	[5] = 1.4,   -- 红
	[6] = 1.5,   -- 紫
	[7] = 1.7,   -- 橙
}

function calcHeroDyAttr(hero)
	calcHeroDyAttrbyStaticAttr(hero)
	calcWeaponDyAttr(hero)
	calcDyAttrbyPower(hero)
	calcDyAttrbyPartner(hero)
	calcDyAttrbyStrength(hero)
	calcHeroBreakthrough(hero)
	calcDyAttrbyTrain(hero)
	calcDyAttrbyWineBuff(hero)
	calcDyAttrBySkillMaster(hero)
	calcDyAttrByEquip(hero)
end


function getHeroBaseAttr(hero,attr)
	if DyAttrName2Enum[attr] then
		local name = hero:getName()
		local quality = hero:getQuality()
		local lv = hero:getLv()
		local value = HeroDefine.DefineConfig[name][attr]
		local growth = HeroDefine.DefineConfig[name][attr..'_growth']
		local initial = HeroDefine.DefineConfig[name][attr..'_initial']
		local qua = HeroQualityConfig[quality][attr..'Rate'] or HeroQualityConfig[quality].defaultRate
		return BaseMath['getHero_'..attr](value,lv,growth,initial,qua)
	end
end

function getHeroDyAttr(hero,dyAttr,lv,quality)
	local name = hero.db.name
	
	-- 英雄偏向
	-- local trend = HeroDefine.DefineConfig[name].trend
	for _,attr in pairs(DyAttrName) do 
		if not dyAttr[attr] then dyAttr[attr] = 0 end
		-- local value = HeroDefine.DefineConfig[name][attr]
		-- local growth = HeroDefine.DefineConfig[name][attr..'_growth']
		-- local initial = HeroDefine.DefineConfig[name][attr..'_initial']
		-- local qua = HeroQualityConfig[quality][attr..'Rate'] or HeroQualityConfig[quality].defaultRate
		-- ldb.ldb_open()
		
		-- if attr == 'maxHp' then
			--  资质系数
			-- local intelligence
			-- if inFactor[attr] then
			-- 	intelligence = inFactor[attr][trend]
			-- else
			-- 	intelligence = 1
			-- end
			--  品质系数
			-- dyAttr[attr] = BaseMath['getHero_'..attr](value,lv,growth,initial,qua)
			dyAttr[attr] = getHeroBaseAttr(hero,attr) or 0
			--print('hero='..name..' attr='..attr..' lv='..lv.." growth="..tostring(growth).." initial="..tostring(initial).." attrvalue="..dyAttr[attr])
	end
	return dyAttr
end

function calcHeroBreakthrough(hero)
	local btLv = hero:getBTLv()
	local name = hero:getName()
	local attrValue = hero.dyAttr
	for _,attr in ipairs(HeroDefine.BaseDyAttrName) do
		attrValue[attr] = attrValue[attr] + Hero.getBTAttr(attr,btLv)
	end
	for i = 1,btLv do
		local capacityId = HeroDefine.DefineConfig[name].breakThrough[i]
		local capacity = HeroCapacityConfig[capacityId]
		if capacity.incType == 1 then
			--绝对值
			attrValue[capacity.incAttr] = attrValue[capacity.incAttr] + capacity.incValue
		else
			attrValue[capacity.incAttr] = attrValue[capacity.incAttr] + getHeroBaseAttr(hero,capacity.incAttr)*capacity.incValue/100
		end
	end
end

function calcHeroDyAttrbyStaticAttr(hero)
	local name = hero.db.name
	local lv = hero:getLv()
	local quality = hero:getQuality()
	getHeroDyAttr(hero,hero.dyAttr,lv,quality)
	-- local qua = qualityFactor[quality]
	-- -- 英雄偏向
	-- local trend = HeroDefine.DefineConfig[name].trend

	-- for _,attr in pairs(DyAttrName) do 
	-- 	if not dyAttr[attr] then dyAttr[attr] = 0 end
	-- 	local value = HeroDefine.DefineConfig[name][attr]
	-- 	-- ldb.ldb_open()
		
	-- 	-- if attr == 'maxHp' then
	-- 		--  资质系数
	-- 		local intelligence
	-- 		if inFactor[attr] then
	-- 			intelligence = inFactor[attr][trend]
	-- 		else
	-- 			intelligence = 1
	-- 		end
	-- 		--  品质系数
			
	-- 		dyAttr[attr] = BaseMath['getHero_'..attr](value,lv,intelligence,qua)
	-- end
end

function calcWeaponDyAttr(hero)
	hero:showInfo("before calcHeroDyAttr")
	local dyAttr = hero.dyAttr
	local wepList = hero.human.db.wep
	for _,wep in pairs(wepList) do
		local weaponConfig = WeaponConfig[wep.wid * 10000 + wep.q * 1000 + wep.lv]
		if weaponConfig then
			for attrName,val in pairs(weaponConfig.attr) do
				dyAttr[attrName] = dyAttr[attrName] + val
			end
		end
	end
	hero:showInfo("after calcHeroDyAttr")
end

--力量加成
local PowerConfig = require("config.PowerConfig").Config
function calcDyAttrbyPower(hero)
	hero:showInfo("before calcHeroDyAttrppp")
	local dyAttr = hero.dyAttr
	local human = hero:getHuman()
	for _,power in ipairs(human.db.power) do
		local conf = PowerConfig[power.powerId]
		for attrName,v in pairs(conf.attr) do
			dyAttr[attrName] = BaseMath.getPowerAttr(power.lv) + dyAttr[attrName]
		end
	end
	hero:showInfo("after calcHeroDyAttrpppp")
end

function calcDyAttrbyPartner(hero)
	hero:showInfo("before Partner calcHeroDyAttrppp")
	local dyAttr = hero.dyAttr
	local human = hero:getHuman()
	local Hero2Partner = PartnerLogic.getHero2PartnerCfg()
	if not Hero2Partner[hero:getName()] then
		return
	end
	local chain = Hero2Partner[hero:getName()].chain
	if not chain then
		return
	end
	local name = hero.db.name
	local quality = hero:getQuality()
	local lv = hero:getLv()
	local herocfg = HeroDefine.DefineConfig[name]
	for k,v in pairs(chain) do
		if PartnerLogic.isActive(human,v) then
			for k,v in pairs(ChainConfig[v].attr) do
				local value = herocfg[k]
				local growth = herocfg[k..'_growth']
				local initial = herocfg[k..'_initial']
				local qua = HeroQualityConfig[quality][k..'Rate'] or HeroQualityConfig[quality].defaultRate
				local base = math.floor(BaseMath['getHero_'..k](value,lv,growth,initial,qua))
				dyAttr[k] = dyAttr[k] + math.floor(base * (v/ 100))
			end
		end
	end
	hero:showInfo("after Partner calcHeroDyAttrppp")
end

function calcDyAttrbyStrength(hero)
	hero:showInfo("before Strength calcHeroDyAttrppp")
	local dyAttr = hero.dyAttr
	local strength = hero.db.strength
	for i = 1,StrengthDefine.kMaxStrengthCellCap do
		local cell = strength.cells[i]
		local cfg = StrengthLogic.getStrengthAppConfig(hero.db.name,i)
		local lvCfg = cfg.lvCfg
		if lvCfg and lvCfg[cell.lv] then
			--for k,v in pairs(lvCfg[cell.lv].attr) do
			--	dyAttr[k] = dyAttr[k] + v
			--end
			for k,v in pairs(lvCfg[cell.lv].append) do
				dyAttr[k] = dyAttr[k] + v
			end
		end
		--for j = 1,StrengthDefine.kMaxStrengthGridCap do
		--	local id = cell.grids[j]
		--	if MaterialConfig[id] then
		--		for k,v in pairs(MaterialConfig[id].attr) do
		--			dyAttr[k] = dyAttr[k] + v
		--		end
		--	end
		--end
	end
	local transferCfg = TransferConfig[strength.transferLv]
	if transferCfg then
		for k,v in pairs(transferCfg.attr) do
			dyAttr[k] = dyAttr[k] + v
		end
	end
	hero:showInfo("after Strength calcHeroDyAttrppp")
end

function calcDyAttrbyTrain(hero)
	hero:showInfo("before Train calcHeroDyAttrppp")
	local dyAttr = hero.dyAttr
	local train = hero.db.train
	for i = 1,#train.base do
		local attr = train.base[i].name
		local val = train.base[i].val
		dyAttr[attr] = dyAttr[attr] + val
	end
	hero:showInfo("after Train calcHeroDyAttrppp")
end

function calcDyAttrbyWineBuff(hero)
	hero:showInfo("before WineBuff calcHeroDyAttrppp")
	local human = hero:getHuman()
	local dyAttr = hero.dyAttr
	if not human.db.wine or not human.db.wine.buff then
		return
	end
	for k,v in pairs(human.db.wine.buff) do
		local cfg = WineItemConfig[tonumber(k)]
		if cfg then
			local data = cfg.buff["dyattr"]
			if data then
				for attr,val in pairs(data) do
					dyAttr[attr] = dyAttr[attr] + getHeroBaseAttr(hero,attr)*val/100
				end
			end
		end
	end
	hero:showInfo("after WineBuff calcHeroDyAttrppp")
end

--技能强化大师加属性
function calcDyAttrBySkillMaster(hero)
	hero:showInfo("before SkillMaster calcHeroDyAttrppp")
	local list = SkillLogic.getEquipSkillGroup(hero, SkillDefine.TYPE_NORMAL)
	local minLv = 101 -- 配置最高等级100
	for k, v in ipairs(list) do
		if v.lv < minLv then
			minLv = v.lv
		end
	end

	if minLv == 101 then
		print("calcDyAttrBySkillMaster==> 101")
		return 
	end

	local masterLv = math.floor(minLv / 5)
	local dyAttr = hero.dyAttr
	local cfg = SkillMasterConfig[masterLv]
	if cfg then
		for _,attr in pairs(DyAttrName) do 
			local v = cfg[attr] 
			if v then
				dyAttr[attr] = dyAttr[attr] + v 
			end
		end
	end
	hero:showInfo("after SkillMaster calcHeroDyAttrppp")
end

--装备附加属性
function calcDyAttrByEquip(hero)
	hero:showInfo("before Equip calcHeroDyAttrppp")
	local dyAttr = hero.dyAttr
	local db = hero.db.equip
	local lv = hero:getLv()

	for pos, attr in ipairs(EquipDefine.EQUIP_ATTR) do
		local openlv = EquipOpenLvConfig[pos].openlv 
		if lv >= openlv then
			local equip = db[pos]
			local id = equip.c * 1000 + equip.lv 
			local conf = EquipConfig[id]
			if conf then
				local v = conf["attr" .. pos]
				dyAttr[attr.name] = dyAttr[attr.name] + v 
			end
		end
	end
	hero:showInfo("after Equip calcHeroDyAttrppp")
end




