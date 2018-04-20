local Hm = require("core.managers.HumanManager")
local Logic = require("modules.guide.GuideLogic")

Hm:addEventListener(Hm.Event_HumanLogin, Logic.onHumanLogin)
