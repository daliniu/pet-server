module(..., package.seeall)
local Json = require("core.utils.Json")
local CommonDefine = require("core.base.CommonDefine")
local Util = require("core.utils.Util")
local PacketID = require("PacketID")
local Msg = require("core.net.Msg")
local Sha1 = require("core.utils.SHA1")

local ForbidManager = require("modules.admin.ForbidManager")
local Announce = require("modules.announce.Announce")
local RechargeLogic = require("modules.recharge.RechargeLogic")
local VipLogic = require("modules.vip.VipLogic")
local VipRechargeConfig = require("config.VipRechargeConfig").Config
local Activity = require("modules.activity.Activity")
local MailManager = require("modules.mail.MailManager")
local MailDefine = require("modules.mail.MailDefine")
local VipDefine = require("modules.vip.VipDefine")
local GuildManager = require("modules.guild.GuildManager")
local BagLogic = require("modules.bag.BagLogic")
local AnnounceDefine = require("modules.announce.AnnounceDefine")
local ItemConfig = require("config.ItemConfig").Config
local HeroDefine = require("modules.hero.HeroDefine")
local Chapter = require("modules.chapter.Chapter")
local PaperLogic = require("modules.guild.paper.PaperLogic")
--http请求总入口

SvrId = Config.SVRNAME:sub(2,Config.SVRNAME:len()-1)
StatPayAPI = "http://login.qhqz.gop.yy.com/stat/pay"

function MakeHttpRequest(oJsonInput, otherParam)
	local ret = "/admin?"
	local bFirst = true
	for k, v in pairs(oJsonInput) do
		if bFirst then
			bFirst = false
		else
			ret = ret .. "&"
		end
		ret = ret .. k .. "=" .. v
	end
	if otherParam then
		ret = ret .. otherParam
	end
	return ret
end

function checkSign(kvTb,...)
	if Config.ISTESTCLIENT then return true end
	local str = ""  
	for _,v in ipairs({...}) do
		str = str .. v
	end
	str = str .. kvTb.ts
	return kvTb.sign == Sha1.hmac(Config.ADMIN_KEY,str)
end

DayRegister = DayRegister or 0
LastRegisterDay = LastRegisterDay or 0
function incDayRegister()
	if os.date("%d") ~= LastRegisterDay then
		DayRegister = 0
		LastRegisterDay = os.date("%d")
	end
	DayRegister = DayRegister + 1
end


------------------------------------------------------------------------------------
-- 管理后台相关函数 begin
------------------------------------------------------------------------------------


local ParamErrRet={}

local OprOKRet= "{\"code\":1,\"message\":\"ok\"}"
local Timeout = "{\"code\":-2,\"message\":\"timeout\"}"
local SighFail = "{\"code\":-3,\"message\":\"sign error\"}"
local UserNotExist= "{\"code\":-4,\"message\":\"User is not exist\"}"

local oResult = {code=1,message="ok"}
local helpMsg = {
	"q=online:请求当前在线人数",
	"q=getPlayer&name=xx:请求玩家信息",
}


function help()
	return Json.Encode(helpMsg)
end


function hotup(kvTb)
	print("hotup============>")
	package.loaded["RenewAll"] = nil
	require("RenewAll")
	return OprOKRet
end

--模拟验证登录
function auth(kvTb)
	return "true"
end

--充值
function pay(kvTb)
	local oResult = {message=""}
	local account = kvTb.account
	local name = kvTb.name
	local orderId = kvTb.order_id
	local rechargeType = kvTb.currency_type	--货币类型
	local recharge = kvTb.money		--人民币(单位分)
	local rmb = kvTb.charge_currency	--兑换的货币,平台提供的不准的
	local channel = kvTb.channel
	local way = kvTb.type
	local param = kvTb.app_param or ""
	if not checkSign(kvTb,kvTb.uid,kvTb.rolename,orderId,rechargeType,kvTb.money,rmb,channel,way,kvTb.items, param) then
		oResult.code = CommonDefine.PAY_FAIL
		oResult.message = "check sign fail"
		addRecharegeLog(nil,kvTb, CommonDefine.PAY_FAIL)
		return Json.Encode(oResult)
	end
	recharge = tonumber(recharge)
	rmb = tonumber(rmb)
	--channel = tonumber(channel) --is str
	local itemArr = Json.Decode(kvTb.items)
	--只支持充值一种商品
	for _,v in pairs(itemArr) do
		kvTb.goodId = tonumber(v.item)
		kvTb.goodNum = tonumber(v.num)
		break
	end
	print("===========>>",account,name)
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	if not human then
		oResult.code = CommonDefine.PAY_NO_CHAR
		oResult.message = "user not exist"
		addRecharegeLog(nil,kvTb, CommonDefine.PAY_NO_CHAR)
		return Json.Encode(oResult)
	else
		kvTb.account = human:getAccount()
		kvTb.name = human:getName()
	end
	local cfg = VipRechargeConfig[kvTb.goodId]
	if cfg and (cfg.cash * 100) == recharge then
		kvTb.rmb = VipLogic.recharge(human, cfg.id)
		if cfg.rechargeType == 2 then
			kvTb.rmb = Activity.buyMonthCard(human,cfg)
		elseif cfg.rechargeType == 3 then
			PaperLogic.send(human,cfg.rmb)
		end
	else
		oResult.code = CommonDefine.PAY_NO_ITEM
		oResult.message = "item not exists"
		addRecharegeLog(human,kvTb, CommonDefine.PAY_NO_ITEM)
		return Json.Encode(oResult)
	end
	oResult.code = CommonDefine.PAY_SUCCESS
	addRecharegeLog(human,kvTb, CommonDefine.PAY_SUCCESS)
	return Json.Encode(oResult)
end

function addRecharegeLog(human,kvTb, status)
	local logTb = Log.getLogTb(LogId.PAY)
	logTb.name = kvTb.name or ""
	logTb.account = kvTb.account or ""
	logTb.orderId = kvTb.order_id or ""
	logTb.rmb = kvTb.rmb or 0	--钻石
	logTb.recharge = kvTb.money or 0			--人民币
	logTb.rechargeType = kvTb.currency_type or ""		--货币类型
	logTb.channel = kvTb.channel or ""			--渠道
	logTb.goodId = kvTb.goodId or 0
	logTb.goodNum = kvTb.goodNum or 0
	logTb.type = kvTb.type or 0
	logTb.status = status
	if human then
		logTb.pAccount = human.db.pAccount
		logTb.lv = human:getLv()
		logTb.channelId = human:getChannelId()
	else
		logTb.pAccount = ""
		logTb.lv = 0 
	end
	logTb:save()
	sendPayLog(human,logTb)
end

function sendPayLog(human,logTb)
	if not human or logTb.status ~= CommonDefine.PAY_SUCCESS then
		return
	end
	if Config.ISTESTCLIENT then 
		return  
	end
	local cfg = VipRechargeConfig[logTb.goodId]
	local stat = {
		msgID = logTb.orderId,
		status = "success",
		OS = "ios",			--@todo 从渠道取os
		accountID = human:getAccount(), 
		orderID = logTb.orderId,
		currencyAmount = logTb.recharge/100,	 --充值金额
		currencyType="CNY",	
		virtualCurrencyAmount = logTb.rmb,	--兑换的虚拟币金额
		chargeTime= os.time(),
		iapID = cfg.name,	 --充值包名称
		paymentType = logTb.channel,	--支付方式
		gameServer = SvrId,
		level = human:getLv(),	
		mission= tostring(Chapter.getTopLevel(human)),	  --关卡	
	}
	local url = string.format("%s?data=%s",StatPayAPI,Util.url_encode(Json.Encode(stat)))
	Msg.sendHttpRequest(PacketID.GG_HTTP_STAT_PAY,human.fd or 0,url)
end

function setActivity(kvTb)
	local actDb = {}
	actDb.opened = tonumber(kvTb.opened)
	actDb.minLv = tonumber(kvTb.minLv)
	actDb.maxLv = tonumber(kvTb.maxLv)
	actDb.type = tonumber(kvTb.type)
	actDb.openDay = tonumber(kvTb.openDay)
	actDb.startTime = kvTb.startTime
	actDb.endTime = kvTb.endTime
	if kvTb.actId then
		Activity.setActivityDB(tonumber(kvTb.actId),actDb)
	end
	oResult.act = Activity.getActivityDB(tonumber(kvTb.actId))
	return Json.Encode(oResult)
end

function getActivity(kvTb)
	local act = Activity.getActivityDB(tonumber(kvTb.actId))
	oResult.act = act
	return Json.Encode(oResult)
end



-- 累计充值活动
function rechargeAct(kvTb)
	local begin = kvTb.begin
	local last = kvTb.last
	local endTime = kvTb.endTime
	RechargeLogic.update(tonumber(begin),tonumber(last),tonumber(endTime))
	return OprOKRet
end

-- 获取在线人数接口
function online(kvTb)
	if not checkSign(kvTb) then
		return SighFail
	end
	oResult.online = HumanManager.countOnline(true)
	oResult.top = 0
	oResult.low = 0
	return Json.Encode(oResult)
end

-- 当天实时注册人数接口
function getRegistNum(kvTb)
	local oResult = {code=1,message="ok"}
	if not checkSign(kvTb,kvTb.start_time,kvTb.end_time) then
		return SighFail
	end
	oResult.register = DayRegister
	return Json.Encode(oResult)
end

--请求玩家信息get_all_info
function getPlayer(kvTb)
	if not checkSign(kvTb,kvTb.server_id,kvTb.rolename,kvTb.uid) then
		return SighFail
	end
	local oResult = {code=1,message="ok"}
	local account = kvTb.account
	local name = kvTb.name
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	if human then
		local map = {
			name = "rolename",
			pAccount = "uid",
			createDate = "create_time",
			lastLogout = "last_online",
			ip = "last_login_ip",
			--sv = "server_id",
			lv = "level",
			recharge = "charged_rmb",
			vipLv = "vip_level",
			rmb = "charge_currency",
			--null = "binding_currency",
			money = "game_coin",
			--null = "binding_game_coin",
			isOnline = "online_status",
			--null = "guild_name",
			exp = "exp",
			--"pk_value",
			--"prestige",	--威望
			--"is_banned",
		}
		local baseInfo = {}
		for k,v in pairs(map) do
			baseInfo[v] = human.db[k]
		end
		--道具
		local bag = human:getBag()
		local items = {}
		local grid,item
		for i=1,#bag do
			grid = bag[i]
			item = {
				bag = "",
				props_id = grid.id,
				name = ItemConfig[grid.id].name,
				quality = "",
				count = grid.cnt,
				binded = 1,
				position = i,
				enhanced_level = 1,
				holes = 0,
				gem = 0,
				get_time = 0,
			}
			items[#items+1] = item
		end
		baseInfo.server_id = SvrId 
		baseInfo.binding_currency = 0 
		baseInfo.binding_game_coin = 0
		baseInfo.guild_name = GuildManager.getGuildNameByGuildId(human.db.guildId)
		baseInfo.is_banned = 0
		oResult.base = baseInfo
		oResult.pets = {}	--宠物
		oResult.props = items	--道具
		return Json.Encode(oResult)
	else
		return UserNotExist
	end
end

--查询玩家列表
--@todo 不支持模糊查询
function getPlayerList(kvTb)
	if not checkSign(kvTb,kvTb.server_id,kvTb.uid,kvTb.role_id,kvTb.role_name,kvTb.ip,kvTb.is_online) then
		return SighFail
	end
	local account = kvTb.account
	local name = kvTb.name	   --暂不支持模糊匹配
	local isOnline = tonumber(kvTb.is_online)
	local human = HumanManager.getOnline(account,name) 
	if not human and (isOnline == 2 or isOnline == 0) then
		human = HumanManager.loadOffline(account,name)
	end
	local oResult = {code=1,message="ok"}
	oResult.data = {}
	if human then
		local map = {
			name = "rolename",
			pAccount = "uid",
			account = "role_id",
			lv = "level",
			recharge = "total_charge",
			rmb = "gold",
			createDate = "create_time",
			lastLogin = "last_login_time",
			ip = "last_login_ip",
			isOnline = "is_online",
		}
		local baseInfo = {}
		for k,v in pairs(map) do
			baseInfo[v] = human.db[k]
		end
		baseInfo.total_charge = baseInfo.total_charge * 100 	--单位(分)
		baseInfo.server_id = SvrId 
		oResult.data[1] = baseInfo
		return Json.Encode(oResult)
	else
		return UserNotExist
	end
end

--查询定制玩家信息
function getPlayerInfo(kvTb)
	if not checkSign(kvTb,kvTb.server_id,kvTb.uid,kvTb.role_name) then
		return SighFail
	end
	local account = kvTb.account
	local name = kvTb.name	   
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	local oResult = {code=1,message="ok"}
	oResult.data = {}
	if human then
		local map = {
			name = "角色名",
			pAccount = "平台账号",
			account = "游戏账号",
			lv = "等级",
			recharge = "总充值",
			rmb = "剩余钻石",
			--createDate = "注册时间",
			--lastLogin = "最近登录时间",
			ip = "最近登录IP",
			isOnline = "是否在线(1在线)",
		}
		local baseInfo = {}
		for k,v in pairs(map) do
			baseInfo[v] = human.db[k]
		end
		baseInfo["注册时间"] = os.date("%Y-%m-%d %X",human.db.createDate)
		baseInfo["最近登录时间"] = os.date("%Y-%m-%d %X",human.db.lastLogin)
		oResult.data["基本信息"] = {baseInfo}
		--英雄信息
		heroInfo = {}
		local list = human:getAllHeroes()
		for _,h in pairs(list) do
			heroInfo[#heroInfo+1] = {
				["英雄名"] = HeroDefine.DefineConfig[h.db.name].cname,
				["等级"] = h:getLv(),
				["星级"] = h:getQuality(),
				["获得时间"] = os.date("%Y%m%d %X",h.db.ctime),
				["突破"] = h.db.btLv,
			}
		end
		oResult.data["英雄信息"] = heroInfo 
		return Json.Encode(oResult)
	else
		return UserNotExist
	end
end



--全服在线玩家信息
function getAllPlayer(kvTb)
	local list = {}
	local human
	for k,v in pairs(HumanManager.online) do
		human = {
			rolename = v:getName(),
			uid = v:getPAccount(),
			ip = v.db.ip,
			pAccount = v:getPAccount(),
			money = v:getMoney(),
			rmb = v:getRmb(),
			login = v:getLoginTime(),
		}
		list[#list+1] = human
	end
	oResult.data = list
	return Json.Encode(oResult)
end

--T人
function kick(kvTb)
	local account = kvTb.account
	local name = kvTb.name
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	if not human then 
		return UserNotExist
	end
	human:disconnect(CommonDefine.DISCONNECT_REASON_ADMIN_KICK)
	return OprOKRet
end

--T所有人
function kickAll(kvTb)
	for _,v in pairs(HumanManager.online) do
		v:disconnect(CommonDefine.DISCONNECT_REASON_ADMIN_KICK)
	end
	return OprOKRet
end

-- 增加钻石接口
function addRmb(kvTb)
	local account = kvTb.account
	local name = kvTb.name
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	local rmb = tonumber(kvTb.rmb)
	if human then
		human:incRmb(rmb,CommonDefine.RMB_TYPE.ADD_ADMIN)
		human:sendHumanInfo()
		return OprOKRet
	end
	return UserNotExist
end

--发公告
function addAnnounce(kvTb)
	if not checkSign(kvTb,kvTb.request_id,kvTb.operate,kvTb.message_type,kvTb.send_type,kvTb.start_time,kvTb.end_time,kvTb.interval_time,kvTb.content) then
		return SighFail
	end
	local stype = tonumber(kvTb.send_type)
	local atype 
	if stype == 1 then
		atype = AnnounceDefine.TYPE_ONCE
	elseif stype == 2 then
		atype = AnnounceDefine.TYPE_INTERVAL
	end
	local announce = {
		id = kvTb.request_id,
		pos = tonumber(kvTb.message_type),
		type = atype,
		startTime = kvTb.start_time,
		endTime = kvTb.end_time,
		interval = kvTb.interval_time,
		content = kvTb.content,
	}
	Announce.addAnnouceFromAdmin(announce)
	return OprOKRet
end

function delAnnounce(kvTb)
	if not checkSign(kvTb,kvTb.request_id) then
		return SighFail
	end
	Announce.delAnnounceFromAdmin(kvTb.request_id)
	return OprOKRet
end

function getGuildInfo(kvTb)
	local page = tonumber(kvTb.page) or 1
	local pageSize = tonumber(kvTb.page_size) or 99
	local serverId = kvTb.server_id
	local name = kvTb.name
	local list = {}
	if not name or name == "" then
		local j = 1
		for i = (page - 1) * pageSize + 1,#GuildManager.GuildList do
			local v = GuildManager.GuildList[i]
			local _,leader = v:getLeader()
			local guild = {
				id = k,
				name = v:getName(),
				create_date = v:getCreateDate(),
				leader_name = leader.name,
				--power = ,
				member = v:getMemCount(),
				--capacity = ,
				--warehouse = ,
				--coin = ,
				--flag_name = ,
				level = v:getLv(),
				--allinace = ,
				--status = ,
			}
			list[#list+1] = guild 
			j = j + 1
			if j > pageSize then
				break
			end
		end
	else
		for k,v in pairs(GuildManager.IdList) do
			local guildName = v:getName()
			print("======>",guildName,name)
			if string.find(guildName,name) then
				local _,leader = v:getLeader()
				local guild = {
					id = k,
					name = v:getName(),
					create_date = v:getCreateDate(),
					leader_name = leader.name,
					--power = ,
					member = v:getMemCount(),
					--capacity = ,
					--warehouse = ,
					--coin = ,
					--flag_name = ,
					level = v:getLv(),
					--allinace = ,
					--status = ,
				}
				list[#list+1] = guild 
				break
			end
		end
	end
	local oResult = {code=1,message="ok",count = #list}
	oResult.data = list
	return Json.Encode(oResult)
end

function getGuildMemberInfo(kvTb)
	local guildId = tonumber(kvTb.guild_id) or 0
	local serverId = kvTb.server_id
	local guild = GuildManager.IdList[guildId]
	if not guild then
		return Json.Encode({code = 2,message = "guild not exist"})
	end
	local list = {}
	local member 
	for k,v in pairs(guild:getMemberList()) do
		member = {
			role_id = v.id,
			rolename = v.name,
			uid = v.pAccount,
			--server_id = ,
			--charge_currency = ,
			level = v.lv,
			--career = ,
			--gender = ,
			position = GuildManager.getPosName(v.pos),
			--contribute = ,
			--exploit = ,
			date = v.createDate,
		}
		list[#list+1] = member
	end
	local oResult = {code=1,message="ok",count = #list}
	oResult.data = list
	return Json.Encode(oResult)
end

function destroyGuild(kvTb)
	local guildId = tonumber(kvTb.guild_id) or 0
	local guild = GuildManager.IdList[guildId]
	if not guild then
		return Json.Encode({code = 2,message = "guild not exist"})
	end
	GuildManager.IdList[guild:getId()] = nil
	GuildManager.NameList[guild:getName()] = nil
	for k,v in pairs(GuildManager.GuildList) do
		if v:getId() == guild:getId() then
			table.remove(GuildManager.GuildList,k)
			break
		end
	end
	GuildManager.reSortGuildByActive()
	GuildManager.reSortGuildByFightVal()
	guild:destroy(true)
	local oResult = {code=1,message="ok"}
	return Json.Encode(oResult)
end

local function doForbid(kvTb,isChat)
	if not checkSign(kvTb,kvTb.server_id,kvTb.type,kvTb.accounts,kvTb.ban_time,kvTb.ban_reason) then
		return SighFail
	end
	local toTime = os.time() + tonumber(kvTb.ban_time) * 60
	local accountTb = Util.Split(kvTb.accounts,",")
	for _,accountOrName in pairs(accountTb) do
		print("=========>",accountOrName)
		local human
		if tonumber(kvTb.type) == 1 then
			--禁账号
			human = HumanManager.getOnline(accountOrName) or HumanManager.loadOffline(accountOrName)
		else
			human = HumanManager.getOnline(nil,accountOrName) or HumanManager.loadOffline(nil,accountOrName)
		end
		if human then
			if isChat then
				ForbidManager.addChat(human:getAccount(), toTime)
			else
				ForbidManager.addAccount(human:getAccount(), toTime)
				if human.fd then
					human:disconnect(CommonDefine.DISCONNECT_REASON_ADMIN_KICK)
				end
			end
		end
	end
	return OprOKRet
end

--禁止登陆
function addForbid(kvTb)
	return doForbid(kvTb,false)
end

--禁言
function addForbidChat(kvTb)
	return doForbid(kvTb,true)
end

local function doDelForbid(kvTb,isChat)
	if not checkSign(kvTb,kvTb.server_id,kvTb.type,kvTb.accounts,kvTb.unban_reason) then
		return SighFail
	end
	local accountTb = Util.Split(kvTb.accounts,",")
	for _,accountOrName in pairs(accountTb) do
		print("=========>",accountOrName)
		local human
		if tonumber(kvTb.type) == 1 then
			--禁账号
			human = HumanManager.getOnline(accountOrName) or HumanManager.loadOffline(accountOrName)
		else
			human = HumanManager.getOnline(nil,accountOrName) or HumanManager.loadOffline(nil,accountOrName)
		end
		if human then
			if isChat then
				ForbidManager.delChat(human:getAccount())
			else
				ForbidManager.delAccount(human:getAccount())
			end
		end
	end
	return OprOKRet
end

--解除账号封禁
function delForbid(kvTb)
	return doDelForbid(kvTb,false)
end

--解除禁言
function delForbidChat(kvTb)
	return doDelForbid(kvTb,true)
end


function addForbidAccount(kvTb)
	local keepTime = tonumber(kvTb.keepTime)
	ForbidManager.addAccount(kvTb.account, os.time() + keepTime)
	return OprOKRet
end

function delForbidAccount(kvTb)
	ForbidManager.delAccount(kvTb.account)
	return OprOKRet
end

function addForbidName(kvTb)
	local keepTime = tonumber(kvTb.keepTime)
	ForbidManager.addName(kvTb.name, os.time() + keepTime)
	return OprOKRet
end

function delForbidName(kvTb)
	ForbidManager.delName(kvTb.name)
	return OprOKRet
end

function addForbidIP(kvTb)
	local ip = kvTb.ip
	local keepTime = tonumber(kvTb.keepTime)
	ForbidManager.addIP(ip, os.time() + keepTime)
	return OprOKRet
end

function delForbidIP(kvTb)
	local ip = kvTb.ip
	ForbidManager.delIP(ip)
	return OprOKRet
end

--删除物品
function deleteItem(kvTb)
	if not checkSign(kvTb,kvTb.type,kvTb.guid,kvTb.rolename) then
		return SighFail
	end
	local name = kvTb.name
	local human = HumanManager.getOnline(nil,name) or HumanManager.loadOffline(nil,name)
	if  not human then
		return UserNotExist
	end
	local itemId = tonumber(kvTb.guid)
	local itemNum = BagLogic.getItemNum(human,itemId)
	BagLogic.delItemByItemId(human,itemId,itemNum,true,CommonDefine.ITEM_TYPE.DEC_ADMIN)
	return OprOKRet
end

function getAllItem(kvTb)
	if not checkSign(kvTb) then
		return SighFail
	end
	local list = {}
	for itemId,v in pairs(ItemConfig) do
		list[#list+1] = {
			id = itemId,
			name = v.name,
			currency_type = 0,	--0其它，1元宝，2绑定元宝，3金币，4绑定金币，5积分，6道具兑换，7荣誉
			currency = 0,	--价格
			nature = 1,  --1一次性，2永久，3期限
		}
	end
	oResult.data = list
	return Json.Encode(oResult)
end

function sendOfflineMessage(kvTb)
	local cond = {}
	local name = kvTb.rolename or ""
	local human = HumanManager.getOnline(nil,name) or HumanManager.loadOffline(nil,name)
	if not human then
		return Json.Encode{code=2,message="no such player"}
	end
	cond.toName = {}
	cond.toName[name] = true
	local title = "系统通知"
	local content = kvTb.content

	local mailBox = MailManager.getSysMailBox()
	if not mailBox then
		return UserNotExist
	end
	local mail = {}
	mail.mtype = MailDefine.MAIL_TYPE_GM
	mail.sender = MailDefine.SYS_MAIL_NAME
	mail.title = title
	mail.content = content
	mail.attach = {}
	if kvTb.props ~= nil then
		local props = Json.Decode(kvTb.props)
		for k,v in pairs(props)do
			table.insert(mail.attach,{v.id,v.count})
		end
	end
	mail.cond = cond
	if not mailBox:addMail(mail) then
		return Json.Encode{code=2,message="addMail fail"}
	else
		return Json.Encode{code=1,message="ok"}
	end
end

function sendMail(kvTb)
	local requestId = kvTb.request_id
	local action = tonumber(kvTb.action)
	local uids = kvTb.uids
	local rolenames = kvTb.rolenames
	local cond = {}
	if action == 0 then
		cond = nil
	elseif action == 1 then
		cond.toUId = {}
		if kvTb.uids == nil or kvTb.uids == "" then
		else
			local uidTb = Util.Split(kvTb.uids,",")
			for _,uid in pairs(uidTb) do
				cond.toUId[uid] = true
			end
		end
		if not next(cond.toUId) then
			local nameTb = Util.Split(kvTb.rolenames,",")
			cond.toName = {}
			for _,name in pairs(nameTb) do
				cond.toName[name] = true
			end
		end
	elseif action == 2 then
		local minVipLevel = tonumber(kvTb.min_vip_level)
		local maxVipLevel = tonumber(kvTb.max_vip_level)
		local minLevel = tonumber(kvTb.min_level)
		local maxLevel = tonumber(kvTb.max_level)
		local minRegisterTime = tonumber(kvTb.min_register_time)
		local maxRegisterTime = tonumber(kvTb.max_register_time)
		local minLoginTime = tonumber(kvTb.min_login_time)
		local maxLoginTime = tonumber(kvTb.max_login_time)
		local online = tonumber(kvTb.online)
		if minVipLevel > 0 then
			cond.minVipLevel = minVipLevel
		end
		if maxVipLevel > 0 then
			cond.maxVipLevel = maxVipLevel
		end
		if minLevel > 0 then
			cond.minLevel = minLevel
		end
		if maxLevel > 0 then
			cond.maxLevel = maxLevel
		end
		if minRegisterTime > 0 then
			cond.minRegisterTime = minRegisterTime
		end
		if maxRegisterTime > 0 then
			cond.maxRegisterTime = maxRegisterTime
		end
		if minLoginTime > 0 then
			cond.minLoginTime = minLoginTime
		end
		if maxLoginTime > 0 then
			cond.maxLoginTime = maxLoginTime
		end
		if online > 0 then
			cond.online = online
		end
	end
	local title = kvTb.title
	local content = kvTb.content

	local mailBox = MailManager.getSysMailBox()
	if not mailBox then
		return UserNotExist
	end
	local mail = {}
	mail.mtype = MailDefine.MAIL_TYPE_GM
	mail.sender = MailDefine.SYS_MAIL_NAME
	mail.title = title
	mail.content = content
	mail.attach = {}
	if kvTb.props ~= nil then
		local props = Json.Decode(kvTb.props)
		for k,v in pairs(props)do
			table.insert(mail.attach,{tonumber(v.id),tonumber(v.count)})
		end
	end
	mail.cond = cond
	if not mailBox:addMail(mail) then
		return Json.Encode({code=2,message="addMail fail"})
	else
		return Json.Encode({code=1,message="ok"})
	end
	--local gender = kvTb.gender
	--local propBinding = kvTb.prop_binding
	--local chargeCurrency = kvTb.charge_currency
	--local bindingCurrency = kvTb.binding_currency
	--local gameCoin = kvTb.game_coin
	--local bindingGameCoin = kvTb.binding_game_coin
	--local exp = kvTb.exp
	--local ts = kvTb.ts
end

function searchAccount(kvTb)
	if not checkSign(kvTb,kvTb.server_id,kvTb.role_id,kvTb.rolename,kvTb.uid,kvTb.fuzzy_search) then
		return SighFail
	end
	local oResult = {code=1,message="ok"}
	local account = kvTb.account
	local name = kvTb.name
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	if not human then
		return UserNotExist
	end
	local data = {}
	local user = {}
	user.id = human:getAccount()
	user.uid = human:getPAccount()
	user.rolename = human:getName()
	user.server_id = SvrId 
	data[#data+1] = user
	oResult.data = data
	return Json.Encode(oResult)
end

local KeyTable = {}
function getHumanData(kvTb)
	local human = OnlineHumanManager[kvTb.roleName]
	if not human then 
		return "{\"result\":4,\"errorMsg\":\"roleName is null \"}"
	end

	KeyTable = {} 
	for k,v in pairs (kvTb) do
		KeyTable[k] = 1
	end

	for k,v in pairs (KeyTable) do
		print(k .. "   " ..v)
	end
	local result = getFields(KeyTable,human.m_db)
	return Json.Encode(getFields(KeyTable,human.m_db))

end

function setHumanData(kvTb)
	local human = OnlineHumanManager[kvTb.roleName]

	if not human then
		return "{\"result\":4,\"errorMsg\":\"roleName is null \"}"
	end
	kvTb.roleName = nil

	setFields(kvTb,human.m_db)

end

--获取字段值
local value = {}
function getFields(Keytable,objTable,flag)
	if not KeyTable  or not objTable then
		print("keyTable or objTable is nil")
		return
	end
	if not flag then
		value = {}
	end
	for k,v in pairs(objTable) do
		if v and type(v) == "table" then
			local temTb = getFields(Keytable,v,true)
			for i,j in pairs(temTb) do
				value[i] = j
			end
		else
			for m,n in pairs(KeyTable) do
				if k == m then
					value[k]= v
				end
			end
		end
	end
	return value
end

--设置字段值
function setFields(keyTable,objTable)
	for k,v in pairs(objTable) do
		if v and type(v) == "table" then
			setFields(KeyTable,v)
		else
			for m,n in pairs(KeyTable) do
				if k == m then
					objTable[v] = n
				end
			end
		end
	end
end

--后台向游戏中发协议，牛逼的接口，请慎用！
function sendCGProtocol(kvTb)

	local human  = OnlineHumanManager[kvTb.roleName]
	local result = {}
	if not human then
		result.result = 4
		result.errorMsg = "roleName is nil"
		return Json.Encode(result)
	end


	local sMsg = {} 
	local protoId = PacketID[kvTb.proto]
	local msg = Dispatcher.ProtoContainer[tonumber(protoId)]
	print("调用协议：",kvTb.proto , ",protoId" , protoId)
	local kType,kLen
	--  if #msg > 0 then
	for k,v in pairs(msg) do
		kType,kLen = "",""
		for m,n in pairs (v) do
			kType = m .. "type"
			kLen = m .. "Len"
			if kvTb[m] then
				if kvTb[kType] or #kvTb[m] == 1 then
					sMsg[m] = tonumber(kvTb[m])
				else
					sMsg[m] = {}
					sMsg[m],sMsg[kLen] = Util.mkStr2Ascii(kvTb[m]) --转化为协议中的字符串存储模式
				end
			end
		end
	end
	--end
	local fun = Dispatcher.ProtoHandler[protoId]

	local ret = fun(human,sMsg)
	if ret then 
		result.result = 1
		result.errorMsg = "return true"
	else
		result.result = 0
		result.errorMsg = "return false"
	end
	return Json.Encode(result)

end


--获取帮会数据
function getGuildData(kvTb)
	local result = {}
	local guild  = GuildManager:FindGuildByName(kvTb.guildName)
	if not guild then 
		result.result = 0
		result.errorMsg = " no such guild !"
		return Json.Encode(result)
	end

	return Json.Encode(guild)
end


--设置帮会数据
function setGuildData(kvTb)
	local result = {} 
	local guild =  GuildManager:FindGuildByName(kvTb.guildName) 
	if not guild then
		result.result = 0
		result.errorMsg = "no such guild !"
		return Json.Encode(result)
	end

	if table_replace(guild,kvTb.guild) then
		return getGuildData(kvTb)
	else
		result.result = -1 
		result.msg = "set guild data error!"
		return Json.Encode(result)
	end

end

function getBagData(kvTb)
	local result = {}
	local human = OnlineHumanManager[kvTb.roleName]
	if not human then
		result.result = 0
		result.msg = "human is nil !"
		return Json.Encode(result)
	end

	return Json.Encode(human.bag)

end

function setBagData(kvTb)
	local result = {}
	local human = OnlineHumanManager[kvTb.roleName]
	if not human then
		result.result = 0
		result.errorMsg = "human is nil"
		return Json.Encode(result)
	end
	if table_replace(human.bag,kvTb.bag) then
		getBagData(kvTb)
	else
		result.result = -1
		result.msg = "set bag data error !"
		return Json.Encode(result)
	end
end

function test(kvTb)
	print("测试后台接口数据！")
	Util.PrintTable(kvTb)
	return Json.Encode(kvTb)
end

--该方法用于将srcTb中的字段覆盖dstTb中相对应的字段
function table_replace(dstTb,srcTb)
	if not dstTb or not srcTb then  
		return false
	end
	for k,v in pairs(srcTb) do 
		if type(v) == "table" and dstTb[k] ~= nil then
			table_replace(dstTb[k],v)
		else
			if dstTb[k] then
				dstTb[k] = v
			end
		end
	end
	return true
end


--获取dst表中的指定字段，tplTb为需要获取的字段模板，结构深度和dst一致
local tempTb = {} 
function table_search(dstTb,tplTb,flag)
	if not flag then
		tempTb = {}
	end
	for k,v in pairs(tplTb) do
		if type(v) == "table" and dstTb[k] ~= nil then  
			table_search(dstTb[k],v,true)
		else
			tempTb[k] = dstTb[k]
		end
	end     
	return tempTb
end


function addVIP(kvTb)
	local result = {}
	local account = kvTb.account
	local name = kvTb.name
	local human = HumanManager.getOnline(account,name) or HumanManager.loadOffline(account,name)
	local vipLv = tonumber(kvTb.vipLv)
	if not human then
		result.result = -1
		result.msg = "roleName is nil!"
		return Json.Encode(result)
	end
	if vipLv < 1 or  vipLv > VipDefine.VIP_MAX_LV then
		result.result = -1
		result.msg = "vipLv error!"
		return Json.Encode(result)
	end
	VipLogic.adminSetVipLv(human,vipLv)
	result.result = 1
	result.msg = "add vip ok!"
	return Json.Encode(result)
end

function getHumanDateByTb(data)
	local human = OnlineHumanManager[data.roleName] 
	local msg = {}
	if not human then
		msg.result = -1
		msg.msg = "human is nil!"
		return Json.Encode(msg)
	end



end

function getInlineTbByKey(tb,key)
	if not tb or type(tb) ~= "table" then
		return false
	end
	for k,v in pairs(tb) do
		if type(v) == "table" then
			if k ~= key then
				getInlineTbByKey(v,key)
			else
				return v
			end
		end
	end
	return false 
end


------------------------------------------------------------------------------------
-- 管理后台相关函数 end
------------------------------------------------------------------------------------
