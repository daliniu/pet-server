local Hm = require("core.managers.HumanManager")
local Logic = require("modules.weapon.WeaponLogic")

Hm:addEventListener(Hm.Event_HumanLogin, Logic.onHumanLogin)
