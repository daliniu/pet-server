module(...,package.seeall)

ADD_STATUS = {
	kOk = 1,	
	kErr = 2,	
}

ADD_STATUS_TIPS = {
	[1] = "申请成功",
	[2] = "申请好友已满或已申请过该好友",
}

OP_STATUS = {
	kOk = 1,	
	kErr = 2,	
}

OP_STATUS_TIPS = {
	[1] = "添加成功",
	[2] = "添加失败:当前申请好友已满",
}

ONLINE_STATUS = {
	kYes = 1,	
	kNo = 0,
}

ONLINE_STATUS_TIPS = {
	[1] = "在线",
	[0] = "离线",
}

DEL_STATUS = {
	kOk = 1,	
	kErr = 2,	
}

DEL_STATUS_TIPS = {
	[1] = "删除成功",
	[2] = "删除失败",
}

REJECT_STATUS = {
	kOk = 1,	
	kErr = 2,	
}

REJECT_STATUS_TIPS = {
	[1] = "操作成功",
	[2] = "操作失败",
}