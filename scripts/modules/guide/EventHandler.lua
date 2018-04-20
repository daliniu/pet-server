module(...,package.seeall)

local Logic = require("modules.guide.GuideLogic")


--引导
function onCGGuide(human, guideId)
	Logic.saveGuide(human, guideId)
end

function onCGGuideAll(human)
	Logic.saveAllGuide(human)
end
