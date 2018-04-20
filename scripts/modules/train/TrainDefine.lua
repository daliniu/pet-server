module(...,package.seeall)

--培养固定属性
ATTRS = {
	[1] = "atk",
	[2] = "finalAtk",
	[3] = "def",
	[4] = "finalDef",
	[5] = "maxHp",
}

TRAIN_RET = {
	kOk = 1,
	kNoHero = 2,
	kDataErr = 3,
	kNoMoney = 4,
	kNoRmb = 5,
	kNoItem = 6,
	kMax = 7,
	kNoLv= 8,
}

TRAIN_ADD_RET = {
	kOk = 1,
	kNoHero = 2,
	kDataErr = 3,
	kEmpty = 4,
}
