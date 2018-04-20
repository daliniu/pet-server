local Hm = require("core.managers.HumanManager")
local GuildManager = require("modules.guild.GuildManager")
local Crontab = require("modules.public.Crontab")
local WineLogic = require("modules.guild.wine.WineLogic")
local KickLogic = require("modules.guild.kick.KickLogic")
local BossLogic = require("modules.guild.boss.BossLogic")
local Boss = require("modules.guild.boss.Boss")
local GUILD_SORT_EVENT = 3
local GUILD_REFRESH_DAY = 1
local GUILD_BOSS = 10

Hm:addEventListener(Hm.Event_DecPhysics, GuildManager.onHumanDecPhysics)
Hm:addEventListener(Hm.Event_DecEnergy, GuildManager.onHumanDecEnergy)
Hm:addEventListener(Hm.Event_HumanLogin,WineLogic.onHumanLogin)
Hm:addEventListener(Hm.Event_HumanLogin,KickLogic.onHumanLogin)
Hm:addEventListener(Hm.Event_HumanDBLoad, WineLogic.onHumanDBLoad)

Crontab.AddEventListener(GUILD_SORT_EVENT,GuildManager.reSortGuild)
Crontab.AddEventListener(GUILD_REFRESH_DAY,GuildManager.refreshDayActive)
Crontab.AddEventListener(GUILD_BOSS,BossLogic.startBoss)
--BossLogic.startBoss()
Boss.initConfig()
