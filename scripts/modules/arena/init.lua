local Hm = require("core.managers.HumanManager")
local ArenaLogic = require("modules.arena.ArenaLogic")
local Arena = require("modules.arena.Arena")
local Crontab = require("modules.public.Crontab")
local ARENA_SORT_EVENT = 3
local ARENA_REWARD_EVENT = 5
Hm:addEventListener(Hm.Event_HumanLogin,ArenaLogic.onHumanLogin)
Hm:addEventListener(Hm.Event_FightValChange,ArenaLogic.onFightValChange)

Crontab.AddEventListener(ARENA_SORT_EVENT,Arena.refreshRank)
Crontab.AddEventListener(ARENA_REWARD_EVENT,Arena.rewardRank)
