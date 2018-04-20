module(...,package.seeall)
local PeakRobotConfig = require("config.PeakRobotConfig").Config
local ArenaHero = require("modules.arena.ArenaHero")
local Define = require("modules.peak.PeakDefine")

function new(account)
	local cfg = PeakRobotConfig[account]
	local robot = {}
	robot.account = account
	robot.bodyId = cfg.icon
	robot.lv = cfg.lv
	robot.name = cfg.name
	robot.hero= {}
	initRobotHeroes(robot)
	setmetatable(robot, {__index = _M}) 
	return robot
end

function getHero(self,name)
	return self.hero[name]
end

function getAllHero(self)
	return self.hero
end

function initRobotHeroes(self)
	local cfg = PeakRobotConfig[self.account]
	local fightList = {}
	for i = 1,Define.HERO_COUNT do
		local name = cfg["hero"..i]
		local hero = ArenaHero.new(cfg,i)
		hero.quality = cfg['quality'..i]
		self.hero[name] = hero
	end
end
