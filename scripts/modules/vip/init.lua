local Logic = require("modules.vip.VipLogic")
local HumanManager = require("core.managers.HumanManager")
local VipLevelLogic = require("modules.vip.VipLevelLogic")

HumanManager:addEventListener(HumanManager.Event_HumanDBLoad, Logic.onHumanDBLoad)
HumanManager:addEventListener(HumanManager.Event_HumanLogin, Logic.onHumanLogin)
HumanManager:addEventListener(HumanManager.Event_HumanLogin, VipLevelLogic.onHumanLogin)