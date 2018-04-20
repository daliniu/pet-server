module("Object", package.seeall)
setmetatable(Object, {__index = EventDispatcher}) 

TYPE_OBJECT = "object"

function new()  
    local obj = {
		id = ObjectManager.newId(),
		otype = TYPE_OBJECT,
		typeId = ObjectManager.OBJ_TYPE_OBJECT,
	}
	setmetatable(obj, {__index = Object})
	ObjectManager.add(obj)
    return obj 
end

function resetMeta(self) 
	setmetatable(self, {__index = Object})
end

function release(self)
	--todo 
	--删计时器
	ObjectManager.remove(self)
end

function getPosition(self)
    return self.x, self.y
end

function setPosition(self, x, y)
	self.x = x
	self.y = y
end

