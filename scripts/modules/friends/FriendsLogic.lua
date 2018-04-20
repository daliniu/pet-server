module(...,package.seeall)
local Msg = require("core.net.Msg")
local Friends = require("modules.friends.Friends")
local Config = require("config.FriendConfig").FriendConfig
local FriendsDefine = require("modules.friends.FriendsDefine")
local Arena = require("modules.arena.Arena")

function RecommendList(human)
	local List = {}
	local conf = Config[1].condition
	local allOnline = HumanManager.getAllOnline()
	local index = 0

	for _,humanInfo in pairs(allOnline) do
		local data = {}
		if index < conf.num then
			if math.abs(humanInfo.db.lv-human.db.lv) <= conf.range and humanInfo.db.account ~= human.db.account and not Friends.checkIsFriend(humanInfo.db.account,human.db.account) then 
				index = index+1
				data.id = humanInfo.db.account
				data.name = humanInfo.db.name
				data.lv = humanInfo.db.lv
				data.fighting = Arena.getArenaFightVal(humanInfo.db.account)
				data.icon = humanInfo.db.bodyId
				table.insert(List,data)
			end
		else
			break
		end
	end

	local rankList = Arena.RankList
	for _,obj in pairs(rankList) do
		local data = {}
		local isAdd = false
		if index < conf.num then
			for i,v in ipairs(List) do
				if v.id == obj.account then 
					isAdd = true
				end
			end
			local myFightVal = Arena.getArenaFightVal(human.db.account)
			if not Arena.isRobot(obj.account) and math.abs(obj.fightVal-myFightVal) <= conf.ft and obj.account ~= human.db.account and not Friends.checkIsFriend(obj.account,human.db.account) and not isAdd then 
				index = index+1
				local humanInfo =  HumanManager.getOnline(obj.account) or HumanManager.loadOffline(obj.account)
				if humanInfo == nil then 
					return
				end 
				data.id = humanInfo.db.account
				data.name = humanInfo.db.name
				data.lv = humanInfo.db.lv
				data.fighting = Arena.getArenaFightVal(humanInfo.db.account)
				data.icon = humanInfo.db.bodyId
				table.insert(List,data)
			end
		else
			break
		end
	end
	return List
	-- body
end 

function addRank(human,id)
	if Friends.addRank(human,id) then
		local humanBy = HumanManager.getOnline(id)
		if humanBy then 
			Msg.SendMsg(PacketID.GC_FRIEND_MES,humanBy)
		end 
		return FriendsDefine.ADD_STATUS.kOk
	else
		return FriendsDefine.ADD_STATUS.kErr
	end
end

function ApplyList(human)
	local data = Friends.getByApplyList(human)
	return data
end

function FriendsList(human)
	local data = Friends.getFriendsList(human)
	return data
end


function FriendAccept(human,id)
	if Friends.updateRank(human,id) then
		return FriendsDefine.OP_STATUS.kOk
	else
		return FriendsDefine.OP_STATUS.kErr
	end
end

function FriendDel(human,id)
	if Friends.delRank(human,id) then
		return FriendsDefine.DEL_STATUS.kOk
	else
		return FriendsDefine.DEL_STATUS.kErr
	end
end

function FriendReject(human,id)
	if Friends.delRank(human,id) then
		return FriendsDefine.REJECT_STATUS_TIPS.kOk
	else
		return FriendsDefine.REJECT_STATUS_TIPS.kErr
	end
end

function Friend_query(human,name)
	local data = {}
	local humanInfo = HumanManager.getOnline(nil,name) or HumanManager.loadOffline(nil,name)
	if nil == humanInfo or humanInfo.db.account == human.db.account then
		return data
	end
	data.id = humanInfo.db.account
	data.name = humanInfo.db.name
	data.lv = humanInfo.db.lv
	data.fighting = Arena.getArenaFightVal(humanInfo.db.account)
	data.icon = humanInfo.db.bodyId
	
	return data
end
