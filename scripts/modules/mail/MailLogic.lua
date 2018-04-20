module(...,package.seeall)
local MailManager = require("modules.mail.MailManager")
local MailDefine = require("modules.mail.MailDefine")
local BagLogic = require("modules.bag.BagLogic")
local EventHandler = require("modules.mail.EventHandler")
local RechargeCharConfig = require("config.RechargeCharConfig").Config

function onHumanCreate(hm,human)
	--新服补偿
	local pAccount = human:getPAccount()
	local cfg = RechargeCharConfig[pAccount]
	if cfg then
		local title = "旧服充值账号进驻新服的钻石补偿"
		local content = string.format("感谢您在旧服中的奋战，同时欢迎您进入新服继续征程！我们返还您在1服充值所获的等值钻石以及VIP等级，预祝您在这一片新天地中大展宏图~~~~！\n您获得VIP%d级,钻石%d。",cfg.vip,cfg.recharge*20)
		local attach = {[1] = {9901002,cfg.recharge*20}}
		MailManager.sysSendMail(human:getAccount(),title,content,attach)
		human.db.vipLv = cfg.vip
	end
end

function onHumanLogin(hm,human)
	EventHandler.sendMailList(human)
end

function hasAttach(mail)
	if #mail.attach > 0 then
		return true
	else
		return false
	end
end

function delMail(human,id)
	local mailBox = MailManager.getMailBox(human.db.account)
	local mail = mailBox:getMailById(id)
	if not mail then
		return false,MailDefine.DEL_MAIL_RET.kDataErr
	end
	local retCode = MailDefine.DEL_MAIL_RET.kDelOk
	local isAttach = 0
	if hasAttach(mail) then
		isAttach = 1
		local itemGroup = {}
		for i = 1,#mail.attach do
			table.insert(itemGroup,{id = mail.attach[i][1],num = mail.attach[i][2]})
		end
		--if not BagLogic.checkCanAddItemGroup(human,itemGroup) then
		--	return false,MailDefine.DEL_MAIL_RET.kBagFull
		--end
		for i = 1,#mail.attach do
			BagLogic.addItem(human,mail.attach[i][1],mail.attach[i][2],false,CommonDefine.ITEM_TYPE.ADD_MAIL)
		end
		retCode = MailDefine.DEL_MAIL_RET.kGetOk
	end
	mailBox:delMailById(id)
	BagLogic.sendBagList(human)
	human:sendHumanInfo()

	local logTb = Log.getLogTb(LogId.RECV_MAIL)
	logTb.channelId = human:getChannelId()
	logTb.account = human:getAccount()
	logTb.name = human:getName()
	logTb.pAccount = human:getPAccount()
	logTb.sendAccount = "system"
	logTb.sendCharName = "系统"
	logTb.recvAccount = human:getAccount()
	logTb.content = mail.content
	logTb.title = mail.title
	logTb.attach = isAttach
	logTb:save()

	return true,retCode
end

function readMail(human,id)
	local mailBox = MailManager.getMailBox(human.db.account)
	local mail = mailBox:getMailById(id)
	if not mail then
		return false,MailDefine.READ_MAIL_RET.kDataErr
	end
	local mailId,mtype = MailManager.unMaskMailId(id)
	if mtype == MailDefine.MAIL_TYPE_SYSTEM then
		if mailBox.db.inbox[mailId].status == MailDefine.MAIL_STATUS_UNREAD then
			mailBox.db.inbox[mailId].status = MailDefine.MAIL_STATUS_READED
		end
	elseif mtype == MailDefine.MAIL_TYPE_GM then
		if not mailBox.db.sysbox[mailId] or mailBox.db.sysbox[mailId] == MailDefine.MAIL_STATUS_UNREAD then
			mailBox.db.sysbox[mailId] = MailDefine.MAIL_STATUS_READED
		end
	end
	mailBox:raiseSave()
	return true,MailDefine.READ_MAIL_RET.kOk
end
