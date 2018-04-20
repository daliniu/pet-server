module(...,package.seeall)

local BaseMath = require("modules.public.BaseMath")

local SkillConfig = require("config.SkillConfig").Config
local SkillGroupConfig = require("config.SkillGroupConfig").Config
local SkillDefine = require("modules.skill.SkillDefine")
local SkillUpConfig = require("config.SkillUpConfig").Config

function new(groupId)
	local o = {
		--type = SkillDefine.TYPE_NORMAL,
		groupId = groupId,
		equipType = SkillDefine.EQUIP_NONE,
		lv = SkillDefine.MIN_SKILL_LV,		--技能等级
		isOpen = 0,							--是否已开放
		--skillList = {},					--技能列表
		exp = 0,
	}
	setmetatable(o,{__index=_M})
	o:init()
	return o
end

function init()
end

function getType(self)
	return self:getConf().type
end

function open(self)
	self.isOpen = 1
end

--装备
function equip(self,equipType)
	self.equipType = equipType or SkillDefine.EQUIP_NONE
	--self.skillList = skillList or {}
end

function isEquip(self)
	return self.equipType ~= SkillDefine.EQUIP_NONE
end

function incLv(self)
	self.lv = self.lv + 1
end

--伤害
function getAtk(self)
	local conf = self:getConf()
	local atk = 0
	for pos,v in ipairs(conf.atk) do
		atk = atk + BaseMath.getSkillAttr(self.lv,v,conf.atkBase[pos])
	end
	return atk
end

--先手值
function getOrder(self)
	return self:getConf().order
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
	local conf = self:getConf()
	return conf.hit[1]
end

function getLv(self)
	return self.lv
end

--技能升级花费
function getUpgradeCost(self,lv)
	local type = self:getType()
	local typeConf = SkillDefine.TYPE_CONF[type]
	lv = lv or self.lv
	if type == SkillDefine.TYPE_ASSISTR then
		local upType = typeConf.upType .. self.equipType
		return SkillUpConfig[lv][upType]
	else
		return SkillUpConfig[lv][typeConf.upType]
	end
end

function getCostType(self)
	return SkillDefine.TYPE_CONF[self:getType()].costType
end

function getConf(self)
	local conf = SkillGroupConfig[self.groupId]
	assert(conf,"lost skillGroup conf=====>" .. self.groupId)
	return conf
end

function getFight(self)
	local conf = SkillGroupConfig[self.groupId]
	if not conf then return 0 end
	return conf.fight * self.lv
end







