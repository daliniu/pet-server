module(...,package.seeall)

local Hm = require("core.managers.HumanManager")
local CrazyLogic = require("modules.crazy.CrazyLogic")

CrazyLogic.startCrontab()
Hm:addEventListener(Hm.Event_HumanLogin,CrazyLogic.onHumanLogin)
