module(...,package.seeall)

CGAskMailList = {
}

Attachment = {
	{"id",		"int",	"物品id"},
	{"num",		"int",	"数量"},
}

MailNode = {
	{"id",	"int",	"邮件id"},
	{"sender",	"string",	"发件人"},
	{"sendtime",	"int",	"发送时间"},
	{"title",	"string",	"邮件标题"},
	--{"content",	"string",	"邮件内容"},
	{"status",	"int",		"已读状态"},
	--{"attachment",	Attachment,	"附件",	"repeated"}
}

GCAskMailList = {
	{"mailList",	MailNode,	"邮件列表",		"repeated"}
}

CGAskMailDetail = {
	{"id",	"int",	"邮件id"},
}

GCAskMailDetail = {
	{"id",	"int",	"邮件id"},
	{"content",	"string",	"邮件内容"},
	{"attachment",	Attachment,	"附件",	"repeated"}
}

CGDelMail= {
	{"id",	"int",	"邮件id"},
}

GCDelMail= {
	{"ret",	"int",	"删除邮件结果"},
}

CGReadMail = {
	{"id",	"int",	"邮件id"},
}
GCReadMail = {
	{"id",	"int",	"邮件id"},
	{"ret",	"int",	"返回码"},
}

GCNewMail = {
}

