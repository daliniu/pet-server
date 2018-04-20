module(..., package.seeall)

local DB = require("core.db.DB")

-- {id,count,hasBuy}
function new()
	local tab = {
		nextUpdate = 0,			--下一次刷新时间
		itemlist = {},			--物品列表
	}
	setmetatable(tab, {__index = _M})
	return tab
end