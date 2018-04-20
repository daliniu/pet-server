module(...,package.seeall)
local Paper = require("modules.guild.paper.Paper")
local BossDefine = require("modules.guild.boss.BossDefine")
local ns = "guild"

function new()
	local db = {
		name = "",   --公会名	
		id = 0,		--公会id
		lv = 1,		--公会等级
		icon = 1,		--公会图标
		announce = "",	--公会公告
		memList = {},	--成员
		applyList = {},	--申请列表
		genMemId = 0,	--唯一成员id
		genApplyId = 0,	--唯一申请id
		active = 0,	--公会活跃度
		dayActive = 0,	--公会日活跃度
		texasRank = {}, --公会德州排行榜
		texasRankDay = 0,
		weekTop = {},	--本周最高牌组
		kickRecord = {},	--踢馆记录
		texasLv = 0,
		texasExp = 0,
		wineLv = 1,
		wineExp = 0,
		createDate = os.time(),
		paper = Paper.new(),
		bossId = BossDefine.GUILD_BOSS_ID,
	}
	setmetatable(db,{__index = _M})
	return db 
end

function add(self,isSync)
    return DB.Insert(ns,self,isSync)
end

function save(self,isSync)
    local query = {_id=self._id};
    return DB.Update(ns,query,self,isSync)
end

function destroy(self,isSync)
	local query = {_id=self._id}
	return DB.Delete(ns,query,self,isSync)
end
