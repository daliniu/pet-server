local Hm = require("core.managers.HumanManager")
local DB = require("modules.orochi.OrochiDB")
local Logic = require("modules.orochi.OrochiLogic")
local Crontab = require("modules.public.Crontab")

local RANK_REWARD_EVENT = 1

Hm:addEventListener(Hm.Event_HumanDBLoad, DB.setMeta)
Hm:addEventListener(Hm.Event_HumanLogin, Logic.onHumanLogin)

--Crontab.AddEventListener(RANK_REWARD_EVENT,Logic.sendRankReward)

