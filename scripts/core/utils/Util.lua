module("Util", package.seeall)

local SendMsg           = require("core.net.Msg").SendMsg
local PacketID          = require("PacketID")

function WriteToFile( fileName, message )
    if fileName == nil then
        assert( false, "WriteToFile--收到的文件名字是空的" )
        return;
    end
    
    local file = io.open( fileName, "w" )
    file:write( message )
    file:close()
end

function IsInList( list, element )
    for _, oneListElement in ipairs( list ) do
        if oneListElement == element then
            return true;
        end
    end
end

local exceptCharset = { '-', '.', '_' };
function url_encode(str)
    if str then
        str = string.gsub ( str, "\n", "\r\n" )
        str = string.gsub ( str, "([^%w ])",
            function (c) 
                for _, exceptChar in ipairs( exceptCharset ) do
                    if exceptChar == c then
                        return c;
                    end
                end
                
                local resultChar = string.format ( "%%%02X", string.byte( c ) ) ;
                return resultChar
            end )
            
        str = string.gsub (str, " ", "+")
    end
    
    return str  
end

function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

function GetFormatedCurTime()
    local todayTimeInfo = os.date( "*t", GetCurTime() );
    return { month = todayTimeInfo.month, day = todayTimeInfo.day, hour = todayTimeInfo.hour, min = todayTimeInfo.min,
            sec = todayTimeInfo.sec }
end 

function GetFormatedTime(t)
    local todayTimeInfo = os.date( "*t", t);
    return { month = todayTimeInfo.month, day = todayTimeInfo.day, hour = todayTimeInfo.hour, min = todayTimeInfo.min,
            sec = todayTimeInfo.sec }
end 

function print_t_lsy(table_to_print)
    do_print_t_lsy{t=table_to_print}
end

function do_print_t_lsy(args)
    if args.t == nil then
        print('param t is nil!')
        return
    end

    if _G.next( args.t ) == nil then
        print('param t is empty!')
        return
    end
  
    if type(args.t) ~= 'table' then
        print('param is not a table!')
        return
    end
  
    -- format prefix
    local lev = args.lev or 1
    if (lev == 1) then
        print ('[table]')
    end
    local pre = ' |--'
    local pre_space = ' |  '
    pre_t = {}
    for i = 1, lev do
        if (i == lev) then
            table.insert(pre_t, pre)
        else
            table.insert(pre_t, pre_space)
        end
    end
    pre = table.concat(pre_t)
  
    -- do print
    local tt = {}
    for k,v in pairs(args.t) do
        if type(v) ~= 'table' then
            print (pre..'['..k..']=',v)
        else
            tt = v
            print (pre..'[table:' .. k .. ']')
            do_print_t_lsy{t=tt, lev=lev+1}
        end
    end  
end

function GetRandPos(x, y, nRadius)
    return x + math.random(-nRadius, nRadius), y + math.random(-nRadius, nRadius)
end

function GetRandPosOnEdge(x, y, r)
    local hudu = math.random() * 2 * math.pi
    x = x + math.cos(hudu) * r
    y = y + math.sin(hudu) * r
    return math.floor(x), math.floor(y)
end

function GetRandPosOnEllipse(i,cnt)
    local a = (i - 1) % 4
    local b = (a + 1) % 4
    local x1 = math.min(pos[b].x,pos[a].x)
    local x2 = math.max(pos[b].x,pos[a].x)
    local x = math.random(x1,x2)
    local y = ((pos[b].y - pos[a].y)/(pos[b].x - pos[a].x)) * (x - pos[a].x) + pos[a].y
    return math.floor(x),math.floor(y)
end

function GetRandPosOnMiddle(i)
    a = (i - 1) % 4
    b = (a + 1) % 4
    local x = (pos[b].x + pos[a].x)/2
    local y = (pos[b].y + pos[a].y)/2
    return math.floor(x),math.floor(y)
end

tbCharArrayToString = tbCharArrayToString or {}
function GetStringFromTable(tbLen, tb)
    for i = 1, tbLen do
        tbCharArrayToString[i] = string.char(tb[i] % 256)
    end
    return table.concat(tbCharArrayToString, "", 1, tbLen)
end

function newEnum(tb, nStartFrom)    --创建一个枚举类型
    nStartFrom = nStartFrom or 1
    local o = {m_begin = nStartFrom, m_end = nStartFrom + #tb -1 }
    for i = 1, #tb do
        o[tb[i]] = i - 1 + nStartFrom
    end
    o.__index = function(t, k) assert(nil, k .. " not exist") end
    setmetatable(o, o)
    return o
end

function Div(a, b)
    return (a - a % b) / b
end

--获取一个整形的第几位是什么
function GetBit(n, bitIndex)
    return Div(n, 2^bitIndex) % 2
end

--设置一个整形的第几位为0或1
function SetBit(n, bitIndex, zeroOrOne)
   local bit = GetBit(n, bitIndex)
   if bit == 0 and zeroOrOne == 1 then
    return n + 2 ^ bitIndex
   end
   if bit == 1 and zeroOrOne == 0 then
    return n - 2 ^ bitIndex
   end
   return n
end

function PrintTable(tb, step)
    step = step or 0
    for k, v in pairs(tb) do
        print(string.rep("  ", step), k, "=", v)
        if type(v) == "table" then
            PrintTable(v, step + 1)
        end
    end
end

function print_r(table)
    PRINT('{')
    local cnt=0
    for v in pairs(table) do
        if cnt > 0 then
            PRINT(',')
        end
        cnt = cnt+1
        if type(v) == 'string' then
            PRINT(string.format("%s=", v))
        end
        if type(table[v]) == 'table' then
            print_r(table[v])
        else
            PRINT(table[v])
        end
    end
    PRINT('}')
end

function GDB()
    print("\n--------Begin GDB\n")
    local level = 2
    local info = debug.getinfo(level)
    print(info.source, info.name, info.currentline)
    for i = 1, math.huge do
        local name, value = debug.getlocal(level, i)
        if not name then break end
        print(name, "=", value)
    end
    print("\n--------End GDB\n")
end

function IncludeClassHeader(moduleName)
    loadfile("../scripts/common/ClassHeader.lua")(moduleName)
end

function newStack ()
    return {""}
end

function addString (stack, s)
    table.insert(stack, tostring(s))
    for i=table.getn(stack)-1, 1, -1 do
       if string.len(stack[i]) > string.len(stack[i+1]) then
           break
       end
       stack[i] = stack[i] .. table.remove(stack)
    end
end

function tab2str(s, name, pkt, show_tabaddr)
    local first = true
    addString(s, name)
    if show_tabaddr == true then
        addString(s, tostring(pkt))
    end
    addString(s, "{")
    for k,v in pairs(pkt) do
        if first then
            first = false
        else
            addString(s, ",")
        end
        if type(v) == "table" then
            tab2str(s, "[\"" .. k .."\"]=", v, show_tabaddr)
        elseif type(v) == "string" then
            addString(s, "[\"" .. k .."\"]")
            addString(s, "=\"")
            addString(s, v)
            addString(s, "\"")
        else
            addString(s, "[\"" .. k .."\"]")
            addString(s, "=")
            addString(s, v)
        end
    end
    addString(s, "}")
end

function val2str(o, show_tabaddr)
    local valtype = type(o)
    if valtype == "table" then
        local s = newStack()
        tab2str(s, "", o, show_tabaddr)
        return table.concat(s)
    elseif valtype == "string" then
        local s = newStack()
        addString(s, "\"")
        addString(s, o)
        addString(s, "\"")
        return table.concat(s)
    else
        return tostring(o)
    end
end

function print_obj(oMsg)
    local oMsgStr = val2str(oMsg)
    local oMsgStrLen = string.len(oMsgStr)
    -- if oMsgStrLen > 500 and print(oMsgStr) will get coredump, @todo: need to be fixed
    if oMsgStrLen > 500 then
        print("oMsgStrLen:", oMsgStrLen)
        local oMsgStrLen_idx = 1
        while oMsgStrLen_idx <= oMsgStrLen do
            local oMsgStrLen_write = oMsgStrLen - oMsgStrLen_idx + 1
            if oMsgStrLen_write > 500 then
            oMsgStrLen_write = 500
        end
        print(string.sub(oMsgStr, oMsgStrLen_idx, oMsgStrLen_idx + oMsgStrLen_write - 1))
        oMsgStrLen_idx = oMsgStrLen_idx + oMsgStrLen_write
        end
    else
        print(oMsgStr)
    end
end

function getArg(...)
    local argc = 0
    local argv = {}

    for i = 1, select('#', ...) do

        local arg = select(i, ...)

        if arg == nil then
            argv[i] = tostring(nil)
        else
            argv[i] = arg
        end
    end
    argc = #argv

    return argc, argv
end

function getTimeByStr(str)
    -- str : hour:min:sec  09:01:00
    -- ret : value of os.time(XXX)
    local hour 
    local min
    local sec
    if string.sub(str, 2, 2) == ":" then
        hour = string.sub(str, 1, 1)
        min = string.sub(str, 3, 4)
        sec = string.sub(str, 6, 7)
    else
        hour = string.sub(str, 1, 2)
        min = string.sub(str, 4, 5)
        sec = string.sub(str, 7, 8)
    end
    local timeTable = os.date('*t', os.time())
    timeTable.hour = math.floor(hour)
    timeTable.min = math.floor(min)
    timeTable.sec = math.floor(sec)
    return os.time(timeTable)
end

function getTimeByStr2(str)
    -- str : hour:min:sec  20120704 09:01:00
    -- ret : value of os.time(XXX)
    local year = string.sub(str, 1, 4)
    local month = string.sub(str, 5, 6)
    local day = string.sub(str, 7, 8)
    local hour = string.sub(str, 10, 11)
    local min = string.sub(str, 13, 14)
    local sec = string.sub(str, 16, 17)
    local timeTable = {}
    timeTable.year = math.floor(year)
    timeTable.month = math.floor(month)
    timeTable.day = math.floor(day)
    timeTable.hour = math.floor(hour)
    timeTable.min = math.floor(min)
    timeTable.sec = math.floor(sec)
    return os.time(timeTable)
end

function Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function dump_obj(obj, key, sp, lv, st)
    sp = sp or '  '
    if type(obj) ~= 'table' then
        return sp..(key or '')..' = '..tostring(obj)..'\n'
    end
    local ks, vs, s= { mxl = 0 }, {}
    lv, st =  lv or 1, st or {}
    st[obj] = key or '.' -- map it!
    key = key or ''
    for k, v in pairs(obj) do
        if type(v)=='table' then
            if st[v] then -- a dumped table?
                table.insert(vs,'['.. st[v]..']')
                s = sp:rep(lv)..tostring(k)
                table.insert(ks, s)
                ks.mxl = math.max(#s, ks.mxl)
            else
                st[v] =key..'.'..k -- map it!
                table.insert(vs, dump_obj(v, st[v], sp, lv+1, st))
                s = sp:rep(lv)..tostring(k)
                table.insert(ks, s)
                ks.mxl = math.max(#s, ks.mxl)
            end
        else
            if type(v)=='string' then
                table.insert(vs,(('%q'):format(v):gsub('\\\10','\\n'):gsub('\\r\\n', '\\n')))
            else
                table.insert(vs, tostring(v))
            end
            s = sp:rep(lv)..tostring(k)
            table.insert(ks, s)
            ks.mxl = math.max(#s, ks.mxl);
        end
    end

    s = ks.mxl
    for i, v in ipairs(ks) do
        vs[i] = v..(' '):rep(s-#v)..' = '..vs[i]..'\n'
    end

    return '{\n'..table.concat(vs)..sp:rep(lv-1)..'}'
end

function CalDistance(x1,y1,x2,y2)
    return math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1))
end

function IsFinalGiftCanLvUp(human,kind)
    if kind > 11 or human.m_db.giftInfo[kind] ~= 0 then 
        return false
    end
    local enum = kind - 8
    local tag =1
    for i = 1,8 do
        if human.m_db.giftInfo[i] < enum * 10 then
            tag = 0
        end
    end
    return tag == 1
end


function IsValidServerName(serverName)
    if not serverName then 
        return false
    end

    local nameLen = #serverName
    if nameLen ~= 4 and nameLen ~= 5 then
        return false
    end

    if string.sub(serverName,1,1) ~= "[" then
        return false
    end

    if string.sub(serverName,-1) ~= "]" then
        return false
    end

    if string.find(Config.SVRNAME,"%"..serverName) == nil then
        return false
    end

    return true
end

--返回明天0点的时间戳
function GetNextDayTime()
    local t = os.date("*t", os.time());
    local nextDayTime = {year = t.year, month = t.month , day = t.day + 1, hour=0,min=0,sec=0}
    return os.time(nextDayTime) 
end

--返回当天0点的时间戳
function GetTodayTime(N)
    local t = os.date("*t", os.time());
    local todayTime = {year = t.year, month = t.month , day = t.day , hour=N or 0,min=0,sec=0}
    return os.time(todayTime) 
end

--检查是否是下一天
function CheckIsNextDay(oldTime,curTime)
    curTime = curTime or os.time()
    return os.date('%d',oldTime) ~= os.date('%d',curTime) 
end


local ck_step = 0
local ck_ms = 0
local ck_start = 0
local ck_name = ""
--重置计时
function clock_reset(clockName)
    ck_step = 0
    ck_ms = _CurrentTime()
    ck_start = ck_ms
    ck_name = clockName or ""
    print("")
end

function clock_step(stepName,printCost)
    local cost = _CurrentTime() - ck_ms
    ck_ms = ck_ms + cost
    ck_step = ck_step + 1
    if cost > printCost then
        print("ClockStep "..ck_name.."==>["..ck_step.."]"..(stepName or "").." cost:"..cost..",now:"..ck_ms)
    end
end
function clock_tick(tickName,printCost)
    local cost = _CurrentTime() - ck_start
    ck_ms = ck_start + cost
    ck_step = ck_step + 1
    if cost > printCost then
        print("ClockTick "..ck_name.."==>["..ck_step.."]"..(tickName or "").." cost:"..cost)
    end
end





local timeStart = 0
local timeStop = 0
function tick_start() 
    if Config.ISOPENMONITOR == true then
        aop_start()
        timeStart = _CurrentTime()
    end
end

function tick_end_timer(node)
    if Config.ISOPENMONITOR == true then
        timeStop = _CurrentTime()
        local cost = timeStop - timeStart
        if cost > 9 then
            _LOG_ERR("[TimeDispatch] " ..string.format('{"eventId":%d,"timerId":%d,"cost":%d}',
            node.eventID,node.timerID,cost))
           -- if cost >20 then
                aop_out()
           -- end
        end
    end
end

function tick_end_packet(packetId)
    if Config.ISOPENMONITOR == true then
        timeStop = _CurrentTime()
        local cost = timeStop - timeStart
        if cost > Config.MONITOR_MS then
            _LOG_ERR("[MsgDispatch] " ..string.format('{"packetId":%d,"cost":%d}',packetId or 0,cost))
            --if cost >20 then
                aop_out()
            --end
       end
    end
end

local aop_log = {}
local aop_fun = {}
local aop_deep = 0
local aop_deli = {}
function aop_start()
    if not next(aop_fun) then
        for k, v in pairs(package.loaded) do
            if type(v) == "table" then
                local pos = string.find(k,"%.")
                if pos and string.sub(k,1,pos-1) ~= "core" then                    
                    --print("aop==> "..k)
                    for m, n in pairs(v) do
                        if type(n) == "function" then
                            local f = function(...)
                                aop_deep = aop_deep + 1
                                local t1 = _USec()         
                                local ret = {n(...)} 
                                local t2 = _USec()         
                                if t2 - t1 > 100 then
                                    table.insert(aop_log,{aop_deep,aop_deli[aop_deep],k,m,t2-t1}) 
                                end
                                aop_deep = aop_deep - 1
                                return unpack(ret)
                            end
                            v[m] = f
                            aop_fun[f] = n
                        end
                    end
                end
            end
        end
        aop_deli = {}
        local deli = ""
        for i=1,50 do 
            table.insert(aop_deli,deli)
            deli = deli .. "\t"
        end
    end
    aop_log = {}
    aop_deep = 0
end

function aop_out()
    for k,v in ipairs(aop_log) do
        _LOG_ERR("[AOP_LOG] " .. table.concat(v,"\t"))
    end
    aop_log = {}
end

function aop_stop()
    if next(aop_fun) then
        for k, v in pairs(package.loaded) do
            for m, n in pairs(v) do
                if type(n) == "function" and aop_fun[n] then
                    v[m] = aop_fun[n] 
                end
            end
        end
        aop_fun = {}
        aop_deep = 0
    end
end

--将字符串转化为ascii码table，此函数配合GetStringFromtable使用
function mkStr2Ascii(str)
    local ret = {}
    for i=1,#str do
        ret[i] = string.byte(str,i)
    end
    return ret,#ret

end


-- 判断是否同一天
-- @param   epoch1    unix时间戳（秒）
-- @param   epoch2    unix时间戳（秒）
-- @return  true表示同一天
--          false表示不是同一天
function IsSameDate(epoch1, epoch2)
    local date1 = os.date("%x", epoch1)
    local date2 = os.date("%x", epoch2)
    return date1 == date2
end

-- Print anything - including nested tables
function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        table_print (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(tt .. "\n")
  end
end

function FillList( destList, srcList )
    for i = 1, #srcList do
        destList[i] = srcList[i]
    end
end

function GetTbNum(tb)
    local count = 0
    if tb then
        for _ in pairs(tb) do
            count = count + 1
        end
    end
    return count
end

function isInTable(tb,var)
    return table.foreach(tb,function(k,v)if v == var then return true end end)  
end

local Switch = 1
-- 普通输出
function Output(...)
    if type((select(2,...))) == "table" then 
        print("协议 = > ", (select(2,...)))
    else
        local str = ""
        for i,v in pairs{...} do str = str .. v end
        print(str)
    end
end

-- table深度输出
function DeepOutput(obj)
    if Switch == 1 then 
        if type(obj) == "table" then
            DeepOutput2(obj, 0) 
            print()
        elseif obj then Output(obj)
        end
    end
end
function DeepOutput2(tab, num)
    for i,v in pairs(tab) do
        if i ~= "_real_" then 
            if type(v) == "table" then
                Output(string.rep("    ", num), i, "  =>")
                DeepOutput2(v, num + 1) 
            else
                Output(string.rep("    ", num), i, "\t=", " ", v)
            end
        end
    end
end

-- 提示信息
function InformFrontTips(humanID,returnID,tipsMsg)
    DeepOutput(tipsMsg.tips)
    local tipsMsgRet = Dispatcher.ProtoContainer[PacketID.GC_RETURN_CODE]
    tipsMsgRet.id = returnID
    tipsMsgRet.retCode = tipsMsg.retCode
    tipsMsgRet.showWay = tipsMsg.showWay
    tipsMsgRet.content = tipsMsg.tips
    SendMsg(tipsMsgRet, humanID)
end


--随机角色名
function RandomRoleName(sex)
    local firstName = {'司马', '欧阳','端木','上官','独孤','夏侯','尉迟','赫连','皇甫','公孙','慕容','长孙','宇文','司徒','轩辕','百里','呼延','令狐','诸葛','南宫','东方','西门','李','王','张','刘','陈','杨','赵','黄','周','胡','林','梁','宋','郑','唐','冯','董','程','曹','袁','许','沈','曾','彭','吕','蒋','蔡','魏','叶','杜','夏','汪','田','方','石','熊','白','秦','江','孟','龙','万','段','雷','武','乔','洪','鲁','葛','柳','岳','梅','辛','耿','关','苗','童','项','裴','鲍','霍','甘','景','包','柯','阮','华','滕','穆','燕','敖','冷','卓','花','蓝','楚','荆'}
                
    local name1 = {'峰','不','近','小','千','万','百','一','求','笑','双','凌','伯','仲','叔','震','飞','晓','昌','霸','冲','志','留','九','子','立','小','云','文','安','博','才','光','弘','华','清','灿','俊','凯','乐','良','明','健','辉','天','星','永','玉','英','真','修','义','雪','嘉','成','傲','欣','逸','飘','凌','青','火','森','杰','思','智','辰','元','夕','苍','劲','巨','潇','紫','邪','尘'}
    local name2 = {'败','悔','南','宝','仞','刀','斐','德','云','天','仁','岳','宵','忌','爵','权','敏','阳','狂','冠','康','平','香','刚','强','凡','邦','福','歌','国','和','康','澜','民','宁','然','顺','翔','晏','宜','怡','易','志','雄','佑','斌','河','元','墨','松','林','之','翔','竹','宇','轩','荣','哲','风','霜','山','炎','罡','盛','睿','达','洪','武','耀','磊','寒','冰','潇','痕','岚','空'}
                                
    local wname1 = {'思','冰','夜','痴','依','小','香','绿','向','映','含','曼','春','醉','之','新','雨','天','如','若','涵','亦','采','冬','安','芷','绮','雅','飞','又','寒','忆','晓','乐','笑','妙','元','碧','翠','初','怀','幻','慕','秋','语','觅','幼','灵','傲','冷','沛','念','寻','水','紫','易','惜','诗','青','雁','盼','尔','以','雪','夏','凝','丹','迎','问','宛','梦','怜','听','巧','凡','静'}
    local wname2  = {'烟','琴','蓝','梦','丹','柳','冬','萍','菱','寒','阳','霜','白','丝','南','真','露','云','芙','筠','容','香','荷','风','儿','雪','巧','蕾','芹','柔','灵','卉','夏','岚','蓉','萱','珍','彤','蕊','曼','凡','兰','晴','珊','易','青','春','玉','瑶','文','双','竹','凝','桃','菡','绿','枫','梅','旋','山','松','之','亦','蝶','莲','柏','波','安','天','薇','海','翠','槐','秋','雁','夜'}
                                                
    local n1,n2,n3
    n1 = firstName[math.random(1,#firstName)]
    if sex == 1 then
        n2 = name1[math.random(1,#name1)]
        n3 = name2[math.random(1,#name2)]
    else
        n2 = wname1[math.random(1,#name1)]
        n3 = wname2[math.random(1,#name2)]
    end
    return n1 .. n2 .. n3
end

-- 判断一个时间点是否在今日以内
function isToday(dt)
    if not dt then return false end
    local s1 = os.date("%Y%m%d",os.time())
    local s2 = os.date("%Y%m%d",dt)
    return s1 == s2
end

function getToken(...)
	local str = os.time()
	for _,v in ipairs({...}) do
		str = str .. v
	end
	str = str .. _CurrentTime() 
	return _md5(str)
end

function deepCopy(ori_tab)
    if (type(ori_tab) ~= "table") then
        return nil;
    end
    local new_tab = {};
    for i,v in pairs(ori_tab) do
        local vtyp = type(v);
        if (vtyp == "table") then
            new_tab[i] = deepCopy(v);
        elseif (vtyp == "thread") then
            new_tab[i] = v;
        elseif (vtyp == "userdata") then
            new_tab[i] = v;
        else
            new_tab[i] = v;
        end
    end
    return new_tab;
end


--0xxxxxxx
--110xxxxx 10xxxxxx
--1110xxxx 10xxxxxx 10xxxxxx
--11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
--111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
--1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
--定义查找表，长度256，表中的数值表示以此为起始字节的utf8字符长度
UTFLEN =
{
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 1, 1
}

function utf2tb(str)
    local i = 1
    local index = 1
    local tb = {}
    local len = string.len(str)
    while (true) do
        if i > len then
            break
        end
        local c = string.sub(str,i,i)
        local j = i + UTFLEN[string.byte(c)]    
        local word = string.sub(str,i,j-1)
        tb[index] = word
        index = index + 1
        i = j
    end
    return tb 
end

function parseUrl(url)
	if not url or type(url) ~= "string" then
		return 
	end
	--?
	local params = Split(url,"?")[1]
	if not params then
		return
	end
	--&
	local ptb = Split(params,"&")
	if not ptb or not next(ptb) then return end
	local res = {}
	for _,v in pairs(ptb) do
		local p = Split(v,"=")
		if p[2] then
			p[2] = url_decode(p[2])
		end
		res[p[1]] = p[2] 
	end
	return res
end

function getTimeByString(str)
    -- str 格式 YYYYMMDDhhmmss
    local year = tonumber(string.sub(str,1,4))
    local month = tonumber(string.sub(str,5,6))
    local day = tonumber(string.sub(str,7,8))
    local hour = tonumber(string.sub(str,9,10)) or 0
    local min = tonumber(string.sub(str,11,12)) or 0
    local sec = tonumber(string.sub(str,13,14)) or 0
    local timeTable = {year = year, month = month , day = day, hour=hour,min=min,sec=sec}
    return os.time(timeTable),timeTable
end

function getToday0Clock(t)
	local ONE_DAY = 24 * 3600
	local ENGHT_HOUR = 8 * 3600
	return t - (t + ENGHT_HOUR)%ONE_DAY
end


return Util

