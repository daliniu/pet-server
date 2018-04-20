module(...,package.seeall)

local Msg = require("core.net.Msg")

function sendSysDot(human, type)
	Msg.SendMsg(PacketID.GC_DOT, human, type)
end
