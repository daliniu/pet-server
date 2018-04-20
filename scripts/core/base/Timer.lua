-- 计时器
-- 还可以如下优化（如果有必要的话）
-- 1 timer 提供回收池
-- 2 timerList 用数组的写法维护

module("Timer", package.seeall)

timerList = timerList or {}
now = now or _CurrentTime()

-- 构造计时器
-- interval:间隔多少毫秒 maxTimes:执行总次数，-1表示永久执行
function new(interval, maxTimes)
	assert(interval > 0)
	assert(maxTimes > 0 or maxTimes == -1)
	local timer = {
		interval = interval, 
		maxTimes = maxTimes,
	}
	setmetatable(timer, {__index = Timer})
	return timer
end

function setRunner(self, func, runner)
	local src = debug.getinfo(func).short_src
	assert(src,"get short_src fail")
	src = src:gsub("\\",".")
	src = src:gsub("/",".")
	local pos = src:find("scripts")
	src = src:sub(pos + 8,src:len()-4)
	--print("set timer runner>>>>>>",src)
	local callModule = require(src)
	local funcname
	for k,v in pairs(callModule) do
		if v == func then
			funcname = k
		end
	end
	assert(funcname,"anonymous or local function is not allowed!")
	self.src= src
	self.fname = funcname

	self.func = func 
	self.runner = runner 
end

--热更时需要重置runner
function resetTimerRunner()
	for timer,_ in pairs(timerList) do
		print("resetTimer=====>",timer.src,"==>",timer.fname)
		local callModule = require(timer.src)
		if callModule and callModule[timer.fname] then
			timer.func = callModule[timer.fname]
		else
			timer:stop()
			print("Timer"," lost timer src " .. timer.src .. " >>>>fname>>> " .. timer.fname)
			LogErr("Timer","lost timer src " .. timer.src .. " >>>>fname>>> " .. timer.fname)
		end
	end
	now = _CurrentTime()
end

function start(self)
	assert(self.func)
	self.nextCall = now + self.interval
	timerList[self] = true
end

function stop(self)
	timerList[self] = nil
end

function getNow()
	return now
end

function HandlerTimer(curTime)
	now = curTime
	for timer, v in pairs(timerList) do
		if timer.nextCall <= curTime then
			timer.nextCall = timer.nextCall + timer.interval
			timer.maxTimes = timer.maxTimes - 1
			Util.tick_start()
			timer.func(timer.runner, timer)
			Util.tick_end_packet()
			if timer.maxTimes == 0 then
				stop(timer)
			end
		end
	end
end

function TimerDispatch(curTime)
	now = curTime
	for timer, v in pairs(timerList) do
		if timer.nextCall <= curTime then
			timer.nextCall = timer.nextCall + timer.interval
			timer.maxTimes = timer.maxTimes - 1

			--timer.func(timer.runner, timer)
			function cofunc(...)
				Util.tick_start()
				timer.func(...)
				Util.tick_end_packet()
			end
			local co = coroutine.create(cofunc)
			--local co = coroutine.create(timer.func)
			local ret,tid = coroutine.resume(co, timer.runner, timer)
			if not ret then 
				local errMsg = "coroutine fail \n" .. tostring(tid)
				errMsg = errMsg .. debug.traceback(co)
				LogErr("error",errMsg)
				print("--------------------------------------------")
				print(errMsg)
				print("--------------------------------------------")
			end

			if timer.maxTimes == 0 then
				stop(timer)
			end

			if tid and type(tid) == "number" then 
				DB.DBTManager[tid] = co
			end
		end
	end
end

_G["TimerDispatch"] = TimerDispatch
if Config.ISSYNC then
	_G["TimerDispatch"] = HandlerTimer 
end

return Timer

