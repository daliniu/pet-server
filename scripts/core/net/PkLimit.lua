--[[
_SetPkLimit(PacketID.CG_CHAT, 3, 2)表示3秒2次
_SetPkLimit(PacketID.CG_CHAT, 3, 0)表示该功能在维护中
_SetPkLimit(PacketID.CG_CHAT, 0, 2)表示无限制
--]]

module(..., package.seeall)
local PacketID = require("PacketID")

local HashID = 0
for k, v in pairs(PacketID) do
	if k:sub(1, 3) == "CG_" then
		HashID = HashID + 1
		_SetHashPk(v, HashID)
		_SetPkLimit(v, 1, 4)	--默认所有的CG协议1秒4次
	end
end

_SetPkLimit(PacketID.CG_HEART_BEAT, 10, 1)
_SetPkLimit(PacketID.CG_ASK_LOGIN, 1, 1)
_SetPkLimit(PacketID.CG_ITEM_USE, 1, 5)
--_SetPkLimit(PacketID.CG_HUMAN_QUERY, 1, 8)
