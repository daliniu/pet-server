module(...,package.seeall)
local SkillExpConfig = require("config.SkillExpConfig").Config

MIN_SKILL_LV = 1

MAX_LV = #SkillExpConfig --最大等级

--MAX_EQUIP_ITEM = 4      --最多可装备技能数
EXP_ITEM_ID = 1203001  --经验丹

--技能类型
TYPE_NORMAL = 1 	--普通技能
TYPE_FINAL  = 2		--必杀技
TYPE_ASSIST = 3		--援助技能
TYPE_COVER  = 4		--补位技能
TYPE_COMBO  = 5		--连招技能
TYPE_BROKE  = 6		--破招技能
TYPE_ASSISTR  = 7		--被动援助技能
TYPE_MAP = {
	[TYPE_NORMAL] = 1,
	[TYPE_FINAL]  = 2,
	[TYPE_ASSIST] = 3,
	[TYPE_COVER]  = 4,
	[TYPE_COMBO]  = 5,
	[TYPE_BROKE]  = 6,
	[TYPE_ASSISTR]  = 7,
}

TYPE_CONF = {
	[TYPE_NORMAL] = {equipNum=3,costType="money",upType="normal"},
	--怒气技
	[TYPE_FINAL]  = {equipNum=1,costType="rage",upType="final"},
	[TYPE_COMBO]  = {equipNum=1,costType="rage",upType="combo"},
	[TYPE_BROKE]  = {equipNum=1,costType="rage",upType="broke"},
	--援助类型
	[TYPE_ASSIST] = {equipNum=1,costType="assist",upType="assist"},
	[TYPE_ASSISTR] = {equipNum=3,costType="money",upType="assist"},
}

--攻击方式/装备位置
EQUIP_NONE = 0      --未装备
EQUIP_A = 1			
EQUIP_B = 2			
EQUIP_C = 3			
EQUIP_D = 4			
EQUIP_TYPE_MAP = {
    [EQUIP_A] = "A",
    [EQUIP_B] = "B",  
    [EQUIP_C] = "C", 
    [EQUIP_D] = "D", 
}

--经验类型
EXP_TYPE_MAP = {
	[TYPE_FINAL] = true,
	[TYPE_ASSIST] = true,
}

--暴击
ExtralAddLvMap = {}
--[[
	{per=0,lv=4},
	{per=0,lv=3},
	{per=0,lv=2},
	{per=0,lv=1},
}
]]


ERROR_CODE = Util.newEnum({
    "ERROR_CONF",
    "NOT_HERO_SKILL",
    "NO_SKILL",
    "NOT_EMPTY_POS",
    "HAD_EQUIP",
    "NOT_FIT_TYPE",
    "COST_OVER",
    "NOT_OPEN_LV",
    "ERROR_TYPE",
	"UPGRADE_MAX_LV",
	"SKILL_LIMIT",
	"EXCEED_HERO_LV",
	"UP_NEED_ITEM",
	"NO_MONEY",
	"NO_RAGE",
	"NO_ASSIST",
})
--[[
ERROR_CONTENT = {
    [ERROR_CODE.ERROR_CONF] = "配置出错",
    [ERROR_CODE.NOT_HERO_SKILL] = "英雄没有该技能",
    [ERROR_CODE.NO_SKILL] = "没有学会该技能",
    [ERROR_CODE.NOT_EMPTY_POS] = "格子已满",
    [ERROR_CODE.HAD_EQUIP] = "已装备",
    [ERROR_CODE.NOT_FIT_TYPE] = "装备类型不符",
    [ERROR_CODE.COST_OVER] = "超出cost值",
    [ERROR_CODE.NOT_OPEN_LV] = "未达到技能开放等级",
    [ERROR_CODE.ERROR_TYPE] = "错误的技能类型",
    [ERROR_CODE.UPGRADE_MAX_LV] = "已达到最大技能等级",
    [ERROR_CODE.SKILL_LIMIT] = "技能限定",
    [ERROR_CODE.EXCEED_HERO_LV] = "技能等级不能超过英雄等级",
    [ERROR_CODE.UP_NEED_ITEM] = "缺少技能经验丹",
    [ERROR_CODE.NO_MONEY] = "金币不足",
    [ERROR_CODE.NO_RAGE] = "怒气点不足",
    [ERROR_CODE.NO_ASSIST] = "援助点不足",
}
--]]




