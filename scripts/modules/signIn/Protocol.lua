module(...,package.seeall)

CGSignIn = {
}

GCSignIn = {
    {"ret",     "int",        "签到结果"}, -- 0 成功签到， 1 今天已经签过了
}

GCSignInInfo = {
    {"month",    "int",  "月"},
    {"info",     "int",   "商品次数",  "repeated"},
}

