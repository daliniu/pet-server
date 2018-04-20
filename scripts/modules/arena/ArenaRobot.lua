module(...,package.seeall)
local ArenaRobotConfig = require("config.ArenaRobotConfig").Config
local ArenaHero = require("modules.arena.ArenaHero")
RobotManager = RobotManager or {}
local ROBOT_DEL_TIME = 60*1000

function new(account)
	local cfg = ArenaRobotConfig[account]
	local robot = {}
	robot.db = {}
	robot.db.account = account
	--robot.db.bodyId = cfg.bodyId
	robot.db.bodyId = math.random(1,26)
	robot.db.lv = cfg.lv
	robot.db.name = cfg.name
	robot.db.guildId = 0
	robot.hero= {}
	initRobotHeroes(robot)
	raiseClear(robot)
	setmetatable(robot, {__index = _M}) 
	return robot
end

function raiseClear(self)
	if not self.timer then
		self.timer = Timer.new(ROBOT_DEL_TIME,1)
		self.timer:setRunner(onClearRobotCache,self)
	end
	self.timer:start()
end

function onClearRobotCache(self)
	local account = self.db.account
	RobotManager[account] = nil
end

function getByAccount(account)
	if not RobotManager[account] then
		local robot = new(account)
		RobotManager[account] = robot
	end
	local rob = RobotManager[account]
	raiseClear(rob)
	return rob
end

function getHero(self,name)
	return self.hero[name]
end

function initRobotHeroes(self)
	local cfg = ArenaRobotConfig[self.db.account]
	local fightList = {}
	for i = 1,4 do
		local name = cfg["hero"..i]
		local hero = ArenaHero.new(cfg,i)
		self.hero[name] = hero
		fightList[name] = {pos = i,val = 0}
	end
	self.fightList = fightList
end
