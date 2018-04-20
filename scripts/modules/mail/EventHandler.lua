module(...,package.seeall)
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local MailManager = require("modules.mail.MailManager")
local MailLogic = require("modules.mail.MailLogic")

function onCGAskMailList(human)
	HumanManager:dispatchEvent(HumanManager.Event_AskMail,{human=human})
	sendMailList(human)
end

function sendMailList(human)
	local mailBox = MailManager.getMailBox(human.db.account)
	local mails = mailBox:getMails(human)
	local mailList = {}
	for i = 1,#mails do
		local mail = mails[i]
		local ret = {}
		ret.id = MailManager.maskMailId(mail)
		ret.sender = mail.sender
		ret.sendtime = mail.sendtime
		ret.title = mail.title
		ret.content = mail.content
		ret.status = mail.status
		ret.attachment = {}
		for j = 1,#mail.attach do
			ret.attachment[j] = {}
			ret.attachment[j].id = mail.attach[j][1]
			ret.attachment[j].num = mail.attach[j][2]
		end
		table.insert(mailList,ret)
	end
	Msg.SendMsg(PacketID.GC_ASK_MAIL_LIST,human,mailList)
end

function onCGAskMailDetail(human,id)
	local mailBox = MailManager.getMailBox(human.db.account)
	local mail = mailBox:getMailById(id)
	local ret = {}
	ret.id = id 
	ret.content = ""
	ret.attachment = {} 
	if mail then
		ret.content = mail.content
		for j = 1,#mail.attach do
			ret.attachment[j] = {}
			ret.attachment[j].id = mail.attach[j][1]
			ret.attachment[j].num = mail.attach[j][2]
		end
	end
	Msg.SendMsg(PacketID.GC_ASK_MAIL_DETAIL,human,ret.id,ret.content,ret.attachment)
end

function onCGDelMail(human,id)
	local ret,retCode = MailLogic.delMail(human,id)
	if ret then
		sendMailList(human)
	end
	Msg.SendMsg(PacketID.GC_DEL_MAIL,human,retCode)
end

function onCGReadMail(human,id)
	local ret,retCode = MailLogic.readMail(human,id)
	Msg.SendMsg(PacketID.GC_READ_MAIL,human,id,retCode)
end
