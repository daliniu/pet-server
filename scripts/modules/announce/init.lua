local Hm = require("core.managers.HumanManager")
local Logic = require("modules.announce.Announce")


Hm:addEventListener(Hm.Event_HumanLogin, Logic.onHumanLogin)
--local ANNOUNT_EVENT = 4
--Crontab.AddEventListener(ANNOUNT_EVENT,Logic.doAnnouce)
