module(...,package.seeall)
local MailBox = require("modules.mail.MailBox")
local MailDefine = require("modules.mail.MailDefine")
local MailConfig = require("config.MailConfig").Config
local BagLogic = require("modules.bag.BagLogic")
local DB = require("core.db.DB")
local ns = 'mail'
MailBoxList = MailBoxList or {}
SysBox = SysBox or nil

function getMailBox(account)
	local accountEx = account
	local mailBox = MailBoxList[account]
	if mailBox == nil then
		local query = {account = account}
		mailBox = MailBox.new()
    	local ret = DB.Find(ns,query,mailBox.db)
		if not ret then
			mailBox.db.account = account
			if not mailBox.db:add() then
				return false
			end
		end
		MailBoxList[account] = mailBox
	end
	return mailBox
end

function getSysMailBox()
	if not SysBox then
		local query = {account = MailDefine.SYS_MAIL_ACCOUNT}
		local result = MailBox.new()
    	local ret = DB.Find(ns,query,result.db)
		if not ret then
			result.db.account = MailDefine.SYS_MAIL_ACCOUNT
			if not result.db:add() then
				return false
			end
		end
		SysBox = result
	end
	return SysBox
end

--param: attachment = {{id,cnt},{id,cnt}}
function sysSendMail(receiver,title,content,attachment)
	local attachment = attachment or {}
	if next(attachment) then
		local tempAttach = {}
		local virItems = {}
		for i = 1,#attachment do
			local id = attachment[i][1]
			local cnt = attachment[i][2]
			if BagLogic.isVirItem(id) then
				table.insert(virItems,{id,cnt})
			else
				table.insert(tempAttach,{id,cnt})
			end
			if i == #attachment then
				for k,v in pairs(virItems) do
					table.insert(tempAttach,v)
				end
				sysSendMailSub(receiver,title,content,tempAttach)
			else
				if #tempAttach >= 3 then
					for k,v in pairs(virItems) do
						table.insert(tempAttach,v)
					end
					sysSendMailSub(receiver,title,content,tempAttach)
					tempAttach = {}
				end
			end
		end
	else
		sysSendMailSub(receiver,title,content,attachment)
	end

	local logTb = Log.getLogTb(LogId.SEND_MAIL)
	logTb.account = "system"
	logTb.name = "系统"
	logTb.pAccount = ""
	logTb.sendAccount = "system"
	logTb.sendCharName = "系统"
	logTb.recvAccount = receiver
	logTb.content = content
	logTb.title = title
	logTb.source = way or CommonDefine.MAIL_TYPE.SEND
	logTb:save()
end

--param: attachment = {{id,cnt},{id,cnt}}
function sysSendMailSub(receiver,title,content,attachment)
	local mailBox = getMailBox(receiver)
	local mail = {}
	mail.mtype = MailDefine.MAIL_TYPE_SYSTEM
	mail.sender = MailDefine.SYS_MAIL_NAME
	mail.sendtime = os.time()
	mail.title = title
	mail.content = content
	mail.attach = attachment or {}
	if not mailBox:addMail(mail) then
		mailBox:raiseSave()
	end
	return true
end

--param: appendAttach = {{id,cnt},{id,cnt}}
function sysSendMailById(receiver,mailId,appendAttach,...)
	local cfg = MailConfig[mailId]
	if cfg then
		local content = cfg.content
		if ... then
			content = string.format(cfg.content,...)
		end
		local attachment = {}
		if cfg.attachment.items then
			for i = 1,#cfg.attachment.items do
				table.insert(attachment,cfg.attachment.items[i])
			end
		end
		if appendAttach then
			for i = 1,#appendAttach do
				table.insert(attachment,appendAttach[i])
			end
		end
		sysSendMail(receiver,cfg.title,content,attachment)
	end
end

function gmSendMail()
	local mailBox = getSysMailBox()
	local mail = {}
	mail.mtype = MailDefine.MAIL_TYPE_GM
	mail.sender = MailDefine.SYS_MAIL_NAME
	mail.sendtime = os.time()
	mail.title = "转战新服 返还钻石"
	mail.content = "拳皇Q传即将开启新服！在新服中我们将会返还大家在1服中充值所获得VIP等级以及全部钻石！欢迎进驻！！\n1.	充值返回的统计截止到新服开启前一天，新服开启之后，在1服中充值是不会返还的\n2.	使用同样的YY账号进驻新服才能获得返还\n3.	新服2015年5月28日下午2点开启"
	--mail.attach = {{9901001,123},{9901002,345}}
	--mail.attach = {{9901003,123},{9901004,345}}
	--mail.attach = {{9901005,123},{9901006,345},{1204001,2}}
	--mail.cond = {minLv = 3,maxLv = 5,to = {["[]yy2"] = 1,["[]yy3"] = 1,["[]yy4"] = 1}}
	if not mailBox:addMail(mail) then
		mailBox:raiseSave()
	end
	return true
end

function saveAll()
	for k,v in pairs(MailBoxList) do
		if v.saveTimer then
			v.db:save(true)
			v.saveTimer = nil
		end
	end
	if SysBox then
		SysBox.db:save(true)
	end
end

function unMaskMailId(id)
	if id > MailDefine.MAIL_GM_MASK then
		return id - MailDefine.MAIL_GM_MASK,MailDefine.MAIL_TYPE_GM
	else
		return id,MailDefine.MAIL_TYPE_SYSTEM
	end
end

function maskMailId(mail)
	if mail.mtype == MailDefine.MAIL_TYPE_SYSTEM then
		return mail.id
	else
		return mail.id + MailDefine.MAIL_GM_MASK
	end
end
