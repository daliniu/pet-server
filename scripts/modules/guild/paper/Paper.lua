module(...,package.seeall)
local MailManager = require("modules.mail.MailManager")
local PaperDefine = require("modules.guild.paper.PaperDefine")

function new()
	local db = {
		genId = 0,
		list = {}
	}
	setmetatable(db,{__index = _M})
	return db 
end

--发红包
function sendPaper(self,human,guild,sum,count)
	self.genId = self.genId + 1
	local seq = makeSeq(sum,count)
	local name = human:getName()
	local account = human:getAccount()
	local id = self.genId
	local list = guild:getMemberList()
	local temp = {}
	for k,v in pairs(list) do
		temp[v.account] = 0
	end
	local data = {
		id = id,
		date = os.time(),
		account = account,
		name = name,
		seq = seq,
		sum = sum,
		got = temp,
	}
	table.insert(self.list,data)
	if #self.list > PaperDefine.MAX_PAPER_NUM then
		self:returnBackAndRemove(1)
	end
	return data 
end

function returnBackAndRemove(self,i)
	self:returnBack(i)
	table.remove(self.list,i)
end
--退还红包
function returnBack(self,i)
	local p = self.list[i]
	if not p then
		return false
	end
	local n = 0
	for k,v in pairs(p.seq) do
		n = n + v
	end
	if n > 0 then
		MailManager.sysSendMail(p.account,"公会红包","红包没有被领取退还",{{9901002,n}})
	end
	p.seq = {}
	--table.remove(self.list,i)
	return true
end

--领红包
function getPaper(self,human,id)
	local account = human:getAccount()
	local num = 0
	for i = 1,#self.list do
		if self.list[i].id == id then
			local data = self.list[i]
			if next(data.seq) then
				local s = math.random(1,#data.seq)
				num = data.seq[s]
				table.remove(data.seq,s)
				data.got[account] = num
			end
		end
	end
	return num
end

--生成红包
function makeSeq(sum,count)
	local randSeq = {}
	local s1 = 0 
	for i = 1,count do
		local num = math.random(1,100)
		s1 = s1 + num
		table.insert(randSeq,num)
	end
	local seq = {}
	for i = 1,count do
		local num = randSeq[i]
		local result = (num/s1) * (sum-count)
		result = result == 0 and 1 or math.ceil(result)
		table.insert(seq,result)
	end
	table.sort(seq,function(a,b)return a<b end)
	table.remove(seq,#seq)
	local s2 = 0
	for i = 1,#seq do
		s2 = s2 + seq[i]
	end
	table.insert(seq,sum-s2)
	return seq
end

function checkOutOfDate(self)
	while 1 do
		local flag = false
		for k,v in pairs(self.list) do
			if os.time() - v.date > PaperDefine.OUT_OF_DATE then
				self:returnBackAndRemove(k)
				flag = true
				break
			end
		end
		if not flag then
			break
		end
	end
end
