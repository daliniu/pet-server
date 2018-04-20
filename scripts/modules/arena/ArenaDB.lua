module(...,package.seeall)
local ArenaDefine = require("modules.arena.ArenaDefine")
local ArenaLogic = require("modules.arena.ArenaLogic")

function new()
	local db = {
		challenge = 0,
		challengeRefresh = 0,
		nextTime = 0,
		win = 0,
		enemyList = {},
		record = {},
		shop = {},
		shopRefresh = 0,
		lastRefresh = 0,
		arenaing = 0,
	}
	setmetatable(db,{__index = _M})
	return db 
end
