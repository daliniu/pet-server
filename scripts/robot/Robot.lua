module(..., package.seeall)

local Util = require("common.Util")
Util.IncludeClassHeader(...)
local CommonDefine = require("common.CommonDefine")

function Init(self)
    -- init
    self.__step = "init" -- init => login => info => action => logout
    self.__heartBeatAt = 0
    self.__heartBeatCd = 30
    self.__stop = 1 -- 0可移动，1停止
    self.__isDie = false
    self.__enterCd = -1
    self.__infoCd = -1
    self.__moveCd = 0
    self.__taskCd = 0
    self.__skillCd = 0
    self.__chatCd = 0
    self.__caijicd = 0
    self.infonum = 0       -- info消息次数
    self.infoms = 0        -- info消息总的耗时毫秒数
    self.infomax = 0
    self.infomin = 99999
    self.logintime = 0
    self.login_file = 0
    self.infotime = 0
    self.infoready = 0      -- 是否可以发送
    --self.svrName    = ""
    self.account   = ""
    self.authkey   = ""
    self.timestamp = 0
    --self.status    = 0
    --self.job       = 0
    --self.roleName  = ""
    self.cityNum   = 0
    -- GC_ASK_LOGIN  = 10002
    self.result    = 0 
    self.svrName   = "" 
    self.msvrIP    = ""
    self.msvrPort  = 0 
    -- GC_HUMAN_INFO =  10006
    self.mapWidth    = 0  -- number(4703)
    self.sceney      = 0  -- number(527)
    self.atkmode     = 0  -- number(0)
    self.objid       = 0  -- number(128)
    self.maptype     = 0  -- number(1)
    self.scenex      = 0  -- number(3571)
    self.mapid       = 0  -- number(101)
    self.camp        = 0  -- number(1)
    self.speed       = 0  -- number(120)
    self.level       = 0  -- number(1)
    self.rolenameLen = 0  -- number(0)
    self.roleName    = "" -- string([01]kbtest)
    self.horsePower  = 0  -- number(0)
    self.horseIcon   = 0  -- number(0)
    self.bodyId      = 0  -- number(3)
    self.job         = 0  -- number(3)
    self.guildLen    = 0  -- number(0)          
    self.guild       = "" -- string()
    self.timeServer  = 0  -- number(1361516317)
    self.sex         = 1  -- number(1)
    self.status      = 0  -- number(1)
    self.mapHeight   = 0  -- number(4691)
    self.mode        = 0  -- number(0)
    -- 10011 GC_DETAIL_ATTR
    self.level      = 0 -- SHORT     1      角色等级
    self.maxhp      = 0 -- INT       1      角色最大hp
    self.maxmp      = 0 -- INT       1      角色最大mp
    self.hp         = 0 -- INT       1      角色当前hp
    self.mp         = 0 -- INT       1      色当前mp
    self.exp        = 0 -- INT       1      经验值
    self.lingli     = 0 -- INT       1      灵力值
    self.rmb        = 0 -- INT       1      元宝
    self.bindrmb    = 0 -- INT       1      绑定元宝
    self.money      = 0 -- INT       1      铜币
    self.bindmoney  = 0 -- INT       1      绑定铜币 
    self.atk        = 0 -- SHORT     1      攻击力     
    self.def        = 0 -- SHORT     1      防御力  
    self.dodge      = 0 -- SHORT     1      闪避  
    self.hitrate    = 0 -- SHORT     1      命中  
    self.bash       = 0 -- SHORT     1      暴击  
    self.tough      = 0 -- SHORT     1      坚韧
    self.atkSpeed   = 0 -- SHORT     1      攻击速度
    self.defA       = 0 -- SHORT     1      抗性A
    self.defB       = 0 -- SHORT     1      抗性B
    self.defC       = 0 -- SHORT     1      抗性C
    self.xiuWei     = 0 -- INT       1      修为
    self.anger      = 0 -- INT       1      怒气
    self.arenaScore = 0 -- INT       1      擂台积分  
    --
    self.mapElemList = { -- 地图元素
         [CommonDefine.OBJ_TYPE_INVALID] = {} -- = -1            --// 无效
        ,[CommonDefine.OBJ_TYPE_HUMAN  ] = {} -- = 0             --// 玩家
        ,[CommonDefine.OBJ_TYPE_NPC    ] = {} -- = 1
        ,[CommonDefine.OBJ_TYPE_MONSTER] = {} -- = 2
        ,[CommonDefine.OBJ_TYPE_COLLECT] = {} -- = 3
        ,[CommonDefine.OBJ_TYPE_JUMP   ] = {} -- = 4
        ,[CommonDefine.OBJ_TYPE_ITEM   ] = {} -- = 5
        ,[CommonDefine.OBJ_TYPE_PET    ] = {} -- = 6
    }
    --
    self.taskList    = {} -- 任务列表
    self.taskList.doingTasks = {}
    self.taskList.canDoTasks = {}
    --
    self.bagList     = {} -- 背包物品
    self.equipList   = {} -- 装备

end

Instance = Instance or New(_M)



