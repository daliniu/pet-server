--背包模块自用的接口
module(...,package.seeall)
local PacketID = require("PacketID")
local BagDefine = require("modules.bag.BagDefine")
local ItemConfig = require("config.ItemConfig").Config
local Grid = require("modules.bag.Grid")
local Msg = require("core.net.Msg")
local BAG_OP = BagDefine.BAG_OP

function setGridsDirty(grids)
    for k,v in pairs(grids) do
       v.dirty = true 
    end
end

function makeBagList(bag)
	local needSend = false
    local grids = bag.grids
	local bagData = {}
    for pos = 1,bag.cap do
        local grid = grids[pos] 
        if grid.dirty then
			needSend = true
            grid.dirty = false
			table.insert(bagData,{id = grid.id,pos = pos,cnt = grid.cnt})
        end
    end
	return needSend,bag.cap,bagData
end

function canGridAddItem(grid, itemId, cap)
    if grid.cnt < 1 then
        return true
    end
    if grid.cnt < cap and grid.id == itemId then
        return true
    end
    return false
end

function canGridAppendItem(grid,itemId,cap)
    if grid.cnt > 0 and grid.cnt < cap and grid.id == itemId then
        return true
    end
    return false
end

function cmpGrid(gridA, gridB)
    if gridA.cnt < 1 or gridB.cnt < 1 then 
        return gridA.cnt > 0 
    end

    local itemA =  ItemConfig[gridA.id]
    local itemB =  ItemConfig[gridB.id]
	local typeA = math.floor(gridA.id / 100000)
	local typeB = math.floor(gridB.id / 100000)
    if itemA and itemB then
        if typeA == typeB then
			if itemA.color == itemB.color then
				return gridA.id < gridB.id 
			else
				return itemA.color > itemB.color
			end
        else
            return typeA < typeB
        end
    elseif itemA then
        return true
    else
        return false
    end
end

function uniqueGrid(bag)
    local grids         = bag.grids
    local cap           = bag.cap
    local i = 2
    local j = 1
    while i <= bag.cap do
        local grid = grids[i]
        if i <= j or grid.cnt < 1 then
            i = i + 1
        elseif moveItem(grid, grids[j], grid.cnt, ItemConfig[grid.id].cap) < 1 then
            j = j + 1
        elseif grids[i] == grids[j] then
            assert(false)
        end
    end
end

--移动源格子物品给目标格子,cnt 期望移动数目，cap 物品堆叠数
--返回成功移动物品数目，小于1表示失败
function moveItem(src, dst, cnt, cap)
    if not cnt or cnt < 1 then
        return 0
    end
    
    if src.cnt < 1 then
        return 0
    end
    
    if dst.cnt > 0 and src.id ~= dst.id then
        return 0
    end
    
	--[[
    if dst.cnt < 1 then
        dst.cnt   = 0
        dst.id      = src.id 
    end
	--]]
    
    local cntReal   = math.min(src.cnt, cap - dst.cnt)
    cntReal         = math.min(cntReal, cnt)
    dst.cnt       = dst.cnt + cntReal
    src.cnt       = src.cnt - cntReal
    src.dirty      = true
    dst.dirty      = true
    return cntReal
end

function isValidPos(human, pos)
    return pos and 0 < pos and pos <= human:getBag().cap
end

--其中一组道具没有达到叠加最大数时，则从改组道具扣除相应消耗 
--多组叠加道具达到最大数时，则按照次序消耗最后一组道具
--
function getGrid(human, itemId) 
	local bag = human:getBag()
	local grids = bag.grids
	local cfg = ItemConfig[itemId]
	for i = 1, bag.cap do
		if grids[i].cnt > 0 and grids[i].id == itemId and grids[i].cnt < cfg.cap then
			return grids[i],i 
		end
	end
	for i = bag.cap,1,-1 do
		if grids[i].cnt > 0 and grids[i].id == itemId and grids[i].cnt == cfg.cap then
			return grids[i],i
		end
	end
end

function getGridNum(human)
	local res = 0
	local bag = human:getBag()
	for k = 1,bag.cap do
		res = res + bag.grids[k].cnt > 0 and 1 or 0
	end
	return res
end

