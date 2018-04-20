module(...,package.seeall)
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local PartnerLogic = require("modules.partner.PartnerLogic")

function onCGPartnerQuery(human)
	PartnerLogic.query(human)
end

function onCGPartnerCompose(human,id)
	--local ret,retCode = PartnerLogic.compose(human,id)
    --Msg.SendMsg(PacketID.GC_PARTNER_COMPOSE,human,retCode)
end

function onCGPartnerEquip(human,chainId,partnerId)
	--local ret,retCode = PartnerLogic.equip(human,chainId,partnerId)
    --Msg.SendMsg(PacketID.GC_PARTNER_EQUIP,human,retCode,chainId,partnerId)
end

function onCGPartnerActive(human,chainId)
	local ret,retCode,attrs = PartnerLogic.active(human,chainId)
    Msg.SendMsg(PacketID.GC_PARTNER_ACTIVE,human,retCode,chainId,attrs or {})
end
