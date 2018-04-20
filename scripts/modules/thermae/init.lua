module(...,package.seeall)

local Hm = require("core.managers.HumanManager")
local ThermaeLogic = require("modules.thermae.ThermaeLogic")

ThermaeLogic.startCrontab()
Hm:addEventListener(Hm.Event_HumanLogin,ThermaeLogic.onHumanLogin)
