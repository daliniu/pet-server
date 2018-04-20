module(...,package.seeall)
local Msg = require("core.net.Msg")
local PacketID = require("PacketID")
local PartnerDefine = require("modules.partner.PartnerDefine")
local PartnerDB = require("modules.partner.PartnerDB")
local COMPOSE_RET = PartnerDefine.COMPOSE_RET
local EQUIP_RET = PartnerDefine.EQUIP_RET
local ACTIVE_RET = PartnerDefine.ACTIVE_RET
local PartnerConfig = require("config.PartnerConfig").Config
local ChainConfig = require("config.PartnerChainConfig").Config
local Partner = require("modules.partner.Partner")
local BagLogic = require("modules.bag.BagLogic")
local HeroManager = require("modules.hero.HeroManager")
Hero2PartnerCfg = Hero2PartnerCfg or {}

function onHumanLogin(hm,human)
	query(human)
end

function query(human)
	local retMsg = {}
	for k,v in pairs(human.db.partner) do
		local data = {}
		data.chainId = tonumber(k)
		data.partnerIds = {}
		for i = 1,#v do
			table.insert(data.partnerIds,v[i])
		end
		table.insert(retMsg,data)
	end
    Msg.SendMsg(PacketID.GC_PARTNER_QUERY,human,retMsg)
end

function compose(human,id)
	local cfg = PartnerConfig[id]
	if not cfg then
		return false,COMPOSE_RET.kDataErr
	end
	--local hero = human:getHero(cfg.hero)
	--if not hero then
	--	return false,COMPOSE_RET.kNoHero
	--end
	for k,v in pairs(cfg.need) do
		if BagLogic.getItemNum(human,k) < v then
			return false,COMPOSE_RET.kNoMaterial
		end
	end
    if not BagLogic.checkCanAddItem(human, id, 1) then
		return false,COMPOSE_RET.kFullBag
	end
	for k,v in pairs(cfg.need) do
		BagLogic.delItemByItemId(human,k,v,false,CommonDefine.ITEM_TYPE.DEC_PARTNER_COMPOSE)
	end
	BagLogic.addItem(human, id, 1,true,CommonDefine.ITEM_TYPE.ADD_PARNTER_COMPOSE)
	query(human)
	return true,COMPOSE_RET.kOk
end

function equip(human,chainId,partnerId)
	--if not ChainConfig[chainId] then
	--	return false,EQUIP_RET.kDataErr
	--end
	local cfg = PartnerConfig[partnerId]
	if not cfg then
		return false,EQUIP_RET.kDataErr
	end
	--local hero = human:getHero(cfg.hero)
	--if not hero then
	--	return false,EQUIP_RET.kNoHero
	--end
	if BagLogic.getItemNum(human,partnerId) <= 0 then
		return false,EQUIP_RET.kNoItem
	end
	BagLogic.delItemByItemId(human,partnerId,1,true,CommonDefine.ITEM_TYPE.DEC_PARTNER_EQUIP)
	addPartner(human,chainId,partnerId)
	query(human)
	sendHeroDyAttr(human)

	local HumanManager = require("core.managers.HumanManager")
	HumanManager:dispatchEvent(HumanManager.Event_PartnerActive,{human=human,objId=partnerId})
	
	return true,EQUIP_RET.kOk
end

function sendHeroDyAttr(human)
	local heroList = HeroManager.getAllHeroes(human)
	for _,hero in pairs(heroList) do
		hero:resetDyAttr()
		hero:sendDyAttr()
	end
end

function isActive(human,chainId)
	local infoPartner = getInfoPartner(human)
	if not infoPartner.active[chainId] then
		return false
	end
	return true
end

function getInfoPartner(human)
	if not human.info.partner then
		Partner.init(human)
	end
	return human.info.partner
end

function addPartner(human,chainId,partnerId)
	local dbPartner = human.db.partner
	dbPartner:add(chainId,chainId)
	--local infoPartner = human.info.partner
	local infoPartner = getInfoPartner(human)
	infoPartner:refreshActive(human,chainId)
end

function onDBLoad(hm,human)
	PartnerDB.setMeta(human)
end

function init()
	Hero2PartnerCfg = {}
	for k,v in pairs(PartnerConfig) do
		Hero2PartnerCfg[v.hero] = Hero2PartnerCfg[v.hero] or {}
		Hero2PartnerCfg[v.hero].partner = v.id
	end
	for k,v in pairs(ChainConfig) do
		for id,val in pairs(v.group) do
			if PartnerConfig[id] then
				local name = PartnerConfig[id].hero
				Hero2PartnerCfg[name] = Hero2PartnerCfg[name] or {}
				Hero2PartnerCfg[name].chain = Hero2PartnerCfg[name].chain or {}
				table.insert(Hero2PartnerCfg[name].chain,k)
			end
		end
	end
	--print("Hero2PartnerCfg")
	--Util.print_r(Hero2PartnerCfg)
end

function getHero2PartnerCfg()
	return Hero2PartnerCfg
end

function getPartnerNumById(human,id)
	local num = 0
	local dbPartner = human.db.partner
	for _,chain in pairs(dbPartner) do
		for _,partnerId in pairs(chain) do
			if id == partnerId then
				num = num + 1
			end
		end
	end
	return num
end

function active(human,chainId)
	local cfg = ChainConfig[chainId]
	if not cfg then
		return false,ACTIVE_RET.kDataErr
	end
	for k,v in pairs(cfg.group) do
		if BagLogic.getItemNum(human,k) < v then
			return false,ACTIVE_RET.kNoItem
		end
	end
	if PartnerDB.checkActive(human.db.partner,chainId) then
		return false,ACTIVE_RET.kHasActive
	end
	for k,v in pairs(cfg.group) do
		BagLogic.delItemByItemId(human,k,v,false,CommonDefine.ITEM_TYPE.DEC_PARTNER_ACTIVE)
	end
	addPartner(human,chainId)
	local attrs = {}
	for k,v in pairs(cfg.group) do
		if PartnerConfig[k] then
			local name = PartnerConfig[k].hero
			local hero = human:getHero(name)
			local changeVal = {}
			if hero then
				for kk,vv in pairs(cfg.attr) do
					local preVal = hero.dyAttr[kk]
					table.insert(changeVal,{name = name,attrname = kk,preVal = preVal})
				end
				hero:resetDyAttr()
				hero:sendDyAttr()
			end
			for kk,vv in pairs(changeVal) do
				local val = hero.dyAttr[vv.attrname]
				table.insert(attrs,{name = vv.name,attrname = vv.attrname,preAttrVal = vv.preVal,attrVal = val})
			end
		end
	end
	BagLogic.sendBagList(human)
	query(human)
	local HumanManager = require("core.managers.HumanManager")
	HumanManager:dispatchEvent(HumanManager.Event_EquipOpen,{human=human})
	return true,ACTIVE_RET.kOk,attrs
end
