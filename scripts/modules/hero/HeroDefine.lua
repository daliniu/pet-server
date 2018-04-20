module(...,package.seeall)

local HeroQualityConfig = require("config.HeroQualityConfig").Config

MAX_QUALITY = 5

local dc = require("config.HeroDefineConfig").Config
DefineConfig = {} 
for _,c in ipairs(dc)do
    -- 容错处理
    if c.star > MAX_QUALITY or c.star < 1 then
        c.star = 3
    end
	DefineConfig[c.name] = c
end
local ac = require("config.HeroAttrConfig").Config
AttrConfig = {}
for _,c in ipairs(ac)do 
    AttrConfig[c.name] = AttrConfig[c.name] or {}
    AttrConfig[c.name][c.quality] = c.attr
end

--[[
hero由英文名定义
iori	八神
kyo	    草薙京
chang	陈国汉
chris	克里斯
orochi	大蛇
athena	雅典娜
mai	    不知火舞
terry	特瑞
mary	玛丽
clark	克拉克
chin	镇元斋




hero所有属性定义

1.基本属性，这些属性会存库
lv=等级
quality=品阶
exp=经验值
name=英雄标识，英文名


2.静态属性，来自配置表，部分配置表的属性为了方便使用，放到hero对象上

cname=中文名
career=职业
trend=技能偏向
fragId=对应碎片道具id
final=必杀技能id
assist=援助技能id



3.延伸属性，值会随等级，品阶等因素的变化而变化,由hero:freshAttr()来更新数值
maxHp=血量上限
cost=cost值
hpRecovery=血量回复值
assistRecovery=援助回复值
furyRecovery=怒气回复值
skillAtk=技能攻击值
skillDef=技能防御值
hitAtk=拳脚攻击值
hitDef=拳脚防御值
comboAtk=连击攻击值
comboDef=连击防御值
hpradar=血量雷达值
defradar=防御雷达值


4.雷达属性值
hp=血量
def=防御
hit=拳脚
combo=连招
throw=投技
final=必杀



--]]

--这些属性在配置文件中的定义是小数，需要做相应的转换
DecimalAttrs = {'hpR','rageR','rageRByHp','rageRByWin'}


-- 突破等系统会英雄到的基础动态属性
BaseDyAttrName = {
    "maxHp",
    "atk",
    "def",
    "finalAtk",
    "finalDef",
}

DyAttrName = {
    "maxHp",        --血量上限
    "hpR",        --血量回复值
    "assist",      --援助个数
    "rageR",    --怒气回复值
    "atkSpeed",       --攻速值
    "atk",      --攻击值
    "def",   --防御值
    "crthit",  --暴击值
    "antiCrthit",   --防爆值
    "block",      --格挡值
    "antiBlock",  --破挡值
    "damage",     --真实伤害值
    "rageRByHp",    -- 每损失1%血量获得的怒气值
    "rageRByWin",   -- 战胜一个敌人获得的怒气值
    "finalAtk",     -- 必杀攻击值
    "finalDef",     -- 必杀防御值
    "initRage",     -- 初始怒气值
}

DyAttrName2Enum = {
    maxHp = 1,
    hpR = 2,
    assist = 3,
    rageR = 4,
    atkSpeed = 5,
    atk = 6,
    def = 7,
    crthit = 8,
    antiCrthit = 9,
    block = 10,
    antiBlock = 11,
    damage = 12,
    rageRByHp = 13,
    rageRByWin = 14,
    finalAtk = 15,
    finalDef = 16,
    initRage = 17,
}

Enum2DyAttrName = {
    [1] = "maxHp",
    [2] = "hpR",
    [3] = "assist",
    [4] = "rageR",
    [5] = "atkSpeed",
    [6] = "atk",
    [7] = "def",
    [8] = "crthit",
    [9] = "antiCrthit",
    [10] = "block",
    [11] = "antiBlock",
    [12] = "damage",
    [13] = "rageRByHp",
    [14] = "rageRByWin",
    [15] = "finalAtk",
    [16] = "finalDef",
    [17] = "initRage",
}




CAREER_A =  1
CAREER_B =  2
CAREER_C =  3


QA_WHITE  = 1       --品阶 白
QA_GREEN  = 2       --品阶 绿
QA_BLUE   = 3       --品阶 蓝
QA_YELLOW = 4       --品阶 黄
QA_RED    = 5       --品阶 红
QA_PURPLE = 6       --品阶 紫
QA_ORANGE = 7       --品阶 橙

CAREER_NAMES = {[0]='全部',[1]='炎',[2]='雷',[3]='地',[4]='风',[5]='暗'}

EXP_MEDICINE = {[1]=1406001,[2]=1406002}


MAX_LEVEL = 100
MAX_BT = 10 -- 最大突破等级

RET_OK  =  0
RET_NOSUCH_HERO  = 1
RET_FRAG_NOTENOUGH = 2
RET_MONEY_NOTENOUGH = 3
RET_MAXLIMIT = 4   -- 已达最高等级
RET_HEROLV = 5 -- 英雄等级不足
RET_HEROSTAR = 6 -- 英雄星级不足

-- 英雄状态
STATUS_NORMAL = 0  --正常
STATUS_THERMAE = 1 -- 温泉

--战斗力相关
FIGHT_ATTR_LIST = {
    [Enum2DyAttrName[DyAttrName2Enum.maxHp]]   		= 0.05,
    [Enum2DyAttrName[DyAttrName2Enum.hpR]]    		= 0,
    [Enum2DyAttrName[DyAttrName2Enum.assist]]    	= 0,
    [Enum2DyAttrName[DyAttrName2Enum.rageR]]   		= 0,
    [Enum2DyAttrName[DyAttrName2Enum.atkSpeed]]    	= 0.5,
    [Enum2DyAttrName[DyAttrName2Enum.atk]]    		= 0.2,
    [Enum2DyAttrName[DyAttrName2Enum.def]]    		= 0.2,
    [Enum2DyAttrName[DyAttrName2Enum.crthit]]    	= 0,
    [Enum2DyAttrName[DyAttrName2Enum.antiCrthit]]   = 0,
    [Enum2DyAttrName[DyAttrName2Enum.block]]    	= 0,
    [Enum2DyAttrName[DyAttrName2Enum.antiBlock]]    = 0,
    [Enum2DyAttrName[DyAttrName2Enum.damage]]    	= 0,
    [Enum2DyAttrName[DyAttrName2Enum.rageRByHp]]    = 0,
    [Enum2DyAttrName[DyAttrName2Enum.rageRByWin]]   = 0,
    [Enum2DyAttrName[DyAttrName2Enum.finalAtk]]   	= 0.2,
    [Enum2DyAttrName[DyAttrName2Enum.finalDef]]   	= 0.2,
}



BREAK_STONE_ID = 2103001
EXCHANGE_COIN_ID = 9901013