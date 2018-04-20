module(...,package.seeall)


--local Broadcast = require("common.Broadcast")
local CommonDefine = require("core.base.CommonDefine")
local Msg = require("core.net.Msg")

local ChatDefine = require("modules.chat.ChatDefine")
local ChatLogic = require("modules.chat.ChatLogic")
local GMCmdLogic = require("modules.chat.GMCmdLogic")
local GMCmdDefine = require("modules.chat.GMCmdDefine")

function onCGChat(human, chatType,content,targetAccount)
    print("chatType = "..chatType.." content="..content)
	if Config.ISTESTCLIENT then
		if GMCmdLogic.MatchGMCmdRule(content, chatType) then
			local gmRetCode = GMCmdLogic.DoGMFuntion(human, content)
			if gmRetCode then
				Msg.SendMsg(PacketID.GC_CHAT,human,CommonDefine.OK,ChatDefine.TYPE_SYSTEM,human:getName(),GMCmdDefine.GM_RETURN_CODE_CONTENT[gmRetCode])
			end
			return true
		end
	end

    local chatRetCode = ChatLogic.canChat(human, chatType, content, targetAccount)
    --print("chatRetCode:", chatRetCode)
    if chatRetCode == CommonDefine.OK then
        ChatLogic.doCost(human, chatType)
        ChatLogic.doChat(human, chatType, content, targetAccount)
	else
    	Msg.SendMsg(PacketID.GC_CHAT,human,chatRetCode,ChatDefine.TYPE_SYSTEM)
    end
    return true
end




