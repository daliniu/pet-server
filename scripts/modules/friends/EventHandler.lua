module(...,package.seeall)
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local Logic = require("modules.friends.FriendsLogic")
local Friends = require("modules.friends.Friends")

function onCGRecommendList(human)
	local  list = Logic.RecommendList(human);
	Msg.SendMsg(PacketID.GC_RECOMMEND_LIST,human,list)
 	-- body
end 

function onCGFriendList(human)
	local  list =  Logic.FriendsList(human);
	Msg.SendMsg(PacketID.GC_FRIEND_LIST,human,list)
end 

function onCGFriendQuery(human,name)
 	local data = Logic.Friend_query(human,name)
 	Msg.SendMsg(PacketID.GC_FRIEND_QUERY,human,data)
end 

function onCGFriendAdd( human,id )
	local ret = Logic.addRank(human,id)
	Msg.SendMsg(PacketID.GC_FRIEND_ADD,human,ret)
end


function onCGApplyList(human)
	local  list =  Logic.ApplyList(human);
	Msg.SendMsg(PacketID.GC_APPLY_LIST,human,list)
end

function onCGApplyList(human)
	local  list =  Logic.ApplyList(human);
	Msg.SendMsg(PacketID.GC_APPLY_LIST,human,list)
end

function onCGFriendAccept(human,id)
	local  ret =  Logic.FriendAccept(human,id);
	Msg.SendMsg(PacketID.GC_FRIEND_ACCEPT,human,ret)
end

function onCGFriendDel( human,id )
	-- body
	local  ret =  Logic.FriendDel(human,id);
	Msg.SendMsg(PacketID.GC_FRIEND_DEL,human,ret)
	
end

function onCGFriendReject( human,id )
	-- body
	local  ret =  Logic.FriendReject(human,id);
	Msg.SendMsg(PacketID.GC_FRIEND_REJECT,human,ret)
	
end