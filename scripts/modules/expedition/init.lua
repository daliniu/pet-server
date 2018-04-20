local Define = require("modules.expedition.ExpeditionDefine")
local Util = require("core.utils.Util")
local Logic = require("modules.expedition.ExpeditionLogic")
local HumanManager = require("core.managers.HumanManager")

HumanManager:addEventListener(HumanManager.Event_HumanDBLoad, Logic.onHumanDBLoad)
HumanManager:addEventListener(HumanManager.Event_HumanLogin, Logic.onHumanLogin)
HumanManager:addEventListener(HumanManager.Event_HumanLvUp, Logic.onHumanLvUp)
HumanManager:addEventListener(HumanManager.Event_HeroCollect, Logic.onAddHero)
