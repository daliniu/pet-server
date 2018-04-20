module(...,package.seeall)
local ns = "mail"

-- mailbox{ account, genId,sendtime, 
--          inbox[id={id,mtype,sender,status,time,title,content,rmb,money,attach[{itemId,cnt}]}],
--          outbox[id={id,mtype,receiver,status,time,title,content,rmb,money,attach[{itemId,cnt}]}],
--          sysbox[id={id,status}]
--}

function new()
	local mail = {
		account = "",
		genId = 0,
		sendtime = 0,
		cond = nil, --后台邮件限制条件 minLv:最小等级，maxLv：最大等级, to:发送对象们
		inbox = {},
		--outbox = {},
		sysbox = {},
	}
	DB.dbSetMetatable(mail.inbox)
	DB.dbSetMetatable(mail.sysbox)
	setmetatable(mail,{__index = _M})
	return mail
end

function add(self,isSync)
    return DB.Insert(ns,self,isSync)
end

function save(self,isSync)
	local query = {_id = self._id}
    return DB.Update(ns,query,self,isSync)
end
