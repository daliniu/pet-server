module(...,package.seeall)

MAIL_TYPE_SYSTEM = 1
MAIL_TYPE_GM = 2

MAIL_STATUS_UNREAD   = 1  --未读
MAIL_STATUS_READED   = 2  --已读
MAIL_STATUS_DELETED  = 3  --已删

MAIL_MAX_LEN = 40

MAIL_GM_MASK = 1000000000   --系统邮件箱掩码

SYS_MAIL_ACCOUNT = "system_mail_s"
SYS_MAIL_NAME = "系统"

DEL_MAIL_RET = {
	kDelOk = 1,		--删除成功
	kGetOk = 2,		--提取成功
	kBagFull = 3,	--背包满
	kDataErr = 4,	--数据错误
}

READ_MAIL_RET = {
	kOk = 1,
	kDataErr = 2,
}
