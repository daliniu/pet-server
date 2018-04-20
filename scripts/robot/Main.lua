print = _print
--print = function(...) end
for k, v in pairs(package.loaded) do
    package.loaded[k] = nil
end

SERVER_IP = "192.168.1.245"
SERVER_IP = "192.168.1.245"
SERVER_IP = "192.168.1.245"
SERVER_PORT = 4399
HEARTBEAT = 1000000

-- 0 移动、战斗、聊天：高并发压力
-- 1 网络、同步：高压力下，是否有明显同步问题。
-- 2 登录、登出：测在线的稳定性
-- 3 db：高压力下数据库表现

function dump(...)
    local tbls = {}
    local function _dump(as, ind)
        for k, a in pairs(as) do
            if type(a) == "table" and tbls[tostring(a)] then
                _print(ind .. type(k) .. "(" .. tostring(k) .. ") = " 
                    .. type(a) .. "(" .. tostring(a) .. ") --seeup--")
            else
                _print(ind .. type(k) .. "(" .. tostring(k) .. ") = " 
                    .. type(a) .. "(" .. tostring(a) .. ")")
                if type(a) == "table" then
                    tbls[tostring(a)] = true
                    _dump(a, string.sub(ind, 1, -2)..".|-")
                end
            end
        end
    end
    for i=1, select('#', ...) do
        local a = select(i, ...),
        _print("---- dump " .. i .. "th ----")
        _print(type(a) .. "(" .. tostring(a) .. ")")
        if type(a) == "table" then 
            tbls[tostring(a)] = true
            _dump(a, ".|-") 
        end
    end
end
dump = function(...) print(...) end

-- 增加加载路径
function AppendPath(path)
    package.path = package.path .. ";" .. LUA_SCRIPT_ROOT .. path
end

AppendPath("?.lua")
AppendPath("modules/?.lua")
require("ldb")
--ldb.ldb_open()
local PacketID      = require("common.PacketID")
local Dispatcher    = require("common.Dispatcher")
local RequireModule = require("common.RequireModule")
local MapConfig     = require("config.MapConfig").Config
local EventAI       = require("robot.EventAI")
local TimerAI       = require("robot.TimerAI")
local Util          = require("common.Util")
--local Robot = require("robot.Robot")
--local robot = Robot.Instance


-- 收消息
function RecvMsg(packetID)
    --print(os.time().." recv "..packetID.." "..Dispatcher.ProtoName[packetID])
    local msgRet = Dispatcher.ProtoContainer[packetID]
    if _RecvMsg(_pRobotThread, packetID, Dispatcher.ProtoContainer[packetID]) then
        return msgRet
    end
end

-- 发消息
function SendMsg(packetID,...)
    return _SendMsg(packetID,_pRobotThread,...)
end


-- 消息分发回调
function MsgDispatch(fd,packetID,sn,...)
    --print(os.time() .. " == MsgDispatch: "  .. packetID)
    --
    local OnMsg = Dispatcher.ProtoHandler[packetID]
    if OnMsg then
        --local oMsg = RecvMsg(packetID)
--        print(os.time().." recv "..packetID.." "..Dispatcher.ProtoName[packetID])
        --if not oMsg then
--            print("Packet: ", packetID, " read fail ", Dispatcher.ProtoName[packetID])
            --return true
        --end
        OnMsg(...)
        return true
    else
--        print(os.time().." recv "..packetID)
    end
    return true
end


-- 心跳回调
function HeartBeat(nameID, mapID)
    TimerAI.DoAI(nameID, mapID)
    return true
end

-- 注册协议
function Reg(protoName)
    print("reg protoName ="..protoName)
    local packetID = PacketID[RequireModule.TransProtoName(protoName)]
    local protoTemplate
    local handler = EventAI["on" .. protoName]
    for _, v in ipairs(Modules) do
        local protocol = require(v .. ".Protocol")
        if protocol[protoName] then
            protoTemplate = protocol[protoName]
            break
        end
    end
    assert(packetID     
        , "proto "..packetID.." '"..protoName.."' is not exists!")
    assert(protoTemplate
        , "proto "..packetID.." '"..protoName.."' is not exists!")
    assert(protoName:sub(1, 2) == "CG" or handler
        , "proto "..packetID.." '"..protoName.."' is not exists!")
    print("register "..packetID.." "..protoName)
    --Util.PrintTable(protoTemplate)
    Dispatcher.Register(packetID, protoTemplate, protoName, handler)
end

function GetMsg(protoName)
    -- print(" -- " .. protoName)
    -- print(" -- " .. RequireModule.TransProtoName(protoName))
    -- print(" -- " .. PacketID[RequireModule.TransProtoName(protoName)])
    local msg = Dispatcher.ProtoContainer[PacketID[RequireModule.TransProtoName(protoName)]]
    if msg then
        return msg
    else
        Reg(protoName)
        return  Dispatcher.ProtoContainer[PacketID[RequireModule.TransProtoName(protoName)]]
    end
end
Modules = {
    "character",
    --"gift",
}
--[[
Modules = {
     "activity"
    ,"board"
    ,"broadcast"
    ,"buff" 
    ,"character"
    ,"chat"
    ,"copyscene"
    ,"deal"
    ,"duplicate"
    ,"flower"
    ,"gather"
    ,"gem"
    ,"gift"
    ,"gm"
    ,"guaJi"
    ,"guild"
    ,"horse"
    ,"item"
    ,"itemMake"
    ,"look"
    ,"mail"
    ,"market"
    ,"master"
    ,"monster"
    ,"pet"
    ,"public"
    ,"question"
    ,"refine"
    ,"relation"
    ,"shop"
    ,"skill"
    ,"soul"
    ,"tao"
    ,"task"
    ,"team"
    ,"vip"
}
]]
-- 注册所有GC协议

for k, v in pairs(EventAI) do
    if type(v) == "function" and k:sub(1, 4) == "onGC" then
        Reg(k:sub(3))
    end
end
Reg("CGHeartBeat")
--Reg('CGAskLogin')
-- 初始化地图
for k, v in pairs(MapConfig) do
    --print(os.time() .. " == map: " .. k)
    --_InitRobotMap(v.map)
end
