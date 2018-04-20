module("Log",package.seeall)
local LogStandard = require("config.LogStandard")

_G["LogId"] = require("config.LogStandard").LogId

local LogContainer = {}
local LogId2LogName = {}

--[[
--使用方法:
logTb = Log.getLogTb(logId.LOGIN)
logTb.ret=1
logTb.ip="192.168.1.1"
logTb:save()
--]]

local mt = {}
mt.save = function(self) 
	local logId = self.logId
	local tagName = string.upper(LogId2LogName[logId])
	self.logId = nil
	--print("tagName....." .. tagName)
	LogOss(tagName,self)
	self.logId = logId
end

function getLogTb(logId)
    assert(logId,"logId is nil ")
    assert(LogStandard.LogTpl[logId],"[LogError]>>>logId" .. logId .. " not exists")
    if LogContainer[logId] == nil then
        LogContainer[logId] = {logId=logId,channelId=0}
        fields = LogStandard.LogTpl[logId]
        assert(type(fields)=='table',"[LogError]>>>logId" .. logId .. " fields isnot table")
        for _,field in pairs(fields) do
			field[2] = field[2]:upper()
            if field[2] == 'INT' or field[2] == 'TINYINT' or field[2] == 'SMALLINT' then 
                LogContainer[logId][field[1]] = field[5] or 0
            else
                LogContainer[logId][field[1]] = field[5] or ""
            end
        end
		setmetatable(LogContainer[logId],{
			__index = mt,
			__newindex = function(t,k,v)
				if k ~= "logId" then
					print(debug.traceback())
					print("[LogWarn]key " .. k .. " not exist.maybe it had set to nil  ====>logId===>" .. logId)
					LogErr("LogWarn","key " .. k .. " not exist.maybe it had set to nil ==>logId===>" .. logId)
				else
					rawset(t,k,v)
				end
			end,
		})
    end
    return LogContainer[logId]
end

function initLogId2LogName()
	local logIdTb = LogStandard.LogId
	for name,id in pairs(logIdTb) do
		LogId2LogName[id] = name
	end
end

initLogId2LogName()




