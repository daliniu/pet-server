module(...,package.seeall)
Config={
[1001] = {id=1001, func="addVirItem", itemId=9901001, buynum=25000, desc="确定花费%d%s购买%d金币吗？\n（今日还可以购买%d次）", mtype=1, price={{1,10},{2,20},{4,50},{10,100},{21,200},{40,400}}, daylimited=0, vipAppend="moneyCount", },
[1002] = {id=1002, func="addVirItem", itemId=9901006, buynum=100, desc="确定花费%d%s购买%d点体力吗？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{3,100},{5,200},{7,400},{9,800},{12,1600}}, daylimited=0, vipAppend="physicsCount", },
[1003] = {id=1003, func="addArenaCnt", itemId=0, buynum=1, desc="确定花费%d%s购买%d次竞技场次数吗？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{3,100},{5,200},{8,400},{12,800}}, daylimited=0, vipAppend="arenaCount", },
[1004] = {id=1004, func="", itemId=0, buynum=0, desc="", mtype=1, price={{1,100},{3,200},{5,300},{7,400},{13,800}}, daylimited=0, vipAppend="", },
[1005] = {id=1005, func="addTreasureDoubleTime", itemId=0, buynum=1, desc="确定花费%d%s开启%d次双倍收益吗？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{2,100}}, daylimited=1, vipAppend="treasureDoubleCount", },
[1006] = {id=1006, func="addTreasureSafeTime", itemId=0, buynum=1, desc="确定花费%d%s开启%d次保护时间吗？\n（今日还可以购买%d次）", mtype=1, price={{1,50}}, daylimited=1, vipAppend="treasureSafeCount", },
[1007] = {id=1007, func="addTreasureExtendTime", itemId=0, buynum=1, desc="确定花费%d%s延长%d次占领时间吗？\n（今日还可以购买%d次）", mtype=1, price={{1,50}}, daylimited=1, vipAppend="treasureExtendCount", },
[1008] = {id=1008, func="addTreasureGrabCount", itemId=0, buynum=1, desc="确定花费%d%s购买%d次挑战次数吗？\n（今日还可以购买%d次）", mtype=1, price={{1,20},{3,50},{7,100},{21,200},{51,400}}, daylimited=0, vipAppend="treasureGrabCount", },
[1009] = {id=1009, func="resetBuyCnt", itemId=0, buynum=1, desc="购买该道具次数已达上限，确定花费%d钻石重置当前次数？", mtype=1, price={{1,50},{2,100},{4,200},{7,400},{12,800}}, daylimited=-1, vipAppend="", },
[1010] = {id=1010, func="addTrialTime", itemId=0, buynum=1, desc="确定花费%d%s购买%d次挑战次数？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{2,100},{3,200},{4,400},{5,800}}, daylimited=0, vipAppend="trialCount", },
[1011] = {id=1011, func="addTrialTime", itemId=0, buynum=1, desc="确定花费%d%s购买%d次挑战次数？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{2,100},{3,200},{4,400},{5,800}}, daylimited=0, vipAppend="trialCount", },
[1012] = {id=1012, func="addTrialTime", itemId=0, buynum=1, desc="确定花费%d%s购买%d次挑战次数？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{2,100},{3,200},{4,400},{5,800}}, daylimited=0, vipAppend="trialCount", },
[1013] = {id=1013, func="addTreasureFightTime", itemId=0, buynum=1, desc="确定花费%d%s购买%d次挑战次数？\n（今日还可以购买%d次）", mtype=1, price={{1,10},{2,20},{3,30},{4,50}}, daylimited=1, vipAppend="treasureFightCount", },
[1014] = {id=1014, func="addTreasurerRefreshMapTime", itemId=0, buynum=1, desc="确定花费%d%s购买%d次刷新次数？\n（今日还可以购买%d次）", mtype=1, price={{1,10}}, daylimited=1, vipAppend="treasureRefreshMapCount", },
[1015] = {id=1015, func="addVipLevelCount", itemId=0, buynum=1, desc="确定花费%d%s购买%d次VIP副本挑战次数？\n（今日还可以购买%d次）", mtype=1, price={{1,50},{2,100},{3,200}}, daylimited=1, vipAppend="vipLevelCount", },
}
