module(..., package.seeall)

ISGAMESVR = true
ISTESTCLIENT = true 
ISOPENMONITOR = false     --//性能监控日志
MONITOR_MS = 1           --//性能监控阀值，毫秒级人物
ISMOBDEBUG = false		 --//开启mobdebug调试

GAME_IO_LISTEN_PORT=52520          --// Logic接入端口
GAME_HTTP_LISTEN_PORT=10000       --// Http接入端口
--开服相关
ADMIN_KEY   = "1234567"           --管理http接口key
ADMIN_AGENT = "yy"                --代理

key = "25414291b5d562cd9e61d6b3cce74c94"        --登录key
payKey = "bx32017616e8396cbfae965ba2162f32"     --充值key

-- 允许访问管理接口的IP列表
ADMIN_IP_LIST = {"127.0.0.1","192.168.1.125"}

-- mongoDB数据库配置
DBIP="127.0.0.1"
DBNAME="kof"		--数据库名
DBUSER="kof"		--数据库账号
DBPWD="kof"			--数据库密码
DBPORT=27017		--数据库端口号

--服务器代号
SVRNAME="[01]"

-- 跨服pk服相关字段 正常游戏服可不配置
MSVRIP="127.0.0.1"
MSVRPORT=20000
MSVRHTTPPORT=30000
GSVR = {}
GSVR[1] = {svrName="[01]", ip="127.0.0.1", ioPort = 4399, httpPort = 10000, dbIP = "127.0.0.1", dbName = "jydb", dbUser="test", dbPwd = "test123"}

-- 游戏功能相关设定
ISCLOSEGMCOMMAND = 1
QQGROUP = '玩家群1  189024862'

--开服时间
newServerDate={year=2012,month=7,day=30,hour=12,min=0,sec=0}
newServerTime=os.time(newServerDate)

--SDK验证
OPEN_SDK_AUTH = false
SDK_AUTH_KEY = "A85951dc1a2d3da6c5a49a"
--SDK_AUTH_URL = "http://gameproxy.xinmei365.com/game_agent/checkLogin" 



