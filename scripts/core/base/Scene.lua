module(..., package.seeall)
Scene = Scene or {}

function Scene:new(sceneId)
    local s = {
        sceneId = sceneId,
        human = {},
    }
    setmetatable(s,self)
    self.__index = self
    return s
end

function Scene:addObj(obj)
    assert(not self.human[obj.id],"can not add existing obj to scene")
    self.human[obj.id] = obj
end

function Scene:removeObj(obj)
    assert(self.human[obj.id],"can not remove a obj not existing to scene")
    self.human[obj.id] = nil
end
