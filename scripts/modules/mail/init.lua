local Hm = require("core.managers.HumanManager")
local MailLogic = require("modules.mail.MailLogic")

Hm:addEventListener(Hm.Event_HumanLogin,MailLogic.onHumanLogin)
Hm:addEventListener(Hm.Event_HumanCreate,MailLogic.onHumanCreate)
