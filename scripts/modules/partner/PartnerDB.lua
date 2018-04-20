module(...,package.seeall)
local ChainConfig = require("config.PartnerChainConfig").Config

function new()
	local o = {}
	setmetatable(o,{__index = _M})
	return o
end

function add(self,chainId,partnerId)
	local chainId = tostring(chainId)
	self[chainId] = self[chainId] or {}
	for i = 1,#self[chainId] do
		if partnerId == self[chainId][i] then
			return
		end
	end
	table.insert(self[chainId],partnerId)
end

function setMeta(human)
	local o = human.db.partner
	setmetatable(o, {__index = _M})
	--DB.dbSetMetatable(o)
end

function checkActive(self,chainId)
	local cfg = ChainConfig[chainId]
	local chainId = tostring(chainId)
	if not self[chainId] then
		return false
	end
	if not cfg then
		return false
	end
	--if #cfg.group ~= #self[chainId] then
	--	return false
	--end
	--local temp = {}
	--for k,v in pairs(self[chainId]) do
	--	temp[v] = true
	--end
	--for i = 1,#cfg.group do
	--	local id = cfg.group[i]
	--	if not temp[id] then
	--		return false
	--	end
	--end
	return true
end
