module(..., package.seeall)

local Robot = require("robot.Robot")
local ChatDic = require("robot.ChatDict").ChatDict
local robot = Robot.Instance
--local TaskConfig = require("config.TaskConfig").Config
local CommonDefine = require("common.CommonDefine")
local Util = require("common.Util")
local CharacterDefine = require("character.CharacterDefine")
local PacketID = require("common.PacketID")
function DoAI(nameID, mapID)
-- print("DoAI==>name:"..nameID..",mapID:"..mapID..",step:"..robot.__step..",x:"..robot.scenex..",y:"..robot.sceney..",lv:"..robot.level)
    DoHeartBeat(nameID, mapID)
    if robot.__step == "init" then
        if robot.__enterCd == -1 then
            local t = _CurrentTime()
            print("randomseed "..t)
            math.randomseed(t)
            robot.__enterCd = math.random(1, 120)
            print("login entercd ="..robot.__enterCd)
            return
        elseif robot.__enterCd > 0 then
            robot.__enterCd = robot.__enterCd - 1
            return
        end
        --
        robot.svrName   = "[01]"    
        robot.account   = nameID    
        robot.authkey   = "test"    
        robot.timestamp = os.time()    
        robot.status    = 1        
        robot.job       = math.random(1, 6)
        robot.roleName  = nameID
        robot.cityNum   = 1 
        --
        robot.logintime = _CurrentTime()
        SendMsg(PacketID.CG_ASK_LOGIN,robot.svrName,robot.account,robot.authkey,robot.timestamp,robot.status)
        --
        robot.__step = "login"
    elseif robot.__step == "login" then
    elseif robot.__step == "info" then
        if robot.__infoCd == -1 then
            local t = _CurrentTime()
            print("randomseed "..t)
            math.randomseed(t)
            robot.__infoCd = math.random(50,120)
            print("infoCd = "..robot.__infoCd)
            robot.infoready = 1
            return
        elseif robot.__infoCd > 0 then
            robot.__infoCd = robot.__infoCd -1
            if robot.infoready == 1 then
                SendMsg(PacketID.CG_HUMAN_QUERY,1)
                local t = _CurrentTime()
                --print(robot.roleName.." send CG_HUMAN_QUERY "..robot.roleName.." currenttime ="..t)
                robot.infotime = t
                robot.infoready = 0
            end
            return
        end
        robot.__step = "logout"

    elseif robot.__step == "action" then
        --moveTo(101,1000,900)
        DoAction(nameID, mapID)
    elseif robot.__step == "logout" then
        local info = "infonum="..robot.infonum.." infoms="..robot.infoms.." info avarage="..tostring(robot.infoms/robot.infonum).." max="..robot.infomax.." min="..robot.infomin
        local infofile = io.open("info.log","a")
        infofile:write(info.."\n")
        infofile:close()
        print(info)
        _StopRobot(_pRobotThread)
    else 
        error(os.time().." ill cmd! robot = "..nameID.." step = "..robot.__step)
    end
end

-- 心跳包
function DoHeartBeat(nameID)
    local currTime = os.time()
    if robot.__heartBeatAt + robot.__heartBeatCd < currTime then
        --print(os.time().." == ".."HeartBeat nameID: "..nameID)
        SendMsg(PacketID.CG_HEART_BEAT)
        --
        robot.__heartBeatAt = currTime
    end
end

        
-- 执行各种登录之后的操作
function DoAction(nameID, mapID)
    if robot.__isDie then return end
    local rand = math.random(0, 99)
    if      100 > rand then 
        DoRandMove()
    elseif  5 > rand then 
        DoChat()
    elseif 10 > rand then
        DoSendMail()
    else
        if 20 > math.random(0, 99) then
            DoKillNearbyMob()
        end
        if robot.level < 35 then
            DoTask()
        else
            DoRandMove()
        end
        DoCGPickUpItem()
    end
end

-- MovePoint = {
--     {"x",          "SHORT",      1, "移动位置的x坐标"},
--     {"y",          "SHORT",      1, "移动位置的y坐标"},
-- }
-- 
-- CGMove = {
--     {"isJump",     "SHORT",     1,  "跳跃标识"},
--     {"points",     MovePoint,    64,    "移动位置的坐标"},
-- }
function DoRandMove()
    if robot.__moveCd > 0 then 
        robot.__moveCd = math.max(0, robot.__moveCd - 1)
        return 
    end
    -- 不让移动
    --if robot.__stop == 1 then return end
    -- 移动概率 %
    if 10 < math.random(1, 100) then return end
    --
    local pos_x, pos_y = robot.scenex, robot.sceney 
    local dis = 300
    local sMsg = GetMsg("CGMove")
    --for i=1,math.random(1, 64) do
    for i=1,2 do
        pos_x = math.max(0, math.min(robot.mapWidth , pos_x + math.random(-dis, dis)))
        pos_y = math.max(0, math.min(robot.mapHeight, pos_y + math.random(-dis, dis)))
        sMsg.points[i] = {x=pos_x,y=pos_y}
        --print(">>>>> move "..robot.objid.." x"..sMsg.points[i].x.." y"..rMsg.points[i].y)
        robot.scenex = pos_x
        robot.sceney = pos_y
    end

   -- sMsg.points[i].x = 1000
   -- sMsg.points[i].y = 900
   -- sMsg.pointsLen = 1  

    SendMsg(sMsg)
    --
    robot.__moveCd = 20
end

function setStop()  
    robot.__stop = 1 
end
function setAlive() 
    robot.__stop = 0 
end

-- 地图/位置切换
function moveTo(mapId, x, y)
    if robot.__moveCd > 0 then 
        robot.__moveCd = math.max(0, robot.__moveCd - 1)
        return 
    end

--print(">>> moveTo map:"..mapId..",x:"..x..",y:"..y)

    x = math.max(0, math.min(x + math.random(-20, 20), robot.mapWidth ))
    y = math.max(0, math.min(y + math.random(-20, 20), robot.mapHeight))
    if robot.mapid ~= mapId then
        print("====> tomap:"..mapId)
        --local sMsg = GetMsg("CGJumpAi")
        DoChat(0, "jy_it="..CharacterDefine.FLY_SHOE_ID)
        local sMsg = GetMsg("CGFly")
        sMsg.mapId = mapId 
        sMsg.posX = x 
        sMsg.posY = y 
        sMsg.npcId = -1 
        SendMsg(sMsg)
        --moveTo(mrobot.mapid, jump_x, jump_y)
        return 
    end

    local dis = math.random(10, 15)
    local nextX, nextY 
    -- 
    if robot.scenex == x then
        nextX = x
    elseif robot.scenex > x then
        nextX = robot.scenex - dis > x and x - dis or x
    else
        nextX = robot.scenex + dis < x and x + dis or x
    end

    if robot.sceney == y then
        nextY = y
    elseif robot.sceney > y then
        nextY = robot.sceney - dis > y and y - dis or y
    else
        nextY = robot.sceney + dis < y and y + dis or y
    end
        
    local sMsg = GetMsg("CGMove")
    sMsg.isJump = 0
    sMsg.pointsLen = 0
    for i=1,1 do
        sMsg.points[i].x = nextX
        sMsg.points[i].y = nextY
        sMsg.pointsLen = sMsg.pointsLen + 1
        robot.scenex = nextX
        robot.sceney = nextY
    end
    SendMsg(sMsg)
    robot.__moveCd = 5 
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
-- [10101001] = {
--     taskId=10101001
--     , name="天降大任"
--     , preTask=0
--     , viewLevel=1
--     , canDoLevel=1
--     , maxLevel=0
--     , type1=1
--     , type2=1
--     , maxTimes=1
--     , objId=0
--     , objPos={}
--     , objCount=0
--     , callback=0
--     , multiTarget={}
--     , finishCondition=0
--     , cookie=""
--     , npcType=0
--     , beginNPC=1011000
--     , endNPC=1011000
--     , rewardExp=300
--     , rewardMoney=300
--     , rewardLingli=300
--     , rewardXiuwei=0
--     , rewardGuildContribution=0
--     , rewardGuildWealth=0
--     , rewardItem={}
--     , taskLogic=""
--     , teamId=0
-- }
--
-- type1 => 
-- 1.主线任务；
-- 2.支线任务；
-- 3.历练任务;
-- 4.周常任务;
-- 5.悬赏任务;
-- 6.降妖除魔任务;
-- 7.异域降妖除魔任务;
-- 8.帮派试炼;
-- 9.你画我猜;
-- 10.帮派任务;
-- 11.师徒任务;
-- 12.境界任务
-- 
-- type2 =>
-- 1.对话任务；
-- 2.对话传送；
-- 3.打怪任务；
-- 4.采集任务；
-- 5.打开面板;
--[[                                                         
function DoTask() 
    if robot.__taskCd > 0 then 
        robot.__taskCd = math.max(0, robot.__taskCd - 1)
        return 
    end
    if 30 > math.random(0, 99) then
        DoChat(0, "jy_diaobao")
    end
    local flag, index, task, conf = "doing"
    index, task, conf = GetNextTask(robot.taskList.doingTasks)
    if not task then
        flag = "canDo"
        index, task, conf = GetNextTask(robot.taskList.canDoTasks)
    end
    if flag == "doing" and task then
print("doing task:"..task.taskId)

        -- 没有配置该任务
        local endNPC = task.endNPC
        --
        local isFinished = true
        if task.taskCurTime < conf.maxTimes and #task.obj > 0 then
            for _, v in pairs(task.obj) do
                for m,n in pairs(conf.multiCallback) do
                    if v.objId == n.objId then
                        v.objCount = n.objCount
                        if v.objCurNum < n.objCount then
                            isFinished = false
                        end
                        break
                    end
                end
            end
        end

        --
        if isFinished then -- 完成,前去提交
            if robot.mapid  == endNPC[1].mapId
                and math.abs(robot.scenex - endNPC[1].x) < 50
                and math.abs(robot.sceney - endNPC[1].y) < 50
            then -- 提交npc
                local sMsg = GetMsg("CGTaskFinish")
                sMsg.taskId = task.taskId
                sMsg.cookie = task.cookie
                SendMsg(sMsg)
            else -- 移动去npc
                moveTo(endNPC[1].mapId, endNPC[1].x, endNPC[1].y)
            end

        else -- 未完成，前去杀怪

            for _, mob in pairs(task.obj) do
                mob.objCount = mob.objCount or 0
                if mob.objCurNum >= mob.objCount then break end
                if robot.mapid ~= mob.mapId then -- 没在该地图
                    moveTo(mob.mapId, mob.x, mob.y)
                else 
                    local mapElemObjType
                    if mob.objType == 3 then -- 3.打怪任务；
                        mapElemObjType = CommonDefine.OBJ_TYPE_MONSTER --  = 2
                    elseif mob.objType == 4 then-- 4.采集任务；
--print("========>采集")
                        mapElemObjType = CommonDefine.OBJ_TYPE_COLLECT --  = 3
                    else
                        error("~~")
                    end
                    table.sort(robot.mapElemList[mapElemObjType], function(a, b)
                        return math.pow(robot.scenex - a.posx, 2) 
                             + math.pow(robot.sceney - a.posy, 2)
                             < math.pow(robot.scenex - b.posx, 2) 
                             + math.pow(robot.sceney - b.posy, 2)
                    end)
--Util.print_obj(robot.mapElemList[mapElemObjType])
                    for _, mon in pairs(robot.mapElemList[mapElemObjType]) do 
                        if mon.monsterId == mob.objId then 
                            if math.abs(robot.scenex - mon.posx) < 200 
                            and  math.abs(robot.sceney - mon.posy) < 200
                            then -- 在怪旁边，开始杀怪
                                if mob.objType ==3 then -- .打怪任务；
print("do打怪"..mon.monsterId) 
                                    KillEmemy(mapElemObjType, mon.objid)
                                elseif mob.objType ==4 then -- .采集任务；
print("do采集"..mon.monsterId)
                                    DoCollectTask(mapElemObjType, mon.objid)
                                end
                            else
                                moveTo(mob.mapId, mon.posx, mon.posy)
                            end
                            return
                        end
                    end
                    moveTo(mob.mapId, mob.x, mob.y) -- 直接走到传送阵旁边
                    -- error("not monster for kill")
                end
            end
        end
    elseif flag == "canDo" and task then
print("canDo task:"..task.taskId)
print("--------------------------- 262 taskId: "..task.taskId)
        local beginNPC = task.beginNPC
        if      robot.mapid  == beginNPC[1].mapId
            and math.abs(robot.scenex - beginNPC[1].x) < 50
            and math.abs(robot.sceney - beginNPC[1].y) < 50
        then -- 接受任务
print("--------------------------- 269")
            table.insert(robot.taskList.doingTasks, task)
            table.remove(robot.taskList.canDoTasks, index)
            --
            local sMsg = GetMsg("CGTaskAccept")
            sMsg.taskId = task.taskId
            SendMsg(sMsg)
        else -- 移动到开始npc处
print("--------------------------- 274")
            moveTo(beginNPC[1].mapId, beginNPC[1].x+math.random(-10, 10), beginNPC[1].y+math.random(-10, 10))
        end
    else
print("--------------------------- 276")
dump(robot.taskList.doingTasks,robot.taskList.canDoTasks)
    end

    robot.__taskCd = math.random(0, 2)
end

function GetNextTask(tasks)
    for i, task in pairs(tasks) do
        local conf = TaskConfig[task.taskId]
        if not conf then 
            table.remove(tasks, i)
            print("不存在任务：" .. task.taskId) 
            return
        end
        if conf.type1 == 1 or conf.type1 == 2 then
            return i, task, conf
        -- else
        --     table.remove(tasks, i)
        end
    end
end

-- TODO:
function KillEmemy(objType, objId)
    if robot.__skillCd > 0 then 
        robot.__skillCd = math.max(0, robot.__skillCd - 1)
        return 
    end
    -- --技能使用
    --local skillId = robot.job * 100000 + 10010
    local skillId = robot.job * 100000 
print("-------->>>>>> 294 kill ememy ["..objType.."] "..objId.." skillId: "..skillId)
    local sMsg = GetMsg("CGSkillUse")
    sMsg.skillId    = skillId
    sMsg.receiverId = objId
    sMsg.posX       = robot.scenex 
    sMsg.posY       = robot.sceney 
    SendMsg(sMsg)
    --
    sMsg = GetMsg("CGSkillHit")
    SendMsg(sMsg)
    --
    robot.__skillCd = 0
end

-- 杀附近的怪物
function DoKillNearbyMob()
    local objType = CommonDefine.OBJ_TYPE_MONSTER --  = 2
    local objId 
    for _, v in pairs(robot.mapElemList[objType]) do
        if (robot.scenex - v.posx) < 300 and (robot.sceney - v.posy) < 200 then
            if 90 > math.random(0, 99) then
                moveTo(
                    robot.mapid
                    , v.posx+math.random(-20, 20)
                    , v.posy+math.random(-20, 20)
                )
                objId = v.objid
                break
            end
        end
    end
    if objId then
        KillEmemy(objType, objId)
    end
end


function DoCollectTask(ObjType, objId)
    -- CGTaskCollectStart = {   
    --     {'objId',      'INT',      1},
    -- }
    -- CGTaskCollectFinish = {
    --     {'nouse',       'CHAR',     1},
    -- }
    
    if robot.__caijicd >= 0 then 
        robot.__caijicd = robot.__caijicd - 1 
    end

    if robot.__caijicd == 0 then 
        sMsg = GetMsg("CGTaskCollectFinish")
        SendMsg(sMsg)
    elseif robot.__caijicd < 0 then
        local sMsg = GetMsg("CGTaskCollectStart")
        sMsg.objId = objId
        SendMsg(sMsg)
        robot.__caijicd = 4 
    end
end

function GetNearbyRoleName()
    local name, nameLen
    for _, v in pairs(robot.mapElemList[CommonDefine.OBJ_TYPE_HUMAN]) do
        if 80 > math.random(0, 99) then
            name = v.rolename
            nameLen = v.rolenameLen
            break
        end
    end
    return name, nameLen
end

function DoChat(chatType, chatCont)
    if robot.__chatCd > 0 then 
        robot.__chatCd = math.max(0, robot.__chatCd - 1)
        return 
    end
    -- --chat type
    -- TYPE_WORLD = 0     --世界
    -- TYPE_SCENE = 1     --场景  
    -- TYPE_CAMP = 2      --阵营
    -- TYPE_GUILD = 3     --帮会
    -- TYPE_TEAM = 4      --队伍
    -- TYPE_PRIVATE = 5   --私聊
    -- TYPE_CHUAN_YIN = 6 --传音
    -- TYPE_SYSTEM = 7    --系统
    -- TYPE_GOSSIP = 8    --传闻
    -- CGChat = {
    --     {"type",        "CHAR",         1,      "聊天类型"},
    --     {"content",     "CHAR",         2,      "聊天内容"},
    --     {"name",        "CHAR",         2,      "私聊对象姓名"},
    --     {"isShake",     "CHAR",         1,      "是否抖动"},
    --     {"showItemList",ShowItem,       3,      "展示物品列表"},
    -- } 
    local name 
    local sMsg = GetMsg("CGChat")
    if not chatType then chatType = math.random(0, 8) end
    if not chatCont then chatCont = ChatDic[math.random(1, #ChatDic)] end
    if chatType == 5 then
        name, nameLen = GetNearbyRoleName()
        if not name then return end
        name = require("common.Util").GetStringFromTable(nameLen, name)
    end
    sMsg.type    = chatType
    sMsg.content = chatCont 
    sMsg.name    = name and name or ""
    sMsg.isShake = 0
    sMsg.showItemListLen = 0
    SendMsg(sMsg)
    --
    robot.__chatCd = math.random(1, 5)
end

-- CGSendMail = {
--     {'mailType',        'CHAR',      1,     '邮件类型'},
--     {'receiver',        'CHAR',     128,     '收件人'},
--     {'title',           'CHAR',      64,     '邮件标题'},
--     {'content',         'CHAR',     2048,   '邮件内容'},
--     {'bagPos',          POSES,      20,     '背包格子数组'},
--     {'bindMoney',        'INT',     1,      '绑定铜币'},
--     {'bindRmb',          'INT',     1,      '绑定元宝'},
-- }
function DoSendMail()
    local name, nameLen = GetNearbyRoleName()
    if not name then return end
    name = require("common.Util").GetStringFromTable(nameLen, name)
    local sMsg = GetMsg("CGSendMail")
    sMsg.mailType  = 0
    sMsg.receiver  = name
    sMsg.title     = "测试发邮件"..math.random(10, 99)
    sMsg.content   = "测试发邮件"..math.random(10, 99)
    sMsg.bagPosLen = 0
    sMsg.bagPos    = {}
    sMsg.bindMoney = 0
    sMsg.bindRmb   = 0
    SendMsg(sMsg)
end

-- CGPickUpItem = {    
--         {"objId",     "INT",         1, '掉落物的objId'},  -- objid
-- }
function DoCGPickUpItem()
    for _, v in pairs(robot.mapElemList[CommonDefine.OBJ_TYPE_ITEM]) do
        if   math.abs(v.posx - robot.scenex) < 150 
         and math.abs(v.posy - robot.sceney) < 150
        then
            local sMsg = GetMsg("CGPickUpItem")
            sMsg.objId = v.objid
            SendMsg(sMsg)
        end
    end
end
--]]

