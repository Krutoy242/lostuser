--[[

Lost User - simpliest robot

Author: Krutoy242

Source and readme:
https://gist.githubusercontent.com/Krutoy242/1f18eaf6b262fb7ffb83c4666a93cbcc

]]

--[[
██╗███╗   ██╗██╗████████╗
██║████╗  ██║██║╚══██╔══╝
██║██╔██╗ ██║██║   ██║   
██║██║╚██╗██║██║   ██║   
██║██║ ╚████║██║   ██║   
╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   
]]

-- Forward declarations
local proxy, sleep, run, loadTranslated

-- If we run from PC
if not debug.upvalueid then

-- If we run from OpenOS
if require then
  component, computer = require'component', require'computer'
end
if not print then print = function(...)end end

proxy = function(name)
  local p = component.list(name)()
  return p and component.proxy(p) or nil
end

-- Define all components as big letter global, long names first
do
  local cmpList = {}
  for k, v in pairs(component.list()) do
    cmpList[#cmpList+1] = {v, k}
  end
  table.sort(cmpList, function(a,b)return#a[1]<#b[1] end)
  for _, v in pairs(cmpList) do
    local c = v[1]:sub(1, 1):upper()
    _G[c] = component.proxy(v[2])
  end
end

sleep = os and os.sleep or function(t)
  local u = computer.uptime
  local d = u() + (t or 0)
  repeat computer.pullSignal(d - u())
  until u() >= d
end

end

local function localError(err)
  if computer then computer.beep(800, 0.05) end
  -- error(debug.traceback(err))
end

local function __truthy(a)
  if not a or a == '' or a == 0 then return false end
  return true
end

--[[
 ██████╗    ████████╗ █████╗ ██████╗ ██╗     ███████╗
██╔═══██╗   ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝
██║   ██║█████╗██║   ███████║██████╔╝██║     █████╗  
██║▄▄ ██║╚════╝██║   ██╔══██║██╔══██╗██║     ██╔══╝  
╚██████╔╝      ██║   ██║  ██║██████╔╝███████╗███████╗
 ╚══▀▀═╝       ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
]]

local q -- q(x) to turn Function / Table into Q

--- Get first object field key by shortand
---@param short string
---@param obj table
---@return string
local function getKey(short, obj)
  local t,rgx = {},'^'..short:gsub('.','%1.*')
  for k in pairs(obj)do
    if type(k)=='string' and k:match(rgx) then t[#t+1] = k end
  end
  table.sort(t, function(a,b)return#a<#b end)
  return t[1]
end

--- Make call function
---@param f function
---@return function
local function QFnc(f)
  return function(_, ...)
    local result = table.pack(f(...))
    for k, v in pairs(result) do
      result[k] = q(v)
    end
    return table.unpack(result)
  end
end

local function isQ(t)
  local succes, mt = pcall(getmetatable, t)
  return succes and mt and mt.__q
end

local function isCallable(t)
  return type(t) == 'function' or isQ(t) -- TODO: fix if Q-table not actually callable
end

--- Generate safe function from lua code
---@param txt string Lua code to load as function body
---@param params string param names devided by comma
local function makeRunedFunction(txt, params)
  local loaded, err = loadTranslated(
    'function(...) local '.. params ..' = ... return '..txt..' end',
    txt
  )
  if err then
    localError(err)
    return q{}
  else
    return function(...)
      local safeResult = table.pack(pcall(loaded(), ...))
      if not safeResult[1] then
        localError(safeResult[2])
        return nil
      end
      return table.unpack(safeResult, 2)
    end
  end
end

--- For each t run f(v,k)
--- pack and return Qued result
---@param t table
---@param f function
local function packFor(t, f)
  local r,i = {},1
  for k, v in pairs(t) do
    -- local callable,f1,v1 = isCallable(f),f,v
    -- if not callable then f1,v1=v1,f1 end
    -- local resultTable = table.pack(f1(v1,k))
    -- TODO: should not call q(v) on v instead pairs(t) should return Q
    local resultTable = table.pack(f(q(v), k))
    if resultTable.n > 1 then
      resultTable.n = nil
      r[i] = q(resultTable)
    else
      r[i] = q(resultTable[1])
    end
    i=i+1
  end
  return q(r)
end

--- Generate helper functions
---@param target any Anything we targeting function to
---@param params string param names devided by comma
local function getTarget(target, params)
  local targetFnc, targetCallable
  if type(target) == 'string' then
    targetFnc = makeRunedFunction(target, params)
    targetCallable = true
  else
    targetFnc = target
    targetCallable = isCallable(target)
  end
  return targetFnc, targetCallable
end

--- Filter table.
--- Remove values for keys that not pass predicate
--- {1, '', 3, 0, foo = false, goo=true}  / 'a1' => {1, 3, goo=true}
--- {1, '', 3, 0, foo = false, goo=true} // 'a1' => {goo=true}
---@param t table
---@param p function
---@param checkNil boolean
local function filter(t, f, checkNil)
  local r = {}
  for k, v in pairs(t) do
    local res = f(q(v),k)
    if checkNil and res ~= nil or __truthy(res) then
      r[k] = v
    end
  end
  return q(r)
end

local function buildFilter(t, isTable, target, checkNil)
  local targetFnc, targetCallable = getTarget(target, 'v,k')

  if isTable then if targetCallable
    -- Table x (Function or String)
    then return filter(t, targetFnc, checkNil)

    -- Table x Table
    -- TODO: implement Table x Table filtering
    else return error('Could not Filter Table x Table')

    end
  else

    if targetCallable
    -- Function x (Function or String)
    -- TODO: implement Function x Function filtering
    then return error('Could not Filter Function x Function')

    -- Function x Table
    -- TODO: implement Function x Table filtering
    else return error('Could not Filter Function x Table')

    end
  end
end

local function reducer(t, f)
  local pre,r
  for k, v in pairs(t) do
    if not pre then
      r = q(v)
      pre = true
    else
      r = q(f(r, q(v)))
    end
  end
  return r
end

q = function(t)
  local qtype = type(t)
  local qIsFunction = qtype == 'function'
  if qtype ~= 'table' and not qIsFunction then return t end
  if isQ(t) then
    -- error(debug.traceback('Trying to Q(t) when t is already Q'))
    return t
  end

  local mt = {
    __q = true,
    __tostring = function() return '{q}'..(qIsFunction and tostring(t) or '#'..#t..': '..tostring(t)) end,
  }

  --
  -- t & u
  -- make a lambda function
  --
  function mt:__band(arg)
    return q(function(...) return t(arg, ...) end)
  end

  -----------------------------------------------------------------
  -- t * u
  -- Map t into u(t)
  -----------------------------------------------------------------
  function mt:__mul(target)
    local targetFnc, targetCallable = getTarget(target, 'v,k')

    if qtype == 'table' then if targetCallable
      -- Table x (Function or String)
      -- simple map, apply function or compiled string as function
      then return packFor(t, targetFnc)

      -- Table x Table
      -- {a,b} x {c,d} => {{c(a), d(a)}, {c(b), d(b)}}
      else return packFor(t, function(v,k) return packFor(target, v) end)

      end
    else

      if targetCallable
      -- Function x (Function or String)
      then return q(function(...) return targetFnc(t(...)) end)

      -- Function x Table
      -- f x {1,2,3} => {f(1), f(2), f(3)}
      else return packFor(target, t)

      end
    end
  end

  -----------------------------------------------------------------
  -- t / u
  -- Filter
  -----------------------------------------------------------------
  function mt:__div(target)
    return buildFilter(t, qtype == 'table', target, false)
  end

  -----------------------------------------------------------------
  -- t // u
  -- Filter strict
  -----------------------------------------------------------------
  function mt:__idiv(target)
    return buildFilter(t, qtype == 'table', target, true)
  end

  -----------------------------------------------------------------
  -- t % u
  -- Reduce
  -----------------------------------------------------------------
  function mt:__mod(target)
    local f, targetCallable = getTarget(target, 'a,b')
  
    if qtype == 'table' then if targetCallable
      -- Table x (Function or String)
      then return reducer(t, f)
  
      -- Table x Table
      -- TODO: implement Table x Table
      else return error('Could not reduce Table x Table')
  
      end
    else
  
      if targetCallable
      -- Function x (Function or String)
      -- TODO: implement Function x Function
      then return error('Could not reduce Function x Function')
  
      -- Function x Table
      -- TODO: implement Function x Table
      else return error('Could not reduce Function x Table')
  
      end
    end
  end

  -----------------------------------------------------------------
  --[[
    TODO: Possible need to implement
    - zip
    - compose
    - flat
  ]]
  --[[
     <     >     <=    >=    ~=    ==
     |
     ~
     &
     <<    >>
     ..
     +     -
     *     /     //    %
     unary operators (not   #     -     ~)
     ^
  ]]
  -----------------------------------------------------------------

  if qIsFunction then
    mt.__call = QFnc(t)
    return setmetatable({}, mt)
  end

  function mt:__index(key)
    local exact = t[key]
    if exact ~= nil then return q(exact) end

    local v

    -- Global key that started with _
    if key:sub(1,1) == '_' then
      -- Empty: _ global return function that just print output
      -- TODO: add functionality for q{}._
      if #key == 1 then v = function(...) print(...) end end
      
      -- Number: _8 create table {1,2,3,4,5,6,7,8}
      local subCommand = key:sub(2)
      local num = tonumber(subCommand)
      if num then
        local arr={}
        for i=1,num do arr[i]=i end
        v = arr
      end

    -- Big letter shortand
    elseif key:match'^[A-Z]' then
      local c = key:sub(1,1)
      local C = t[c]
      if C then
        v = C[getKey(key:sub(2), C)]
      end
    end

    -- Other cases
    if v == nil then
      v = t[getKey(key, t)]
    end

    return q(v)
  end
  mt.__newindex = t
  function mt:__pairs()
    return function(self, k)
      local k, v = next(t, k)
      return k, q(v)
    end, t, nil
  end
  function mt:__len() return #t end

  return setmetatable({}, mt)
end

--[[
████████╗██████╗  █████╗ ███╗   ██╗███████╗██╗      █████╗ ████████╗███████╗
╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ██╔══██╗╚══██╔══╝██╔════╝
   ██║   ██████╔╝███████║██╔██╗ ██║███████╗██║     ███████║   ██║   █████╗  
   ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██╔══██║   ██║   ██╔══╝  
   ██║   ██║  ██║██║  ██║██║ ╚████║███████║███████╗██║  ██║   ██║   ███████╗
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
]]

local _MACROS = {}
local tab = 0

local function translate(text)
  tab = tab + 1
  local result = text
  local i = 1
  while i <= #_MACROS do
    result = result:gsub(_MACROS[i][1], _MACROS[i][2])
    i=i+1
  end
  tab = tab - 1
  return result
end

local __id = 0
local function nextID() __id=__id+1; return __id-1 end

--[[
███╗   ███╗ █████╗  ██████╗██████╗  ██████╗ ███████╗
████╗ ████║██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝
██╔████╔██║███████║██║     ██████╔╝██║   ██║███████╗
██║╚██╔╝██║██╔══██║██║     ██╔══██╗██║   ██║╚════██║
██║ ╚═╝ ██║██║  ██║╚██████╗██║  ██║╚██████╔╝███████║
╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
]]

local function addMacro(rgx, fnc_or_str)
  _MACROS[#_MACROS+1] = {rgx, fnc_or_str}
end

-----------------------------------------------------------------
-- Simple replaces
-----------------------------------------------------------------

addMacro('`T', [[Tg!|'a1.tr!']]) -- Trade all trades
addMacro('`Z', [[a=`!a ;; ??`!Rm(3){ Rtn(a) c=`!Rm(3) Rtn(a) ??c{Rtn(a)Rm(3)} a=`!a}]]) -- Zig-Zag move
addMacro('`&', ' and ')
addMacro('`!', ' not ')

-- Syntax Sugar
local WRD = '[_%a][_%a%d]*'
for _,c in pairs{'%+','%-'} do
  local from, to = '('..WRD..'[%._%a%d]*)('..c..')'..c, '(function() %1=__number(%1)%21 return %1 end)'
  addMacro(from..c, to)
  addMacro(from, to..'()')
end

-- TODO: Add *= += and stuff

-----------------------------------------------------------------
-- Captures {}
-----------------------------------------------------------------

local function translateTabbed(str,from,to)
  return translate(str:sub(from, to)):gsub('\n', '\n'..string.rep('  ',tab))
end

local function captureGen(fnc)
  return function (r)
    local from,to = r:match'(){()'
    if not from then return '' end
    local head = r:sub(1, from-1)
    local body = translateTabbed(r, to, -2)
    if type(fnc)=='function' then return fnc(head, body) or ''
    else
      return fnc:gsub('HEAD', head):gsub('BODY', body)
    end
  end
end

local function addCaptureMacro(prefix, fnc)
  addMacro(prefix..'(.-%b{})', captureGen(fnc))
end

-- Add Macros
addCaptureMacro('@', addMacro)

-----------------------------------------------------------------
-- Conditionals
-----------------------------------------------------------------

local function makeCondition(cond, body, checkFalsy)
  return [[

local __if = (]].. cond ..[[)
if __if ]].. (checkFalsy and 'and __truthy(__if) ' or '') ..[[then
  ]].. body ..[[

end
]]
end

addCaptureMacro('?%?', makeCondition('HEAD', 'BODY', true)) -- Simple

-- Safe pointer
addCaptureMacro('?%.', [[
if type(HEAD)=='table' then
    HEAD.BODY
end
]])

-- Safe call
addCaptureMacro('?!', [[
local __p = HEAD
if type(__p)=='table' and (type(__p.BODY)=='table' or type(__p.BODY)=='function') then
  HEAD.BODY()
end
]])

-----------------------------------------------------------------
-- Loops
-----------------------------------------------------------------

local function replLetter(str, letter, to)
  return str
    :gsub('^'..letter..'([^_%a%d])', to..'%1')
    :gsub('([^_%a%d])'..letter..'$', '%1'..to)
    :gsub('([^_%a%d])'..letter..'([^_%a%d])', '%1'..to..'%2')
end

-- For Each inventory slot
addCaptureMacro('~#', function (head, body)
  local i = 'i'..nextID()
  body = replLetter(body, 'i', i)
  head = replLetter(head, 'i', i)
  local haveP = head ~= nil and not head:match"^%s*$"
  return 'for '..i..'=1, (D or R).inventorySize() do\n'
    ..(haveP and makeCondition(head, body, true) or body)
    ..'\nend '
end)

-- Pairs
addCaptureMacro('~:', function (head, body)
  local id = nextID()
  body = replLetter(body, 'k', 'k'..id)
  body = replLetter(body, 'v', 'v'..id)
  return 'for k'..id..', v'..id..' in pairs('..head..') do\n'..body..'\nend '
end)

-- Loop
addCaptureMacro('~~', function (head, body)
  local i = 'i'..nextID()
  body = replLetter(body, 'i', i)
  return 'for '..i..'='..head..', 1 do\n'..body..'\nend '
end)

-----------------------------------------------------------------
-- Lowest priority
-----------------------------------------------------------------

-- Exec
addMacro('!', '()')

-- -- Get value from global
-- local function api(s, p)
--   if p==nil then p = _G end
--   local t,k = {}
--   for c in s:gmatch'[^.]+' do
--     if p==nil or type(p)=='function' then break end
--     k = getKey(c, p)
--     p = p[k]
--     t[#t+1] = k
--   end
--   return p, table.concat(t,'.')
-- end

-- -- Global Shortand
-- local function globFnc(r)
--   local c = r:sub(1, 1)
--   if c:match'[A-Z]' and _G[c] ~= nil then
--     local res, way = api(r:sub(2), _G[c])
--     return res and c..'.'..way or r
--   end
--   local res, way = api(r)
--   return res and way or r
-- end
-- local globRgx = '%.('..WRD..('%.?[_%a%d]*'):rep(5)..')'
-- addMacro('^'..globRgx, globFnc)
-- addMacro('([^_%a%d%.])'..globRgx, function(p, r) return p..globFnc(r) end)

-----------------------------------------------------------------
-- Weird stuff
-----------------------------------------------------------------

-- Run only once
local is_first_run = true
function on_first_run(fnc)
  if is_first_run then fnc() is_first_run = false end
end
addMacro('(.+);;(.*)', function(once, rest)
  return 'on_first_run(function()\n  '..once..'\n  \nend)\n'..rest
end)

--[[
██╗      ██████╗  █████╗ ██████╗ 
██║     ██╔═══██╗██╔══██╗██╔══██╗
██║     ██║   ██║███████║██║  ██║
██║     ██║   ██║██╔══██║██║  ██║
███████╗╚██████╔╝██║  ██║██████╔╝
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ 
]]

-- Global environment inside loaded code
local __ENV = q(_G)

loadTranslated = function(text, chunkName)
  local code = translate(text)
  if code == nil or code:match('^%s*$') then
    localError('Unable to translate: '..text)
    return nil
  end
  code = code:gsub('[%s\n]*\n','\n'):gsub('^%s*',''):gsub('%s*$','')
  -- print('Code:',code)
  local res, err = load('return '..code, chunkName, nil, __ENV)
  if err then res, err = load(code, chunkName, nil, __ENV) end
  if err then localError(err) end
  return res, err
end

local XTerminated = false
run = function(input)
  local fnc, err = loadTranslated(input)
  local r
  while true do
    r = fnc()
    if isCallable(r) then r() end
    if XTerminated then return end
  end
end

__ENV.X = function(...) XTerminated = true print(...) end
__ENV.__truthy = __truthy

__ENV.__number = function(a)
  local t = type(a)
  if t=='number' then return a end
  if t=='string' then return tonumber(a) end
  return __ENV.__truthy(a) and 1 or 0
end

__ENV.run = function(text)
  return loadTranslated(text)()
end

__ENV.proxy = proxy
__ENV.sleep = sleep

-- Assemble --

-- Dump everything down and suck 4 slots from top then trade
-- ~#Rc*i{Rsel(i)Rd(0)}Rs(2)~~1,5{IsFS(1,i)`T}
-- ~#Rc*i{Rsel(i)Rd(0)}~~1,5{IsFS(1,i)}Rsk(3)~:Tg(){~~1,5{?!v{tr}}}

local cmd, prog, pointer = ...

-- Program is called from shell
if cmd then prog = cmd

-- Program defined by Robot/Drone name
elseif D then pointer = D elseif R then pointer = R end
if pointer and pointer.name then prog = pointer.name() end

if not prog or prog=='' then error'No program defined' end

-- Play music
if prog:sub(1,1) ~= ' ' then
  for s in prog:sub(1,5):gmatch"%S" do
    computer.beep(200 + s:byte() * 10, 0.05)
  end
end

return run(prog)

--[[


Some programs:
Dm(tb.u(Nf(300)[a++%2+1].p))s(3)~#{Dsel(i)Dd(0)Dsu(0)}
a++b=Nf(300)[a%2+1]Dm(tb.u(b.p))s(14)run(b.l)


Tg!|'a1.tr!'
~:Tg(){?!v{tr}}

]]
