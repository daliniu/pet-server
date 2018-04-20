module(...,package.seeall)
local MailDefine = require("modules.mail.MailDefine")
local MailDB = require("modules.mail.MailDB")
local MailManager = require("modules.mail.MailManager")
local HumanManager = require("core.managers.HumanManager")
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local MAIL_SAVE_TIME = 60

function new()
	local mailBox = {
		db=MailDB.new(),
		saveTimer = nil,
	}
	setmetatable(mailBox,{__index = _M})
	return mailBox
end

function onMailBoxSave(self)
	if self.saveTimer then
		self.db:save()
		self.saveTimer = nil
	end
end

function raiseSave(self)
	if not self.saveTimer then
		local saveTime = (MAIL_SAVE_TIME + math.random(0,600)) * 1000
		self.saveTimer = Timer.new(saveTime,1)
		self.saveTimer:setRunner(onMailBoxSave,self)
		self.saveTimer:start()
	end
end

function getMails(self,human)
	local mails = {}
	local cnt = 0
	for k,v in pairs(self.db.inbox) do
		cnt = cnt + 1
		mails[cnt] = v
	end
	local sysBox = MailManager.getSysMailBox()
	for k,v in pairs(sysBox.db.inbox) do
		local status = self.db.sysbox[k]
		if status then
			if status ~= MailDefine.MAIL_STATUS_DELETED then
				cnt = cnt + 1
				v.status = status or MailDefine.MAIL_STATUS_UNREAD
				v.mtype = MAIL_TYPE_GM
				mails[cnt] = v
			end
		else
			if self:checkGMMail(human,v) then
				cnt = cnt + 1
				v.status = status or MailDefine.MAIL_STATUS_UNREAD
				v.mtype = MAIL_TYPE_GM
				mails[cnt] = v 
			end
		end
	end
	nMails = self:processMaxMail(mails)
	return nMails 
end

function getMailById(self,id)
	local mailId,mtype = MailManager.unMaskMailId(id)
	if mtype == MailDefine.MAIL_TYPE_SYSTEM then
		return self.db.inbox[mailId]
	elseif mtype == MailDefine.MAIL_TYPE_GM then
		if not self.db.sysbox[mailId] or self.db.sysbox[mailId] ~= MailDefine.MAIL_STATUS_DELETED then
			local sysBox = MailManager.getSysMailBox()
			return sysBox.db.inbox[mailId]
		end
	end
	return 
end

function processMaxMail(self,mails)
	if #mails > MailDefine.MAIL_MAX_LEN then
		local temp = {}
		for k,v in pairs(mails) do
			table.insert(temp,{id = k,mail = v})
		end
		table.sort(temp,function(a,b)
			if a.mail.sendtime == b.mail.sendtime then
				return a.mail.id > b.mail.id
			else
				return a.mail.sendtime > b.mail.sendtime 
			end
		end)
		local ret = {}
		for i = 1,#mails do
			local mailId = temp[i].mail.id
			if i > MailDefine.MAIL_MAX_LEN then
				if temp[i].mail.mtype == MailDefine.MAIL_TYPE_SYSTEM then
					self.db.inbox[mailId] = nil
				else
					self.db.sysbox[mailId] = MailDefine.MAIL_STATUS_DELETED
				end
			else
				ret[i] = temp[i].mail
			end
		end
		self:raiseSave()
		return ret
	else
		return mails
	end
end

function addMail(self,mail)
	self.db.genId = self.db.genId + 1
	local mailto = {}
	mailto.id = self.db.genId
	mailto.status = MailDefine.MAIL_STATUS_UNREAD
	mailto.mtype = mail.mtype or MailDefine.MAIL_TYPE_SYSTEM
	mailto.sender = mail.sender or "匿名"
	mailto.sendtime = mail.sendtime or os.time()
	mailto.title = mail.title or ""
	mailto.content = mail.content or ""
	mailto.attach = mail.attach or {}
    mailto.cond = mail.cond or nil
	self.db.inbox[mailto.id] = mailto
	self:raiseSave()

	if self.db.account == MailDefine.SYS_MAIL_ACCOUNT then
		for k,v in pairs(HumanManager.online) do
			if self:checkGMMail(v,mailto) then
				Msg.SendMsg(PacketID.GC_NEW_MAIL,v)
			end
		end
	else
		local account = self.db.account
		local obj = HumanManager.getOnline(account)
		if obj then
			Msg.SendMsg(PacketID.GC_NEW_MAIL,obj)
		end
	end
	return true
end

function delMailById(self,id)
	local mailId,mtype = MailManager.unMaskMailId(id)
	if mtype == MailDefine.MAIL_TYPE_SYSTEM then
		self.db.inbox[mailId] = nil
	elseif mtype == MailDefine.MAIL_TYPE_GM then
		self.db.sysbox[mailId] = MailDefine.MAIL_STATUS_DELETED
	end
	self:raiseSave()
	return true
end

function isMatchCond(human,mail)
	local ret = true
	--if mail.cond then
	--	if mail.cond.minLv and human:getLv() < mail.cond.minLv then
	--		ret = false
	--	end
	--	if mail.cond.maxLv and human:getLv() > mail.cond.maxLv then
	--		ret = false
	--	end
	--	if mail.cond.recharge and human.db.recharge <= 0 then
	--		ret = false
	--	end
	--	if mail.cond.to and not mail.cond.to[human:getAccount()] then
	--		ret = false
	--	end
	--end
	if mail.cond then
		if mail.cond.toUId then
			if next(mail.cond.toUId) then
				if not mail.cond.toUId[human:getAccount()] then
					ret = false
				end
			else
				if not mail.cond.toName[human:getName()] then
					ret = false
				end
			end
		else
			if mail.cond.minVipLevel and human:getVip() < mail.cond.minVipLevel then
				ret = false
			end
			if mail.cond.maxVipLevel and human:getVip() > mail.cond.maxVipLevel then
				ret = false
			end
			if mail.cond.minLevel and human:getLv() < mail.cond.minLevel then
				ret = false
			end
			if mail.cond.maxLevel and human:getLv() < mail.cond.maxLevel then
				ret = false
			end
			if mail.cond.minRegisterTime and human.db.createDate < mail.cond.minRegisterTime then
				ret = false
			end
			if mail.cond.maxRegisterTime and human.db.createDate > mail.cond.maxRegisterTime then
				ret = false
			end
			if mail.cond.minLoginTime and human.db.lastLogin < mail.cond.minLoginTime then
				ret = false
			end
			if mail.cond.maxLoginTime and human.db.lastLogin > mail.cond.maxLoginTime then
				ret = false
			end
			if mail.cond.online then
				if mail.cond.online == 1 and human.db.isOnline == 0 then --在线邮件
					ret = false
				elseif mail.cond. online == 2 and human.db.isOnline == 1 then --不在线邮件
					ret = false
				end
			end
		end
	end
	return ret
end

function checkGMMail(self,human,mail)
	local ret = isMatchCond(human,mail)
	if not ret then
		self.db.sysbox[mail.id] = MailDefine.MAIL_STATUS_DELETED
		self:raiseSave()
	end
	return ret
end
