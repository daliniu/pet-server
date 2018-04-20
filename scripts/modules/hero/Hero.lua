module(...,package.seeall)
local PacketID = require("PacketID")
local HeroDefine = require("modules.hero.HeroDefine")
local HeroQualityConfig = require("config.HeroQualityConfig").Config
local HeroDefineConfig = require("config.HeroDefineConfig").Config
local HeroBTConfig = require("config.HeroBreakthroughConfig").Config
local ItemConfig = require("config.ItemConfig").Config
local HeroManager = require("modules.hero.HeroManager")
local Bag = require("modules.bag.BagLogic")
local DyAttrCalc = require("modules.hero.DyAttrCalc")
local Msg = require("core.net.Msg")
local BaseMath = require("modules.public.BaseMath")
local Util = require("core.utils.Util")
local Def = require("modules.hero.HeroDefine")
local SkillDefine = require("modules.skill.SkillDefine")
local ExpConfig = require("config.ExpConfig").Config
local GoldLogic = require("modules.gold.GoldLogic")
local BagDefine = require("modules.bag.BagDefine")

function getName(self)
	return self.db.name
end

function getExp(self)
	return self.db.exp
end
function setExp(self,exp)
	self.db.exp = exp
end
function getBTLv(self)
	return self.db.btLv or 0
end
function getStatus(self)
	return self.db.status or Def.STATUS_NORMAL
end
function setStatus(self,status)
	self.db.status = status
end

function setBTLv(self,lv)
	self.db.btLv = lv
end

function getExchange(self,star)
	if self.db.exchange == nil then self.db.exchange = {} end
	local exchange = self.db.exchange
	if exchange[star] == nil then
		for i=1,HeroDefine.MAX_QUALITY do 
			if exchange[i] == nil then
				exchange[i] = 0 
			end
		end
	end
	return exchange[star]
end
function setExchange(self,star,frag)
	local curFrag= self:getExchange(star)
	self.db.exchange[star] = frag
end

function getSkillPoint(self)
	return  0
end

function decSkillPoint(self,cnt)
	if self:getSkillPoint() >= cnt then
		self.db.skillPoint = self.db.skillPoint - cnt
		return true
	else
		return false
	end
end

function incSkillPoint(self,cnt)
	self.db.skillPoint = self:getSkillPoint() + cnt
end

function setSkillPoint(self,skillPoint)
	if skillPoint and type(skillPoint) == 'number' then
		self.db.skillPoint = skillPoint
	end
end
-- function incExp(self,delta)
-- 	self.db.exp = self.db.exp + delta
-- end

-- function decExp(self,delta)
-- 	if self.db.exp < delta then
-- 		return false
-- 	else
-- 		self.db.exp = self.db.exp - delta
-- 		self:resetDyAttr()
-- 		return true
-- 	end
-- end

function getLv(self)
	return self.db.lv
end
function setLv(self,lv)
	self.db.lv = lv
end
function incLv(self)
	local curLv = self:getLv()
	if curLv >= HeroDefine.MAX_LEVEL then
		return false
	else
		self:setLv(curLv+1)
		self:resetDyAttr()

		-- self:incSkillPoint(ExpConfig[curLv+1].skillPoint)
	end

	HumanManager:dispatchEvent(HumanManager.Event_HeroLvUp,{human=self:getHuman(),objId=self.db.name,objNum=self:getLv()})
	-- 
	-- if curLv >= HeroDefine.MAX_LEVEL then
	-- 	return false
	-- end
	-- --升级所需的经验在此处计算
	-- local exp = self.lv*100
	-- if self:decExp(exp) then
	-- 	self:setLv(curLv+1)
	-- 	self:resetDyAttr()
	-- 	return true
	-- else
	-- 	return false
	-- end
end


-- 计算升级到最高等级需要的经验值
function getTopExp(self)
	local lv = self:getLv()
	local humanLv = self.human:getLv()
	if lv >= Def.MAX_LEVEL or lv >= humanLv then
		return 0
	end
	local exp = self:getExpForLv(lv+1) -self:getExp()
	for i=lv+1,humanLv-1,1 do
		local max = self:getExpForLv(i+1)
		if i == lv then
			exp = max - self:getExp()
		else
			exp = exp + max
		end
	end
	return exp
end

function addTopExp(self,total)
	if total <= 0 then
		return
	end
	local drugIds = BagDefine.ITEM_DRUG_ID
	local sum = 0
	local delGroup = {}
	local topExp = total
	for i = 1,#drugIds do
		local id = drugIds[i]
		delGroup[id] = 0
		local exp = ItemConfig[id].cmd[1]["addExp"][1]
		local need = math.ceil(topExp / exp)
		local own = Bag.getItemNum(self.human,id)
		if own >= need then
			delGroup[id] = need
			topExp = topExp - need * exp
		else
			delGroup[id] = own
			topExp = topExp - own * exp
		end
	end
	local addExpReal = 0
	for k,v in pairs(delGroup) do
		if v > 0 then
			local exp = ItemConfig[k].cmd[1]["addExp"][1]
			addExpReal = addExpReal + exp * v
			Bag.delItemByItemId(self.human,k,v,false,CommonDefine.ITEM_TYPE.DEC_USE_ITEM)
		end
	end
	Bag.sendBagList(self.human)
	self:addExp(addExpReal)
end

function addExp(self,delta,itemId,itemNum)
	if self:getLv() >= HeroDefine.MAX_LEVEL then
		return false
	end
	--如果可以升级，则提升等级，并扣减经验，并发送到前端
	local oldExp = self:getExp()
	local curExp = oldExp + delta
	local oldLv = self:getLv()
	local nextLvExp = self:getExpForNextLv()
	if oldLv > self.human:getLv() then
		return false
	elseif oldLv == self.human:getLv() and oldExp >= nextLvExp then
		return false
	end
	while true do 
		nextLvExp = self:getExpForNextLv()
		if curExp  >= nextLvExp then
			if self:getLv() >= self.human:getLv() then
				curExp = nextLvExp
				break
			else
				self:incLv()
				curExp = curExp - nextLvExp
			end
		else
			break
		end
	end
	self:setExp(curExp)
	local newLv = self:getLv()
	self:sendHeroAttr()
	Msg.SendMsg(PacketID.GC_HERO_ADD_EXP,self.human,self.name,delta,oldLv,newLv)
	local itemName = ''
	if itemId then
		itemName = ItemConfig[fragId].name
	end
	local logTb = Log.getLogTb(LogId.HERO_LEVELUP)
			logTb.account = self.human:getAccount()
			logTb.channelId = self.human:getChannelId()
			logTb.name = self.human:getName()
			logTb.pAccount = self.human:getPAccount()
			logTb.heroName = self:getName()
			logTb.rmb = 0
			logTb.money = 0
			logTb.itemName = itemName
			logTb.itemNum = itemNum or 0
			logTb.incExp = delta
			logTb.postExp = oldExp
			if oldLv ~= newLv then
				logTb.isLvUp = 1
			else
				logTb.isLvUp = 0
			end

			logTb.prevLevel = oldLv
			logTb.postLevel = newLv
			logTb:save()
	return true
end

function getQuality(self)
	return self.db.quality
end

function getTransferLv(self)
	return self.db.strength.transferLv
end

function setQuality(self,quality)
	if quality > 0 and quality <= HeroDefine.MAX_QUALITY then
		self.db.quality = quality
	end
end
function getCTime(self)
	return self.db.ctime
end
function incQuality(self,goldBuyTimes)
	local curQuality = self:getQuality()
	if curQuality >= HeroDefine.MAX_QUALITY then
		return Def.RET_MAXLIMIT
	end
	local frag = BaseMath.getHeroQualityFrag(self:getName(),curQuality+1)
	local fragId = HeroDefine.DefineConfig[self.name].fragId
	if Bag.getItemNum(self.human,fragId) < frag then
		return Def.RET_FRAG_NOTENOUGH
	end
	if self.human:getMoney() < HeroQualityConfig[curQuality+1].qualityMoney then
		if goldBuyTimes > 0 then
			local ret = GoldLogic.buyTen(self.human,goldBuyTimes)
		end

	end
	if self.human:getMoney() < HeroQualityConfig[curQuality+1].qualityMoney then
		return Def.RET_MONEY_NOTENOUGH
	end
	Bag.delItemByItemId(self.human,fragId,frag,true,CommonDefine.ITEM_TYPE.DEC_HERO_STARUP)
	self.human:decMoney(HeroQualityConfig[curQuality+1].qualityMoney,CommonDefine.MONEY_TYPE.DEC_HERO_STARUP)
	self:setQuality(curQuality+1)
	self:resetDyAttr()

	local fragName = ItemConfig[fragId].name
	local logTb = Log.getLogTb(LogId.HERO_STARUP)
			logTb.account = self.human:getAccount()
			logTb.channelId = self.human:getChannelId()
			logTb.name = self.human:getName()
			logTb.pAccount = self.human:getPAccount()
			logTb.heroName = self:getName()
			logTb.rmb = 0
			logTb.money = HeroQualityConfig[curQuality+1].qualityMoney
			logTb.fragName = fragName
			logTb.fragNum = frag
			logTb.prevStar = curQuality
			logTb.postStar = curQuality + 1
			logTb:save()
	return Def.RET_OK
end
-- function incQuality(self,frag,coinFrag,goldBuyTimes)
-- 	local curQuality = self:getQuality()
-- 	if curQuality >= HeroDefine.MAX_QUALITY then
-- 		return Def.RET_MAXLIMIT
-- 	end
-- 	local targetFrag = BaseMath.getHeroQualityFrag(self:getName(),curQuality+1)
-- 	local fragId = HeroDefine.DefineConfig[self.name].fragId
-- 	local fragNum = Bag.getItemNum(self.human,fragId)
-- 	local coinNum = self.human:getExchangeCoin()
-- 	local exchange = Def.DefineConfig[self.name].exchangeCoin

-- 	if self.human:getMoney() < HeroQualityConfig[curQuality+1].qualityMoney then
-- 		if goldBuyTimes > 0 then
-- 			local ret = GoldLogic.buyTen(self.human,goldBuyTimes)
-- 		end

-- 	end
-- 	if self.human:getMoney() < HeroQualityConfig[curQuality+1].qualityMoney then
-- 		return Def.RET_MONEY_NOTENOUGH
-- 	end

-- 	if frag > fragNum or coinFrag*exchange[1] > coinNum or coinFrag > exchange[curQuality+1] then
-- 		return Def.RET_FRAG_NOTENOUGH
-- 	end
-- 	if frag + coinFrag < targetFrag then
-- 		return Def.RET_FRAG_NOTENOUGH
-- 	end

-- 	Bag.delItemByItemId(self.human,fragId,frag,true,CommonDefine.ITEM_TYPE.DEC_HERO_STARUP)
-- 	self.human:decExchangeCoin(coinFrag*exchange[1])
-- 	self.human:decMoney(HeroQualityConfig[curQuality+1].qualityMoney,CommonDefine.MONEY_TYPE.DEC_HERO_STARUP)
-- 	self:setQuality(curQuality+1)
-- 	self:resetDyAttr()

-- 	local fragName = ItemConfig[fragId].name
-- 	local logTb = Log.getLogTb(LogId.HERO_STARUP)
-- 			logTb.account = self.human:getAccount()
-- 			logTb.channelId = self.human:getChannelId()
-- 			logTb.name = self.human:getName()
-- 			logTb.pAccount = self.human:getPAccount()
-- 			logTb.heroName = self:getName()
-- 			logTb.rmb = 0
-- 			logTb.money = HeroQualityConfig[curQuality+1].qualityMoney
-- 			logTb.fragName = fragName
-- 			logTb.fragNum = frag
-- 			logTb.prevStar = curQuality
-- 			logTb.postStar = curQuality + 1
-- 			logTb:save()
-- 	return Def.RET_OK
-- end

function resetDyAttr(self)
	self.dyAttr = nil
end



-- 根据heroDb 刷新延伸属性heroInfo
function calcDyAttr(self,notCalcFight)
	if self.dyAttr ~= nil then return end
	self.dyAttr = {}
	-- DyAttrCalc.calcHeroDyAttrbyStaticAttr(self)
	DyAttrCalc.calcHeroDyAttr(self)
	if not notCalcFight then
		self:calcFight()
	end
end

function calcFight(self)
	--属性相关
	local fight = 0
	fight = self.dyAttr.maxHp * (1 + 0.00012 * self.dyAttr.def + 0.00008 * self.dyAttr.finalDef)
		* (1 + self.dyAttr.block / 4000) * (1 + self.dyAttr.antiCrthit / 4000)
		* (0.6 * self.dyAttr.atk + 0.4 * self.dyAttr.finalAtk) * (1 + self.dyAttr.crthit / 4000)
		* (1 + self.dyAttr.antiBlock / 4000) * (self.dyAttr.atkSpeed / 100) / 10000 + 100

	--技能相关
	for _,group in pairs(self:getSkillGroupList()) do
		if group:isEquip() == true or group:getConf().type == SkillDefine.TYPE_FINAL or group:getConf().type == SkillDefine.TYPE_ASSIST then
			fight = fight + group:getFight()
		end
	end 

	self.fight = math.floor(fight)
	HumanManager:dispatchEvent(HumanManager.Event_FightValChange,{obj = self:getHuman(),hero = self,val = self.fight})
end


function sendQualityUp(self,ret)
	Msg.SendMsg(PacketID.GC_HERO_QUALITY_UP,self.human,self.name,ret,self:getQuality())
end
function sendLvUp(self,ret)
	Msg.SendMsg(PacketID.GC_HERO_LV_UP,self.human,self.name,ret,self:getLv())
end

function metaDyAttr(t,k)
	for _,name in pairs(HeroDefine.DecimalAttrs) do
		if k== name then
			return math.floor(rawget(t,k)*100)
		end
	end
	return rawget(t,k)
end

function dyAttr1(dyAttr)
	for _,name in pairs(HeroDefine.DecimalAttrs) do
		if dyAttr[name] then dyAttr[name] = dyAttr[name]*100 end
	end
end

function dyAttr2(dyAttr)
	for _,name in pairs(HeroDefine.DecimalAttrs) do
		if dyAttr[name] then dyAttr[name] = dyAttr[name]/100 end
	end
end

function translateDyAttr(k,v)
	for _,name in pairs(HeroDefine.DecimalAttrs) do
		if k == name then
			return math.floor(v*100)
		end
	end
	return v
end

function sendDyAttr(self)
	self:calcDyAttr()
	dyAttr1(self.dyAttr)
	Msg.SendMsg(PacketID.GC_HERO_DYATTR,self.human,self.name,self.dyAttr)
	dyAttr2(self.dyAttr)
end

function getHuman(self)
	return self.human
end

function sendHeroAttr(self)
	self:calcDyAttr()
	dyAttr1(self.dyAttr)
	Msg.SendMsg(PacketID.GC_HERO_ATTR,self.human,self.name,self:getExp(),self:getLv(),self:getQuality(),self:getCTime(),self:getBTLv(),self:getStatus(),self.dyAttr,self.db.exchange)
	dyAttr2(self.dyAttr)
end

--获得升级到某个等级需要多少

function getExpForNextLv(self)
	return self:getExpForLv(self:getLv() + 1)
end

function getExpForLv(self,lv)
	return BaseMath.getHeroExp(lv)
end

function getSkillGroupList(self)
	return self.db.skill.skillGroup
end

function showInfo(self,msg)
	-- if msg then
	-- 	print(msg)	
	-- end
	-- Util.print_r(self.dyAttr)
	-- print("")
end

function getCost(self)
	return self.dyAttr.cost
end

function getFight(self)
	if self.fight == nil then
		self:calcDyAttr()
	end
	return self.fight
end

function breakthrough(self,lv)


end


function getBTLvInfo(lv)
	if HeroBTConfig[lv] then
		return HeroBTConfig[lv].heroLv,HeroBTConfig[lv].stone,HeroBTConfig[lv].money,HeroBTConfig[lv].heroStar
	end
end

function getBTAttr(attr,lv)
	if lv == 0 then return 0 end
	if HeroBTConfig[lv] and HeroBTConfig[lv][attr] then
		local value = 0
		for i=1,lv do
			value = value + HeroBTConfig[i][attr]
		end
		return value
	end
end

function getGift(self)
	return self.db.gift
end

return Hero
