module(...,package.seeall)

function new()
	local o = {
	}
	setmetatable(o,{__index = _M})
	o:init()
	return o
end

function init(self)
	self.id = 0
	self.cnt = 0
end

function addItem(grid,itemId,cnt)
    init(grid)
    grid.id = itemId
    grid.cnt= cnt
end
