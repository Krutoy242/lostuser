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
local run, loadBody, q, Q

-- If we run from OpenOS
if require then
  component, computer = require'component', require'computer'
end

-- Define all components as big letter global, short names first
do
  local registered = {} -- Set of registered components
  for address, name in pairs(component.list()) do
    local c = name:sub(1, 1):upper()
    if _G[c]==nil or (registered[c] and #registered[c] > #name) then
      _G[c] = component.proxy(address)
      registered[c] = name
    end
  end
end
-- do
--   -- Expose all components as globals
--   for address, name in pairs(component.list()) do
--     _G[name] = component.proxy(address)
--   end
-- end


local function escape(s) return s:gsub('%%','%%%%') end

--- Signal that we have error
---@param err string
---@param skipTraceback? string
local function localError(err, skipTraceback)
  if computer then computer.beep(1800, 1) end
  error(
    -- Fix FML error
    -- [Client thread/ERROR] [FML]: Exception caught during firing event net.minecraftforge.client.event.ClientChatReceivedEvent@3e83e9ca:
    -- net.minecraft.util.text.TextComponentTranslationFormatException: Error parsing
    escape(
      skipTraceback and tostring(err) or debug.traceback(err)
    )
    -- tostring(err)
    -- :sub(1, 400)
    -- os.exit(1)
  )
end

--- Check if value is truthy
--- Falsy values is:
--- empty string, zero, NaN, result of /0
---@param a any
local function truthy(a)
  if not a or a == '' or a == 0 or a ~= a then return false end
  if type(a) == 'number' then
    local s = tostring(a)
    if s == 'inf' or s == '-inf' then return false end
  end
  return true
end

local function TONUMBER(a)
  local t = type(a)
  if t=='number' then return a end
  if t=='string' then return tonumber(a) end
  return truthy(a) and 1 or 0
end

--- Serialize value table
---@param t any
---@return string
local function serialize(t)
  if type(t)~='table' then return tostring(t) end
  local s=''
  for k,v in pairs(t) do s=s..(s==''and''or',')..tostring(k)..'='..tostring(v)end
  return s
end

--[[
███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████║██║
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
]]

--- Create new table
---@param length number length of new array
---@param val? any value to fill array with
---@return table<number, any>
local function newArray(length, val)
  local arr={}
  for i=1,length do arr[i] = val or i end
  return arr
end

--- For each t run f(k,v)
--- map({1,2,3}, (k,v)=>k,v*2) == {{1,2},{2,4},{3,6}}
---@param t table
---@param f function(k:integer, v:any): boolean
---@return table<integer, table<any,any>> f(k,v) will be wrapped into table
local function map(t, f)
  local r = {}
  for k, v in pairs(t) do
    r[k] = f(k, v)
  end
  return r
end

--- Filter table.
--- Remove values for keys that not pass predicate
--- {1, '', 3, 0, foo = false, goo=true}  / 'a1' => {1, 3, goo=true}
--- {1, '', 3, 0, foo = false, goo=true} // 'a1' => {goo=true}
---@param t table
---@param f function
---@param checkNil? boolean skip only if preducate returned nil
local function filter(t, f, checkNil)
  local r = {}
  for k, v in pairs(t) do
    local res = f(k,v)
    if checkNil and res ~= nil or truthy(res) then
      r[k] = v
    end
  end
  return q(r)
end

--- Turn table to one value
---@param t table
---@param f function
local function reduce(qt, f)
  local n,t = pairs(qt)
  local k1,r = n(t)
  for k, v in n,t,k1 do
    r = f(q(r), v)
  end
  return r
end

--- Loop to function
---@param self table
---@param trgFnc function
---@return boolean
local function loop(self, trgFnc)
  local r
  for j=1, math.maxinteger do
    if not truthy(trgFnc(j)) then
      return r
    end
    for k,v in pairs(self) do
      r = v(k,v) and r
    end
  end
  return r
end


--[[
 ██████╗    ████████╗ █████╗ ██████╗ ██╗     ███████╗
██╔═══██╗   ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝
██║   ██║█████╗██║   ███████║██████╔╝██║     █████╗
██║▄▄ ██║╚════╝██║   ██╔══██║██╔══██╗██║     ██╔══╝
╚██████╔╝      ██║   ██║  ██║██████╔╝███████╗███████╗
 ╚══▀▀═╝       ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
]]

--- Does this variable can be called
---@param t any
local function isCallable(t)
  local ty = type(t)
  if ty == 'function' then return true end
  if ty == 'table' then
    local mt = getmetatable(t)
    if mt and mt.__call then return true end
  end
  return false
end

--- Get first object field key by shortand
---@param short string
---@param obj table
---@param onlyTables? boolean keep only table results
---@return string
local function getKey(short, obj, onlyTables)
  local t,rgx = {},'^'..short:gsub('.','%1.*')
  for k,v in pairs(obj) do
    if type(k)=='string'
      and (not onlyTables or type(v) == 'table')
      and k:match(rgx)
    then
      t[#t+1] = k
    end
  end
  table.sort(t, function(a,b)
    local m,n=#a,#b
    return m==n and a:upper() < b:upper() or m<n
  end)
  return t[1]
end

--- Find value by key in table
---@param t table
---@param keyFull string
---@return any Queued value q(v)
local function index(t, keyFull)
  local exact = t[keyFull]
  if exact ~= nil then return q(exact) end

  local key,arg = keyFull:match'(.-)(%d*)$'

  -- Key ends with number - probably function call
  -- Ru3 => robot.use(3)
  if arg ~= '' then
    local f = index(t, key)
    if isCallable(f) then
      return Q(f(tonumber(arg)))
    end
  end

  -- Global key that started with _
  if key:sub(1,1) == '_' then
    -- Number: _8 create table {1,2,3,4,5,6,7,8}
    local subCommand = key:sub(2)
    local num = tonumber(subCommand)
    if num then return q(newArray(num)) end
    -- TODO: add functionality for q{}._
    -- TODO: add for _word

  -- Big letter shortand Tg => T.g
  elseif key:match'^[A-Z]' then
    local c = key:sub(1,1)
    local C = t[c]
    if C then
      return q(C[getKey(key:sub(2), C)])
    end
  end
  -- elseif #key > 1 and key:match'^[A-Z]' then
  --   local C, obj = key:sub(1,1)
  --   if t[C] ~= nil then
  --     obj = t[C]
  --   else
  --     obj = t[getKey(C:lower(), t, true)]
  --   end
  --   if obj then
  --     return index(obj, key:sub(2))
  --   end
  -- end

  -- Other cases
  return q(t[getKey(key, t)])
end

local function isQ(t)
  local succes, mt = pcall(getmetatable, t)
  return succes and mt and mt.__q
end

local function safeCall(f, ...)
  local safeResult = table.pack(pcall(f, ...))
  if not safeResult[1] then localError(safeResult[2]) end
  return table.unpack(safeResult, 2)
end

--- Generate safe function from lua code
---@param txt string Lua code to load as function body
---@param params string param names devided by comma
local function makeRunedFunction(txt, params)
  local p1,p2 = 'return function(...) local '.. params ..' = ... ',txt..' end'
  local loaded = loadBody(p1..'return '..p2, p1..p2, txt)
  return function(...) return safeCall(loaded(), ...) end
end

--- Generate helper functions
---@param target any Anything we targeting function to
---@param params string param names devided by comma
---@return function, boolean, boolean
local function getTarget(target, params)
  local tt = type(target)
  local trgFnc
  if tt == 'string' then
    trgFnc = makeRunedFunction(target, params)
  elseif isCallable(target) then
    trgFnc = target
  end
  return trgFnc, tt == 'table'
end

--- Make call function
---@param f function
---@return function
local function QFnc(f)
  return function(_, ...) return Q(f(...)) end
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
  if (qtype ~= 'table' and not qIsCallable) or isQ(t) then return t end

  --############################################################
  -- Generic operator
  --############################################################
  --- Compute operator result based on different targets
  ---@param op string operator identifier
  ---@return any
  local function generic(op)
    return function(self, target)
      local trgFnc, trgTable = getTarget(target, 'k,v')
      local r

      if not qIsCallable then
        --?-- Table x Function|String
        if trgFnc then
          if     op=='map'    then r = map(self, trgFnc) -- {1,2,3} x f => {f(1),f(2),f(3)}
          elseif op=='reduce' then r = reduce(self, trgFnc)
          elseif op=='filter' then r = filter(self, trgFnc, false)
          elseif op=='strict' then r = filter(self, trgFnc, true)
          elseif op=='loop'   then r = loop(self, trgFnc)
          end

        --?-- Table x Table
        elseif trgTable then
          if     op=='map'    then r = map(target, function(k,v) return self[v] end) -- {1,2,3} x {1,3} => {1,3}
          elseif op=='lambda' then r = map(self, function(k,v) return function() return v(table.unpack(target)) end end)
          end

        --?-- Table x Number|Boolean
        else
          if     op=='map'    then local u = {} for k in pairs(self) do u[k]=target end r = u -- {1,2,3} x n => {n,n,n}
          elseif op=='lambda' then r = map(self, function(k,v) return function(...) return v(target, ...) end end)
          elseif op=='loop'   then r = loop(self, function(j) return j <= TONUMBER(target) end) -- TODO: Loop actually should call other function f(k,v), not call each element of Table
          end

        end
      else
        --?-- Function x Function|String
        if trgFnc then
          if     op=='map'    then r = function(...) return self(trgFnc(...)) end -- f x g => f(g()) (Pipe)
          elseif op=='lambda' then r = function(...) return trgFnc(self(...)) end -- f x g => g(f()) (Reversed Pipe)
          elseif op=='loop'   then r = loop({self}, trgFnc)
          end

        --?-- Function x Table
        elseif trgTable then
          if     op=='map'    then r = self(table.unpack(target)) -- f x {1,2,3} => f(1,2,3) (Unpack table)
          elseif op=='lambda' then r = map(target, self) -- reversed map f x {a,b,c} => {f(a),f(b),f(c)}
          end

        --?-- Function x Number|Boolean
        else
          if     op=='map'    then r = QFnc(self)(self, target) -- f*1 => f(1)
          elseif op=='lambda' then r = function(...) return self(target, ...) end
          elseif op=='loop'   then r = loop({self}, function(j) return j <= TONUMBER(target) end)
          end

        end
      end
      return q(r)
    end
  end
  --############################################################

  local mt = {
    __q = true,
    __tostring = function() return '{q}'..(qIsCallable and tostring(t) or '{'..serialize(t)..'}') end,

  -- 1 --
  -- [[ ^ ]] __pow = generic'??',

  -- 2 --
  -- [[ - ]] __unm = generic'??', -- Filter falsy
  -- [[ ~ ]] __bnot = generic'??', -- Probably filter nulls
  -- [[ # ]] __len = generic'??', -- Probably tostring()

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
  --[[ ~ ]] __bxor = generic'loop',

  -- 9 --
  -- [[ | ]] __bor = generic'??',

  -- 10 --
  -- [[== ]] __eq = generic'??',
  -- [[ < ]] __lt = generic'??',
  -- [[<= ]] __le = generic'??',

  }

  -----------------------------------------------------------------
  --[[
    Possible need to implement:
    - zip
    - flat
    - gsub
  ]]
  -----------------------------------------------------------------

  if qIsCallable then
    mt.__pow = QFnc(t)
    mt.__call = QFnc(t)
    return setmetatable({}, mt)
  end

  function mt:__index(key)
    return index(t, key)
  end

  -- Possibilities for __newindex:
  -- a.b='func(k,v)'
  -- a._={}
  -- _5='k,v'
  function mt:__newindex(k, v)
    rawset(t, k, q(v))
  end

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

--- Replace all macroses
---@param text string
local function translate(text)
  local result = text
  local i = 1
  while i <= #_MACROS do
    result = result:gsub(_MACROS[i][1], _MACROS[i][2])
    i=i+1
  end
  return result
end

local function loadTranslated(text)
  local code = translate(text)
  if code == nil or code:match('^%s*$') then
    localError('Unable to translate: '..text)
    return nil
  end
  return loadBody('return '..code, code, text)
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
addMacro('ⓡ', ' return ')
addMacro('⒯', '(true)')
addMacro('⒡', '(false)')
addMacro('∅', ' __trash=')

-- -- Syntax Sugar
-- local WRD = '[_%a][_%a%d]*'
-- for _,c in pairs{'%+','%-'} do
--   local from, to = '('..WRD..'[%._%a%d]*)('..c..')'..c, '(function() %1=TONUMBER(%1)%21 return %1 end)'
--   addMacro(from..c, to)
--   addMacro(from, to..'()')
-- end

-- -- TODO: Add *= += and stuff

-----------------------------------------------------------------
-- Captures {}
-----------------------------------------------------------------
addMacro('(`.+`)', function (r)
  for s in r:gmatch'[^`]+' do
    addMacro(escape(s:sub(1, 1)), escape(s:sub(2)))
  end
  return ''
end)

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

loadBody = function(code1, code2, chunkName)
  local res, err = load(code1, chunkName, nil, __ENV)
  if err then
    res, err = load(code2, chunkName, nil, __ENV)
  end
  if err then localError(err) end
  return res
end

__ENV.i = 0
__ENV.l = true
local XKeepLoop = true
run = function(input)
  local fnc = loadTranslated(input)
  while XKeepLoop do
    -- Recursively call functions that returned
    local function unfold(f)
      for _,v in pairs({safeCall(f)}) do
        if isCallable(v) then unfold(v) end
      end
    end
    unfold(fnc)
    __ENV.i = __ENV.i + 1
    __ENV.l = not __ENV.l
  end
end

__ENV.write = function(...)
  XKeepLoop = false
  if print then return print(...) end
  localError(tostring(q{...}), true)
end
-- __ENV.truthy = truthy
-- __ENV.TONUMBER = TONUMBER
-- __ENV.proxy = function(name)
--   local p = component.list(name)()
--   return p and component.proxy(p) or nil
-- end
__ENV.sleep = function(t)
  local u = computer.uptime
  local d = u() + (t or 1)
  repeat computer.pullSignal(d - u())
  until u() >= d
end

--- Helper function
__ENV._ = q(function(target)
  local trgFnc, trgTable = getTarget(target, 'k,v')
  return q(trgFnc or target)
end)

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

if not prog or prog=='' then localError'No program defined' end

-- Play music
if prog:sub(1,1) ~= ' ' then
  for s in prog:sub(1,5):gmatch"%S" do
    computer.beep(math.min(2000, 200 + s:byte() * 10), 0.05)
  end
end

return run(prog)
