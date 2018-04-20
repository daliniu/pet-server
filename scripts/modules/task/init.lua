local Logic = require("modules.task.TaskLogic")
local HM  = require("core.managers.HumanManager")


Logic.addTaskListener()
HM:addEventListener(HM.Event_HumanDBLoad, Logic.onDBLoad)
HM:addEventListener(HM.Event_HumanLogin, Logic.onHumanLogin)



