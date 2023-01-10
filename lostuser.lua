--[[

Lost User - simpliest robot

Author: Krutoy242

Source and readme:
https://github.com/Krutoy242/lostuser

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
    if _G[c]==nil then _G[c] = component.proxy(v[2]) end
  end
end

sleep = os and os.sleep or function(t)
  local u = computer.uptime
  local d = u() + (t or 0)
  repeat computer.pullSignal(d - u())
  until u() >= d
end

end

--- Signal that we have error
---@param err string
local function localError(err)
  if computer then computer.beep(1800, 1) end
  -- print(debug.traceback(err):sub(1, 200))
  error(debug.traceback(err):gsub('[ \t]*/LostUser/lostuser.lua:',''):sub(1, 400))
  -- os.exit(1)
end

local function __truthy(a)
  if not a or a == '' or a == 0 then return false end
  return true
end

local function TONUMBER(a)
  local t = type(a)
  if t=='number' then return a end
  if t=='string' then return tonumber(a) end
  return __truthy(a) and 1 or 0
end

--[[
 ██████╗    ████████╗ █████╗ ██████╗ ██╗     ███████╗
██╔═══██╗   ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝
██║   ██║█████╗██║   ███████║██████╔╝██║     █████╗
██║▄▄ ██║╚════╝██║   ██╔══██║██╔══██╗██║     ██╔══╝
╚██████╔╝      ██║   ██║  ██║██████╔╝███████╗███████╗
 ╚══▀▀═╝       ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
]]

local q, Q -- q(x) to turn Function / Table into Q

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

local function isCallable(t)
  local ty = type(t)
  if ty == 'function' then return true end
  if ty == 'table' then
    local mt = getmetatable(t)
    if mt and mt.__call then return true end
  end
  return false
end

--- Make call function
---@param f function
---@return function
local function QFnc(f)
  return function(_, ...) return Q(f(...)) end
end

local function isQ(t)
  local succes, mt = pcall(getmetatable, t)
  return succes and mt and mt.__q
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

--- For each t run f(k,v)
--- map({1,2,3}, (k,v)=>k,v*2) == {{1,2},{2,4},{3,6}}
---@param t table
---@param f function(k:integer, v:any): boolean
---@return table<integer, table<any,any>> f(k,v) will be wrapped into table
local function map(t, f)
  local r = {}
  for k, v in pairs(t) do
    -- r[k] = table.pack(f(k, v))
    r[k] = f(k, v)
  end
  return r
end

--- Generate helper functions
---@param target any Anything we targeting function to
---@param params string param names devided by comma
---@return function, boolean, boolean
local function getTarget(target, params)
  local trgFnc, trgCallable
  local trgType = type(target)
  if trgType == 'string' then
    trgFnc = makeRunedFunction(target, params)
    trgCallable = true
  else
    trgFnc = target
    trgCallable = isCallable(target)
  end
  return trgFnc, trgCallable, trgType == 'table'
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
    local res = f(k,q(v))
    if checkNil and res ~= nil or __truthy(res) then
      r[k] = v
    end
  end
  return q(r)
end

local function reducer(t, f)
  local pre,r
  for k, v in pairs(t) do
    if not pre then
      r = v
      pre = true
    else
      r = f(q(r), q(v))
    end
  end
  return r
end

--- Create new table
---@param length number length of new array
---@param val? any value to fill array with
---@return table<number, any>
local function newArray(length, val)
  local arr={}
  for i=1,length do arr[i] = val or i end
  return arr
end

--[[
███╗   ███╗████████╗
████╗ ████║╚══██╔══╝
██╔████╔██║   ██║
██║╚██╔╝██║   ██║
██║ ╚═╝ ██║   ██║
╚═╝     ╚═╝   ╚═╝
]]

--- Pack all parameters as q
Q = function(...)
  local r = {}
  for k, v in pairs(table.pack(...)) do r[k] = q(v) end
  return table.unpack(r)
end

--- Single value q(t)
q = function(t)
  local qtype = type(t)
  local qIsCallable = isCallable(t)
  if qtype ~= 'table' and not qIsCallable then return t end
  if isQ(t) then
    -- error(debug.traceback('Trying to Q(t) when t is already Q'))
    return t
  end

  --############################################################
  -- Generic operator
  --############################################################
  --- Compute operator result based on different targets
  ---@param op string operator identifier
  ---@return any
  local function generic(op)
    return function(self, target)
      local trgFnc, trgCallable, trgTable = getTarget(target, 'k,v')
      local r

      if qtype == 'table' then
        --?-- Table x Function|String
        if trgCallable then
          -- {1,2,3} x f => {f(1),f(2),f(3)}
          if     op=='map'    then r = map(self, trgFnc)
          elseif op=='reduce' then r = reducer(self, trgFnc)
          elseif op=='filter' then r = filter(t, trgFnc, false)
          elseif op=='strict' then r = filter(t, trgFnc, true)
          end

        --?-- Table x Table
        elseif trgTable then
          -- {a,b} x {c,d} => {{c(a), d(a)}, {c(b), d(b)}}
          -- if     op=='map'    then r = map(self, function(k,v) return map(target, v) end)
          if op=='lambda' then r = map(self, function(k,v) return function() return v(table.unpack(target)) end end)
          end

        --?-- Table x Number|Boolean
        else
          -- {1,2,3} x n => {n,n,n}
          if     op=='map'    then local u = {} for k in pairs(self) do u[k]=target end r = u
          elseif op=='lambda' then r = map(self, function(k,v) return function(...) return v(target, ...) end end)
          elseif op=='for'    then r = true for j=1, TONUMBER(target) do for k,v in pairs(self) do r = v(k,v) and r end end
          end

        end
      else

        --?-- Function x Function|String
        if trgCallable then
          -- f x g => f(g()) (Pipe)
          if op=='map' then r = function(...) return self(trgFnc(...)) end

          -- f x g => g(f()) (Reversed Pipe)
          elseif op=='lambda' then r = function(...) return trgFnc(self(...)) end
          end

        --?-- Function x Table
      elseif trgTable then
          -- f x {1,2,3} => f(1,2,3) (Unpack table)
          if op=='map' then r = self(table.unpack(target))
          end

        --?-- Function x Number|Boolean
        else
          -- f(...) x v => g(...) => f(v, ...) (Pipe)
          if     op=='map'    then r = function(...) return self(target, ...) end
          end

        end
      end
      return q(r)
    end
  end
  --############################################################

  local mt = {
    __q = true,
    __tostring = function() return '{q}'..(qIsCallable and tostring(t) or '#'..#t..': '..tostring(t)) end,

  -- 1 --
  -- [[ ^ ]] __pow = generic'??',

  -- 2 --
  -- [[ - ]] __unm = generic'??',
  -- [[ ~ ]] __bnot = generic'??',
  -- [[ # ]] __len = generic'??',

  -- 3 --
  --[[ * ]] __mul = generic'map',
  --[[ % ]] __mod = generic'reduce',
  --[[ / ]] __div = generic'filter',
  --[[// ]] __idiv = generic'strict',

  -- 4 --
  -- [[ + ]] __add = generic'??',
  -- [[ - ]] __sub = generic'??',

  -- 5 --
  -- [[ .. ]] __concat = generic'??',

  -- 6 --
  -- [[<< ]] __shl = generic'??',
  -- [[>> ]] __shr = generic'??',

  -- 7 --
  --[[ & ]] __band = generic'lambda',

  -- 8 --
  --[[ ~ ]] __bxor = generic'for',

  -- 9 --
  -- [[ | ]] __bor = generic'??',

  -- 10 --
  -- [[== ]] __eq = generic'??',
  -- [[ < ]] __lt = generic'??',
  -- [[<= ]] __le = generic'??',

  }

  -----------------------------------------------------------------
  --[[
    TODO: Possible need to implement
    - zip
    - compose
    - flat
  ]]
  -----------------------------------------------------------------

  if qIsCallable then
    -----------------------------------------------------------------
    -- t ^ u
    -- Call
    -----------------------------------------------------------------
    mt.__pow = QFnc(t)

    -----------------------------------------------------------------
    mt.__call = QFnc(t)
    return setmetatable({}, mt)
  end

  function mt:__index(key)
    local exact = t[key]
    if exact ~= nil then return q(exact) end

    local v

    -- Global key that started with _
    if key:sub(1,1) == '_' then
      -- Empty: _ is q()
      if #key == 1 then return q end

      -- Number: _8 create table {1,2,3,4,5,6,7,8}
      local subCommand = key:sub(2)
      local num = tonumber(subCommand)
      if num then v = newArray(num) end
      -- TODO: add functionality for q{}._
      -- TODO: add for _word

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

  -- When pairs, returned elements wrapped into q(v)
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

addMacro('ⓐ', ' and ')
addMacro('ⓞ', ' or ')
addMacro('ⓝ', ' not ')
addMacro('⒯', '(true)')
addMacro('⒡', '(false)')

-- Syntax Sugar
local WRD = '[_%a][_%a%d]*'
for _,c in pairs{'%+','%-'} do
  local from, to = '('..WRD..'[%._%a%d]*)('..c..')'..c, '(function() %1=TONUMBER(%1)%21 return %1 end)'
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
-- Lowest priority
-----------------------------------------------------------------

-- Exec
addMacro('!', '()')


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

__ENV.i = 0
local XExitLoop = false
run = function(input)
  local fnc, err = loadTranslated(input)
  local r
  while true do
    r = fnc()
    if isCallable(r) then r() end
    if XExitLoop then return end
    __ENV.i = __ENV.i + 1
  end
end

__ENV.X = function(...) XExitLoop = true print(...) end
__ENV.__truthy = __truthy

__ENV.TONUMBER = TONUMBER

__ENV.run = function(text)
  return loadTranslated(text)()
end

__ENV.proxy = proxy
__ENV.sleep = sleep

-- Get value from global
__ENV.api = function(s, p)
  if p==nil then p = _G end
  local t,k = {}
  for c in s:gmatch'[^.]+' do
    if p==nil or type(p)=='function' then break end
    k = getKey(c, p)
    p = p[k]
    t[#t+1] = k
  end
  return table.concat(t,'.')
end

-----------------------------------------------------------------
-- Assemble
-----------------------------------------------------------------

local cmd, prog = ...
local pointer = R or D

-- Program is called from shell
if cmd then prog = cmd

-- Program defined by Robot/Drone name
elseif pointer and pointer.name then prog = pointer.name() end

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

]]
