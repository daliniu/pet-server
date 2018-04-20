local Hm = require("core.managers.HumanManager")
local DB = require("modules.trial.TrialDB")
local Logic = require("modules.trial.TrialLogic")
local Rank = require("modules.trial.TrialRank")

Hm:addEventListener(Hm.Event_HumanDBLoad, DB.setMeta)
Hm:addEventListener(Hm.Event_HumanLogin, Logic.onHumanLogin)
Hm:addEventListener(Hm.Event_HumanLvUp, Rank.onHumanLvUp)


