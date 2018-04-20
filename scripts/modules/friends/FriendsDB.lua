module(...,package.seeall)


function new()
	local db = {
	}
	setmetatable(db,{__index = _M})
	return db 
end