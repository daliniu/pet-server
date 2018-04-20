module(...,package.seeall)

local Util = require("core.utils.Util")
local GMCmdFunction = require("modules.chat.GMCmdFunction")
--local GameMasterConfig = require("config.GameMasterConfig").Config
local Hm = require("core.managers.HumanManager")
local DB = require("modules.orochi.OrochiDB")
local Logic = require("modules.chat.ChatLogic")

Hm:addEventListener(Hm.Event_HumanDBLoad, Logic.dbLoad)
Hm:addEventListener(Hm.Event_HumanLogin, Logic.onHumanLogin)



function InitHelpMsg()
    local tb = {}
    for funName, value in pairs(GMCmdFunction) do
        if type(value) == "function" then
            tb[#tb + 1] = funName
        end
    end
    tb[#tb + 1] = ""

    GMCmdFunction.HelpMsg = table.concat(tb, "\n")
end

function InitGmConfig()
    local nameList = {}
    for id, v in pairs(GameMasterConfig) do
        nameList[v.name] = id
    end

    for id, v in pairs(GameMasterConfig) do
        if GameMasterConfig[v.name] == nil then
            GameMasterConfig[v.name] = GameMasterConfig[nameList[v.name]]
        end
    end
    --Util.PrintTable(GameMasterConfig)
end

InitHelpMsg()
--InitGmConfig()
