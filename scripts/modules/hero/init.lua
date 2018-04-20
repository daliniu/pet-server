local Hm = require("core.managers.HumanManager")
local HeroManager = require("modules.hero.HeroManager")

Hm:addEventListener(Hm.Event_HumanCreate,HeroManager.onHumanCreate)
Hm:addEventListener(Hm.Event_HumanLogin,HeroManager.onHumanLogin)
