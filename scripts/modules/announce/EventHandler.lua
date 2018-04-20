module(..., package.seeall)
local AnnounceConfig = require("config.AnnounceConfig").Config
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")

function onCGAnnounceQuery(human)
	local lastId = AnnounceConfig[#AnnounceConfig].id
	local isFirst = 0
	if lastId ~= human.db.announceId then
		human.db.announceId = lastId
		isFirst = 1
	end
    Msg.SendMsg(PacketID.GC_ANNOUNCE_QUERY,human,lastId,isFirst)
end
