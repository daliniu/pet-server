module(..., package.seeall)

MAX_LV = 100

--起名花费
RENAME_RMB = 100

-- sex
HUMAN_SEX_MALE   = 1
HUMAN_SEX_FEMALE = 2

--定时存库时间
TIMER_SAVE_CHAR_DB = 5 * 60 * 1000
--掉线重连
TIMER_RE_LOGIN_TIMEOUT = 10 * 60 * 1000	
--定时加体力
TIMER_ADD_PHYSICS = 6 * 60 * 1000	
--TIMER_ADD_PHYSICS = 0.2 * 60 * 1000	

-- 登录错误码
ASK_LOGIN_FAIL              = 1     --登录验证不通过
ASK_LOGIN_TIMEOUT           = 2     --登录超时
ASK_LOGIN_SDK_FAIL          = 3     --SDK验证不通过

-- return code for relogin
RET_TOKEN_EXPIRE = 1	--token过期
RET_TOKEN_ERR = 2	--token无效
RET_TOKEN_OFFLINE = 3	--玩家已下线
RET_TOKEN_ONLINE = 4	--玩家在线

-- result code for rename 
RET_NAME_EXIST = 1	--已存在
RET_NAME_INVALID = 2	--名字不合法
RET_NAME_NORMB = 3	--没rmb


-- return code for giftcode
RET_GIFT_FAIL = 1 --使用失败


