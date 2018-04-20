module(...,package.seeall)

local SkillDefine = require("modules.skill.SkillDefine")
local Skill = require("modules.skill.Skill")
local SkillGroup = require("modules.skill.SkillGroup")

function new()
	local o = {
		skillGroup = {},
	}
	return o
end

function init(heroDB)
	if not heroDB.skill then
		heroDB.skill = new()
	end
	local skillDB = heroDB.skill
	DB.dbSetMetatable(skillDB.skillGroup)
	for _,group in pairs(skillDB.skillGroup) do
		setmetatable(group,{__index=SkillGroup})
	end
end


