module(...,package.seeall)

local EquipLogic = require("modules.equip.EquipLogic")

function onCGEquipList(human, heroName)
	local hero = human:getHero(heroName)
	if hero then
		EquipLogic.sendEquipList(hero)
	end
	return true
end

function onCGEquipLvUp(human, heroName, pos, cnt)
	EquipLogic.lvUp(human, heroName, pos, cnt)
	return true
end


function onCGEquipColorUp(human, heroName, pos)
	EquipLogic.colorUp(human, heroName, pos)
	return true
end
