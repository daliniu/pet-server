--print = _print 
function AppendPath(path)
    package.path = package.path .. string.format(";%s/%s", LUA_SCRIPT_ROOT, path)
end
AppendPath("?.lua")
-- require("ldb")
-- db = ldb.ldb_open

local t1 = os.clock()
local Sha1 = require("core.utils.SHA1")
local t2 = os.clock()
print("=====>sha1 ", t2-t1)

require("init")

if Config.ISMOBDEBUG then
	local mobdebug = require('mobdebug')
	mobdebug.start('localhost')
	mobdebug.off()
end

local Json = require("core.utils.Json")

function LogErr(tag, str)
    _LOG_ERR("[" .. tag .. "] " .. str)
end

function LogOss(tag, table)
    _LOG_GAME("[" .. tag .. "] " .. Json.Encode(table))
end

--刷新老obj对象的元表,必须require所有obj类后面，否则不能热更新
ObjectManager:resetMeta()
Timer.resetTimerRunner()

function Init()
    _SetServerInfo(Config.GAME_IO_LISTEN_PORT, Config.GAME_HTTP_LISTEN_PORT, Config.MSVRIP, Config.MSVRHTTPPORT)
    g_oMongoDB = g_oMongoDB or MongoDB()
    if not g_oMongoDB:Connect(Config.DBIP, Config.DBNAME,Config.DBUSER, Config.DBPWD,Config.DBPORT) then
        LogErr("error", string.format("Connection MongoDB %s@%s:%s fail", Config.DBNAME, Config.DBIP, Config.DBPWD));
    end

    --建立索引
    g_oMongoDB:EnsureIndex("char",{{account=1}})
    g_oMongoDB:EnsureIndex("char",{{name=1}})
	g_oMongoDB:EnsureIndex("char",{{lastSaveTime=1}})
    --g_oMongoDB:EnsureIndex("market",{{marketId=1}})
    --g_oMongoDB:EnsureIndex("relation",{{name=1}})
    --g_oMongoDB:EnsureIndex("master",{{name=1}})
    --g_oMongoDB:EnsureIndex("mail",{{account=1}})

    --清空在线标记
    g_oMongoDB:SyncUpdate("char",{},{["$set"]={isOnline=0}},0,1)
	--

	require("modules.arena.Arena").init()
	require("modules.friends.Friends").init()
	require("modules.guild.GuildManager").init()
	require("modules.orochi.OrochiRank").init()
	require("modules.trial.TrialRank").init()
    require("modules.treasure.Treasure").init()
    require("modules.chapter.Chapter").initDB()
	require("modules.worldBoss.WorldBossLogic").init()
	require("modules.activity.Activity").init()
	require("modules.announce.Announce").init()
	require("modules.flower.FlowerRank").init()
	require("modules.admin.ForbidManager").init()
	require("modules.recharge.RechargeLogic").init()
	require("modules.newopen.NewOpenLogic").init()
	require("modules.rank.RankLogic").init()
    _RegisterDB(Config.DBIP,Config.DBNAME,Config.DBUSER,Config.DBPWD,Config.DBPORT)
    LogErr("notice", "Game init done !!");
end

function GameExit()
	require("modules.friends.Friends").save(true)
	require("modules.arena.Arena").save(true)
	require("modules.guild.GuildManager").save(true)
	require("modules.orochi.OrochiRank").save(true)
	require("modules.trial.TrialRank").save(true)
    require("modules.treasure.Treasure").save(true)
    require("modules.chapter.Chapter").saveDB(true)
	require("modules.worldBoss.WorldBossLogic").saveDB(true)
	require("modules.activity.Activity").save(true)
	require("modules.mail.MailManager").saveAll()
	require("modules.announce.Announce").saveAll()
	require("modules.flower.FlowerRank").saveDB(true)
	require("modules.admin.ForbidManager").save(true)
	require("modules.newopen.NewOpenLogic").save(true)
	require("modules.rank.RankLogic").saveDB(true)

	HumanManager.onGameExit()
	DB.onGameExit()

    print('------------------------------Game Exit ----------------------------------')
    print('------------------------------Good bye -----------------------------------')
end
