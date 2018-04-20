module(...,package.seeall)

kMaxStrengthCellCap = 6
kMaxStrengthGridCap = 1
kMaxStrengthLv = 10
kMaxTransferLv = 10

STRENGTH_QUERY_RET = {
	kOk = 1,
	kDataErr = 2,
}

STRENGTH_EQUIP_RET = {
	kOk = 1,
	kClientErr = 2,
	kDataErr = 3,
	kNoMaterial = 4,
	kNoLv = 5,
}
STRENGTH_QUICK_EQUIP_RET = {
	kOk = 1,
	kNoEquip = 2,
	kClientErr = 3,
}

STRENGTH_LV_UP_RET = {
	kOk = 1,
	kClientErr = 2,
	kDataErr = 3,
	kMaxLv = 4,
	kNoMaterial = 5,
}

STRENGTH_TRANSFER_RET = {
	kOk = 1,
	kClientErr = 2,
	kNotLv = 3,
	kMaxLv = 4
}

MATERIAL_COMPOSE_RET = {
	kOk = 1,
	kClientErr = 2,
	kNoMaterial = 3,
	kBagFull = 4,
	kAtom = 5,
	kNoMoney = 6
}

FRAG_COMPOSE_RET = {
	kOk = 1,
	kClientErr = 2,
	kNoMaterial = 3,
	kBagFull = 4,
	kAtom = 5,
}
