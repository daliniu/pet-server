module(...,package.seeall)
local Arena = require("modules.arena.Arena")
local ArenaLogic = require("modules.arena.ArenaLogic")
local Config = require("config.FriendConfig").FriendConfig

local ns = 'friends'
FriendsList = FriendsList or {}
Account2Rank = Account2Rank or {}
UpRank = UpRank or {}
UserFriendsList = UserFriendsList or {}
ApplyList = ApplyList or {}
ByApplyList = ByApplyList or {}

index = index or 1

-----db 操作接口 begin--------
function init()
	loadDB()
	local cleanTimer = Timer.new(30*60*1000,-1)
	cleanTimer:setRunner(save)
	cleanTimer:start()
end

function loadDB()
	local pCursor = g_oMongoDB:SyncFind(ns,{});
	if not pCursor then 
		return true
	end
	local cursor = MongoDBCursor(pCursor)
	while(true) do
		local tmp = {}
		if not cursor:Next(tmp) then
			break
		end
		--table.insert(FriendsList,tmp)
		FriendsList[tmp.rank] = tmp
		if index < tmp.rank then 
			index = tmp.rank
		end 
		Account2Rank[tmp.account.."#"..tmp.accountBy] = tmp.rank
		Account2Rank[tmp.accountBy.."#"..tmp.account] = tmp.rank

		UserFriendsList[tmp.account] = UserFriendsList[tmp.account] or {}
		table.insert(UserFriendsList[tmp.account],tmp.rank)
		UserFriendsList[tmp.accountBy] = UserFriendsList[tmp.accountBy] or {}
		table.insert(UserFriendsList[tmp.accountBy],tmp.rank)
	end
	--table.sort(FriendsList,function(a,b)return a.rank < b.rank end)
	--print("Arena:loadDB::"..(_USec()-begin))
end

function save(isSync)
	for i=1,#UpRank do
		local data = FriendsList[UpRank[i]]
		print("UpRank===>",UpRank[i])
		if data then 
			DB.Insert(ns,data,isSync) 
		end 
	end
	UpRank = {}
    return true
end

function addRank(human,id)
	if ApplyList[human.db.account] == nil and UserFriendsList[human.db.account] then 
		if #UserFriendsList[human.db.account] + 1 > Config[1].numMax then
			return false
		end
	end 

	if UserFriendsList[human.db.account] == nil and ApplyList[human.db.account] then 
		if #ApplyList[human.db.account] + 1 > Config[1].numMax then
			return false
		end
	end 

	if UserFriendsList[human.db.account] and ApplyList[human.db.account] then 
		if #UserFriendsList[human.db.account] + 1 + #ApplyList[human.db.account] > Config[1].numMax then
			return false
		end
	end 

	if Account2Rank[human.db.account.."#"..id] or Account2Rank[id.."#"..human.db.account] then 
		return false
	end

	if ApplyList[human:getAccount()] then
		for _,account in pairs(ApplyList[human:getAccount()]) do
			if account == id then
				--已申请
				return false
			end
		end
	end
	if ByApplyList[human:getAccount()] then
		for _,account in pairs(ByApplyList[human:getAccount()]) do
			if account == id then
				--已申请
				return false
			end
		end
	end
 
	ByApplyList[id] = ByApplyList[id] or {}
	ApplyList[human.db.account] = ApplyList[human.db.account] or {}
	if #ByApplyList[id] > 50 then
		table.remove(ByApplyList[id],1)
	end
	if #ApplyList[human.db.account] > 50 then
		table.remove(ApplyList[human.db.account],1)
	end
	table.insert(ByApplyList[id],human:getAccount())
	table.insert(ApplyList[human.db.account],id)
	return true
end

function getFriendsList(human)
	local List = {}
	local tmp = UserFriendsList[human.db.account]
	if tmp == nil then 
		return
	end

	for i=1,#tmp do
		if FriendsList[tmp[i]] then 
			local data = {}
			local temp = {}
			if  FriendsList[tmp[i]].account == human.db.account then 
				local returnHuman = HumanManager.getOnline(FriendsList[tmp[i]].accountBy) or HumanManager.loadOffline(FriendsList[tmp[i]].accountBy)
				data.id = FriendsList[tmp[i]].accountBy
				data.name = returnHuman.db.name
				data.lv = returnHuman.db.lv
				data.fighting = Arena.getArenaFightVal(FriendsList[tmp[i]].accountBy)
				data.icon = returnHuman.db.bodyId
				data.arena = ArenaLogic.makeByIdEnemyData(FriendsList[tmp[i]].accountBy)

				if HumanManager.getOnline(FriendsList[tmp[i]].accountBy) == nil then 
					data.isOnline = 0
				else
					data.isOnline = 1
		   		 end

			else 
				local returnHuman = HumanManager.getOnline(FriendsList[tmp[i]].account) or HumanManager.loadOffline(FriendsList[tmp[i]].account)
				data.id = FriendsList[tmp[i]].account
				data.name = returnHuman.db.name
				data.lv = returnHuman.db.lv
				data.fighting = Arena.getArenaFightVal(FriendsList[tmp[i]].account)
				data.icon = returnHuman.db.bodyId
				data.arena = ArenaLogic.makeByIdEnemyData(FriendsList[tmp[i]].account)
				
				if HumanManager.getOnline(FriendsList[tmp[i]].account) == nil then 
					data.isOnline = 0
				else
					data.isOnline = 1
		 	   end
			end

			table.insert( List, data )
		else 
			print("=======================================================好友数据出现错误")
		end
	end
	return List;
end

function getByApplyList(human)
	local List = {}
	local accountList = ByApplyList[human.db.account]
	if not accountList or not next(accountList) then 
		return
	end
	for _,account in pairs(accountList) do
		local data = {}
		local returnHuman = HumanManager.getOnline(account) or HumanManager.loadOffline(account)
		data.id = account
		data.name = returnHuman.db.name
		data.lv = returnHuman.db.lv
		data.fighting = Arena.getArenaFightVal(account)
		data.icon = returnHuman.db.bodyId
		table.insert( List, data )
	end
	return List;
end

function checkIsFriend(accountA,accountB)
	local rank = Account2Rank[accountA.."#"..accountB] or Account2Rank[accountB.."#"..accountA]
	if rank == nil then 
		return false
	else 
		return true
	end
end

function delRank(human,targetAccount)
	local rank = Account2Rank[human.db.account.."#"..targetAccount] or Account2Rank[targetAccount.."#"..human.db.account]
	local account = human.db.account
	Account2Rank[account.."#"..targetAccount] = nil
	Account2Rank[targetAccount.."#".. account] = nil
	if FriendsList[rank] then 
		FriendsList[rank] = nil
	end 

	if UserFriendsList[account] ~= nil then 
		for i,v in pairs(UserFriendsList[account]) do
			if v == rank then 
				table.remove(UserFriendsList[account],i)
			end
		end
	end
	
	if UserFriendsList[targetAccount] ~= nil then 
		for i,v in pairs(UserFriendsList[targetAccount]) do
			if v == rank then 
				table.remove(UserFriendsList[targetAccount],i)
			end
		end
	end

	if ByApplyList[account] then
		for i,v in pairs(ByApplyList[account]) do
			if v == targetAccount then 
				table.remove(ByApplyList[account],i)
			end
		end
	end	
	 
	if ApplyList[targetAccount] then 
		for i,v in pairs(ApplyList[targetAccount]) do
			if v == account then 
				table.remove(ApplyList[targetAccount],i)
			end
		end
	end
	--delete db
	local query = {rank = rank}
	return DB.Delete(ns,query)
end

function updateRank(human,account)
	if ApplyList[human.db.account] == nil and UserFriendsList[human.db.account] then 
		if #UserFriendsList[human.db.account] + 1 > Config[1].numMax then
			return false
		end
	end 

	if UserFriendsList[human.db.account] == nil and ApplyList[human.db.account] then 
		if #ApplyList[human.db.account] + 1 > Config[1].numMax then
			return false
		end
	end 

	if UserFriendsList[human.db.account] and ApplyList[human.db.account] then 
		if #UserFriendsList[human.db.account] + 1 + #ApplyList[human.db.account] > Config[1].numMax then
			return false
		end
	end 

	if Account2Rank[human.db.account.."#"..account] or Account2Rank[account.."#"..human.db.account] then 
		--已经是好友
		return false
	end
	--local rank = Account2Rank[human.db.account.."#"..account] or Account2Rank[account.."#"..human.db.account]
	--local ret = false
	--if FriendsList[rank] == nil then 
	--	return false
	--end
	index = index +1
	FriendsList[index] = newFriendRankDB(human,account,index)
	local rank = index
	Account2Rank[human.db.account.."#".. account] = rank
	Account2Rank[account.."#"..human.db.account] = rank

	table.insert(UpRank,rank) 
	UserFriendsList[human.db.account] = UserFriendsList[human.db.account] or {}
	table.insert(UserFriendsList[human.db.account],rank)
	UserFriendsList[account] = UserFriendsList[account] or {}
	table.insert(UserFriendsList[account],rank)
	for i,v in pairs(ByApplyList[human.db.account]) do
		if v == account then 
			print("remove====>",account)
			table.remove(ByApplyList[human.db.account],i)
			ret = true
		end
	end

	for i,v in pairs(ApplyList[account]) do
		if v == human:getAccount() then 
			table.remove(ApplyList[account],i)
			ret = true
		end
	end
	return ret
	--table.insert(human.db.FriendsDB,rank)
end

function newFriendRankDB(human,id,rank)
	humanBy = HumanManager.getOnline(id) or HumanManager.loadOffline(id)
	local db = {
		account = human.db.account,
		lv =  human.db.lv,
		name = human.db.name,
		fighting = Arena.getArenaFightVal(human.db.account),
		icon = human.db.bodyId,

		accountBy = humanBy.db.account,
		lvBy =  humanBy.db.lv,
		nameBy = humanBy.db.name,
		fightingBy = Arena.getArenaFightVal(id),
		iconBy = humanBy.db.bodyId,

		rank = rank,
	}
	return db
end

--[[function addRank(human,fightList)
	if Account2Rank[human.db.account] then
        LogErr("[error]", string.format("Arena addRank a exist account:%s", human.db.account))
		return
	end
	table.insert(RankList,newArenaRankDB(human,fightList,#RankList+1))
	local rank = #RankList
	Account2Rank[human.db.account] = rank
	refreshEnemy(human)
	if not saveAdd(rank) then
		return 
	end
	return RankList[rank]
end]]
