local Logic = require("modules.skill.SkillLogic")
local HM  = require("core.managers.HumanManager")


--HM:addEventListener(HM.Event_HeroCollect, Logic.onHeroCreate)
HM:addEventListener(HM.Event_HeroQualityUp, Logic.onHeroQualityUp)



