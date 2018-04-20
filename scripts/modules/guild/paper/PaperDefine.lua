module(...,package.seeall)

PAPER_QUERY_RET = {
	kOk = 1,
	kNoGuild = 2,
}

PAPER_SEND_RET = {
	kOk = 1,
	kNoGuild = 2,
	kSumMin = 3,
	kSumMax = 4,
	kNotVip = 5,
}

PAPER_GET_RET = {
	kOk = 1,
	kNoGuild = 2,
	kNotGet = 3,
}

MAX_PAPER_NUM = 10
OUT_OF_DATE = 24 * 3600 * 3
VIP_LV_NEED = 0
