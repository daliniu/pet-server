--在线，离线用户管理 
module("HumanManager", package.seeall)
setmetatable(HumanManager, {__index = EventDispatcher}) 

local DB = require("core.db.DB")
local ObjectManager = require("core.managers.ObjectManager")

online = online or {}
offline   = offline or {}

onlineName = onlineName or {}
offlineName   = offlineName or {}

Event_HumanDBLoad = "humanDBLoad"
Event_HumanCreate = "humanCreate"
Event_HumanLogin = "humanLogin"
Event_HumanLogout = "humanLogout"
Event_HumanDisconnect = "humanDisconnect"
Event_HumanLvUp = "humanLvUp"
Event_HumanExpChange = "expChange"
Event_HumanMoneySumChange = "moneySumChange"
Event_DecPhysics = "decPhysics"
Event_DecEnergy = "decEnergy"
Event_FightValChange = "fightValChange"
Event_HumanAttrChange = "humanAttrChange"
Event_HeroCollect = "heroCollect"	--收集英雄
Event_HeroLvUp = "heroLvUp"	
Event_HeroQualityUp = "heroQualityUp"
Event_SkillLvUp = "skillLvUp"	
Event_PowerLvUp = "powerLvUp"	
Event_WeaponLvUp = "weaponLvUp"	
Event_WeaponQualityUp = "weaponQualityUp"
Event_EquipLvUp = "equipLvUp"	
Event_EquipOpen = "equipOpen"	
Event_MonsterDie = "monsterDie"
Event_PartnerActive = "partnerActive"
Event_RechargeChange = "rechargeChange"
Event_AskMail = "askMail"
Event_SendFlower = "sendFlower"

Event_Strength = "strength"
Event_Chapter = "chapter"		
Event_Orochi = "orochi"		
Event_Trial = "trial"		
Event_Arena = "arena"		
Event_Expedition = "expedition"		
Event_WorldBoss = "worldBoss"  
Event_Treasure = "treasure"  	
Event_Physics = "physics"  	
Event_Shop = "shop"  	--商店寻宝
Event_Train = "train"
Event_GetFlower = "getFlower"
Event_OrochiID = "orochiId"
Event_TrialID = "trialId"
Event_HeroBreak = "heroBreak"
Event_HeroStar = "heroStar"
Event_SkillOpen = "skillOpen"
Event_TrainUp = "trainUp"
Event_Spa = "sap"
Event_UpEquip = "upEquip"
Event_Crazy = "crazy"
Event_TopArena = "topArena"
-- 热更新之前需要先清掉事件
_M:removeAllEventListener()

--在线
function countOnline(isReal)
    local count = 0;
    for k,v in pairs(online) do
		if v.fd or not isReal then
        	count = count + 1
		end
    end
    return count
end

function getAllOnline()
	return online
end

function getOnline(account,name)
    return online[account] or onlineName[name]
end

function addOnline(account, human)
	assert(human.typeId == ObjectManager.OBJ_TYPE_HUMAN)
	if offline[account] then --容错，此时不应该纯在离线数据
		offline[account] = nil
	end
	human.db.isOnline = 1
    online[account] = human
	if human:getName():len() > 0 then
		onlineName[human:getName()] = human
	end
end

function delOnline(account)
	local human = online[account] 
	if human then
		dispatchEvent(HumanManager, Event_HumanLogout, human)
		online[account] = nil
		onlineName[human:getName()] = nil
	end
end

function addOnlineByName(name,human)
	assert(human.typeId == ObjectManager.OBJ_TYPE_HUMAN)
    onlineName[name] = human
end

function delOnlineByName(name)
    onlineName[name] = nil
end

-- 离线
function loadOffline(account,name)
	assert(online[account] == nil)
	assert(onlineName[name] == nil)
	local offman = offline[account] or offlineName[name]
    if offman then
        offman:updateTime()
    else
		offman = OfflineHuman.new(account,name)
		if offman then
			offline[offman.account] = offman 
			offlineName[offman.name] = offman 
		end
    end
    return offman
end

function getOffline(account)
    return offline[account] 
end

function delOffline(account)
    local offman = offline[account] 
	print("delOffline=========>",account)
	if offman then
		offline[account] = nil 
		offlineName[offman.name] = nil 
		print("del offline ok=========>",account)
	end
end

function getCharDBByName(name)
	local human = onlineName[name]
	if human == nil then
		local query = {name=name}
		local db = {}
		local ret = DB.Find('char',query,db)
		if ret then
			return db
		end
	else
		return human.db
	end
	return nil
end

function onSaveOfflineDB()
    local alive = 600
    for account,v in pairs(offline) do
        if (v.UpdateTime + alive) <= os.time() then
            v:saveAll()
            offline[account] = nil
            offlineName[v.name] = nil
        end
    end
end

--游戏退出，数据入库
function onGameExit()
	onHumanExit(offline)
	onHumanExit(online)
	print("HumanManager::onGameExit")
end

function onHumanExit(group)
	for account,human in pairs(group) do
		local function cofunc(...)
			human:exit()
		end
		local co = coroutine.create(cofunc)
		local ret,tid = coroutine.resume(co)
		if not ret then 
			local errMsg = "onGameExit coroutine fail \n" .. tostring(tid)
			errMsg = errMsg .. debug.traceback(co)
			LogErr("error",errMsg)
			print("--------------------------------------------")
			print(errMsg)
			print("--------------------------------------------")
		end
		if tid and type(tid) == "number" then 
			DB.DBTManager[tid] = co
		end
	end
end

return HumanManager

