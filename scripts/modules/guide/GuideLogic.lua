module(...,package.seeall)

local Msg = require("core.net.Msg")
local GuideConfig = require("config.GuideConfig").Config
local GuideDefine = require("modules.guide.GuideDefine")
local BagLogic = require("modules.bag.BagLogic")
local BagDefine = require("modules.bag.BagDefine")

function onHumanLogin(hm,human)
	Msg.SendMsg(PacketID.GC_GUIDE, human, human.db.finishGuide)	
	initFinishGuideMap(human)
end

function initFinishGuideMap(human)
	local tab = Util.Split(human.db.finishGuide, ',')
	for _,id in ipairs(tab) do
		if id ~= "" then
			human.finishGuideMap[tonumber(id)] = true
		end
	end
end

function saveGuide(human, guideId)
	if GuideConfig[guideId] then
		if human.finishGuideMap[guideId] == nil then
			human.db.finishGuide = human.db.finishGuide .. guideId .. ','
			human.finishGuideMap[guideId] = true

			local logTb = Log.getLogTb(LogId.GUIDE)
			logTb.name = human:getName()
			logTb.account = human:getAccount()
			logTb.pAccount = human:getPAccount()
			logTb.guideId = guideId
			logTb:save()
			
			if guideId == GuideDefine.GUIDE_HERO_LV_UP then
				--加突破石
				BagLogic.addItem(human, BagDefine.ITEM_BREAK, 50, true, CommonDefine.ITEM_TYPE.ADD_GUIDE_ITEM)
				BagLogic.addItem(human, BagDefine.ITEM_MONEY, 10000, true, CommonDefine.MONEY_TYPE.ADD_GUIDE_MONEY)
			elseif guideId == GuideDefine.GUIDE_TRAIN_PRE then
				--加培养石
				BagLogic.addItem(human, BagDefine.ITEM_TALENT, 25, true, CommonDefine.ITEM_TYPE.ADD_GUIDE_ITEM)
			elseif guideId == GuideDefine.GUIDE_SKILL_TALK then
				--加暗属性
				BagLogic.addItem(human, BagDefine.ITEM_BLACK_ATTR, 100, true, CommonDefine.ITEM_TYPE.ADD_GUIDE_ITEM)
			elseif guideId == GuideDefine.GUIDE_EQUIP_PRE then
				--加进阶石和金币
				BagLogic.addItem(human, BagDefine.ITEM_EQUIP_UP, 50, true, CommonDefine.ITEM_TYPE.ADD_GUIDE_ITEM)
				BagLogic.addItem(human, BagDefine.ITEM_MONEY, 31000, true, CommonDefine.MONEY_TYPE.ADD_GUIDE_MONEY)
			elseif guideId == GuideDefine.GUIDE_EXP_PRE then
				--加经验药水
				BagLogic.addItem(human, BagDefine.ITEM_DRUG_ID[3], 1, true, CommonDefine.ITEM_TYPE.ADD_GUIDE_ITEM)
			end
		end
	end
end

function saveAllGuide(human)
	for k,v in pairs(GuideConfig) do
		human.finishGuideMap[k] = true
	end
end
