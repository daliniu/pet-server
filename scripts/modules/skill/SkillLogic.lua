module(...,package.seeall)

local Msg = require("core.net.Msg")
local CommonDefine = require("core.base.CommonDefine")

local Skill = require("modules.skill.Skill")
local SkillGroup = require("modules.skill.SkillGroup")
local SkillDefine = require("modules.skill.SkillDefine")
local SkillConfig = require("config.SkillConfig").Config
local SkillGroupConfig = require("config.SkillGroupConfig").Config
local SkillExpConfig = require("config.SkillExpConfig").Config


function onHeroQualityUp(hm,event)
	local human = event.human
	local heroName = event.heroName
    local hero = human:getHero(heroName)
	local isDirty = checkSkillGroupConf(hero)
	if isDirty then
		sendSkillGroupList(hero)
	end
end

--[[
function onHeroCreate(HM,event)
	local human = event.human
	local heroName = event.heroName
    local hero = human:getHero(heroName)
	checkSkillGroupConf(hero)
end
--]]

function checkSkillGroupConf(hero,isCreate)
	local skillGroupList = hero:getSkillGroupList()
	local lv = hero:getLv()
	local heroName = hero:getName()
	local isDirty = false
	for groupId,v in pairs(SkillGroupConfig) do
		if v.hero == heroName then
			if v.autoEquip == 1 or (v.needStar <= hero:getQuality() and v.type == SkillDefine.TYPE_ASSISTR) then
				--自动上阵
				local group = skillGroupList[groupId]
				if not group then
					group = SkillGroup.new(groupId)
					group:open()
					group:equip(v.equipType)
					--[[特殊技能
					if v.type ~= SkillDefine.TYPE_NORMAL then
						group.skillList = v.skill
					end
					--]]
					skillGroupList[groupId] = group
					isDirty = true
				end
			end
		end
	end
	return isDirty
end


function isHeroSkillGroup(hero,groupId)
	local conf = SkillGroupConfig[groupId]
	return conf.hero == hero.name
end

function getSkillGroupById(hero,groupId)
	if not isHeroSkillGroup(hero,groupId) then
		return false
	end
	local skillGroupList = hero:getSkillGroupList()
	return skillGroupList[groupId]
	--[[
	if not group then
		--配置表改动
		local conf = SkillGroupConfig[groupId]
		if conf.openLv <= hero:getLv() then
			group = SkillGroup.new(groupId)
			group:open()
			skillGroupList[groupId] = group
		end
	end
	return group 
	--]]
end

function getSkillGroupByType(hero,type,equipType)
	local skillGroupList = hero:getSkillGroupList()
	equipType = equipType or SkillDefine.EQUIP_A
	for _,group in pairs(skillGroupList) do
		if group:getType() == type and equipType == group.equipType then
			return group
		end
	end
end

function equip(hero,equipType,groupId)
	local group = getSkillGroupById(hero,groupId)
	if not group then
		return SkillDefine.ERROR_CODE.NOT_HERO_SKILL
	end
	local lastGroup = getSkillGroupByType(hero,group:getType(),equipType)
	if lastGroup then
		--替换旧技能组
		lastGroup:equip()
	end
	group:equip(equipType)
	return CommonDefine.OK
end

function makeSkillGroupMsg(group,list)
	list[#list+1] = {
		groupId=group.groupId,
		lv=group.lv,
		equipType=group.equipType,
		isOpen=group.isOpen,
		exp = group.exp,
		--skillList = group.skillList,
	}
	return list
end

function sendSkillGroupList(hero)
	local groupList = hero:getSkillGroupList()
	local groupMsg = {}
	for _,group in pairs(groupList) do
		makeSkillGroupMsg(group,groupMsg)
	end
	Msg.SendMsg(PacketID.GC_SKILL_QUERY,hero:getHuman(),hero.name,groupMsg)
end

function sendAllSkillList(human)
	local heroes = human:getAllHeroes()
	local groupMsg = {}
	for _,hero in pairs(heroes) do 
		local groupList = hero:getSkillGroupList()
		local msg = {}
		for _,group in pairs(groupList) do
			makeSkillGroupMsg(group,msg)
		end
		groupMsg[#groupMsg+1] = {
			heroName = hero.name,
			skillGroupList = msg,
		}
	end
	Msg.SendMsg(PacketID.GC_SKILL_ALL,human,groupMsg)
end

--开放技能
function openSkillGroup(hero,groupId)
	local skillGroupList = hero:getSkillGroupList()
	local conf = SkillGroupConfig[groupId]
	local group = SkillGroup.new(groupId)
	group:open()
	assert(not skillGroupList[groupId],"error==>has group==>" .. groupId)
	skillGroupList[groupId] = group
	hero:calcFight()
	return true
end

function getExp(hero,type)
	local expList = hero.db.skill.expSkillGroup
	for _,v in pairs(expList) do
		if type == v.type then
			return v
		end
	end
	return 0
end

--增加经验
function addExp(hero, group ,exp)
	local hasLvUp = false
	group.exp = group.exp or 0
	group.exp = group.exp + exp
	local maxExp = getSkillUpExp(group.groupId,group.lv+1) 
	if not maxExp then	--满级
		return hasLvUp
	end
	while maxExp <= group.exp do
		if (group.lv + 1) <= SkillDefine.MAX_LV then
			group.lv = group.lv + 1
			group.exp = group.exp - maxExp
			maxExp = getSkillUpExp(group.groupId,group.lv+1) 
			hasLvUp = true
		else
			break
		end
	end
	return hasLvUp
end

function getSkillUpExp(groupId,lv)
	local conf = SkillGroupConfig[groupId]
	local typeM = "assist"
	if conf.type == SkillDefine.TYPE_FINAL then
		typeM = "final"
	end
	if not SkillExpConfig[lv] then
		return false
	end
	return SkillExpConfig[lv][typeM]
end

--获得所有上阵技能
function getEquipSkillGroup(hero,type)
	local list = {}
	local listData = hero:getSkillGroupList()
	for _,v in pairs(listData) do
		if (v:getType() == type or not type) and v:isEquip() then
			list[#list+1] = v
		end
	end
	return list
end








