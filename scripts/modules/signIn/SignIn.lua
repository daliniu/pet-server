module(...,package.seeall)

local SignInConfig = require("config.SignInActivityConfig").Config
local Msg = require("core.net.Msg")
local Hm = require("core.managers.HumanManager")
local Util = require("core.utils.Util")
local PublicLogic = require("modules.public.PublicLogic")
local BagLogic = require("modules.bag.BagLogic")
local ShopDefine = require("modules.shop.ShopDefine")
local MailManager = require("modules.mail.MailManager")

function onHumanLogin(hm,human)
	local db = human.db.signIn
	Msg.SendMsg(PacketID.GC_SIGN_IN_INFO, human, db.month, db.info)
	return true
end

Hm:addEventListener(Hm.Event_HumanLogin,onHumanLogin)

