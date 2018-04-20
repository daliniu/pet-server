module(...,package.seeall)

COMPOSE_RET = {
	kOk = 1,
	kDataErr = 2,
	kNoMaterial = 3,
	kFullBag = 4,
	kNoHero = 5,
}

EQUIP_RET = {
	kOk = 1,
	kDataErr = 2,
	kNoHero = 3,
	kNoItem = 4,
}

ACTIVE_RET = {
	kOk = 1,
	kNoItem = 2,
	kDataErr = 3,
	kHasActive = 4,
}
