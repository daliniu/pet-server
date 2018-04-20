local Handbook = require("modules.handbook.Handbook")
require("modules.handbook.HandbookDefine")
local Hm = require("core.managers.HumanManager")

Hm:addEventListener(Hm.Event_HumanLogin,Handbook.onHumanLogin)
Hm:addEventListener(Hm.Event_HumanDBLoad, Handbook.onDBLoaded)
