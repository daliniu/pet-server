module(..., package.seeall)

--local MapConfig = require("config.MapConfig").Config
--local Scene = require("common.Scene").Scene
--local CommonDefine = require("common.CommonDefine")
--local CopyManager = require("copy.CopyManager")

--local Util = require("common.Util")
SceneContainer = SceneContainer or {}

function init()
    for mapId, mapConfig in pairs(MapConfig) do
		if mapConfig.scenetype == CommonDefine.SCENETYPE_MAP 
			or mapConfig.scenetype == CommonDefine.SCENETYPE_SINGLECOPY then
			local sceneId = mapId
			SceneContainer[sceneId] = Scene:new(sceneId)
		else
			for i = 1, mapConfig.sceneCount do
				local sceneId = mapId * 1000 + i
				SceneContainer[sceneId] = Scene:new(sceneId)
			end
		end
	end
end

--mapId 和 sceneId对应规则如下：
--场景地图和单人副本的mapId和sceneId是一一对应的，mapId就等于sceneId
--多人副本在服务器有多个实例，因此多个sceneId对应到一个mapId：sceneid = mapId * 1000 + xxx
function getSceneId(mapId,human)
	local mapConfig = MapConfig[mapId]
    if not mapConfig then
		LogErr("warn", "一个错误的mpaID = "..( mapId or 0 ) )
        return CommonDefine.INVALID_SCENEID
    end

    --todo
	if mapConfig.scenetype ~= CommonDefine.SCENETYPE_MAP then
        return CopyManager.getSceneId(mapId,human)
    else
        return mapId
    end
end

function getMapId(sceneId)
    if sceneId <= 999 then
        return sceneId
    else
        return math.floor(sceneId/1000)
    end
end

function getHeightAndWidth(sceneId)
	return 1024,768
end

function validateMapID(mapId)
	local m = MapConfig[mapId]
	if not m then
		LogErr("warn", "前端发来了一个错误的mpaID = "..( mapId or 0 ) )
		return CommonDefine.HUMAN_MAIN_MAPID;
	else
		return mapId;
	end
end

function getBornPoint(mapId)
   local mc = MapConfig[mapId]
   assert(mc)
   local bp = mc.born
   local nRadius = 50
   return bp.x + math.random(-nRadius,nRadius),bp.y + math.random(-nRadius,nRadius)
end

function objLeaveScene(objId,sceneId)
    local s = SceneContainer[sceneId]
    assert(s,"invalid sceneId "..tostring(sceneId))
    local o = ObjManager[objId]
    assert(o,"invalid objId "..tostring(objId))
    s:removeObj(o)
end

function objEnterScene(objId,sceneId)
    local s = SceneContainer[sceneId]
    assert(s,"invalid sceneid .."..tostring(sceneId))
    local o = ObjManager[objId]
    assert(o,"invalid objId .."..tostring(objId))
    s:addObj(o)
end

function getMapType(mapId)
    local m = MapConfig[mapId]
    if m then
        return m.scenetype
    else
        return 0
    end
end

function isValidMapId(mapId)
	return MapConfig[mapId] ~= nil
end

function isHumanCanEnter(mapId, oHuman)
    local minLev = MapConfig[mapId].level
    if minLev < oHuman:GetLv() then
        return true
    end
    
    return false
end

