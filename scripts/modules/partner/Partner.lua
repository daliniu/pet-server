module(...,package.seeall)
local PartnerDB = require("modules.partner.PartnerDB")

function init(human)
	local partner = new()
	partner:refreshActive(human)
	human.info.partner = partner
end

function new()
	local o = {}
	setmetatable(o,{__index = _M})
	return o
end

function refreshActive(self,human,chainId)
	self.active = self.active or {}
	local forTb = human.db.partner or {}
	if chainId then
		forTb = {[chainId] = true}
	end
	for k,v in pairs(forTb) do
		local cId = tonumber(k)
		if PartnerDB.checkActive(human.db.partner,cId) then
			self.active[cId] = true
		end
	end
end
