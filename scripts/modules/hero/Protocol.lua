module(...,package.seeall)

CGAllHeroAttr = 
{
	{"placeHolder", "int", "占位符"},
}


CGHeroAttr = 
{
	{"name", "string", "英雄标识"}
}
GCHeroAddExp = 
{
	{"name","string","英雄标识"},
	{"exp","int","增加的经验值"},
	{"oldLv","int","操作前的等级"},
	{"newLv","int","操作后的等级"},
}

CGHeroTopLvup = 
{
	{"name","string","英雄标识"},
}

GCHeroTopLvup = 
{
	{"result","int","结果"},
	{"name","string","英雄标识"},
}

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
	{"initRage","int","初始怒气值"},
}

GCHeroAttr = 
{
	{"name","string","英雄标识"},
	{"exp","int","经验值"},
	{"lv","int","等级"},
	{"quality","int","品阶"},
	{"ctime","int","招募时间"},
	{"btLv","int","突破等级"},
	{"status","int","英雄状态"},
	{"dyAttr",HeroDyAttr,"动态属性"},
	{"exchange","int","兑换碎片","repeated"},
}


GCAllHeroAttr =
{
	{"heroes",GCHeroAttr,"英雄属性值","repeated"},
}

CGHeroCompose = 
{
	{"name","string","需要合成的英雄标识"}
}

GCHeroCompose = 
{
	{"name","string","需要合成的英雄标识"},
	{"result","int","结果"},
	{"quality","int","星级"},
}

CGHeroRecruit = 
{
	{"name","string","需要招募的英雄标识"}
}

GCHeroRecruit = 
{
	{"name","string","需要招募的英雄标识"},
	{"result","int","结果"}
}

CGHeroQualityUp = 
{
	{"name","string","需要招募的英雄标识"},
	-- {"frag","int","升星消耗的碎片数量"},
	-- {"coinFrag","int","升星消耗的兑换积分数量"},
	{"goldBuyTimes","int","需要购买金币的次数"},
}
GCHeroQualityUp = 
{
	{"name","string","需要升品阶的英雄标识"},
	{"result","int","结果"},
	{"quality","int","升级后的品阶"},

}

-- CGHeroLvUp = 
-- {
-- 	{"name","string","需要招募的英雄标识"}
-- }
-- GCHeroLvUp = 
-- {
-- 	{"name","string","需要升级的英雄标识"},
-- 	{"result","int","结果"},
-- 	{"lv","int","升级后的等级"}
-- }

CGHeroDyattr = 
{
	{'name',"string","英雄标识"},
}

GCHeroDyattr = 
{
	{'name',"string","英雄标识"},
	{'dyAttr',HeroDyAttr,"动态属性"},
}


CGHeroExpedition = 
{
	{'name','string','英雄名称','repeated'},
}

GCHeroExpedition = 
{
	{'name','string','英雄名称','repeated'},
}

CGHeroBreakthrough = 
{
	{'name','string','英雄名称'},
}

GCHeroBreakthrough = 
{
	{"name","string","需要招募的英雄标识"},
	{"result","int","结果"},
	{'lv','int','级别'},
}

CGHeroStarAttr = 
{
	{'name','string','英雄名称'},
	{"quality","int","星级"},
}

GCHeroStarAttr = 
{
	{'result','int','结果'},
	{'name','string','英雄名称'},
	{"quality","int","星级"},
	{'dyAttr',HeroDyAttr,"动态属性"},
}

CGHeroExchange = 
{
	{"name","string","英雄名称"},
	{"frag","int","碎片数量"},
}
GCHeroExchange = 
{
	{"retCode","int","返回码"},
	{"name","string","英雄名称"},
	{"star","int","星级"},
	{"frag","int","碎片数量"},
}