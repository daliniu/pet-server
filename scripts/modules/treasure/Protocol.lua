module(...,package.seeall)
REWARD =
{
	{"itemId","int","道具id"},
	{"cnt","int","数量"},
}
GUARD = {
	{"name","string","守护英雄名称"},
	{"quality","int","星级"},
	{"lv","int","等级"},
	{"power","int","战斗力"},
}
SIMPLE_MINE = {
	{'account',"string","账号"},
	{'charName',"string","战队名字"},
	{"mineId","int","宝藏id"},
	{'rankId',"int","宝藏品阶"},
	{'mineType',"int","宝藏类型"},
	{"startTime","int","开始时间"},
	{'endTime','int','保护时间'},
	{"safeStartTime","int","保护开始时间"},
	{'safeEndTime','int','结束保护时间'},
	{"extend","int","延长次数"},
}
MINE = 
{
	{'account',"string","账号"},
	{'charName',"string","战队名字"},
	{'lv',"int","战队等级"},
	{"mineId","int","宝藏id"},
	{'rankId',"int","宝藏品阶"},
	{'mineType',"int","宝藏类型"},
	{"reward",REWARD,"收益","repeated"},
	{"startTime","int","开始时间"},
	{'endTime','int','保护时间'},
	{"safeStartTime","int","保护开始时间"},
	{'safeEndTime','int','结束保护时间'},
	{"doubleStartTime","int","双倍收益开始时间"},
	{'doubleEndTime','int','双倍收益结束时间'},
	{"guard",GUARD,"守护英雄","repeated"},
	{"extend","int","延长次数"},
}

CGTreasureMapInfo = 
{
	{"refresh","int","强制刷新"},
}

GCTreasureMapInfo =
{
	{"result","int","查找结果"},
	{"refresh","int","强制刷新"},
	{"mapInfoTime","int","上次更新宝藏列表的时间"},
	{"mineList",SIMPLE_MINE,"宝藏列表","repeated"},
}
CGTreasureMineInfo = 
{
	{"mineId","int","矿Id",},
}
GCTreasureMineInfo = 
{
	{"result","int","查找结果"},
	{"mineInfo",MINE,"矿信息列表"},
}
CGTreasureQueryOccupied =
{

}
GCTreasureQueryOccupied =
{
	{"result","int","查找结果"},
	{"mineList",MINE,"矿信息列表",'repeated'},
}

CGTreasureGuard = 
{
	{"mineId","int","矿Id"},
	{"guard","string","英雄名字",'repeated'},
}
GCTreasureGuard = 
{
	{"result","int","结果"},
	{"mineId","int","矿Id"},
	{"guard","string","英雄名字",'repeated'},
}

CGTreasureAbandon = 
{
	{"mineId","int","矿Id"},
}

GCTreasureAbandon = 
{
	{"result","int","结果"},
	{"mineId","int","矿Id"},
}

-- CGTreasureSafe = 
-- {
-- 	{"mineId","int","矿Id"},
-- }

-- GCTreasureSafe = 
-- {
-- 	{"result","int","结果"},
-- 	{"mineId","int","矿Id"},
-- 	{"safeStartTime","int","保护开始时间"},
-- 	{"safeEndTime","int","保护结束时间"},
-- }

CGTreasurePrepareOccupy = {
	{"mineId","int","矿Id"},
}

CGTreasureStartOccupy = 
{
	{"mineId","int","矿Id"},
}

--英雄动态属性
HeroDyAttr = 
{
	{"maxHp","int","血量上限"},
	{"hpR","int","血量回复值"},
	{"assist","int","援助个数"},
	{"rageR","int","怒气回复值"},
	{"atkSpeed","int","攻速值"},
	{"atk","int","攻击值"},
	{"def","int","防御值"},
	{"crthit","int","暴击值"},
	{"antiCrthit","int","防爆值"},
	{"block","int","格挡值"},
	{"antiBlock","int","破挡值"},
	{"damage","int","真实伤害值"},
	{"rageRByHp","int","每损失1%血量获得的怒气值"},
	{"rageRByWin","int","战胜一个敌人获得的怒气值"},
	{"finalAtk","int","必杀攻击值"},
	{"finalDef","int","必杀防御值"},	
}

GroupInfo = 
{
    {"groupId",     "int",      "技能组ID"},
    {"lv",     		"int",      "等级"},
    {"equipType",   "int",      "装备的位置"},
    {"isOpen",      "int",      "是否已开启"},
    {"skillList",     "int",    "技能ID列表",	"repeated"},
}

HERO =
{
	{"account","string","账号"},
	{"name","string","英雄名称"},
	{"lv","int","等级"},
	{"quality","int","品阶"},
	{"dyAttr",HeroDyAttr,"动态属性"},
    {"skillGroupList",		GroupInfo,			"技能列表",		"repeated"},
	{"gift",	"int", "天赋id", "repeated"},
}
GCTreasurePrepareOccupy = {
	{"result","int","结果"},
	{"mineId","int","矿Id"},
	{"guard",HERO,"宝藏守卫","repeated"},
}

GCTreasureStartOccupy = 
{
	{"result","int","结果"},
	{"mineId","int","矿Id"},
}
CGTreasureEndOccupy = 
{
	{"result","int","结果"},
	{"mineId","int","矿Id"},
	{"hero","string","英雄名称","repeated"},
}

GCTreasureEndOccupy = 
{
	{"result","int","结果"},
	{"result2","int","占领结果"},
	{"mineId","int","矿Id"},
	{"hero","string","英雄名称","repeated"},
}

--[[取消协助
CGTreasureAssist = 
{
	{"cmd","int","命令 0 发起协助；1 归队"},
	{"mineId","int","矿Id"},
	{"heroName","string","英雄名称"},
	{"assistNo","int","第几个协助位置"},
}

GCTreasureAssist = 
{
	{"result","int","结果"},
	{"cmd","int","命令 0 发起协助；1 归队"},
	{"mineId","int","矿Id"},
	{"heroName","string","英雄名称"},
	{"mineInfo",MINE,"宝藏信息"},
}
--]]
CGTreasureChar = 
{
}

GCTreasureChar = 
{
	{"fightTimes","int","当天挑战次数"},
	{"extendTimes","int","当天延长占领次数"},
	{"safeTimes","int","当天保护次数"},
	{"doubleTimes","int","当天双倍收益次数"},
	{"refreshMapTimes","int","当天刷新次数"},
	{"mine",MINE,"此玩家占有的矿","repeated"},
}

--设置宝藏状态
-- CGTreasureStatus = 
-- {
-- 	{"mineId","int",""},
-- 	{"status","int","宝藏状态"},
-- }

-- GCTreasureStatus = 
-- {
-- 	{"result","int","结果"},
-- }

CGTreasureRecord = 
{

}

RECORD = {
	{"recType","int","记录类型"},
	{"dt","int","时间"},
	{"mineId","int","mineId"},
	{"name1","string","己方名字"},
	{"name2","string","对方名字"},
	{"lv1","int","己方等级"},
	{"lv2","int","对方等级"},
	{"body1","int","己方头像"},
	{"body2","int","对方头像"},
	{"hero1",GUARD,"己方英雄","repeated"},
	{"hero2",GUARD,"对方英雄","repeated"},
	{"reward",REWARD,"奖励","repeated"},
	{"closed","int","关闭"},
}
GCTreasureRecord = 
{
	{"record",RECORD,"记录","repeated"},
}
GCTreasureRecord = 
{
	{"record",RECORD,"记录","repeated"},
}
CGTreasureMsg = 
{
	{"msg","string","消息"},
}
CGTreasureConsume = 
{
	{"ConsumeId","int","消费类型"},
	{"mineId","int","宝藏id"},
}

GCTreasureConsume = 
{
	{"retCode","int","返回码"},
	{"ConsumeId","int","消费类型"},
	{"mineId","int","宝藏id"},
}

