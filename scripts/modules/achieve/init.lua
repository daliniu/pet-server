local Logic = require("modules.achieve.AchieveLogic")
local HumanManager = require("core.managers.HumanManager")

Logic.classifyConfig()
Logic.addListener()

HumanManager:addEventListener(HumanManager.Event_HumanDBLoad, Logic.onHumanDBLoad)
HumanManager:addEventListener(HumanManager.Event_HumanLogin, Logic.onHumanLogin)
