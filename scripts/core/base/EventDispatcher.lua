module("EventDispatcher", package.seeall)

function addEventListener(self, etype, func, listener) 
	assert(type(etype) == "string")
	print("EventDispatcher:addEventListener " .. etype) 

	if not self._events then
		self._events = {}
	end

	if not self._events[etype] then
		self._events[etype] = {}
	end

	if not self._events[etype][func] then
		self._events[etype][func] = listener or self 
	else
		assert(false,"function is exist")
	end
end 

function removeEventListener(self, etype, func)
	assert(type(etype) == "string")
	trace("EventDispatcher:removeEventListener " .. etype) 

	if self._events and  self._events[etype] then
		self._events[etype][func] = nil 
	end 
end 

function removeAllEventListener(self)
	self._events = {}
end 

function dispatchEvent(self, etype, event) 
	assert(type(etype) == "string")
	if false and etype ~= Event.Frame then
		self.name = self.name or "unknow"
		self.uiType = self.uiType or "unknow"
		trace("dispatchEvent:" .. etype .. "." .. event.etype .. 
		 " ,[ ".. self.name .. " ] " .. self.uiType) 
	end

	if self._events and self._events[etype] then 
		for func, listener in pairs(self._events[etype]) do
			func(listener, event, self,func)
		end
	end
end 

function hasEventListener(self, etype, func) 
	if self._events and self._events[etype] and self._events[etype][func] then
		return true
	else
		return false
	end
end 

