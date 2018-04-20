module(...,package.seeall)
Config={
[1] = {id=1, name="皇家同花顺", rewards={{9901001,45000},{9901008,300},{9901009,300}}, func="superStraight", },
[2] = {id=2, name="同花顺", rewards={{9901001,30000},{9901008,200},{9901009,200}}, func="flushStraight", },
[3] = {id=3, name="四条", rewards={{9901001,22500},{9901008,150},{9901009,150}}, func="fourOfAKind", },
[4] = {id=4, name="葫芦", rewards={{9901001,18000},{9901008,120},{9901009,120}}, func="fullHouse", },
[5] = {id=5, name="同花", rewards={{9901001,13500},{9901008,90},{9901009,90}}, func="onlyFlush", },
[6] = {id=6, name="顺子", rewards={{9901001,9000},{9901008,60},{9901009,60}}, func="onlyStraight", },
[7] = {id=7, name="三条", rewards={{9901001,6000},{9901008,40},{9901009,40}}, func="threeOfAKind", },
[8] = {id=8, name="两对", rewards={{9901001,4500},{9901008,30},{9901009,30}}, func="twoPairs", },
[9] = {id=9, name="一对", rewards={{9901001,3000},{9901008,20},{9901009,20}}, func="onePair", },
[10] = {id=10, name="单只", rewards={{9901001,1500},{9901008,10},{9901009,10}}, func="badCards", },
}
