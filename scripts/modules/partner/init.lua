local Logic = require("modules.partner.PartnerLogic")
local HM  = require("core.managers.HumanManager")

Logic.init()
HM:addEventListener(HM.Event_HumanDBLoad, Logic.onDBLoad)
HM:addEventListener(HM.Event_HumanLogin,Logic.onHumanLogin)
