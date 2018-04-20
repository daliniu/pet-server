local HM  = require("core.managers.HumanManager")
local Logic = require("modules.newopen.NewOpenLogic")

HM:addEventListener(HM.Event_HumanLogin,Logic.onHumanLogin)
