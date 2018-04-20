function SendHotNotify(op)
    local Dispatcher = require("common.Dispatcher")
    local PacketID = require("common.PacketID")
    local Msg = require("common.Msg")
    local msg = Dispatcher.ProtoContainer[PacketID.GC_HOT_NOTIFY]
    msg.op = op
    Msg.WorldBroadCast(msg)
end


--local Broadcast = require("common.Broadcast")

local msg = {}
msg.pos = 1
msg.content = "系统正在热更。。。"

--Broadcast.doUserBroadcast(msg)

--SendHotNotify(1) --开始热更新
for k, v in pairs(package.loaded) do
    package.loaded[k] = nil
end
--Network.resetProtocol()

local nt1 = _CurrentTime()
require("Main") 
print("---------------------------------")
local nt2 = _CurrentTime()
print('require main cost:',nt2-nt1)
collectgarbage("collect")
local nt3 = _CurrentTime()
print('collect time:',nt3-nt2)
print("3garbage collected:", collectgarbage("count"))
print('nt1:',nt1,' nt2:',nt2,' nt3:',nt3)
--SendHotNotify(2) --结束热更新

msg.content = "系统热更完毕！"
--Broadcast.doUserBroadcast(msg)
