module(...,package.seeall)
Config={
[1] = {lv=1, normal=520, final=3, assist=6, assist1=2040, assist2=3060, assist3=4080, combo=3, broke=3, upItem1=0, upItem2=1, },
[2] = {lv=2, normal=1080, final=6, assist=12, assist1=4160, assist2=6240, assist3=8320, combo=6, broke=6, upItem1=0, upItem2=2, },
[3] = {lv=3, normal=1680, final=9, assist=18, assist1=6360, assist2=9540, assist3=12720, combo=9, broke=9, upItem1=0, upItem2=3, },
[4] = {lv=4, normal=2320, final=12, assist=24, assist1=8640, assist2=12960, assist3=17280, combo=12, broke=12, upItem1=0, upItem2=4, },
[5] = {lv=5, normal=3000, final=15, assist=30, assist1=11000, assist2=16500, assist3=22000, combo=15, broke=15, upItem1=0, upItem2=5, },
[6] = {lv=6, normal=3720, final=18, assist=36, assist1=13440, assist2=20160, assist3=26880, combo=18, broke=18, upItem1=0, upItem2=6, },
[7] = {lv=7, normal=4480, final=21, assist=42, assist1=15960, assist2=23940, assist3=31920, combo=21, broke=21, upItem1=0, upItem2=7, },
[8] = {lv=8, normal=5280, final=24, assist=48, assist1=18560, assist2=27840, assist3=37120, combo=24, broke=24, upItem1=0, upItem2=8, },
[9] = {lv=9, normal=6120, final=27, assist=54, assist1=21240, assist2=31860, assist3=42480, combo=27, broke=27, upItem1=0, upItem2=9, },
[10] = {lv=10, normal=7000, final=30, assist=60, assist1=24000, assist2=36000, assist3=48000, combo=30, broke=30, upItem1=0, upItem2=10, },
[11] = {lv=11, normal=7920, final=33, assist=66, assist1=26840, assist2=40260, assist3=53680, combo=33, broke=33, upItem1=0, upItem2=11, },
[12] = {lv=12, normal=8880, final=36, assist=72, assist1=29760, assist2=44640, assist3=59520, combo=36, broke=36, upItem1=0, upItem2=12, },
[13] = {lv=13, normal=9880, final=39, assist=78, assist1=32760, assist2=49140, assist3=65520, combo=39, broke=39, upItem1=0, upItem2=13, },
[14] = {lv=14, normal=10920, final=42, assist=84, assist1=35840, assist2=53760, assist3=71680, combo=42, broke=42, upItem1=0, upItem2=14, },
[15] = {lv=15, normal=12000, final=45, assist=90, assist1=39000, assist2=58500, assist3=78000, combo=45, broke=45, upItem1=0, upItem2=15, },
[16] = {lv=16, normal=13120, final=48, assist=96, assist1=42240, assist2=63360, assist3=84480, combo=48, broke=48, upItem1=0, upItem2=16, },
[17] = {lv=17, normal=14280, final=51, assist=102, assist1=45560, assist2=68340, assist3=91120, combo=51, broke=51, upItem1=0, upItem2=17, },
[18] = {lv=18, normal=15480, final=54, assist=108, assist1=48960, assist2=73440, assist3=97920, combo=54, broke=54, upItem1=0, upItem2=18, },
[19] = {lv=19, normal=16720, final=57, assist=114, assist1=52440, assist2=78660, assist3=104880, combo=57, broke=57, upItem1=0, upItem2=19, },
[20] = {lv=20, normal=18000, final=60, assist=120, assist1=56000, assist2=84000, assist3=112000, combo=60, broke=60, upItem1=0, upItem2=20, },
[21] = {lv=21, normal=19320, final=63, assist=126, assist1=59640, assist2=89460, assist3=119280, combo=63, broke=63, upItem1=0, upItem2=21, },
[22] = {lv=22, normal=20680, final=66, assist=132, assist1=63360, assist2=95040, assist3=126720, combo=66, broke=66, upItem1=0, upItem2=22, },
[23] = {lv=23, normal=22080, final=69, assist=138, assist1=67160, assist2=100740, assist3=134320, combo=69, broke=69, upItem1=0, upItem2=23, },
[24] = {lv=24, normal=23520, final=72, assist=144, assist1=71040, assist2=106560, assist3=142080, combo=72, broke=72, upItem1=0, upItem2=24, },
[25] = {lv=25, normal=25000, final=75, assist=150, assist1=75000, assist2=112500, assist3=150000, combo=75, broke=75, upItem1=1, upItem2=25, },
[26] = {lv=26, normal=26520, final=78, assist=156, assist1=79040, assist2=118560, assist3=158080, combo=78, broke=78, upItem1=2, upItem2=26, },
[27] = {lv=27, normal=28080, final=81, assist=162, assist1=83160, assist2=124740, assist3=166320, combo=81, broke=81, upItem1=3, upItem2=27, },
[28] = {lv=28, normal=29680, final=84, assist=168, assist1=87360, assist2=131040, assist3=174720, combo=84, broke=84, upItem1=4, upItem2=28, },
[29] = {lv=29, normal=31320, final=87, assist=174, assist1=91640, assist2=137460, assist3=183280, combo=87, broke=87, upItem1=5, upItem2=29, },
[30] = {lv=30, normal=33000, final=90, assist=180, assist1=96000, assist2=144000, assist3=192000, combo=90, broke=90, upItem1=6, upItem2=30, },
[31] = {lv=31, normal=34720, final=93, assist=186, assist1=100440, assist2=150660, assist3=200880, combo=93, broke=93, upItem1=7, upItem2=31, },
[32] = {lv=32, normal=36480, final=96, assist=192, assist1=104960, assist2=157440, assist3=209920, combo=96, broke=96, upItem1=8, upItem2=32, },
[33] = {lv=33, normal=38280, final=99, assist=198, assist1=109560, assist2=164340, assist3=219120, combo=99, broke=99, upItem1=9, upItem2=33, },
[34] = {lv=34, normal=40120, final=102, assist=204, assist1=114240, assist2=171360, assist3=228480, combo=102, broke=102, upItem1=10, upItem2=34, },
[35] = {lv=35, normal=42000, final=105, assist=210, assist1=119000, assist2=178500, assist3=238000, combo=105, broke=105, upItem1=11, upItem2=35, },
[36] = {lv=36, normal=43920, final=108, assist=216, assist1=123840, assist2=185760, assist3=247680, combo=108, broke=108, upItem1=12, upItem2=36, },
[37] = {lv=37, normal=45880, final=111, assist=222, assist1=128760, assist2=193140, assist3=257520, combo=111, broke=111, upItem1=13, upItem2=37, },
[38] = {lv=38, normal=47880, final=114, assist=228, assist1=133760, assist2=200640, assist3=267520, combo=114, broke=114, upItem1=14, upItem2=38, },
[39] = {lv=39, normal=49920, final=117, assist=234, assist1=138840, assist2=208260, assist3=277680, combo=117, broke=117, upItem1=15, upItem2=39, },
[40] = {lv=40, normal=52000, final=120, assist=240, assist1=144000, assist2=216000, assist3=288000, combo=120, broke=120, upItem1=16, upItem2=40, },
[41] = {lv=41, normal=54120, final=123, assist=246, assist1=149240, assist2=223860, assist3=298480, combo=123, broke=123, upItem1=17, upItem2=41, },
[42] = {lv=42, normal=56280, final=126, assist=252, assist1=154560, assist2=231840, assist3=309120, combo=126, broke=126, upItem1=18, upItem2=42, },
[43] = {lv=43, normal=58480, final=129, assist=258, assist1=159960, assist2=239940, assist3=319920, combo=129, broke=129, upItem1=19, upItem2=43, },
[44] = {lv=44, normal=60720, final=132, assist=264, assist1=165440, assist2=248160, assist3=330880, combo=132, broke=132, upItem1=20, upItem2=44, },
[45] = {lv=45, normal=63000, final=135, assist=270, assist1=171000, assist2=256500, assist3=342000, combo=135, broke=135, upItem1=21, upItem2=45, },
[46] = {lv=46, normal=65320, final=138, assist=276, assist1=176640, assist2=264960, assist3=353280, combo=138, broke=138, upItem1=22, upItem2=46, },
[47] = {lv=47, normal=67680, final=141, assist=282, assist1=182360, assist2=273540, assist3=364720, combo=141, broke=141, upItem1=23, upItem2=47, },
[48] = {lv=48, normal=70080, final=144, assist=288, assist1=188160, assist2=282240, assist3=376320, combo=144, broke=144, upItem1=24, upItem2=48, },
[49] = {lv=49, normal=72520, final=147, assist=294, assist1=194040, assist2=291060, assist3=388080, combo=147, broke=147, upItem1=25, upItem2=49, },
[50] = {lv=50, normal=75000, final=150, assist=300, assist1=200000, assist2=300000, assist3=400000, combo=150, broke=150, upItem1=26, upItem2=50, },
[51] = {lv=51, normal=77520, final=153, assist=306, assist1=206040, assist2=309060, assist3=412080, combo=153, broke=153, upItem1=27, upItem2=51, },
[52] = {lv=52, normal=80080, final=156, assist=312, assist1=212160, assist2=318240, assist3=424320, combo=156, broke=156, upItem1=28, upItem2=52, },
[53] = {lv=53, normal=82680, final=159, assist=318, assist1=218360, assist2=327540, assist3=436720, combo=159, broke=159, upItem1=29, upItem2=53, },
[54] = {lv=54, normal=85320, final=162, assist=324, assist1=224640, assist2=336960, assist3=449280, combo=162, broke=162, upItem1=30, upItem2=54, },
[55] = {lv=55, normal=88000, final=165, assist=330, assist1=231000, assist2=346500, assist3=462000, combo=165, broke=165, upItem1=31, upItem2=55, },
[56] = {lv=56, normal=90720, final=168, assist=336, assist1=237440, assist2=356160, assist3=474880, combo=168, broke=168, upItem1=32, upItem2=56, },
[57] = {lv=57, normal=93480, final=171, assist=342, assist1=243960, assist2=365940, assist3=487920, combo=171, broke=171, upItem1=33, upItem2=57, },
[58] = {lv=58, normal=96280, final=174, assist=348, assist1=250560, assist2=375840, assist3=501120, combo=174, broke=174, upItem1=34, upItem2=58, },
[59] = {lv=59, normal=99120, final=177, assist=354, assist1=257240, assist2=385860, assist3=514480, combo=177, broke=177, upItem1=35, upItem2=59, },
[60] = {lv=60, normal=102000, final=180, assist=360, assist1=264000, assist2=396000, assist3=528000, combo=180, broke=180, upItem1=36, upItem2=60, },
[61] = {lv=61, normal=104920, final=200, assist=400, assist1=270840, assist2=406260, assist3=541680, combo=200, broke=200, upItem1=37, upItem2=61, },
[62] = {lv=62, normal=107880, final=220, assist=440, assist1=277760, assist2=416640, assist3=555520, combo=220, broke=220, upItem1=38, upItem2=62, },
[63] = {lv=63, normal=110880, final=240, assist=480, assist1=284760, assist2=427140, assist3=569520, combo=240, broke=240, upItem1=39, upItem2=63, },
[64] = {lv=64, normal=113920, final=260, assist=520, assist1=291840, assist2=437760, assist3=583680, combo=260, broke=260, upItem1=40, upItem2=64, },
[65] = {lv=65, normal=117000, final=280, assist=560, assist1=299000, assist2=448500, assist3=598000, combo=280, broke=280, upItem1=41, upItem2=65, },
[66] = {lv=66, normal=120120, final=300, assist=600, assist1=306240, assist2=459360, assist3=612480, combo=300, broke=300, upItem1=42, upItem2=66, },
[67] = {lv=67, normal=123280, final=320, assist=640, assist1=313560, assist2=470340, assist3=627120, combo=320, broke=320, upItem1=43, upItem2=67, },
[68] = {lv=68, normal=126480, final=340, assist=680, assist1=320960, assist2=481440, assist3=641920, combo=340, broke=340, upItem1=44, upItem2=68, },
[69] = {lv=69, normal=129720, final=360, assist=720, assist1=328440, assist2=492660, assist3=656880, combo=360, broke=360, upItem1=45, upItem2=69, },
[70] = {lv=70, normal=133000, final=380, assist=760, assist1=336000, assist2=504000, assist3=672000, combo=380, broke=380, upItem1=46, upItem2=70, },
[71] = {lv=71, normal=136320, final=400, assist=800, assist1=343640, assist2=515460, assist3=687280, combo=400, broke=400, upItem1=47, upItem2=71, },
[72] = {lv=72, normal=139680, final=420, assist=840, assist1=351360, assist2=527040, assist3=702720, combo=420, broke=420, upItem1=48, upItem2=72, },
[73] = {lv=73, normal=143080, final=440, assist=880, assist1=359160, assist2=538740, assist3=718320, combo=440, broke=440, upItem1=49, upItem2=73, },
[74] = {lv=74, normal=146520, final=460, assist=920, assist1=367040, assist2=550560, assist3=734080, combo=460, broke=460, upItem1=50, upItem2=74, },
[75] = {lv=75, normal=150000, final=480, assist=960, assist1=375000, assist2=562500, assist3=750000, combo=480, broke=480, upItem1=51, upItem2=75, },
[76] = {lv=76, normal=153520, final=500, assist=1000, assist1=383040, assist2=574560, assist3=766080, combo=500, broke=500, upItem1=52, upItem2=76, },
[77] = {lv=77, normal=157080, final=520, assist=1040, assist1=391160, assist2=586740, assist3=782320, combo=520, broke=520, upItem1=53, upItem2=77, },
[78] = {lv=78, normal=160680, final=540, assist=1080, assist1=399360, assist2=599040, assist3=798720, combo=540, broke=540, upItem1=54, upItem2=78, },
[79] = {lv=79, normal=164320, final=560, assist=1120, assist1=407640, assist2=611460, assist3=815280, combo=560, broke=560, upItem1=55, upItem2=79, },
[80] = {lv=80, normal=168000, final=580, assist=1160, assist1=416000, assist2=624000, assist3=832000, combo=580, broke=580, upItem1=56, upItem2=80, },
[81] = {lv=81, normal=171720, final=600, assist=1200, assist1=424440, assist2=636660, assist3=848880, combo=600, broke=600, upItem1=57, upItem2=81, },
[82] = {lv=82, normal=175480, final=620, assist=1240, assist1=432960, assist2=649440, assist3=865920, combo=620, broke=620, upItem1=58, upItem2=82, },
[83] = {lv=83, normal=179280, final=640, assist=1280, assist1=441560, assist2=662340, assist3=883120, combo=640, broke=640, upItem1=59, upItem2=83, },
[84] = {lv=84, normal=183120, final=660, assist=1320, assist1=450240, assist2=675360, assist3=900480, combo=660, broke=660, upItem1=60, upItem2=84, },
[85] = {lv=85, normal=187000, final=680, assist=1360, assist1=459000, assist2=688500, assist3=918000, combo=680, broke=680, upItem1=61, upItem2=85, },
[86] = {lv=86, normal=190920, final=700, assist=1400, assist1=467840, assist2=701760, assist3=935680, combo=700, broke=700, upItem1=62, upItem2=86, },
[87] = {lv=87, normal=194880, final=720, assist=1440, assist1=476760, assist2=715140, assist3=953520, combo=720, broke=720, upItem1=63, upItem2=87, },
[88] = {lv=88, normal=198880, final=740, assist=1480, assist1=485760, assist2=728640, assist3=971520, combo=740, broke=740, upItem1=64, upItem2=88, },
[89] = {lv=89, normal=202920, final=760, assist=1520, assist1=494840, assist2=742260, assist3=989680, combo=760, broke=760, upItem1=65, upItem2=89, },
[90] = {lv=90, normal=207000, final=780, assist=1560, assist1=504000, assist2=756000, assist3=1008000, combo=780, broke=780, upItem1=66, upItem2=90, },
[91] = {lv=91, normal=211120, final=800, assist=1600, assist1=513240, assist2=769860, assist3=1026480, combo=800, broke=800, upItem1=67, upItem2=91, },
[92] = {lv=92, normal=215280, final=820, assist=1640, assist1=522560, assist2=783840, assist3=1045120, combo=820, broke=820, upItem1=68, upItem2=92, },
[93] = {lv=93, normal=219480, final=840, assist=1680, assist1=531960, assist2=797940, assist3=1063920, combo=840, broke=840, upItem1=69, upItem2=93, },
[94] = {lv=94, normal=223720, final=860, assist=1720, assist1=541440, assist2=812160, assist3=1082880, combo=860, broke=860, upItem1=70, upItem2=94, },
[95] = {lv=95, normal=228000, final=880, assist=1760, assist1=551000, assist2=826500, assist3=1102000, combo=880, broke=880, upItem1=71, upItem2=95, },
[96] = {lv=96, normal=232320, final=900, assist=1800, assist1=560640, assist2=840960, assist3=1121280, combo=900, broke=900, upItem1=72, upItem2=96, },
[97] = {lv=97, normal=236680, final=920, assist=1840, assist1=570360, assist2=855540, assist3=1140720, combo=920, broke=920, upItem1=73, upItem2=97, },
[98] = {lv=98, normal=241080, final=940, assist=1880, assist1=580160, assist2=870240, assist3=1160320, combo=940, broke=940, upItem1=74, upItem2=98, },
[99] = {lv=99, normal=245520, final=960, assist=1920, assist1=590040, assist2=885060, assist3=1180080, combo=960, broke=960, upItem1=75, upItem2=99, },
[100] = {lv=100, normal=250000, final=980, assist=1960, assist1=600000, assist2=900000, assist3=1200000, combo=980, broke=980, upItem1=76, upItem2=100, },
}
