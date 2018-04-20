module(..., package.seeall)
local CharDB = require("modules.character.CharDB")
local Character = require("modules.character.Character")
local CharacterDefine = require("modules.character.CharacterDefine")
local ObjectManager = require("core.managers.ObjectManager")
local HumanManager = require("core.managers.HumanManager")
local CommonDefine = require("core.base.CommonDefine")
local PacketID = require("PacketID")
local Util = require("core.utils.Util")
local Msg = require("core.net.Msg")
local Timer = require("core.base.Timer")
local ObjHuman = require("modules.character.ObjHuman")
local SensitiveFilter = require("modules.public.SensitiveFilter")
local GuildManager = require("modules.guild.GuildManager")
local NameAdj = require("config.NameAdjConfig").Config
local NameFull = require("config.NameFullConfig").Config
local PushConfig = require("config.PushConfig").Config
local ExpConfig = require("config.ExpConfig").Config
local BodyConfig = require("config.BodyConfig").Config
local Json = require("core.utils.Json")
local ForbidManager = require("modules.admin.ForbidManager")
local AdminLogic = require("modules.admin.AdminLogic")
local Sha1 = require("core.utils.SHA1")
local BagLogic = require("modules.bag.BagLogic")
local BagDefine = require("modules.bag.BagDefine")
local ChannelConfig = require("config.ChannelConfig").Config

local LogId = require("config.LogStandard").LogId

function onCGAskLogin(fd, sn, svrName, pAccount, channelId ,authKey, timestamp,deviceId)
	print("recv a CGAskLogin msg, pAccount="..pAccount, "==fd==>>",fd)
	local logTb = Log.getLogTb(LogId.LOGIN)
	logTb.channelId = channelId
	logTb.kickOld = 0

	local ret = checkAuth(fd,svrName,pAccount,channelId,authKey,timestamp)
	if ret ~= CommonDefine.OK then
		Character.sendGCDisconnect(fd,ret)
		return true
	end

	local totalOnline = HumanManager.countOnline()
	if totalOnline > 4000 then
		Character.sendGCDisconnect(fd)
		LogErr("fatal", "exceed max online count limit " .. totalOnline)
		return true
	end

	account = string.format("%s[%d]%s",svrName,channelId,pAccount)
	deviceId = deviceId or ""

	local offman = HumanManager.getOffline(account)
	if offman then 
		offman:saveAll()
		HumanManager.delOffline(offman.account)
	end

	local oldHuman = HumanManager.getOnline(account)
	if oldHuman then 
		HumanManager.delOnline(account)
		if not oldHuman.fd or oldHuman.fd == fd then	
			--重登陆,断线重连
			--如果是同一个fd的2次login
			oldHuman:release()
		else
			-- 帐号已经登录了 原连接下线
			oldHuman:disconnect(CommonDefine.DISCONNECT_REASON_ANOTHER_CHAR_LOGIN)
			oldHuman:release()
			--后台日志
			logTb.kickOld = 1
		end
	end

	oldHuman = ObjectManager.getByFD(fd) --不断线切换帐号游戏的情况
	if oldHuman then
		oldHuman:release()
	end

	-- 加载角色信息
	local human = ObjHuman.new(fd, sn)

	print("human:load")
	local ret = human:load(account)
	if not HumanManager.getOnline(account) then
		if not ret then
			--新玩家
			human:setChannelId(channelId)
			human:setAccount(account)
			human:setSvrName(svrName)
			human:setName(getNewName())
			human.db.pAccount = pAccount
			HumanManager.addOnline(account,human)
			human:addUser()
			logTb.isNew = 1
			HumanManager:dispatchEvent(HumanManager.Event_HumanCreate,human)
			--创角日志
			AdminLogic.incDayRegister()
			local newerTb = Log.getLogTb(LogId.NEWER)
			newerTb.channelId = human:getChannelId()
			newerTb.account = account 
			newerTb.name = human:getName()
			newerTb.pAccount = pAccount 
			newerTb:save()
		else
			HumanManager.addOnline(account,human)
			logTb.isNew = 0
		end
		human.db.deviceId = deviceId
		--记录后台日志
		logTb.deviceId = deviceId 
		logTb.account = human:getAccount()
		logTb.name = human:getName()
		logTb.pAccount = human:getPAccount()
		logTb.ip = _GetIP(human.fd)
		logTb.level = human:getLv()
		if not ForbidManager.loginForbid(human) then
			logTb.status = 0
			doHumanLogin(human, logTb)
		else
			logTb.status = 1 
		end
		logTb:save()
	end
end

function doHumanLogin(human, logTb)
	--attr
	if  os.date("%d") ~= os.date("%d",human:getLoginTime()) then  --更新今天在线
		human.db.olDayTime = 0
	end
	human.db.lastLogin = os.time()
	human.db.lastDate = os.date("%Y%m%d",human.db.lastLogin)
	human.db.ip = _GetIP(human.fd)
	human:setToken(Util.getToken(human:getAccount(),human:getSvrName()))
	if logTb.isNew ~= 1 then
		--add physics
		human:addOfflinePhysics()
	end
	human:checkPhysics()
	human:sendSettings()	
	human:sendHumanInfo()
	HumanManager:dispatchEvent(HumanManager.Event_HumanLogin, human)
	human:sendHumanInfo()
	--manager
	GuildManager.onLogin(human)
	--msg send
	Character.sendGCAskLogin(human,CommonDefine.OK,logTb.isNew)

	--玩家定时存库计时器
	local timer = Timer.new(CharacterDefine.TIMER_SAVE_CHAR_DB,-1)
	timer:setRunner(onSaveCharDB,human)
	timer:start()
	human:addTimer(timer)
	return true
end

function onCGReLogin(fd, sn, svrName, account, channelId ,authKey, token ,timestamp )
	local oldHuman = HumanManager.getOnline(svrName .. account)
	local ret = CommonDefine.OK 
	if oldHuman then 
		ret = checkAuth(fd,svrName,account,channelId,authKey,timestamp,token)
		if oldHuman.token ~= token or (os.time() - oldHuman:getLoginTime()) > 3600 * 8 then
			ret = CharacterDefine.RET_TOKEN_ERR
		end
		if ret == CommonDefine.OK then
			--断线
			if oldHuman.fd == fd then
				Msg.SendMsg(PacketID.GC_RE_LOGIN,oldHuman)
			else
				if oldHuman.fd then
                    print("old human fd===",oldHuman.fd,fd)
		            Character.sendGCDisconnect(oldHuman.fd)
                    ObjectManager.removeFd(oldHuman)
				end
                oldHuman:stopReloginTimer()	
                ObjectManager.addByFd(fd,oldHuman)
                Msg.SendMsg(PacketID.GC_RE_LOGIN,oldHuman)
			end
		end
	else
		ret = CharacterDefine.RET_TOKEN_OFFLINE
	end
	if ret ~= CommonDefine.OK then
		--释放fd
        print("disconnect==>",ret)
		Character.sendGCDisconnect(fd)
	end
	--@todo log
	return true
end

function checkAuth(fd,svrName,account,channelId,authKey,timestamp,token)
	if not Config.ISTESTCLIENT then
		local urlEcodeAccount = Util.url_encode(account)
		token = token or ""
		local flag =  svrName .. urlEcodeAccount .. channelId .. timestamp .. token .. Config.key
		--时间差验证
		if os.time() - timestamp > 3600*8 then --8小时时间戳失效
			LogErr( "warn",
			string.format("Authenticate expired,svrName:%s,account:%s, ts:%s, channelId:%d, authKey:%s",
			svrName, account, timestamp, channelId,authKey));
			return CharacterDefine.ASK_LOGIN_TIMEOUT
		end

		local key =  _md5(flag) 
		if authKey ~= key then --md5验证失败 
			LogErr("warn", 
			string.format("Authenticate fail,svrName:%s,account:%s, ts:%s, channelId:%d, authkey:%s, key:%s",
			svrName, account, timestamp, channelId, authKey, key));
			return CharacterDefine.ASK_LOGIN_FAIL
		end

		if not Util.IsValidServerName(svrName) then
			LogErr("warn", string.format("Authenticate svrName fail,account:%s, svrName:%s",
			account, svrName));
			return CharacterDefine.ASK_LOGIN_FAIL 
		end

	end
	return CommonDefine.OK
end


function onCGDisconnect(human,reason)
	print("onCGDisconnectNotify reason="..reason)
	human:onDisconnect(reason);
	return true
end

function onCGRename(human,name)
	if human.db.renameCnt >= 1 and human:getRmb() < CharacterDefine.RENAME_RMB then
		return Msg.SendMsg(PacketID.GC_RENAME,human,CharacterDefine.RET_NAME_NORMB,human:getName())
	end
	local ret = CommonDefine.OK
	if not checkRolename(name) or SensitiveFilter.hasSensitiveWord(name) then
		ret = CharacterDefine.RET_NAME_INVALID
		return Msg.SendMsg(PacketID.GC_RENAME,human,ret,human:getName())
	end
	if HumanManager.onlineName[name] or CharDB.isNameExistInDB(name) then
		ret = CharacterDefine.RET_NAME_EXIST
		return Msg.SendMsg(PacketID.GC_RENAME,human,ret,human:getName())
	end
	if human:getName():len() > 0 then
		HumanManager.delOnlineByName(human:getName())
	end
	local logTb = Log.getLogTb(LogId.RE_NAME)
	logTb.channelId = human:getChannelId()
	logTb.name = human:getName()
	logTb.rmb = 0
	human:setName(name)
	if human.db.renameCnt > 0 then
		human:decRmb(CharacterDefine.RENAME_RMB,"",CommonDefine.RMB_TYPE.DEC_RENAME)
		logTb.rmb = CharacterDefine.RENAME_RMB
	end
	human.db.renameCnt = human.db.renameCnt + 1
	human:sendHumanInfo()
	HumanManager.addOnlineByName(name,human)

	logTb.account = human:getAccount()
	logTb.pAccount = human:getPAccount()
	logTb.newName = human:getName() 
	logTb.money = 0
	logTb:save()
	return Msg.SendMsg(PacketID.GC_RENAME,human,ret,human:getName())
end

function getNewName()
	local name = ""
	local randName = function()
		local n1 = NameAdj[math.random(1,#NameAdj)].name
		local n2 = NameFull[math.random(1,#NameFull)].name
		name = n1 .. n2
		if CharDB.isNameExistInDB(name) or HumanManager.onlineName[name] then
			return false
		else
			return true
		end
	end
	for i=1,3 do
		if randName() then
			print("randName====>",name)
			break
		end
	end
	return name
end

function onSaveCharDB(human)
	print("onSaveCharDB>>>>",human:getAccount())
	human:save()
end

function checkRolename(newName)
    local nameLen = #newName
    if nameLen < 2 or nameLen > 24 then
    	LogErr("warn", string.format("invalid rolename len, rolename %s", newName))
    	return false
    end
    
    local i, j = string.find(newName, "%[")
    if i ~= nil then
    	LogErr("warn", "rolename with invalid char %[")
    	return false
    end
    
    i, j = string.find(newName, "]")
    if i ~= nil then
    	LogErr("warn", "rolename with invalid char ]")
    	return false
    end
    
    for tmpStr in string.gmatch(newName, "([%z\1-\127\194-\244][\128-\191]*)") do
        if string.len(tmpStr) == 1 then
            local byteVal = string.byte(tmpStr)
            if  byteVal < 33 or byteVal == 127 then
                LogErr("warn", "rolename with invalid character")
                return false
            end
        end
    end
    return true
end

function onCGChangeBody(human,bodyId)
	local conf = BodyConfig[bodyId]
	if not conf then
		return true
	end
    local hero = human:getHero(conf.hero)
	if not hero then
		return true
	end
	human.db.bodyId = bodyId
	return Msg.SendMsg(PacketID.GC_CHANGE_BODY,human,CommonDefine.OK,bodyId)
end

function onCGSettings(human,music,effect,pushSettings)
	local settings = human.db.settings
	if music ~= 1 then
		music = 0
	end
	if effect ~= 1 then
		effect = 0
	end
	settings.music = music
	settings.effect = effect
	if Util.GetTbNum(PushConfig) < #pushSettings then
		return true
	end
	settings.pushSettings = pushSettings
	--Util.PrintTable(settings)
	--return Msg.SendMsg(PacketID.GC_SETTINGS,human)
end

--AuthFdList = AuthFdList or {}
function onGGHttp3rdLoginAuth(fd,sn,msg)
--[[
	print("http response=====>",fd,sn,msg)
	msg = msg or ""
	local sign = AuthFdList[fd]
	if sign and msg == "true" then
		local authKey = _md5(sign .. Config.key)
		print("CGLoginAuth===========>",authKey)
		Msg.SendMsgByFD(PacketID.GC_LOGIN_AUTH,fd,authKey)
	else
		Msg.SendMsgByFD(PacketID.GC_KICK,fd,CommonDefine.DISCONNECT_REASON_3RD_AUTH_FAIL)
		LogErr( "warn",
		string.format("checklogin fail,fd:%d,msg:%s,sign:%s",fd,msg,sign))
	end
	AuthFdList[fd] = nil
--]]
end

function onCGLoginAuth(fd,sn,sign,sdkInfo)
	print("CGLoginAuth=======>",fd,sign,sdkInfo)
	if Config.OPEN_SDK_AUTH then
		sdkInfo = Json.Decode(sdkInfo)
		if not sdkInfo or (not sdkInfo.channelId or not sdkInfo.channelUserId or not sdkInfo.ts) then
			LogErr( "warn",
			string.format("loginAuth params wrong,fd:%d,msg:%s",fd,msg))
			return Msg.SendMsgByFD(PacketID.GC_KICK,fd,CommonDefine.DISCONNECT_REASON_3RD_AUTH_FAIL)
		end
		local flag = sdkInfo.channelId .. sdkInfo.channelUserId .. sdkInfo.ts
		if (os.time() - sdkInfo.ts ) > (3600*8) then	--8小时token过期
			LogErr( "warn",
			string.format("loginAuth expired,fd:%d,msg:%s,flag:%s",fd,msg,flag))
			return Msg.SendMsgByFD(PacketID.GC_KICK,fd,CommonDefine.DISCONNECT_REASON_3RD_AUTH_FAIL)
		end
		local key =  _md5(flag .. Config.SDK_AUTH_KEY) 
		if key ~= sdkInfo.token then
			LogErr( "warn",
			string.format("loginAuth fail,fd:%d,msg:%s,flag:%s",fd,msg,flag))
			return Msg.SendMsgByFD(PacketID.GC_KICK,fd,CommonDefine.DISCONNECT_REASON_3RD_AUTH_FAIL)
		end
	end
	local authKey = _md5(sign .. Config.key)
	print("CGLoginAuth OK==>")
	return Msg.SendMsgByFD(PacketID.GC_LOGIN_AUTH,fd,authKey)
	--[[
	--@Todo 暂不使用服务端验证
	local authUrl = Config.SDK_AUTH_URL
	if not Config.OPEN_SDK_AUTH then
		authUrl = string.format("http://127.0.0.1:%d/admin?q=auth",Config.GAME_HTTP_LISTEN_PORT)
	end
	local param = string.format("userId=%s&token=%s&channel=%s&productCode=%s",sdkInfo.userId,sdkInfo.token,sdkInfo.channelId,sdkInfo.productCode)
	local checkUrl = string.format("%s?%s",authUrl,param)
	Msg.sendHttpRequest(PacketID.GG_HTTP_3RD_LOGIN_AUTH,fd,checkUrl)
	AuthFdList[fd] = sign
	--]]
end

--兑换礼品 
local giftChannelName = {
	sn97="ksmobile",
	jj97="ksmobile",
	rx97="ksmobile",	--热血97
	snkd="ksmobile",	--少年快打
}
function onCGGiftCode(human,code,svrId)
	if not Util.IsValidServerName("[" .. svrId .. "]") then
		return Msg.SendMsg(PacketID.GC_GIFT_CODE,human,CharacterDefine.RET_GIFT_FAIL,"参数无效")
	end
	local giftUrl = "http://active-code.gop.yy.com/api/activeCode.do"
	--local giftUrl = "http://172.16.64.197/api/activeCode.do"
	local channelId = human:getChannelId() 
	local conf = ChannelConfig[channelId]
	assert(conf,"lost channel conf==>" .. channelId)
	local channelName = conf.channelName
	channelName = giftChannelName[channelName] or conf.channelName
	local game = "qhqz"
	local role_id = human:getAccount()
	local time = os.time()
	local sign = Sha1.hmac(Config.ADMIN_KEY,game .. channelName .. svrId .. role_id .. code .. time)
	local param = string.format("game=%s&platform=%s&server_id=%s&role_id=%s&code=%s&ts=%d&sign=%s",
					game,channelName,Util.url_encode(svrId),Util.url_encode(role_id),code,time,sign)
	print("=======>",param)
	Msg.sendHttpRequest(PacketID.GG_HTTP_GIFT_CODE_ACTIVE,human.fd,giftUrl .. "?" .. param)
	--onGGHttpGiftCodeActive(human.fd,sn,Json.Encode({code=2,message="ok",gift_desc={{prop_id=1101001,prop_num=1}}}))
end

--礼品返回
function onGGHttpGiftCodeActive(fd,sn,msg)
	print("========>",msg)
	msg = Json.Decode(msg)
	if not msg and (not msg.code or not msg.message or not msg.gift_desc) then
		return Msg.SendMsgByFD(PacketID.GC_GIFT_CODE,fd,CharacterDefine.RET_GIFT_FAIL,"领取失败")
	end
	if msg.code == 1  then
		local human = ObjectManager.getByFD(fd) 
		local rewards = {}
		msg.gift_desc = Json.Decode(msg.gift_desc)
		for _,v in pairs(msg.gift_desc) do
			local itemId = tonumber(v.prop_id)
			local num = tonumber(v.prop_num)
			if BagLogic.addItem(human,itemId,num,false,CommonDefine.ITEM_TYPE.ADD_GIFT_CODE) then
				rewards[#rewards+1] = {
					titleId = BagDefine.REWARD_TIPS.kGetGift,
					id = itemId,
					num = num,
				}
			end
		end
		Msg.SendMsgByFD(PacketID.GC_GIFT_CODE,fd,CommonDefine.OK,"领取成功")
		BagLogic.sendBagList(human)
		BagLogic.sendRewardTips(human,rewards)
		return true
	else
		local errmsg = string.format("兑换失败，错误:[%s]",msg.message)
		return Msg.SendMsgByFD(PacketID.GC_GIFT_CODE,fd,CharacterDefine.RET_GIFT_FAIL,errmsg)
	end
end

--上报充值日志返回
function onGGHttpStatPay(fd,sn,msg)
	print("=================>",msg)
end









