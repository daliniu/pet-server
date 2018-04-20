local Hm = require("core.managers.HumanManager")
local BagLogic = require("modules.bag.BagLogic")

Hm:addEventListener(Hm.Event_HumanCreate,BagLogic.onHumanCreate)
Hm:addEventListener(Hm.Event_HumanLogin,BagLogic.onHumanLogin)
