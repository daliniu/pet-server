module("DB", package.seeall)

DBQueryOK = 0
DBQueryTimeout = 1
DBQueryError = 2

DBTManager = DBTManager or {}

function GetDB(roleName)
	if Config.ISGAMESVR then
		return g_oMongoDB
	else 
		local i, j = string.find(roleName, "]")
		if i ~= nil then
			local svrName = string.sub(roleName, 1, i)
			local db = g_oMongoDBs[svrName]
			assert(db)
			return db
		end
		assert(false)
		return nil
	end
end

function dbErrFunc(retCode,retSet)
	print("dbErrFunc  "..retCode)
end

IKeyTableforDB = {}
IKeyTableforDB.mt = {}
IKeyTableforDB.mt.__index = function(t,k)
	if type(k) ~= "string" then
		local newkey = tostring(k)
		return rawget(t,newkey)
	else
		return rawget(t,k)
	end
end
IKeyTableforDB.mt.__newindex = function(t,k,v)
	if type(k) ~= "string" then
		-- print("__newindex ~string key="..tostring(k).." value="..tostring(v))
		local newkey = tostring(k)
		rawset(t,newkey,v)
	else
		rawset(t,k,v)
	end
end
IKeyTableforDB.new = function()
	local o = {}

	setmetatable(o,IKeyTableforDB.mt)
	print("new metatable "..tostring(getmetatable(o)))
	return o
end

function dbSetMetatable(t)
	setmetatable(t,IKeyTableforDB.mt)
end

function Find(ns, query, target, isSync)
	local sync = isSync or Config.ISSYNC
	local ret, dataset = false, nil

	if sync then
		local pCursor = g_oMongoDB:SyncFind(ns,query)
		if pCursor then
			dataset = {}
			local cursor = MongoDBCursor(pCursor)
			local row = {}
			while cursor:Next(row) do
				table.insert(dataset, row)
				row = {}
			end
			ret = #dataset > 0
		end
	else
		local tid = g_oMongoDB:Find(ns, query);
		assert(tid > 0,"db tid must be positive")
		ret, dataset = coroutine.yield(tid)
		ret = #dataset > 0
	end

	if target and ret then 
		local d = dataset[1]
		for k,v in pairs(d) do 
			local t = target[k]
			if t and type(t) == "table" and type(v) == "table" then
				for kk, vv in pairs(v) do
					t[kk] = vv
				end
			else
				target[k] = v
			end
		end
	end

	if ret then
		return ret,dataset
	else
		print("db find fail!")
		return false 
	end 
end

function Update(ns, query, update, isSync)
	local sync = isSync or Config.ISSYNC
	if sync then
		return g_oMongoDB:SyncUpdate(ns, query, update)
	else
		local tid = g_oMongoDB:Update(ns, query, update);
		assert(tid > 0,"db tid must be positive")
		local ret,retSet = coroutine.yield(tid)
		if ret then 
			return true
		else
			print("upate fail!"..tostring(retSet))
			return false
		end
	end
end

function Insert(ns,query,isSync)
	local sync = isSync or Config.ISSYNC
	local ret, id = false, nil
	if sync then
		ret, id = g_oMongoDB:SyncInsert(ns,query)
	else
		local tid = g_oMongoDB:Insert(ns,query);
		assert(tid > 0,"db tid must be positive")
		ret, id = coroutine.yield(tid)
	end
	if ret then 
		query._id = id 
		return true
	else
		print("insert fail!" , id)
		return false
	end
end

function Count(ns,query,isSync)
	local sync = isSync or Config.ISSYNC
	if sync then
		return g_oMongoDB:SyncCount(ns,query)
	else
		local tid = g_oMongoDB:Count(ns,query);
		assert(tid > 0,"db tid must be positive")
		local ret,count = coroutine.yield(tid)
		if ret then 
			return count
		else
			print("count fail!"..retSet)
			return
		end
	end
end

function Delete(ns,query,isSync)
	local sync = isSync or Config.ISSYNC
	if sync then
		return g_oMongoDB:SyncDelete(ns,query)
	else
		local tid = g_oMongoDB:Delete(ns,query);
		assert(tid > 0,"db tid must be positive")
		local ret = coroutine.yield(tid)
		if ret then 
			return true
		else
			print("delete fail!"..retSet)
			return
		end
	end
end

function dbDispatch(tid,retCode,retSet) 
    local co = DBTManager[tid]
    if co then
        local ret,msgOrTid = coroutine.resume(co,retCode == 0,retSet)
		if not ret then 
			local errMsg = "dbDispatch error \n".. tostring(msgOrTid)
			errMsg = errMsg .. debug.traceback(co)
			LogErr("error",errMsg)
			print("--------------------------------------------")
			print(errMsg)
			print("--------------------------------------------")
			local info = debug.getinfo(co,1,'S')
			if info and info.what == "Lua" then
				if info.short_src:find("UrlDispatch") then
					--http协程请求失败的返回
					_SendHttpResponse("500")
				end
			end
		else
			if type(msgOrTid) == "number" then
				-- 一个msg有多次数据库异步访问，程序就会走到这里
				DBTManager[msgOrTid] = co
			end
		end
		--协程结束，删除掉DBTManager中的协程对象
		DBTManager[tid] = nil
		return ret
    end
end

function onGameExit()
	_G["MsgDispatch"] = function()end 
	_G["dbDispatch"] = function(tid, retCode,retSet)
		_M["dbDispatch"](tid, retCode, retSet)
		if not next(DBTManager) then
			_OnGameExit()
		end
	end
	if not next(DBTManager) then
		_OnGameExit()
	end
end

_G["dbDispatch"] = dbDispatch

return DB
