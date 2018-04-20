local Hm = require("core.managers.HumanManager")
local ShopLogic = require("modules.shop.ShopLogic")

Hm:addEventListener(Hm.Event_HumanLogin,ShopLogic.onHumanLogin)
