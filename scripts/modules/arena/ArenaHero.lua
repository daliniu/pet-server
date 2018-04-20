module(...,package.seeall)
local SkillGroupConfig = require("config.SkillGroupConfig").Config
local SkillDefine = require("modules.skill.SkillDefine")

function new(cfg,i)
	local hero = {}
	hero.name = cfg["hero"..i]
	hero.lv = cfg.lv
	hero.dyAttr = {}
	for k,v in pairs(cfg["attr"..i]) do
		hero.dyAttr[k] = v
	end
	hero.skillgroup = {}
	for k,v in pairs(cfg["skill"..i]) do
		local skill = {}
		skill.groupId = k
		skill.lv = v
		skill.equipType = SkillGroupConfig[k] and SkillGroupConfig[k].equipType or SkillDefine.EQUIP_NONE
		skill.isOpen = 1
		table.insert(hero.skillgroup,skill)
	end
	hero.gift = {}
	setmetatable(hero, {__index = _M}) 
	return hero
end

function getName(self)
	return self.name
end

function getExp(self)
	return 0
end

function getQuality(self)
	return 0
end

function getTransferLv(self)
	return 0
end

function getLv(self)
	return self.lv
end

function getQuality(self)
	return self.quality or 1
end

function getGift(self)
	return self.gift
end


function getSkillGroupList(self)
	return self.skillgroup
end
