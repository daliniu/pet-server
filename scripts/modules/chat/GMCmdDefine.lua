module(...,package.seeall)

GM_FORMAT = "^gm_"

--gm return code
OK = 0
FAIL = 1 --GM指令失败
NOT_EXIST_CMD = 2 --不存在的指令
PARAM_ERROR = 3 --参数错误

GM_RETURN_CODE_CONTENT = {
    [OK] = "use GM function success",
    [FAIL] = "use GM function fail",
    [NOT_EXIST_CMD] = "the GM function doesn't exist",
    [PARAM_ERROR] = "the GM function parameter error",
}
