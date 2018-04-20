module(..., package.seeall)

--local CrontabConfig = require("modules.public.CrontabConfig").Config
local CrontabConfig = require("config.CrontabConfig").Config
DayPlan = DayPlan or {}
DayPlanPtr = DayPlanPtr or 0
DayEvents = nil
DayRunTimer = DayRunTimer or nil

function RunNext()
    local now = os.time()
    local mwEvents = {}
    local event = DayPlan[DayPlanPtr]
    assert(event,"DayPlan event is nil")
    --mwEvents[#mwEvents+1] = event

    if event.evId == 0 then  --重建计划表
        BuildDayPlan()
        RunNext()
        return
    end

    --Next Event
    local nextEvent
    repeat 
        nextEvent = DayPlan[DayPlanPtr]
        assert(nextEvent,'[Error]DayPlan[DayPlanPtr]',DayPlanPtr,'>> is nil')
        if math.floor(nextEvent.run/60) <= math.floor(now/60) then
        	DayPlanPtr = DayPlanPtr + 1
            mwEvents[#mwEvents+1] = nextEvent
        end
    until nextEvent.run>now 

	DayRunTimer = Timer.new((nextEvent.run-now)*1000,1)
	DayRunTimer:setRunner(RunNext)
	DayRunTimer:start()

    print("RaiseDayEvent>>>",event.run)
    for _,event in ipairs(mwEvents) do
        RaiseDayEvent(event)
    end
end

-- 注册事件侦听 
-- evId:    事件ID 
-- cb:      回调函数
-- param:   回调函数的参数
-- @return:  返回监听器的位移，用于删除监听器
function AddEventListener(evId,cb,...)
    if DayEvents == nil then 
        DayEvents = {}
    end
    local events = DayEvents[evId]
    if not events then
        events = {}
        DayEvents[evId]=events
    end
    assert(type(cb)=="function","[error] Crontab:AddEventListener >>> type(cb) ~= function" ) 
    listener = {cb,...}

    table.insert(events,listener)
	--Util.print_r(DayEvents)
    return #events
end

--删除监听的事件
function DelEventListener(evId,listenerIndex)
    local events = DayEvents[evId]
    if not events then
        return false
    end
    return table.remove(events,listenerIndex)
end

function RaiseDayEvent(event)
	print("======RaiseDayEvent")
	if DayEvents == nil then
		return 
	end
	--Util.print_r(DayEvents)
    local events = DayEvents[event.evId]
    if events then
        for _,listener in pairs(events) do
            --print("evId==>",event.evId,",run==>",event.run)
			local exec = function(func,...) func(event,...) end
			exec(unpack(listener))
        end 
    else
        print("======================== not events:".. event.evId)
    end
end

function AddEvent(evId,runtime)
	DayPlan[#DayPlan+1] = {run = runtime,evId=evId}
end

function BuildDayPlan()
	DayPlan = {}
    local now = os.time()
    local date = os.date('*t',now)

    local cronTimeList = {}
    for id,act in ipairs(CrontabConfig) do 
        for _,week in ipairs(act.week) do 
            if date.wday == week+1 then 
                --crontab string parser
                cronTimeList = ParseCron(act.min,act.hour)
                for i=1,#cronTimeList do
                    if math.floor(cronTimeList[i]/60) >= math.floor(now/60) then
                        AddEvent(act.evId,cronTimeList[i])
                    end
                end
            end
        end
    end    
    print("BuildDayPlan=====================>>")
    SortDayPlan(now)
	--Util.print_r(DayPlan)
    --第二天凌晨0点0分 重建计划表
    AddEvent(0,Util.getTimeByStr("24:00:00"))
end

function SortDayPlan(now)
	DayPlanPtr = 1 
    table.sort(DayPlan,function(first,second)
        return first.run < second.run
    end)
    for k,v in ipairs(DayPlan) do 
        if math.floor(v.run/60) >= math.floor(now/60) then
            DayPlanPtr = k
            break
        end
    end
end

function Init()
	print("Crontab Init==========================")
    BuildDayPlan()
    --print(timeStart,'>>BuildDayPlan()>>>cost times:>>',(_CurrentTime() - timeStart))
    local event = DayPlan[DayPlanPtr]
    --print(" DayPlan[DayPlanPtr]=====>>  ")
    if DayRunTimer then
        --print("timer stop>>")
		DayRunTimer:stop()
    end
	RunNext()
end

function ParseCron(min,hour)
    local timeTable = os.date('*t', os.time())
    local cronTime = {}
    local hourList = CronStr2List(hour,23)
    local minList  = CronStr2List(min,59)
    for i=1,#hourList do
        for j=1,#minList do
            timeTable.hour = hourList[i]
            timeTable.min  = minList[j] 
            timeTable.sec  = 0
            cronTime[#cronTime+1] = os.time(timeTable)
        end
    end
    return cronTime
end

function CronStr2List(str,maxNum)
    local list = {}
    if type(str) == 'table' then  --枚举型,{2,4,6}
        for i=1,#str do
            list[#list+1] = str[i]
        end
    elseif str == '*' then           --泛型,*
        for i=0,maxNum do
            list[#list+1] = i
        end
    else                              --步进型,*/5 | 10-50/5
        local start = 0
        local stop  = maxNum
        local step = 1
        if string.sub(str,1,1) == "*" then  --形如*/5
            step = string.sub(str,3)
        else
            local sep2Index = string.find(str,"/")
            local sepIndex = string.find(str,"-")
            start = string.sub(str,1,sepIndex-1)
            stop  = string.sub(str,sepIndex+1,sep2Index-1)
            step  = string.sub(str,sep2Index+1)
        end
        for i=start,stop,step do
            list[#list+1] = i
        end
    end
    return list
end
