module(...,package.seeall)

local PacketID = require("PacketID")
local Msg = require("core.net.Msg")

local GameMasterConfig = require("config.GameMasterConfig").Config

local ChatDefine = require("modules.chat.ChatDefine")
local GMCmdDefine = require("modules.chat.GMCmdDefine")
local GMCmdFunction = require("modules.chat.GMCmdFunction")

function MatchGMCmdRule(content, chatType)
    if chatType == ChatDefine.TYPE_WORLD then
        local ncontent = string.lower(content)
        if string.find(ncontent, GMCmdDefine.GM_FORMAT) then
            return true
        end
    end
    return false
end

function DoGMFuntion(human, content)
    print("do gm function content ="..content)
    local equalIndex = string.find(content, "=")
    local funName = equalIndex and content:sub(4, equalIndex - 1) or content:sub(4, #content)
    local paramList = {}
    if equalIndex then
        local paramContent = string.sub(content, equalIndex + 1, #content)
        for param, sign in string.gmatch(paramContent, "(%w+)(,?)") do
            paramList[#paramList + 1] = param
        end
    end
    local GMFun = nil
    for k,v in pairs(GMCmdFunction) do
        if type(v) == "function" and k == funName or string.lower(k) == funName then 
            GMFun = v
            break
        end
    end
    if GMFun == nil then
        return GMCmdDefine.NOT_EXIST_CMD
    else
        return GMFun(human, paramList[1], paramList[2], paramList[3], paramList[4], paramList[5], paramList[6])
    end
end

