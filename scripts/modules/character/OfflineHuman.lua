module("OfflineHuman", package.seeall)
setmetatable(OfflineHuman, {__index = ObjHuman}) 


local HeroManager = require("modules.hero.HeroManager")
function new(account,name)
    local offman = {
		account = account,
		name = name,
        dbs  = {},
        UpdateTime = os.time(),    

		db = {},
		info = {Hero={}},
    }
	setmetatable(offman, {__index = OfflineHuman})
	offman:init()
	local ret = offman:loadDB("char")
	if ret then
		offman.db = offman.dbs["char"]
		offman.account = offman.db.account
		offman.name = offman.db.name
		return offman
	else
		return nil --查无此人 
	end
end


function init(self)
    self.getHero = HeroManager.getHero
    self.getAllHeroes = HeroManager.getAllHeroes
end

function getLv(self)
    return self.db.lv
end

function loadDB(self, dbname)
    if self.dbs[dbname] ~= nil then
        self:updateTime()
        return true
    end
    self.dbs[dbname] = {}
    local query = {account=self.account}
	if not self.account then
		assert(self.name,"load offline fail,need human name")
		query = {name=self.name}
	end
    local ret = DB.Find(dbname,query,self.dbs[dbname])
    self:updateTime()
    return ret
end

function save(self, dbname,isSync)
    local query = {}
    query._id = self.dbs[dbname]._id 
	local ret = DB.Update(dbname,query,self.dbs[dbname],isSync)
    if not ret then
        LogErr("[mongodb]","OfflineHuman db save fail name:" .. dbname .. "," .. self.dbs[dbname]._id)
    end
end

function saveAll(self,isSync)
    local query = {}
    for dbname,v in pairs(self.dbs) do
        self:save(dbname,isSync)
    end
end

function exit(self)
	self:saveAll()
end

function updateTime(self)
    self.UpdateTime = os.time()
end

function sendHumanInfo(self)
end

return OfflineHuman
