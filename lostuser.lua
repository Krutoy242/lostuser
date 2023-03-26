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
local pack, unpack, run, loadBody, q, Q = table.pack, table.unpack

---MINIFY{{
-- If we run from OpenOS
if require then
  component, computer = require'component', require'computer'
end
---}}

-- Define all components as big letter global, short names first
do
  local registered = {} -- Set of registered components
  for address, name in pairs(component.list()) do
    local C,p = name:sub(1, 1):upper(),component.proxy(address)
    _G[name] = _G[name] or p
    if _G[C]==nil or (registered[C] and #registered[C] > #name) then
      _G[C] = p
      registered[C] = name
    end
  end
end
-- do
--   -- Expose all components as globals
--   for address, name in pairs(component.list()) do
--     _G[name] = component.proxy(address)
--   end
-- end


--- Remove `%` symbol from chat log since its cause an error FML error
--- [Client thread/ERROR] [FML]: Exception caught during firing event net.minecraftforge.client.event.ClientChatReceivedEvent@3e83e9ca:
--- net.minecraft.util.text.TextComponentTranslationFormatException: Error parsing
local function escape(s) return s:gsub('%%','%%%%') end

--- Signal that we have error
---@param err string
---@param skipTraceback? string
local function localError(err, skipTraceback)
  if computer then computer.beep(1800, 0.5) end
  error(escape(
    tostring(err)
    -- skipTraceback and tostring(err) or debug.traceback(err)
  ), 1)
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
  if t=='number' or t=='string' then return tonumber(a) end
  return truthy(a) and 1 or 0
end

--- Serialize value table
---@param t any
---@return string
local function serialize(t)
  if type(t)~='table' then return tostring(t) end
  local s,keys='',{}
  local function append(l) s=s..(s==''and''or',')..l end
  for i=1,#t do append(tostring(t[i]))keys[i]=true end
  for k,v in pairs(t) do if not keys[k] then append(tostring(k)..'='..tostring(v)) end end
  return s
end

--- Create new table with members from first one plus second one
--- If second table not provided - just copy forst one
---@param a table
---@param b? table
---@return string
-- local function merge(a,b)
--   local t = {}
--   for k, v in pairs(a) do t[k] = v end
--   if b then
--     for k, v in pairs(b) do t[k] = v end
--   end
--   return t
-- end

--[[
███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████║██║
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
]]

--- Create new table
---@param from integer first value
---@param length integer length of new array
---@return table<integer, any>
local function newArray(from, length)
  local arr={}
  for i=from,length-(1-from) do arr[i] = i end
  return arr
end

--- Filter table.
--- Remove values for keys that not pass predicate
--- {1, '', 3, 0, foo = false, goo=true}  / 'a1' => {1, 3, goo=true}
--- {1, '', 3, 0, foo = false, goo=true} // 'a1' => {goo=true}
--- For each t run f(k,v)
--- map({1,2,3}, (k,v)=>k,v*2) == {{1,2},{2,4},{3,6}}
---@param t table
---@param f function(k:integer, v:any): boolean
---@param isFilter? boolean filter instead of map
---@return table<any, any> f(k,v) will be wrapped into table
local function map(t, f, isFilter)
  local r = {}
  for k, v in pairs(t) do
    local res = f(k,v)
    if isFilter then
      if truthy(res) then r[k] = v end
    else
      r[k] = res
    end
  end
  return r
end

--- Loop to function
---@param self any Function or table of functions
---@param isTbl boolean if `self` is table
---@param trgFnc function
---@return boolean
local function loop(self, isTbl, trgFnc)
  local r
  for j=1, math.maxinteger do
    if not truthy(trgFnc(j)) then return r end
    if isTbl then
      for k,v in pairs(self) do
        r = v(k,v)
      end
    else
      r = self(j)
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

--- Turn table of tables into table [[1,2],[3,4]] => [1,2,3,4]
---@param t table
local function flatten(t)
  local r = {}
  for k, v in pairs(t) do
    if type(v) == 'table' and not isCallable(v) then
      for k, v in pairs(v) do
        r[#r+1] = v
      end
    else
      r[#r+1] = v
    end
  end
  return r
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

  -- Global key that started with _
  if keyFull:sub(1,1) == '_' then
    -- Number: _8 create table {1,2,3,4,5,6,7,8}
    local numStr = keyFull:sub(2)
    local num = tonumber(numStr)
    if num then
      return q(newArray((numStr:sub(1,1)=='0') and 0 or 1, num))
    end
    -- TODO: add functionality for q{}._
    -- TODO: add for _word
  end

  local key,arg = keyFull:match'(.-)(%d*)$'

  -- Key ends with number - probably function call
  -- Ru3 => robot.use(3)
  if arg ~= '' then
    local f = index(t, key)
    if isCallable(f) then
      return Q(f(tonumber(arg)))
    end

  -- -- Big letter shortand Tg => T.g
  -- elseif key:match'^[A-Z]' then
  --   local c = key:sub(1,1)
  --   local C = t[c]
  --   if C then
  --     return q(C[getKey(key:sub(2), C)])
  --   end
  -- end
  elseif key:match'^[A-Z]' then
    local C, obj = key:sub(1,1)
    if t[C] ~= nil then
      obj = t[C]
    else
      obj = t[getKey(C:lower(), t, true)]
    end
    if obj then
      return #key == 1 and q(obj) or index(obj, key:sub(2))
    end
  end

  -- Other cases
  return q(t[getKey(key, t)])
end

local function isQ(t)
  local succes, mt = pcall(getmetatable, t)
  return succes and mt and mt.__q
end

local function safeCall(f, ...)
  local safeResult = pack(pcall(f, ...))
  if not safeResult[1] then localError(safeResult[2]) end
  return unpack(safeResult, 2)
end

--- Generate safe function from lua code
---@param txt string Lua code to load as function body
---@param params string param names devided by comma
local function makeRunedFunction(txt, params)
  local p1, p2 = 'return function(...)local '.. params ..'=... ', txt..' end'
  return function(...) return safeCall(
    loadBody(p1..'return '..p2, p1..p2, txt, ...)(), ...
  ) end
end

--- Generate helper functions
---@param target any Anything we targeting function to
---@param params? string param names devided by comma
---@return function, boolean
local function getTarget(target, params)
  local tt = type(target)
  local trgFnc
  if tt == 'string' then
    trgFnc = makeRunedFunction(target, params or 'k,v')
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
  for k, v in pairs(pack(...)) do r[k] = q(v) end
  return unpack(r)
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
    return function(source, target)

      -- Determine sides
      local swap
      if type(source) ~= 'table' then
        source, target = target, source
        swap = true
      end

      local trgFnc, trgTable = getTarget(target)
      local r

      if not qIsCallable then
        --?-- Table x Function|String
        if trgFnc then
          if op=='map' then
            r = map(source, trgFnc)

          elseif op=='lambda' then
            r = map(source, trgFnc, true)

          elseif op=='loop' then
            r = loop(source, true, trgFnc)

          end

        --?-- Table x Table
        elseif trgTable then
          if op=='map' then
            r = map(target, function(k,v) return source[v] end) -- _{4,5,6}^{3,1} -- {6,4}

          elseif op=='lambda' then
            r = map(source, function(k,v) return function() return v(unpack(target)) end end)

          --elseif op=='loop' then r = nil -- TODO: Implement, probably merge, union, intersection
          -- _{1,2,a=3}~{a=4,5,6} => {1,2,3,4,5,6}
          -- _2~_3 => {1,2,1,2,3}

        end

        --?-- Table x Number|Boolean
        else
          if op=='map' then
            local u = {} for k in pairs(source) do u[k]=target end r = u

          elseif op=='lambda' then
            if swap then
              r = source[target % #source + 1]
            else
              source[target] = nil; r = source
            end

          elseif op=='loop' then
            r = loop(source, true, function(j) return j <= TONUMBER(target) end) -- TODO: Loop actually should call other function f(k,v), not call each element of Table

          end

        end
      else
        --?-- Function x Function|String
        if trgFnc then
          if op=='map' then
            r = function(...) return source(trgFnc(...)) end

          elseif op=='lambda' then
            r = function(...) return trgFnc(source(...)) end

          elseif op=='loop' then
            r = loop(source, false, trgFnc)

          end

        --?-- Function x Table
        elseif trgTable then
          if op=='map' then
            r = source(unpack(target)) -- f x {1,2,3} => f(1,2,3) (Unpack table)

          elseif op=='lambda' then
            r = map(target, source) -- reversed map f x {a,b,c} => {f(a),f(b),f(c)}

          --elseif op=='loop' then r = nil -- TODO: Implement

          end

        --?-- Function x Number|Boolean
        else
          if op=='map' then
            r = QFnc(source)(source, target)

          elseif op=='lambda' then
            if swap then
              r = function(...) return source(..., target) end
            else
              r = function(...) return source(target, ...) end
            end

          elseif op=='loop' then
            r = loop(source, false, function(j) return j <= TONUMBER(target) end)

          end

        end
      end
      return q(r)
    end
  end

  --- Compute unary operator result based on different targets
  ---@param op string operator identifier
  ---@return any
  local function unary(op)
    return function(source)

      local r

      if not qIsCallable then
        --?-- Table
        if op=='lambda' then
          r = flatten(t)
        -- elseif op=='map' then
        --   r = map(t, function(k,v)return truthy(v) end, true)
        end
      else
        --?-- Function
        if op=='lambda' then
          repeat until not truthy(source())
        end
      end
      return q(r)
    end
  end
  --############################################################

  local mt = {
    __q = true,
    __tostring = function() return '_'..(qIsCallable and tostring(t) or '{'..serialize(t)..'}') end,
  }

  -- 1 --
  --[[ ^ ]] mt.__pow = generic'map'

  -- 2 --
  -- [[ - ]] mt.__unm = generic'map'
  --[[ ~ ]] mt.__bnot = unary'lambda'
  -- [[ # ]] mt.__len = generic'??' -- Probably `tostring()` OR `flat()`

  -- 3 --
  -- [[ * ]] mt.__mul = generic'??'
  -- [[ % ]] mt.__mod = generic'??'
  --[[ / ]] mt.__div = generic'lambda'
  -- [[// ]] mt.__idiv = generic'??'

  -- 4 --
  -- [[ + ]] mt.__add = generic'??'
  --[[ - ]] mt.__sub = mt.__div -- lambda

  -- 5 --
  --[[ .. ]] mt.__concat = generic'loop'

  -- 6 --
  -- [[<< ]] mt.__shl = generic'??'
  -- [[>> ]] mt.__shr = generic'??'

  -- 7 --
  --[[ & ]] mt.__band = mt.__pow -- map

  -- 8 --
  --[[ ~ ]] mt.__bxor = mt.__concat -- loop

  -- 9 --
  --[[ | ]] mt.__bor = mt.__div -- lambda

  -- 10 --
  -- [[ < ]] mt.__lt = generic'??'
  -- [[<= ]] mt.__le = generic'??'
  -- [[== ]] mt.__eq = generic'??'

  -----------------------------------------------------------------
  --[[
    Possible need to implement:
    - zip
    - flat
    - gsub
  ]]
  -----------------------------------------------------------------

  if qIsCallable then
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
  -- if code == nil or code:match('^%s*$') then
  --   localError('Unable to translate: '..text)
  --   return nil
  -- end
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

--- Attempt to load code1 or code2
---@param code1 string
---@param code2 string
---@param chunkName string
loadBody = function(code1, code2, chunkName, ...)
  local t

  -- If we have table parameters that need to be exposed
  -- add them to upvalue
  local expose = pack(...)
  if expose.n > 0 then
    t = q{}
    for k, v in pairs(__ENV) do t[k] = v end
    for k, v in pairs(expose) do
      if type(v) == 'table' then
        for k, v in pairs(v) do t[k] = v end
      end
    end
    -- for k, v in pairs(t) do print(' '..k)end
  else
    t = __ENV
  end

  -- Load
  local res, err = load(code1, chunkName, nil, t)
  if err then
    res, err = load(code2, chunkName, nil, t)
  end
  return err and localError(err) or res
end

__ENV.i = 0

-- Recursively call functions that returned
local function unfold(f)
  local r = pack(safeCall(f))
  for i=1,r.n do
    if r[i] and isCallable(r[i]) then unfold(r[i]) end
  end
  return r
end

---MINIFY{{
local runOnce
---}}
run = function(input)
  local fnc = loadTranslated(input)
  while true do
    local r = unfold(fnc)
    ---MINIFY{{
    if runOnce then return unpack(r) end
    ---}}
    __ENV.i = __ENV.i + 1
    if __ENV.i % 100 == 99 then __ENV.sleep(0.05) end
  end
end

__ENV.write = function(...)
  ---MINIFY{{
  if print then runOnce = true return print(...) end
  ---}}
  localError(q{...}, true)
end

__ENV.sleep = function(t)
  local u = computer.uptime
  local d = u() + (t or 1)
  repeat computer.pullSignal(d - u())
  until u() >= d
end

--- Helper function
__ENV._ = function(target)
  local trgFnc, trgTable = getTarget(target)
  return q(trgFnc or target)
end

-- Get value from global
__ENV.api = function(s, p)
  return __ENV.write(getKey(s, p or _G))
end

-----------------------------------------------------------------
-- Assemble
-----------------------------------------------------------------

local pointer, prog = R or D

---MINIFY{{
local shellArg
shellArg, runOnce = ...

-- Program is called from shell
if shellArg then prog = shellArg end
---}}

-- Program defined by Robot/Drone name
if pointer and pointer.name then prog = pointer.name() end

if not prog or prog=='' then localError'No program defined' end

-- Play music
if not shellArg and prog:sub(1,1) ~= ' ' then
  for s in prog:sub(1,5):gmatch"%S" do
    computer.beep(math.min(2000, 200 + s:byte() * 10), 0.05)
  end
end

return run(prog)
