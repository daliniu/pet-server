module(..., package.seeall)
local AnnounceConfig = require("config.AnnounceConfig").Config
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")

local Define = require("modules.announce.AnnounceDefine")

local ns = "announce"

AnnounceList = AnnounceList or {}

function init()
	loadDB()
end

function loadDB()
    local pCursor = g_oMongoDB:SyncFind(ns,{})
	if not pCursor then
		return true
	end
	local cursor = MongoDBCursor(pCursor)
	while true do
		local row = {}
		if not cursor:Next(row) then
			break
		end
		if not row.isDeleted then
			if tonumber(row.endTime) >= os.time() then
				AnnounceList[row.id] = row
			end
		end
	end
end

function onHumanLogin(hm,human)
	local announceId = human.db.announceId
	local list = {}
	for id,v in pairs(AnnounceList) do
		if not v.isDeleted then
			if tonumber(v.endTime) >= os.time() then
				makeAnnounceMsg(v,list)
			end
		end
	end
	if next(list) then
    	Msg.SendMsg(PacketID.GC_ANNOUNCE_QUERY,human,list)
	end
end

function makeAnnounceMsg(row,list)
	local announce = {}
	announce.id        = row.id
	announce.type      = tonumber(row.type)
	announce.pos       = tonumber(row.pos)
	announce.startTime = tonumber(row.startTime)
	announce.endTime   = tonumber(row.endTime)
	announce.hour      = tonumber(row.hour)
	announce.min       = tonumber(row.min)
	announce.interval  = tonumber(row.interval)
	announce.title     = row.title 
	announce.content   = row.content 
	list[#list+1] = announce
end

function addAnnouceFromAdmin(input)
	local announce = addAnnouce(input)
	if announce.type ~= Define.TYPE_ONCE then
		--save
		AnnounceList[input.id] = announce
	end
end

function delAnnounceFromAdmin(id)
	if AnnounceList[id] then
		--软删除
		AnnounceList[id].isDeleted = true
		Msg.WorldBroadCast(PacketID.GC_ANNOUNCE_DEL,id)
		return id
	end
	return -1
end


--type:type=1定时播放,type=2循环播放,type=3立即播放,type=4登录公告
--pos:播放位置，前端使用,暂时不用
--title:标题
--content:内容
--starttime:开启时间
--endtime:结束时间
--@todo period:循环周期,period=1每日，period=2每周，period=3每个月
--@todo wdays:星期几,(wday, 1 is Sunday),数组
--@todo days:日期-日,数组
--@todo periodTime:循环时间
--hour,min:每天定时播放时间，type=1时有效
--interval:循环播放间隔时间(/分钟),type=2时有效
function addAnnouce(input,human)
	local announce = {}
	announce.id 	   = input.id or 0	
	announce.type      = tonumber(input.type) or Define.TYPE_ONCE
	announce.pos       = tonumber(input.pos) or 1
	announce.startTime = tonumber(input.startTime) or -1
	announce.endTime   = tonumber(input.endTime) or -1
	announce.hour      = tonumber(input.hour) or -1
	announce.min       = tonumber(input.min) or -1
	announce.interval  = tonumber(input.interval) or 1440
	announce.title     = input.title or ""
	announce.content   = input.content or ""
	--[[
	if announce.type ~= Define.TYPE_ONCE then
		announce.id 	   = getId()
		AnnounceList[announce.id]   = announce
	end
	if announce.type == Define.TYPE_LOGIN then
		--登录公告唯一
		delAnnounce(LoginAnnounceId)
		LoginAnnounceId = announce.id
	end
	--]]
	local list = {}
	makeAnnounceMsg(announce,list)
	if human then
		Msg.SendMsg(PacketID.GC_ANNOUNCE_ADD,human,list)
	else
		Msg.WorldBroadCast(PacketID.GC_ANNOUNCE_ADD,list)
	end
	return announce
end

function addAnnounceById(human,id,...)
	local announce = AnnounceConfig[id]
	if not announce then
		return
	end
	announce = Util.deepCopy(announce)
	announce.content = string.format(announce.content,...)
	return addAnnouce(announce,human)
end


function saveAll()
	local begin = _USec()         
	for id,v in pairs(AnnounceList) do
		local query = {id=id}
		local pCursor = g_oMongoDB:SyncFind(ns,query)
		if pCursor then
			local cursor = MongoDBCursor(pCursor)
			if not cursor:Next({}) then
				g_oMongoDB:SyncInsert(ns,v)
			else
				g_oMongoDB:SyncUpdate(ns,query,v)
			end
		end
	end
	print("Announce:save::"..(_USec()-begin))
end



