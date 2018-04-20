module(...,package.seeall)

MAX_GIFT = 5
ActivateRet = {
	ok = 0,
	----
}

ConditionType = {
	all = 0,			--激活就有
	teammateFight = 1,	--队友同时出场
	teammateAssist = 2,	--某个队友作为援助
	useSkill = 3,		--发动某个技能
	useCombo = 4,		--接招之后
	useBreak = 5,		--使用破招
	usePow   = 6,		--使用必杀
	hit		 = 7,		--连击数达到某个值
	opponent = 8,		--对手是某个英雄时
	crtHit	 = 9,		--前一次攻击暴击后(别人打你)
	block	 = 10,		--前一次受击格挡后(别人打你)
	enemyCrtHit = 11 ,		--前一次攻击暴击后(你打别人)
	enemyBlock = 12 ,		--前一次受击格挡后(你打别人)
	hp		 = 13,		--生命值低于某个
	hpR		 = 14,		--生命值低于某个比例
	decHp	 = 15,			--每损失X生命
	decHpR	 = 16,			--每损失X%生命
	pow		 = 17,		--怒气槽满X条
	roundEnd = 18,		--当前战斗结束后
	win		 = 19,		--每胜利一场战斗
	lost	 = 20,		--失败
	beat	 = 21,		--受到攻击
	heroIndex = 22,		--当前英雄出场位置，可以用负数，例如-1表示最后一个出场，-2表示最后第2个
	enemyIndex = 23,		--对方英雄了出场位置，可以用负数，例如-1表示最后一个出场，-2表示最后第2个

	
}

EffectType = {
	addPowBuf = 1,	--提升X时间内每N秒恢复M点怒气
	addPow = 2,	--增加怒气
	enemyNoPow = 3,		--对方不获得怒气(时间控制)
	powR  = 4,		--增加怒气回复(时间控制)
	addHpBuf = 5,	--每X秒回复N生命m
	addHpRBuf = 6,	--每X秒回复N生命m%
	addHp	= 7,	--直接回复一定的生命值
	addHpR  = 8,	--直接回复一定比例的生命值
	addHpWin = 9,	--增加血量回复
	followCrt = 10,	--下一次技能暴击提升
	atk = 11,		--增加技能攻击力()
	finalAtk = 12,	--增加必杀攻击力
	followFinalAtk = 13,	--下一次技能必杀攻击伤害
	followBlock = 14,	--下一次受击必定格挡
	def = 15,		--增加技能防御值
	finalDef = 16,	--增加必杀防御值
	atkSpeed = 17,	--增加攻速值
	block = 18,		--增加格挡值
	antiBlock = 19,	--增加破挡
	decHarmR = 20,	--伤害减少n%
	comboHarm = 21,	--接招伤害提升
	breakHarm = 22,	--破招伤害提升
	addHarmR = 23,  --普通伤害增加n%
	nextAtk = 24,	--下一个出战英雄攻击增加
	nextCrtHit = 25,	--下一个出战英雄攻击暴击增加
	nextAntiCrthit = 26,	--下一个出战英雄暴击防御增加
	
}
