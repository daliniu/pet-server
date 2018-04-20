module(...,package.seeall)

ERR_CODE = 
{
	Success = 0,	--成功
	Invalid = 1,	--非法

	Max = 2,	--已经是顶级
	HeroLvMax = 3,	--英雄等级不够
	NoMoney= 4,	--金钱不足
	NoMeterial= 5,	--材料不足
	NoOpen = 6,	--还未开启
}

ERR_TXT =
{
	[ERR_CODE.Success] = "成功！",
	[ERR_CODE.Invalid] = "非法",
	[ERR_CODE.Max] = "已经是顶级!",
	[ERR_CODE.HeroLvMax] = "英雄等级不够!",
	[ERR_CODE.NoMoney] = "金钱不够！",
	[ERR_CODE.NoMeterial] = "材料不够！",
	[ERR_CODE.NoOpen] = "还未开启！",

}
--进阶石
EQUIP_COLOR_ITEM = 2104001

EQUIP_ATTR = {
[1] = {name="atk", cname="攻击:", item="武器"},
[2] = {name="maxHp", cname="血量:", item="防具"},
[3] = {name="finalAtk", cname="必杀:", item="鞋子"},
[4] = {name="maxHp", cname="血量:", item="发带"},
}
