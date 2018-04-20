local Crontab = require("modules.public.Crontab")
local PublicLogic = require("modules.public.PublicLogic")
local SensitiveFilter = require("modules.public.SensitiveFilter")

Crontab.Init()
SensitiveFilter.init()

TIMER_COUNT_ONLINE = TIMER_COUNT_ONLINE or nil
if not TIMER_COUNT_ONLINE then
	local timer = Timer.new(60*1000,-1)
	timer:setRunner(PublicLogic.on1MinRecord)
	timer:start()
	TIMER_COUNT_ONLINE = timer
end

Crontab.AddEventListener(1,PublicLogic.onNextDayLogic)
