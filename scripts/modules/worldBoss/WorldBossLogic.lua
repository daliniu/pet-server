module(...,package.seeall)

local MonsterConfig = require("config.MonsterConfig").Config
local Define = require("modules.worldBoss.WorldBossDefine")
local Timer = require("core.base.Timer")
local Msg = require("core.net.Msg")
local DB = require("core.db.DB")
local Crontab = require("modules.public.Crontab")
--local CrontabConfig = require("modules.public.CrontabConfig").Config
local CrontabConfig = require("config.CrontabConfig").Config
local Util = require("core.utils.Util")
local RewardConfig = require("config.WorldBossRewardConfig").Config
local MailManager = require("modules.mail.MailManager")
local HeroManager = require("modules.hero.HeroManager")

local TABLE_RANK = "rank"
local RANK_MODULE_BOSS = "worldBoss"
local CRON_BOSS = 2

_gmTimeGap = _gmTimeGap or nil
_firstTimer = _firstTimer or nil
_bossHp = _bossHp or 0
_leftTime = _leftTime or 0
_isDecHp = _isDecHp or false
_isBossStart = _isBossStart or false
_hasSort = _hasSort or false
_startTime = _startTime or 0
_lastHitAccount = _lastHitAccount or nil
_timer = _timer or nil
_rankList = _rankList or {}
_enterAccountList = _enterAccountList or {}
_leaveAccountList = _leaveAccountList or {}
_hurtAccountList = _hurtAccountList or {}
_hurtRewardConfig = _hurtRewardConfig or {}
_rankRewardConfig = _rankRewardConfig or {}
_lastRewardConfig = _lastRewardConfig or {}

function init()
	loadRank()
	addSaveTimer()
end

function startCrontab()
	Crontab.AddEventListener(CRON_BOSS, onOpenWorldBoss)
	initConfig()
end

function initConfig()
	_hurtRewardConfig = {}
	_rankRewardConfig = {}
	_lastRewardConfig = {}
	for _,config in pairs(RewardConfig) do
		if config.type == Define.BOSS_REWARD_TYPE_HURT then
			table.insert(_hurtRewardConfig, config)
		elseif config.type == Define.BOSS_REWARD_TYPE_RANK then
			_rankRewardConfig[config.param[1]] = config
		elseif config.type == Define.BOSS_REWARD_TYPE_LAST then
			table.insert(_lastRewardConfig, config)
		end
	end
end

function addSaveTimer()
	local saveTimer = Timer.new(60*1000, -1)
	saveTimer:setRunner(saveInTimer)
	saveTimer:start()
end

function saveInTimer()
	if _hasSort == true then
		_hasSort = false
		saveDB()
	end
end

function getTimeGap()
	if _gmTimeGap ~= nil then
		return _gmTimeGap
	end
	local todayTime = Util.GetTodayTime()
	local nextDayTime = Util.GetNextDayTime()
	local curTime = os.time()  
	local timeConfig = CrontabConfig[CRON_BOSS]
	local todayTargetTime = todayTime + timeConfig.hour[1] * 3600 + timeConfig.min[1] * 60
	local nextTargetTime = nextDayTime + timeConfig.hour[1] * 3600 + timeConfig.min[1] * 60
	local timeGap = 0
	if curTime > todayTargetTime then
		--明天时间点
		timeGap = nextTargetTime - curTime
	else
		--今天时间点
		timeGap = todayTargetTime - curTime
	end
	return timeGap
end

--用于GM指令
function addWorldBossTimer(hour, min, second)
	if hour == nil then
		hour = "00"
	end
	if min  == nil then
		min = "00"
	end
	if hour == nil  then
		second = "00"
	end
	time = hour .. ":" .. min  .. ":" .. hour
	local t = nil
	if string.match(time, "(%d+):(%d+):(%d+)") ~= nil then
		t = Util.getTimeByStr(time)
	end
	
	if t == nil and t <= 0 then
		onOpenWorldBoss()
	else
		local timeGap = t - os.time()
		if timeGap <= 0 then 
			onOpenWorldBoss()
		else
			_gmTimeGap = timeGap
			_firstTimer = Timer.new(timeGap * 1000, 1)
			_firstTimer:setRunner(onOpenWorldBoss)
			_firstTimer:start()
		end
	end
end

function onOpenWorldBoss()
	_leftTime = Define.BOSS_CONTINUE_TIME

	local tab = {}
	local allOnline = HumanManager.getAllOnline()
	for _,human in pairs(allOnline) do
		if human:getLv() >= Define.BOSS_OPEN_LV then
			table.insert(tab, human.fd)
		end
		if #tab >= Msg.MSG_USER_BROADCAST_LIMIT_COUNT then
			Msg.UserBroadCast(PacketID.GC_WORLD_BOSS_OPEN, tab)
			tab = {}
		end
	end
	if #tab > 0 then
		Msg.UserBroadCast(PacketID.GC_WORLD_BOSS_OPEN, tab)
	end

	startWorldBoss()
end


function startWorldBoss()
	_lastHitAccount = nil
	_isBossStart = true

	_enterAccountList = {}
	_hurtAccountList = {}
	_leaveAccountList = {}
	_bossHp = MonsterConfig[Define.BOSS_ID].maxHp
	_startTime = os.time()

	_timer = Timer.new(Define.BOSS_SYSTEM_DEC_HP_RATE, -1)
	_timer:setRunner(onRefresh)
	_timer:start()
end

function onRefresh(runner, timer)
	refreshRank()
	judgeIsEnd()
	--decBossHp(getSystemDecHp())
	sendBossHpMsg()
	refreshCoolTime()
end

function refreshRank()
	if (os.time() - _startTime) % Define.BOSS_RANK_SORT_TIME == 0 then
		local sortFun = function(a, b)
			return a.hurt > b.hurt
		end
		_rankList = {}
		for no,record in pairs(_hurtAccountList) do
			--策划需求，伤害大于0才进入排行榜
			if record.hurt > 0 then
				local hurtRecord = {account = no, hurt = record.hurt, name = record.name, heroList = record.heroList, fight = record.fight}
				local len = #_rankList
				if len == 0 then
					table.insert(_rankList, hurtRecord)
				else
					if len < Define.BOSS_RANK_COUNT then
						if _rankList[len].hurt >= hurtRecord.hurt then
							table.insert(_rankList, hurtRecord)
						else
							for i=1,len do
								if _rankList[i].hurt < hurtRecord.hurt then
									table.insert(_rankList, i, hurtRecord)
									break
								end
							end
						end
					else
						for i=1,Define.BOSS_RANK_COUNT do
							if _rankList[i].hurt < hurtRecord.hurt then
								table.insert(_rankList, i, hurtRecord)
								table.remove(_rankList)
								break
							end
						end
					end
				end
			end
		end
		_hasSort = true
	end
end

function getRankList()
	return _rankList
end

--获取系统扣血
--TODO：根据时间与进度计算
function getSystemDecHp()
	return 10
end

function decBossHp(hp)
	if _bossHp > 0 then
		_isDecHp = true
		_bossHp = _bossHp - hp
		if _bossHp <= 0 then
			_bossHp = 0
			endWorldBoss(Define.BOSS_END_DIE)
		end
	end
end

function getBossHp()
	return _bossHp
end

function sendBossHpMsg()
	if _isDecHp == true then
		local tab = {}
		for account,_ in pairs(_enterAccountList) do
			local human = HumanManager.getOnline(account)
			if human ~= nil then
				table.insert(tab, human.fd)
			else
				_enterAccountList[account] = nil
			end
			if #tab >= Msg.MSG_USER_BROADCAST_LIMIT_COUNT then
				Msg.UserBroadCast(PacketID.GC_WORLD_BOSS_REFRESH_HP, tab, _bossHp)
				tab={}
			end
		end
		if #tab > 0 then
			Msg.UserBroadCast(PacketID.GC_WORLD_BOSS_REFRESH_HP, tab, _bossHp)
		end
		_isDecHp = false
	end
end

function judgeIsEnd()
	if os.time() - _startTime >= _leftTime and _isBossStart == true then
		endWorldBoss(Define.BOSS_END_TIME_OUT)
	end
end

function refreshCoolTime()
	decCoolTime(_enterAccountList)
	decCoolTime(_leaveAccountList)
end

function decCoolTime(list)
	for account,_ in pairs(list) do
		local human = HumanManager.getOnline(account)
		if human ~= nil then
			if human.worldBossCD > 0 then
				human.worldBossCD = human.worldBossCD - 1
			end
		end
	end
end

function endWorldBoss(type)
	_gmTimeGap = nil
	_isBossStart = false

	--广播结束广播
	local tab = {}
	for account,_ in pairs(_enterAccountList) do
		local human = HumanManager.getOnline(account)
		if human ~= nil then
			table.insert(tab, human.fd)
		end
		if #tab >= Msg.MSG_USER_BROADCAST_LIMIT_COUNT then
			Msg.UserBroadCast(PacketID.GC_WORLD_BOSS_END, tab, type)
			tab = {}
		end
	end
	if #tab > 0 then
		Msg.UserBroadCast(PacketID.GC_WORLD_BOSS_END, tab, type)
	end

	print('endWorldBoss11=====================================')

	--发奖励
	sendReward()

	--存库
	saveDB()

	if _timer ~= nil then
		_timer:stop()
		_timer = nil
	end

	_enterAccountList = {}
	_hurtAccountList = {}
	_leaveAccountList = {}
end

function sendReward()
	sendHurtReward()
	sendRankReward()
	sendLastReward()
end

function sendHurtReward()
	for account,record in pairs(_hurtAccountList) do
		print('sendHurtReward =========================== ' .. account)
		local human = HumanManager.getOnline(account) or HumanManager.loadOffline(account)
		if human ~= nil then
			print('sendHurtReward1 =========================== ' .. account)
			for _,config in ipairs(_hurtRewardConfig) do
				print('sendHurtReward3 =========================== ' .. config.id)
				if record.hurt >= config.param[1] and (config.param[2] == nil or record.hurt <= config.param[2]) then
					print('sendHurtReward4 =========================== ' .. config.id)
					MailManager.sysSendMailById(human.db.account, Define.BOSS_MAIL_HURT, config.reward, human.db.name)
					break
				end
			end
		end
	end
end

function sendRankReward()
	local rankLen = #_rankList
	for i=1,rankLen do
		local record = _rankList[i]
		local human = HumanManager.getOnline(record.account) or HumanManager.loadOffline(record.account)
		local config = _rankRewardConfig[i]
		if human ~= nil and config ~= nil then
			MailManager.sysSendMailById(human.db.account, Define.BOSS_MAIL_RANK, config.reward, human.db.name, i)
		end
	end
end

function sendLastReward()
	if _lastHitAccount ~= nil and _bossHp <= 0 then
		local config = _lastRewardConfig[1]
		local human = HumanManager.getOnline(_lastHitAccount) or HumanManager.loadOffline(_lastHitAccount)
		if config ~= nil and human ~= nil then
			MailManager.sysSendMailById(human.db.account, Define.BOSS_MAIL_LAST, config.reward, human.db.name)

			local logTb = Log.getLogTb(LogId.BOSS_LAST_HIT)
			logTb.name = human:getName()
			logTb.account = human:getAccount()
			logTb.pAccount = human:getPAccount()
			logTb.hurt = hurt
			logTb:save()
		end
	end
end

function resetCoolTime(human)
	human.worldBossCD = Define.BOSS_BATTLE_TIME
end

function hurtHp(human, hurt)
	if _isBossStart == true then
		addAccountHurtHp(human, hurt)
		decBossHp(hurt)
		_lastHitAccount = human:getAccount()

    	local logTb = Log.getLogTb(LogId.BOSS_HURT_RECORD)
		logTb.name = human:getName()
		logTb.account = human:getAccount()
		logTb.pAccount = human:getPAccount()
		logTb.hurt = hurt
		if _hurtAccountList[human:getAccount()] then
			logTb.hurtSum = _hurtAccountList[human:getAccount()].hurt
		end
		logTb:save()
	end
end

function addAccountHurtHp(human, hurt)
	local account = human:getAccount()
	if _hurtAccountList[account] ~= nil then
		_hurtAccountList[account].hurt = _hurtAccountList[account].hurt + hurt
	end
end

function getAcountHurtHp(human)
	if _hurtAccountList[human:getAccount()] == nil then
		return 0
	end
	return _hurtAccountList[human:getAccount()].hurt
end

function enterWorldBoss(human, heroNameList)
	markAccount(human, heroNameList)
	markEnterAccount(human)
	resetCoolTime(human)
end

function markAccount(human, heroNameList)
	local tab = {}
	for i=1,4 do
		local name = heroNameList[i]
		local hero = HeroManager.getHero(human, name)
		if hero then
			table.insert(tab, {name = name, lv = hero:getLv(), quality=hero.db.quality})
		else
			table.insert(tab, {name = '', lv = 1, quality = 1})
		end
	end
	if _hurtAccountList[human:getAccount()] == nil then
		_hurtAccountList[human:getAccount()] = {hurt = 0, name = human:getName(), heroList = tab, fight = human:getTeamFightVal(tab)}
	else
		local data = _hurtAccountList[human:getAccount()]
		_hurtAccountList[human:getAccount()] = {hurt = data.hurt, name = human:getName(), heroList = tab, fight = human:getTeamFightVal(tab)}
	end
end

--标记进入账号，用于广播boss血量
function markEnterAccount(human)
	_enterAccountList[human:getAccount()] = 1
	_leaveAccountList[human:getAccount()] = nil
end

function removeEnterAccount(human)
	_enterAccountList[human:getAccount()] = nil
	_leaveAccountList[human:getAccount()] = 1
end

--加载排行
function loadRank()
	local pCursor = g_oMongoDB:SyncFind(TABLE_RANK,{module=RANK_MODULE_BOSS})
	if not pCursor then
		return
	end
	local cursor = MongoDBCursor(pCursor)
	local tmp = {}
	if not cursor:Next(tmp) then
		g_oMongoDB:SyncInsert(TABLE_RANK,{module=RANK_MODULE_BOSS,rankList = _rankList})
		return
	end

	_rankList = tmp.rankList
end

function saveDB(isSync)
	DB.Update(TABLE_RANK,{module=RANK_MODULE_BOSS},{module=RANK_MODULE_BOSS,rankList=_rankList},isSync)
end

---- 条件相关 ----
function hasSelHero(list)
	return (#list > 0)
end

function hasEnoughLvToOpen(human)
	return (human:getLv() >= Define.BOSS_OPEN_LV)
end

function isInCoolTime(human)
	return human.worldBossCD > 0
end

function hasThatRank(rank)
	if _rankList[rank] == nil then
		return false,nil
	end
	return true,_rankList[rank]
end

function hasBossStart()
	return _isBossStart
end
