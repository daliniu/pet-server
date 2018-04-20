module(...,package.seeall)

function new()
	local db = {
		cnt = 0,	--今日踢馆次数
		fightList = {},		--踢馆阵容
		reset = os.date("%d"),
	}
	setmetatable(db,{__index = _M})
	return db
end
