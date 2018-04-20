module(..., package.seeall)

local Robot = require("robot.Robot")
local robot = Robot.Instance

local PacketID     = require("common.PacketID")
local CommonDefine = require("common.CommonDefine")
local CharacterDefine = require("character.CharacterDefine")
--local ItemDefine = require("item.ItemDefine")
--local TaskDefine = require("task.TaskDefine")

-- GC_ASK_LOGIN = 10002
function onGCAskLogin(result,svrName,msvrIP,msvrPort) 
    assert(robot.__step == "login")
    print("onGCAskLogin  result ="..result)
    --print("~~~~~~~~~ "..rMsg.result)
    -- 登录错误码
    if result == CharacterDefine.ASK_LOGIN_OK                then -- = 1     -- 成功登录
        print(os.time().." "..robot.roleName.." login ok!")
        local t = _CurrentTime()
        if tostring(robot.login_file) == "0" then 
            robot.login_file = io.open("login.log","a")
        end
        robot.login_file:write("login ="..tostring(t-robot.logintime).." "..robot.roleName.."\n")
        robot.login_file:close()
        robot.__step = "info"
    elseif result == CharacterDefine.ASK_LOGIN_ERROR_CREATE_CHAR then -- = 2     -- 登录失败 创建角色失败
        assert(false, result)
    elseif result == CharacterDefine.ASK_LOGIN_GO_TO_MSVR        then -- = 3     -- 跨服pk中，需要重定向到msvr
        assert(false, result)
    elseif result == CharacterDefine.ASK_LOGIN_SERVER_FULL       then -- = 4     -- 服务器人数已满 无法登录
        assert(false, result)
    elseif result == CharacterDefine.ASK_LOGIN_FAIL              then -- = 5     --登录验证不通过
        assert(false, result)
    elseif result == CharacterDefine.ASK_LOGIN_TIMEOUT           then -- = 6     --登录超时
        assert(false, result)
    elseif result == CharacterDefine.ASK_LOGIN_NO_CHAR           then -- = 7     --还没选角色
        print("send CGChooseChar,sex="..robot.sex.." roleName="..robot.roleName)
        --SendMsg(sMsg)
        SendMsg(PacketID.CG_CHOOSE_CHAR,robot.sex,robot.roleName)
    elseif result == CharacterDefine.ASK_LOGIN_NAME_EXIST        then -- = 8     --选角名字重复
        assert(false, result)
    else
        assert(false, result)
    end
    return true
end
function onGCHumanQuery(kbid)
    local t = _CurrentTime()
    local duration = t - robot.infotime
    if duration > 60 then
        print(robot.roleName.." receive curtime="..t.." dur="..duration)
    end
    robot.infonum = robot.infonum + 1
    
    robot.infoms = robot.infoms + duration
    if duration < robot.infomin then 
        robot.infomin = duration
    end
    if duration > robot.infomax then 
        robot.infomax = duration
    end
    robot.infoready = 1
end

-- GC_HUMAN_INFO = 10006
--[[
function OnGCHumanInfo(rMsg)
    assert(robot.__step == "info")
    robot.sceney      = rMsg.sceney     
    robot.objid       = rMsg.objid      
    robot.maptype     = rMsg.maptype    
    robot.scenex      = rMsg.scenex     
    robot.mapid       = rMsg.mapid         
    robot.level       = rMsg.level      
    robot.roleName    = rMsg.rolename     
    robot.timeServer  = rMsg.timeServer 
    robot.sex         = rMsg.sex                     
    --
    local sMsg
    -- 10004 CG_ENTER_SCENE_OK
    --sMsg = GetMsg("CGEnterSceneOK")
    --sMsg.sceneid = 101
    --SendMsg(sMsg)
    -- 10403 CG_ASK_MAIL_LIST
    sMsg = GetMsg("CGAskMailList")
    sMsg.mailType = 1
    sMsg.curPage  = 0
    SendMsg(sMsg)
    -- 12901 CG_BOARD_QUERY
    sMsg = GetMsg("CGBoardQuery")
    sMsg.type = 1001
    sMsg.job  = robot.job
    sMsg.sex  = robot.sex
    SendMsg(sMsg)
    -- 11907 CG_TAO_STORE_DETAIL
    sMsg = GetMsg("CGTaoStoreDetail")
    SendMsg(sMsg)
    -- 13101 CG_VIP_INFO
    sMsg = GetMsg("CGVipInfo")
    SendMsg(sMsg)

    --
    robot.__step = "action"
    return true
end

function OnGCEnterScene(rMsg)
    robot.objid     = rMsg.objid    
    robot.mapid     = rMsg.mapid    
    robot.maptype   = rMsg.maptype  
    robot.scenex    = rMsg.scenex   
    robot.sceney    = rMsg.sceney   
    robot.mode      = rMsg.mode     
    robot.mapWidth  = rMsg.mapWidth 
    robot.mapHeight = rMsg.mapHeight
    -- 10004 CG_ENTER_SCENE_OK
    sMsg = GetMsg("CGEnterSceneOK")
    sMsg.sceneid = mapid
    SendMsg(sMsg)
end

--]]
--[[
-- 登录时收到的协议
-- 10901 GC_BAG_LIST
-- 10902 GC_EQUIP_UPDATE
-- 10903 GC_EQUIP_LIST
-- 10902 GC_EQUIP_UPDATE
-- 10707 GC_SEND_COOLDOWN_LIST
-- 10706 GC_SKILL_LIST
-- 10714 GC_TOOLBAR_LIST
-- 10801 GC_SEND_BUFF_LIST
-- 10011 GC_DETAIL_ATTR
-- 11205 GC_TASK_LIST
-- 11214 GC_REWARD_TASK_INFO
-- 10032 GC_SYSTEM_CONFIG
-- 11702 GC_HORSE_QUERY
-- 11704 GC_HORSE_ICON_QUERY
-- 10404 GC_ASK_MAIL_LIST
-- 12902 GC_BOARD
-- 11908 GC_TAO_STORE_DETAIL

-- 10011 GC_DETAIL_ATTR
function OnGCDetailAttr(rMsg)
    robot.level      = rMsg.level      -- SHORT     1      角色等级
    robot.maxhp      = rMsg.maxhp      -- INT       1      角色最大hp
    robot.maxmp      = rMsg.maxmp      -- INT       1      角色最大mp
    robot.hp         = rMsg.hp         -- INT       1      角色当前hp
    robot.mp         = rMsg.mp         -- INT       1      色当前mp
    robot.exp        = rMsg.exp        -- INT       1      经验值
    robot.lingli     = rMsg.lingli     -- INT       1      灵力值
    robot.rmb        = rMsg.rmb        -- INT       1      元宝
    robot.bindrmb    = rMsg.bindrmb    -- INT       1      绑定元宝
    robot.money      = rMsg.money      -- INT       1      铜币
    robot.bindmoney  = rMsg.bindmoney  -- INT       1      绑定铜币 
    robot.atk        = rMsg.atk        -- SHORT     1      攻击力     
    robot.def        = rMsg.def        -- SHORT     1      防御力  
    robot.dodge      = rMsg.dodge      -- SHORT     1      闪避  
    robot.hitrate    = rMsg.hitrate    -- SHORT     1      命中  
    robot.bash       = rMsg.bash       -- SHORT     1      暴击  
    robot.tough      = rMsg.tough      -- SHORT     1      坚韧
    robot.atkSpeed   = rMsg.atkSpeed   -- SHORT     1      攻击速度
    robot.defA       = rMsg.defA       -- SHORT     1      抗性A
    robot.defB       = rMsg.defB       -- SHORT     1      抗性B
    robot.defC       = rMsg.defC       -- SHORT     1      抗性C
    robot.xiuWei     = rMsg.xiuWei     -- INT       1      修为
    robot.anger      = rMsg.anger      -- INT       1      怒气
    robot.arenaScore = rMsg.arenaScore -- INT       1      擂台积分  
    --
    if robot.hp < 1 then 
        robot.__isDie = true
    end
end

-- 10901 GC_BAG_LIST
-- GridData = {
--     {"id",      "INT",      1,  "静态表id"},
--     {"pos",     "SHORT",    1,  "格子位置"},
--     {"count",   "SHORT",    1,  "物品数量"},
--     {"isBind",  "SHORT",    1,  "是否绑定"},
--     {"equipId", "INT",      1,  "装备索引"},
-- }
-- --- 背包 ---
-- GCBagList = {
--     {"op",      "CHAR",     1,  "背包更新操作码"},
--     {"bagData", GridData,   180, "背包数组"},
-- }
function OnGCBagList(rMsg)
    if     rMsg.op == ItemDefine.BAG_OP.LIST                 then 
    elseif rMsg.op == ItemDefine.BAG_OP.REBUILD              then 
    elseif rMsg.op == ItemDefine.BAG_OP.DISCARD              then 
    elseif rMsg.op == ItemDefine.BAG_OP.SWAP                 then 
    elseif rMsg.op == ItemDefine.BAG_OP.DIVIDE               then 
    elseif rMsg.op == ItemDefine.BAG_OP.ADDITEM              then 
    elseif rMsg.op == ItemDefine.BAG_OP.DELITEM              then 
    elseif rMsg.op == ItemDefine.BAG_OP.SWAP_WITH_EQUIP_GRID then  --跟装备格子交换
    elseif rMsg.op == ItemDefine.BAG_OP.DEAL                 then 
    elseif rMsg.op == ItemDefine.BAG_OP.MAGICBOX             then  --开箱子
    elseif rMsg.op == ItemDefine.BAG_OP.REFINE               then  --精炼
    elseif rMsg.op == ItemDefine.BAG_OP.QUICK_BUY            then  --快速购买
    elseif rMsg.op == ItemDefine.BAG_OP.GUILD                then 
    elseif rMsg.op == ItemDefine.BAG_OP.MARKET               then 
    elseif rMsg.op == ItemDefine.BAG_OP.BAG_SALE             then  --背包出售
    elseif rMsg.op == ItemDefine.BAG_OP.SWAP_WITH_STORE      then  --与仓库交换数据
    elseif rMsg.op == ItemDefine.BAG_OP.PET                  then  --宠物相关
    elseif rMsg.op == ItemDefine.BAG_OP.TASK_FINISH_GET_ITEM then  --任务相关
    elseif rMsg.op == ItemDefine.BAG_OP.PICK_UP              then   --拾取
    elseif rMsg.op == ItemDefine.BAG_OP.GUILD_BUY            then  -- 帮会商店购买
    elseif rMsg.op == ItemDefine.BAG_OP.SWAP_WITH_GUILD_BAG  then  -- 与帮会仓库交换数据
    elseif rMsg.op == ItemDefine.BAG_OP.ADDITEM              then 
    elseif rMsg.op == ItemDefine.BAG_OP                      then
    else
    end
    for i=1, rMsg.bagDataLen do -- 用位置索引
--        robot.bagList[rMsg.bagData[i].pos] = rMsg.bagData[i]
    end
end


function copyTaskNode(taskNodeLen, taskNodes)
    local list = {}
    for i=1, taskNodeLen do
        list[i] = {}
        list[i].taskId      = taskNodes[i].taskId     
        list[i].taskCurTime = taskNodes[i].taskCurTime
        list[i].obj = {}
        for j=1, taskNodes[i].objLen do
            list[i].obj[j] = {}
            list[i].obj[j].objId     = taskNodes[i].obj[j].objId    
            list[i].obj[j].objType   = taskNodes[i].obj[j].objType  
            list[i].obj[j].x         = taskNodes[i].obj[j].x        
            list[i].obj[j].y         = taskNodes[i].obj[j].y        
            list[i].obj[j].mapId     = taskNodes[i].obj[j].mapId    
            list[i].obj[j].objCurNum = taskNodes[i].obj[j].objCurNum
            list[i].obj[j].cbType = taskNodes[i].obj[j].cbType
        end
        list[i].cookie      = taskNodes[i].cookie    
        list[i].beginNPC    = {}
        for j=1, taskNodes[i].beginNPCLen do
            list[i].beginNPC[j] = {}
            list[i].beginNPC[j].objId = taskNodes[i].beginNPC[j].objId
            list[i].beginNPC[j].x     = taskNodes[i].beginNPC[j].x    
            list[i].beginNPC[j].y     = taskNodes[i].beginNPC[j].y    
            list[i].beginNPC[j].mapId = taskNodes[i].beginNPC[j].mapId
        end
        list[i].endNPC    = {}
        for j=1, taskNodes[i].endNPCLen do
            list[i].endNPC[j] = {}
            list[i].endNPC[j].objId = taskNodes[i].endNPC[j].objId
            list[i].endNPC[j].x     = taskNodes[i].endNPC[j].x    
            list[i].endNPC[j].y     = taskNodes[i].endNPC[j].y    
            list[i].endNPC[j].mapId = taskNodes[i].endNPC[j].mapId
        end
    end
    return list
end

-- -- 10101
-- GCReturnCode = {
--     {"id",          "INT",          1,  "id"},       --AAABBB AAA代表模块号(依据PACKID的规则) BBB是由各模块自行定义
--     {"showWay",     "CHAR",         1,  "消息显示方式"}, --参照 common/Broadcast 的消息显示方式
--     {"retCode",     "CHAR",         1,  "返回码"},
--     {"content",     "CHAR",         2,  "显示内容"},
-- }
function OnGCReturnCode(rMsg)
    if rMsg.id == PacketID.GC_TASK_ACCEPT then
    elseif rMsg.id == PacketID.GC_CHAT then -- 10202
        dump(rMsg.id, rMsg.retCode)
    else
        dump(rMsg.id, rMsg.retCode)
    end
end


-- -- 11205 GC_TASK_LIST
-- GCTaskList = {
--     {'doingTasks',    TaskNode,    50,    '已接任务'},
--     {'canDoTasks',    TaskNode,    50,    '可接任务'},
-- }
-- TaskNode = {
--     {'taskId',      'INT',     1,    '任务id'},
--     {'taskCurTime', 'SHORT',   1,    '当天已做次数'},
--     {'obj',          OBJ,      10,   '怪物'},
--     {'cookie',      'CHAR',    1024, '特殊参数'},
--     {'beginNPC',     NPCINFO,  2,    '接任务NPC'},
--     {'endNPC',       NPCINFO,  2,    '交任务NPC'},
-- }
-- OBJ = {
--     {'objId'     , 'INT'   , 1 , '对象id'}       ,
-- 	   {'objType'   , 'INT'   , 1 , '对象类型'}     ,
--     {'x'         , 'SHORT' , 1 , 'x坐标'}        ,
--     {'y'         , 'SHORT' , 1 , 'y坐标'}        ,
--     {'mapId'     , 'SHORT' , 1 , '地图id'}       ,
--     {'objCurNum' , 'SHORT' , 1 , '已杀怪物数量'} ,
-- }
-- NPCINFO = {
--     {'objId'     , 'INT'   , 1 , 'NPC id'}       ,
--     {'x'         , 'SHORT' , 1 , 'x坐标'}        ,
--     {'y'         , 'SHORT' , 1 , 'y坐标'}        ,
--     {'mapId'     , 'SHORT' , 1 , '地图id'}       ,
-- }
function OnGCTaskList(rMsg)
    local taskList = {}
    taskList.doingTasks = copyTaskNode(rMsg.doingTasksLen, rMsg.doingTasks)
    taskList.canDoTasks = copyTaskNode(rMsg.canDoTasksLen, rMsg.canDoTasks)
    robot.taskList = taskList
end

-- -- GC_TASK_ADD            = 11206
-- GCTaskAdd = {
--     {'tasks',         TaskNode,    50,     '添加可接任务'},
-- }
function OnGCTaskAdd(rMsg)
    local tasks = copyTaskNode(rMsg.tasksLen, rMsg.tasks)
    for i, v in pairs(tasks) do
        table.insert(robot.taskList.canDoTasks, v)
    end
end

-- -- GC_TASK_DEL            = 11207
-- GCTaskDel = {
--     {'taskId',        'INT',       30,      '删除任务id'},
-- }
function OnGCTaskDel(rMsg)
    local Len = rMsg.taskIdLen
    for i = 1, Len do
        DelTaskById(i)
    end
end


function DelTaskById(id)
    for j, v in pairs(robot.taskList.doingTasks) do
        if v.taskId == id then
            table.remove(robot.taskList.doingTasks, j)
            break
        end
    end
    for j, v in pairs(robot.taskList.canDoTasks) do
        if v.taskId == id then
            table.remove(robot.taskList.canDoTasks, j)
            break
        end
    end
end


-- GC_TASK_FINISH         = 11211  --完成任务
-- GCTaskFinish = {  
--     {'taskId',      'INT',      1},   
--     {'retCode',     'CHAR',    1}, 
-- }
function OnGCTaskFinish(rMsg)
    return DelTaskById(rMsg.taskId)
end
 
-- GCTaskObjNum = {    
--     {'taskId',      'INT',      1},  
--     {'objTypeId',   'INT',      1},  
--     {'objNum',      'SHORT',    1},
-- }
function OnGCTaskObjNum(rMsg)
    for _, v in pairs(robot.taskList.doingTasks) do
        if v.taskId == rMsg.taskId then
            for _, vobj in pairs(v.obj) do
                if vobj.objId == rMsg.objTypeId then
                    vobj.objCurNum = rMsg.objNum   
                end
                break
            end
            break
        end
    end
end

-- -- GC_TASK_STATUS         = 11208
-- GCTaskStatus = {
--     {'taskId',        'INT',       1,       '返回已接任务id'},
--     {'taskStatus',    'INT',       1,       '返回已接任务状态'},
-- }
-- --- task status ---
-- TASK_CAN_DO = 0   --可接，nil也是可接
-- TASK_ACCEPT = 1   --已接
-- TASK_FINISH = 2   --完成
-- TASK_FAILED = 3   --失败
function OnGCTaskStatus(rMsg)
    local taskId = rMsg.taskId
    if     rMsg.taskStatus == TaskDefine.TASK_CAN_DO then
    elseif rMsg.taskStatus == TaskDefine.TASK_ACCEPT then
        for i, v in pairs(robot.taskList.canDoTasks) do
            if v.taskId == taskId then
                table.remove(robot.taskList.canDoTasks, i)
                table.insert(robot.taskList.doingTasks, v)
                break
            end
        end
    elseif rMsg.taskStatus == TaskDefine.TASK_FINISH then
        return DelTaskById(rMsg.taskId)
    elseif rMsg.taskStatus == TaskDefine.TASK_FAILED then
        error("fail task: " .. taskId)
    else
        error("unknown taskStatus: " .. rMsg.taskStatus)
    end
end

--------------------------------------------------

-- 移动
-- MovePoint = {
--     {"x",       "SHORT",     1, "移动位置的x坐标"},
--     {"y",       "SHORT",     1, "移动位置的y坐标"},
-- }
-- GCMove = {
--     {"objId",   "INT",       1, "角色objid"},
--     {"objType", "SHORT",     1, "角色objtype"},
--     {"isJump",  "SHORT",     1, "跳跃标识"}, 
--     {"points",   MovePoint, 64, "移动位置的坐标"},
-- }
function OnGCMove(rMsg)
    -- print(">>>>>>>>>>>>>>>>>>>>>>>> "
    --     ..rMsg.objType
    --     .." -> "
    --     ..rMsg.objId
    --     .." ( "
    --     ..rMsg.points[1].x
    --     ..", "
    --     ..rMsg.points[1].y
    --     .." )"
    -- )
    if rMsg.objType == CommonDefine.OBJ_TYPE_HUMAN and rMsg.objId == robot.objid then return true end
    if not robot.mapElemList[rMsg.objType][rMsg.objId] then return false end
    local posx, posy
    for i=1, rMsg.pointsLen do
        posx = rMsg.points[i].x
        posy = rMsg.points[i].y
    end
    --- 对象类型 ---
    if     rMsg.objType == CommonDefine.OBJ_TYPE_INVALID then --  = -1            --// 无效
        return false
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_HUMAN   then --  = 0             --// 玩家
        robot.mapElemList[rMsg.objType][rMsg.objId].posx = posx
        robot.mapElemList[rMsg.objType][rMsg.objId].posy = posy
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_NPC     then --  = 1
        robot.mapElemList[rMsg.objType][rMsg.objId].posx = posx
        robot.mapElemList[rMsg.objType][rMsg.objId].posy = posy
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_MONSTER then --  = 2
        robot.mapElemList[rMsg.objType][rMsg.objId].posx = posx
        robot.mapElemList[rMsg.objType][rMsg.objId].posy = posy
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_COLLECT then --  = 3
        error(rMsg.objType.." => "..rMsg.objId)
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_JUMP    then --  = 4
        error(rMsg.objType.." => "..rMsg.objId)
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_ITEM    then --  = 5
        robot.mapElemList[rMsg.objType][rMsg.objId].posx = posx
        robot.mapElemList[rMsg.objType][rMsg.objId].posy = posy
    elseif rMsg.objType == CommonDefine.OBJ_TYPE_PET     then --  = 6
        robot.mapElemList[rMsg.objType][rMsg.objId].posx = posx
        robot.mapElemList[rMsg.objType][rMsg.objId].posy = posy
    else
        error(rMsg.objType.." => "..rMsg.objId)
    end
    --
end

-- 增加地图元素
-- GC_ADD_PLAYER  = 10009 --玩家
function OnGCAddPlayer(rMsg)
    local player = {}
    player.rolenameLen = rMsg.rolenameLen
    player.rolename        = rMsg.rolename         -- ,CHAR,      64, 角色名字},
    player.level           = rMsg.level            -- ,SHORT,      1, 角色等级},
    player.status          = rMsg.status           -- ,CHAR,       1, 打坐之类的状态},
    player.job             = rMsg.job              -- ,CHAR,       1, 职业},
    player.guild           = rMsg.guild            -- ,CHAR,      64, 帮会},
    player.camp            = rMsg.camp             -- ,CHAR,       1, 阵营},
    player.bodyId          = rMsg.bodyId           -- ,SHORT,      1, 形象Id},
    player.friendSit       = rMsg.friendSit        -- ,CHAR,      64, 双休角色名字}, 
    player.horseIcon       = rMsg.horseIcon        -- ,INT,        1, 坐骑形象},
    player.horsePower      = rMsg.horsePower       -- ,CHAR,       1, 坐骑显示强化值},
    -- C++
    player.objid           = rMsg.objid            -- ,INT,        1, 角色objid},
    player.posx            = rMsg.posx             -- ,SHORT,      1, 角色当前位置X},
    player.posy            = rMsg.posy             -- ,SHORT,      1, 角色当前位置X},
    -- rMsg.targetPos     -- ,MovePoint, 64, 角色移动路径},
    player.targetDirection = rMsg.targetDirection  -- ,CHAR,  1, 角色面朝的方向},
    player.maxhp           = rMsg.maxhp            -- ,INT,   1, 角色最大hp},
    player.maxmp           = rMsg.maxmp            -- ,INT,   1, 角色最大mp},
    player.hp              = rMsg.hp               -- ,INT,   1, 角色当前hp}, 
    player.mp              = rMsg.mp               -- ,INT,   1, 角色当前mp},
    player.speed           = rMsg.speed            -- ,SHORT, 1, 角色移动速度},
    player.diaphaneity     = rMsg.diaphaneity      -- ,CHAR,  1, 透明度(隐身功能)},
    player.isjump          = rMsg.isjump           -- ,CHAR,  1, 是否是跳跃},
    --
    robot.mapElemList[CommonDefine.OBJ_TYPE_HUMAN][rMsg.objid] = player
end

-- GC_ADD_MONSTER = 10501 --怪物九宫格添加
function OnGCAddMonster(rMsg)
    local mob = {}
    local nObjType = math.floor(rMsg.monsterId/1000)%10  

    mob.monsterId   = rMsg.monsterId   -- , INT,        1,   '怪物类型ID'}, -- 怪物类型ID
    --mob.gbufferItems = rMsg.bufferItems -- , BufferAddMonsterItem,   20,     'buffer列表'},-- buffer列表    
    --C++
    mob.objid       = rMsg.objid       -- , INT,        1},  -- 怪物objid  
    mob.posx        = rMsg.posx        -- , SHORT,      1},  -- 怪物当前位置X    
    mob.posy        = rMsg.posy        -- , SHORT,      1},  -- 怪物当前位置X    
    --mob.gtargetPos   = rMsg.targetPos   -- , MovePoint,    64}, -- 怪物移动路径    
    mob.maxhp       = rMsg.maxhp       -- , INT,        1},  -- 怪物最大hp    
    mob.maxmp       = rMsg.maxmp       -- , INT,        1},  -- 怪物最大mp    
    mob.hp          = rMsg.hp          -- , INT,        1},  -- 怪物当前hp    
    mob.mp          = rMsg.mp          -- , INT,        1},  -- 怪物当前mp        
    mob.speed       = rMsg.speed       -- , SHORT,      1},  -- 怪物移动速度
    --

    if nObjType == CommonDefine.OBJ_TYPE_MONSTER then 
        robot.mapElemList[CommonDefine.OBJ_TYPE_MONSTER][rMsg.objid] = mob
    elseif nObjType == CommonDefine.OBJ_TYPE_COLLECT then
        robot.mapElemList[CommonDefine.OBJ_TYPE_COLLECT][rMsg.objid] = mob
    elseif nObjType == CommonDefine.OBJ_TYPE_JUMP then
        robot.mapElemList[CommonDefine.OBJ_TYPE_JUMP][rMsg.objid] = mob
    end
end

-- GC_ADD_NPC     = 10502 --NPC九宫格添加
function OnGCAddNPC(rMsg)
    local npc = {}
    npc.npcId = rMsg.npcId -- , INT,        1,     'NPC id'},  -- NPC id    
    -- C++
    npc.objid = rMsg.objid -- , INT,        1},  -- objid 
    npc.posx  = rMsg.posx  -- , SHORT,      1},  -- 当前位置X    
    npc.posy  = rMsg.posy  -- , SHORT,      1},  -- 当前位置X
    --
    robot.mapElemList[CommonDefine.OBJ_TYPE_NPC][rMsg.objid] = npc
end

-- GC_ADD_ITEM    = 10503 --道具九宫格添加
function OnGCAddItem(rMsg)
    local item = {}
    item.id         = rMsg.id         -- INT",        1, '道具id'},  -- 道具id    
    item.createTime = rMsg.createTime -- INT",       1,  '创建时间'},  -- 创建时间    
    item.ownerId    = rMsg.ownerId    -- INT",       1,  '物主'},  -- 物主    
    -- C++
    item.objid      = rMsg.objid      -- INT",        1},  -- objid    
    item.posx       = rMsg.posx       -- SHORT",      1},  -- 当前位置X    
    item.posy       = rMsg.posy       -- SHORT",      1},  -- 当前位置X
    --
    robot.mapElemList[CommonDefine.OBJ_TYPE_ITEM][rMsg.objid] = item
end

-- GC_ADD_PET     = 10301 --宠物
function OnGCAddPet(rMsg)
    local pet = {}
    pet.name        = rMsg.name       -- CHAR         64     宠物名} 
    pet.level       = rMsg.level      -- SHORT        1      宠物等级}
    pet.step        = rMsg.step       -- SHORT        1      宠物阶级}--宠物阶级
    pet.full        = rMsg.full       -- SHORT        1      饱食度}
    pet.exp         = rMsg.exp        -- INT          1      经验值}
    pet.maxExp      = rMsg.maxExp     -- INT          1      最大经验值}
    pet.bodyId      = rMsg.bodyId     -- SHORT        1      宠物bodyId}
    --pet.bufferItems = rMsg.bufferItems-- BufferAddPetItem    20宠物buffer列表}
    pet.masterid    = rMsg.masterid   -- INT          1      宠物主人id}
    pet.masterName  = rMsg.masterName -- CHAR         64     宠物主人名} --主人名称
    pet.aiState     = rMsg.aiState    -- SHORT 1             宠物ai状态}
    -- C++
    pet.objid       = rMsg.objid      --INT        1     宠物objid}  
    pet.posx        = rMsg.posx       --SHORT      1     宠物当前位置X}  
    pet.posy        = rMsg.posy       --SHORT      1     宠物当前位置Y}  
    --pet.targetPos   = rMsg.targetPos  -- MovePoint    64    宠物移动路径} 
    pet.maxhp       = rMsg.maxhp      --INT        1     宠物最大hp}  
    pet.maxmp       = rMsg.maxmp      --INT        1     宠物最大mp}  
    pet.hp          = rMsg.hp         --INT        1     宠物当前hp}  
    pet.mp          = rMsg.mp         --INT        1     宠物当前mp}  
    pet.speed       = rMsg.speed      --SHORT      1     宠物移动速度}  
    --
    robot.mapElemList[CommonDefine.OBJ_TYPE_PET][rMsg.objid] = pet
end


-- 删除地图元素
-- GC_DEL_ROLE = 10010
function OnGCDelRole(rMsg)
    robot.mapElemList[rMsg.objType][rMsg.objId] = nil
end


-- GCChat = {                     
--     {"type",        "CHAR",         1,      "聊天类型"},
--     {"vipLv",       "CHAR",         1,      "VIP等级"},
--     {"camp",        "CHAR",         1,      "阵营"},
--     {"sex",         "CHAR",         1,      "性别"},
--     {"senderName",  "CHAR",         2,      "发送者姓名"},
--     {"head",        "INT",          1,      "头像"},
--     {"content",     "CHAR",         2,      "聊天内容"},
--     {"objId",       "INT",          1,      "角色ID"},
--     {"isShake",     "CHAR",         1,      "是否抖动"},
--     {"receiverName","CHAR",         2,      "接收者姓名"},
--     {"itemList",    require("item.Protocol").ItemTipsData,       6,      "物品装备列表"},
--     {"horseList",   require("horse.Protocol").HorseData,         6,      "坐骑列表"},
-- } 
function OnGCChat(rMsg)
end
--]]