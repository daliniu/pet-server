module(..., package.seeall)
local ns = "char"                --数据库表
local QueryByAccount={ account=""}     --按帐号查询
local QueryByName = { name=""}         --按角色名查询
local CommonDefine = require("core.base.CommonDefine")
local CharDBDefine = require("modules.character.CharDBDefine")
local DB = require("core.db.DB")
local Util = require("core.utils.Util")
local BaseMath = require("modules.public.BaseMath")

local BagDB = require("modules.bag.BagDB")
local Chapter = require("modules.chapter.Chapter")
local ExpeditionDB = require("modules.expedition.ExpeditionDB")
local ExpeditionShopDB = require("modules.expedition.ExpeditionShopDB")
local ArenaDB = require("modules.arena.ArenaDB")
local OrochiDB = require("modules.orochi.OrochiDB")
local TrialDB = require("modules.trial.TrialDB")
local AchieveDB = require("modules.achieve.AchieveDB")
local TaskDB = require("modules.task.TaskDB")
local PartnerDB = require("modules.partner.PartnerDB")
local VipDB = require("modules.vip.VipDB")
local ShopDB = require("modules.shop.ShopDB")
local FlowerDB = require("modules.flower.FlowerDB")
local TexasDB = require("modules.guild.texas.TexasDB")
local KickDB = require("modules.guild.kick.KickDB")
local WineDB = require("modules.guild.wine.WineDB")
local MysteryShopDB = require("modules.mystery.MysteryShopDB")
local GuildShopDB = require("modules.guild.shop.GuildShopDB")
local GoldDB = require("modules.gold.GoldDB")
local RechargeDB = require("modules.recharge.RechargeDB")
local NewOpenDB = require("modules.newopen.NewOpenDB")
local PeakDB = require("modules.peak.PeakDB")

function new()
	local o =   {
		svrName = 	"",	--服务器名
		account =   "",	--账号
		name    =   "",	--角色名
		pAccount = "",	--平台账号
		channelId = 0,	--渠道号
		createDate = os.time(),	--创建时间

		--default start
		isOnline   = 0,			--是否在线
		bodyId     = CharDBDefine.bodyId,	--头像
		exp        = BaseMath.getHumanLvUpExp(CharDBDefine.lv),
		lv 		   = CharDBDefine.lv,	--等级
		money      = CharDBDefine.money,	--金币
		rmb        = CharDBDefine.rmb,		--钻石(玩家充值兑币->剩余充值兑币数量)
		energy     = CharDBDefine.energy,	--精力
		physics    = CharDBDefine.physics,	--体力
		star       = CharDBDefine.star,	--星魂
		fame 	   = CharDBDefine.fame, --声望
		powerCoin  = CharDBDefine.powerCoin,--巡回币
		tourCoin   = CharDBDefine.tourCoin,--巡回币
        recharge   = CharDBDefine.recharge,     --充值人民币数
        flowerCount= CharDBDefine.flowerCount,--鲜花数
        guildCoin  = CharDBDefine.guildCoin,--公会声望
        exchangeCoin = CharDBDefine.exchangeCoin,--兑换积分
		peakCoin   = CharDBDefine.peakCoin,--巅峰积分
		moneySum   = CharDBDefine.money, --历史金币
		expSum	   = 0,--历史经验
		settings   = {
			music = 1,	
			effect = 1,
			pushSettings={},	--推送设置
		},	
		skillRage = 0,	--怒气值
		skillAssist = 0,	--援助值
		--default end
		
		fcm = 0,
		olTime = 0, 	--玩家总在线时间时长，单位秒
		olDayTime = 0, --今日登录累计在线时间
		lastDate = os.date("%Y%m%d",os.time()), --最后登录日期
		lastLogin = os.time(), --最近一次登入
		lastLogout = os.time(), --最后下线时间
		accumulateDays = 1, --累计登陆天数
		lastSaveTime = os.time(),		--最后存库时间
		ip = "", --登录IP
		sex = 1,
		renameCnt = 0,
		
		--神兵
		wep = {}, 
		--背包
        bag = BagDB.new(),
		--力量
		power = {},
        --远征
        expedition = ExpeditionDB.new(),
        --远征商店
        expeditionShop = ExpeditionShopDB.new(),
		--竞技场
		arena = ArenaDB.new(),
		--大蛇八杰
		orochi = OrochiDB.new(),
		--聊天系统
		chat = {},		
		--闯关
		trial = TrialDB.new(),
		--公会
		guildId = 0, 		
		guildCD = 0,
		guildCnt = 0,
        --成就
        achieve = AchieveDB.new(),    
		--任务
		task = TaskDB.new(),
		--伙伴
        partner = PartnerDB.new(),
		-- 活动
        Activity = {actList={}},
		--签到
        signIn = {month=0, info={}},
		--vip
        vipLv = 0,
        vip = VipDB.new(),    
		--事件 event 
		event = {},
		--公告
		announceId = 0,
		--商城
		shop = ShopDB.new(),
		--完成的引导串
		finishGuide = "",
		--神秘商店
		mystery = MysteryShopDB.new(),
		--鲜花
		flower = FlowerDB.new(),
		--公会德州
		texas = TexasDB.new(),
		--公会踢馆
		kick = KickDB.new(),
		--公会调酒
		wine = WineDB.new(),
		--公会商店 
		guildShop = GuildShopDB.new(),
		--点金
		gold = GoldDB.new(),
		--充值奖励
		rechargeDB = RechargeDB.new(),
		newopenDB = NewOpenDB.new(),
		-- 技能
		skillRage = 0,		--怒气点
		skillAssist = 0,	--援助点
		--培养次数
		trainCnt = 0,
		--巅峰竞技场
		peak = PeakDB.new(),
		--公会bosscd
		guildBossCD = 0,
    }
	setmetatable(o, {__index = _M}) 
	return o;
end

function isNameExistInDB(name)
    QueryByName.name = name
    --return g_oMongoDB:Count(ns,QueryByName) > 0
    local count = DB.Count(ns,QueryByName)
    if count then 
        return count > 0
    else
        return false
    end
end

-- 直接查询db 获取离线角色的特定属性
function getCharPropertyOffLine(name, queryDescrib, isAccount)
    local query = {}
    
    if isAccount then
        query.account = name
    else
        query.name = name
    end
    
    return DB.Find(ns,query,queryDescrib)
end

-- 直接查询db 修改离线角色的特定属性
function setCharPropertyOffLine(name, oValue, isAccount)
    oValue._id = nil

    local query={}
    if isAccount then
      query.account = name
    else
      query.name=name
    end
    local modify={};
    modify["$set"]=oValue
    return DB.Update(ns,query,modify)
end

function loadByAccount(self,account)
	QueryByAccount.account = account
	return DB.Find(ns,QueryByAccount,self)
end

function loadByName(self,name)
    QueryByName.name = name;
    return DB.Find(ns,QueryByName,self)
end

function save(self,isSync)
--local nt1 =  _CurrentTime()
    local query={}
	query._id=self._id
    print("chardb save _id="..tostring(self._id))
    if type(self._id)== 'table' then
        Util.print_r(self._id)
    end 
    local ret = DB.Update(ns,query,self,isSync)
    if not ret then
        LogErr("[mongodb]","char db save fail name:" .. self.name .. "," .. self._id)
    end
--print('-human save db:',_CurrentTime() - nt1)
    return ret
end

function add(self,isSync)
    return DB.Insert(ns,self,isSync)
end

function resetMeta(self)
    setmetatable(self, {__index=_M});
end

