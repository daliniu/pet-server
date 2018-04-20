local Hm = require("core.managers.HumanManager")
local EquipLogic = require("modules.equip.EquipLogic")

Hm:addEventListener(Hm.Event_HumanLogin,EquipLogic.onHumanLogin)
