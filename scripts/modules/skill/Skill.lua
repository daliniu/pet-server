module(...,package.seeall)

local BaseMath = require("modules.public.BaseMath")

local SkillConfig = require("config.SkillConfig").Config
local SkillDefine = require("modules.skill.SkillDefine")
--local SkillDefine = require("src/modules/skill/SkillDefine")

function new(skillId)
	local o = {
		type = SkillDefine.TYPE_NORMAL,			--技能类型
		skillId = skillId,
		equipType = SkillDefine.EQUIP_NONE,
		lv = SkillDefine.MIN_SKILL_LV,		--技能等级
		pos = 0,							--装备位置
		isOpen = 0,							--是否已开放
		canOpen = false,					--能否开放
	}
	setmetatable(o,{__index=_M})
	return o
end

function isFinalSkill(self)
	return self.type == SkillDefine.TYPE_FINAL
end

function isAssistSkill(self)
	return self.type == SkillDefine.TYPE_ASSIST
end


--技能是否已开放
function checkIsOpen(self)
	return self.isOpen == 1
end

function getSkillLv(self)
	return self.lv
end

--装备
function equip(self,equipType,pos)
	self.equipType = equipType or SkillDefine.EQUIP_NONE
	self.pos = pos or 0
end

function incLv(self)
	self.lv = self.lv + 1
end

function open(self)
	self.isOpen = 1
end

function unload(self)
	self.equipType = SkillDefine.EQUIP_NONE
end

--伤害
function getAtk(self)
	return BaseMath.getSkillAttr(self.lv,self:getConf().atk)
end

--先手值
function getOrder(self)
	return 5
	--return BaseMath.getSkillAttr(self.lv,self:getConf().order)
end

--cost值
function getCost(self)
	--return BaseMath.getSkillAttr(self.lv,self:getConf().cost)
	return self:getConf().cost
end

--命中
function getHit(self)
	--return BaseMath.getSkillAttr(self.lv,self:getConf().hit)
	return self:getConf().hit
end

function getLv(self)
	return self.lv
end

--技能升级花费
function getUpgradeCost(self)
	return BaseMath.getSkillUpgradeCost(self.lv + 1)
end


function getConf(self)
	local conf = SkillConfig[self.skillId]
	assert(conf,"lost skill conf=====>" .. self.skillId)
	return conf
end











