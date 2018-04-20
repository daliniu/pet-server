module("ObjectManager", package.seeall)

--- 对象类型Id ---
OBJ_TYPE_INVALID    = 0            --// 无效对象
OBJ_TYPE_OBJECT 	= 0            --//对象 
OBJ_TYPE_HUMAN      = 1             --// 玩家
OBJ_TYPE_NPC        = 2
OBJ_TYPE_MONSTER    = 3
OBJ_TYPE_COLLECT    = 4
OBJ_TYPE_JUMP       = 5
OBJ_TYPE_ITEM       = 6
OBJ_TYPE_PET        = 7

list = list or {}
fd_list = fd_list or {}

index = index or 0

function add(obj)
	assert(type(obj.id) == "number", "Object.id is invalid ! ")
	local o = list[obj.id]
	assert(o == nil, "Object already exists ! id " .. obj.id)
	list[obj.id] = obj

	if obj.fd then
		local o = fd_list[obj.fd]
		assert(o == nil, "Object already exists ! fd " .. obj.fd)
		fd_list[obj.fd] = obj
	end
end

function addByFd(fd,obj)
	obj.fd = fd
	assert(fd_list[obj.fd] == nil,"Object already exists ! fd " .. obj.fd)
	fd_list[obj.fd] = obj
end

function get(id)
	return list[id]
end

function getByFD(fd)
	return fd_list[fd]
end

function newId()
	index = index + 1
	return index
end

function remove(obj)
	list[obj.id] = nil
	if obj.fd then
		fd_list[obj.fd] = nil
	end
end

function removeById(id)
	local o = list[id] 
	list[id] = nil
	if o and o.fd then
		fd_list[o.fd] = nil
	end
end

function removeFd(obj)
	fd_list[obj.fd] = nil
	obj.fd = nil
end

function resetMeta()
	for id, obj in pairs(list) do
		obj:resetMeta()
	end
end

return ObjectManager


