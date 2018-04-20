module(...,package.seeall)
require("modules.character.ObjHuman")
require("modules.character.OfflineHuman")


TIMER_SAVE_OFFLINE = TIMER_SAVE_OFFLINE or nil
if not TIMER_SAVE_OFFLINE then
	--每10分钟保存离线
	local timer = Timer.new(600*1000,-1)
	timer:setRunner(HumanManager.onSaveOfflineDB)
	timer:start()
	TIMER_SAVE_OFFLINE = timer
end


