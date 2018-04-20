module(..., package.seeall)
local _msg = LuaMsgEx(_Msg)
local ProtoName = Network.ProtoName

MSG_USER_BROADCAST_LIMIT_COUNT = 200

function SendMsgByFD(packetId, fd,...)
	print("send: FD " .. packetId .. "  " .. ProtoName[packetId] .. "   " .. fd)
    return _msg:SendMsg(packetId, fd, ...)
end

function SendMsg(packetId,human,... )
	print("send:" .. packetId .. "  " .. ProtoName[packetId])
    if human.fd then
        return _msg:SendMsg(packetId, human.fd,...)
    end
	return false
end

function UserBroadCast(packetId, userList,...)
	print("send: BroadCast " .. packetId .. "  " .. ProtoName[packetId])
    if type(userList) == "table" then
        return _msg:UserBroadcast(packetId, userList,...) 
    else
        assert(false)
    end
end

--[[
function SceneBroadCastByHuman(packetId, human, bIncludeSelf,...)
	print("send: SceneBroadCast " .. packetId .. "  " .. ProtoName[packetId])
    local scene = human:getScene()
    local fdlist = {}
    for objId,obj in pairs(scene.human) do 
        if bIncludeSelf then 
            fdlist[#fdlist+1] = obj.fd
        elseif objId ~= human.id then
            fdlist[#fdlist+1] = obj.fd
        end
    end

    if #fdlist > 0 then
        return _msg:UserBroadcast(packetId,fdlist,...)
    else
        return false
    end
end

function SceneBroadCast(packetId, sceneId, ...)
	print("send: SceneBroadCast " .. packetId .. "  " .. ProtoName[packetId])
    local scene = SceneManager.SceneContainer[sceneId]
    local fdlist = {}
    for _,obj in pairs(scene.human) do
        fdlist[#fdlist+1] = obj.fd
    end
    return _msg:UserBroadcast(packetId, fdlist, ...)
end
]]

function WorldBroadCast(packetId,...)
	print("send: WorldBroadCast " .. packetId .. "  " .. ProtoName[packetId])
    return _msg:WorldBroadcast(packetId, ...)
end


function sendHttpRequest(packetId,fd,url)
	_SendHttpRequest(packetId,tonumber(fd),url)
end




