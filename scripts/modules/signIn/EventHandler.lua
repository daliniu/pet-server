module(...,package.seeall)

local Msg = require("core.net.Msg")
local PublicLogic = require("modules.public.PublicLogic")
local BagLogic = require("modules.bag.BagLogic")
local Logic = require("modules.signIn.SignIn")
local Cfg = require("config.SignInActivityConfig").Config

function onCGSignIn(human)
	local db = human.db.signIn
	local t = os.date('*t', os.time())
	if t.month ~= db.month then
		db.month = t.month
		db.info = {t.day}
	else
		for k,v in ipairs(db.info) do
			if v == t.day then
				return Msg.SendMsg(PacketID.GC_SIGN_IN, human, 1) -- ret == 1 已经签到
			end
		end
		table.insert(db.info, t.day)
	end

	Msg.SendMsg(PacketID.GC_SIGN_IN_INFO, human, db.month, db.info)
	Msg.SendMsg(PacketID.GC_SIGN_IN, human, 0) -- ret == 0 签到成功

	-- 给奖励
	local n = t.day - (db.info[1] or t.day) + 1
	local conf = Cfg[t.month*100 + n] 
	if not conf then -- 没有数据？取4月份暂代
		conf = Cfg[400 + n]
	end
	if not conf then
		conf = Cfg[401]
	end

	local reward = {} 
	local isDouble = human.db.vipLv >= conf.vipLv and conf.vipLv ~= 0
	for k, v in pairs(conf.reward) do
		if isDouble then
			reward[k] = 2*v 
		else
			reward[k] = v
		end
	end

	PublicLogic.doReward(human, reward,nil, CommonDefine.ITEM_TYPE.ADD_ACTIVITY_SIGN_IN, 
			CommonDefine.MONEY_TYPE.ADD_ACTIVITY_SIGN_IN,CommonDefine.RMB_TYPE.ADD_ACTIVITY_SIGN_IN)
	BagLogic.sendRewardTipsEx(human, reward)
end


