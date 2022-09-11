-- local getmetatable, setmetatable, pairs, require, print, table, debug, type, error, tostring, load
--     = getmetatable, setmetatable, pairs, require, print, table, debug, type, error, tostring, load

-- 

--[[
Deploy script:

crunch --lz77 lostuser2.lua lostuser2.min.lua && flash -q lostuser2.min.lua LostUser

]]

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


-----------------------------------------------------------------
-----------------------------------------------------------------

-- Get first object field key by shortand
local function getKey(short, obj)
  local t,rgx = {},'^'..short:gsub('.','%1.*')
  for k in pairs(obj)do
    if type(k)=='string' and k:match(rgx) then t[#t+1] = k end
  end
  table.sort(t, function(a,b)return#a<#b end)
  return t[1]
end

local q

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
  return (type(t) == 'function' or isQ(t)) and getmetatable(t).__call ~= nil
end

--- For each t run f(v,k), pack and return Qued result
---@param t table
---@param f function
local function packFor(t,f)
  local r,i = {},1
  for k, v in pairs(t) do
    local callable,f1,v1 = isCallable(f),f,v
    if not callable then f1,v1=v1,f1 end
    local resultTable = table.pack(f1(v1,k))
    if #resultTable>1 or resultTable[1] == nil then
      r[i] = q(resultTable)
    -- elseif resultTable[1] ~= nil then
    else
      r[i] = resultTable[1]
    -- -- else r[i] = k
    end
    i=i+1
  end
  return q(r)
end

q = function(t)
  local qtype = type(t)
  local qIsFunction = qtype == 'function'
  if qtype ~= 'table' and not qIsFunction then return t end
  if isQ(t) then return t end

  local mt = {
    __q = true,
    __call = QFnc(t),
    __mul = QFnc(t),
    __tostring = function() return '{q}'..(qIsFunction and tostring(t) or '#'..#t..': '..tostring(t)) end,
    __band = function(self, ...) -- Make a function
      local args = table.pack(...)
      return q(function(k,v)
        return t(table.unpack(args))
      end)
    end,
    __bor = function(self, pipe_to) -- Pipe into function
      local pipe_is_callable = isCallable(pipe_to)

      -- Left side is table
      if qtype == 'table' then
        if pipe_is_callable then
          return packFor(t, pipe_to)

        else
          -- Both sides are tables
          return packFor(t, function(v,k) return packFor(pipe_to, v) end)

        end

      -- Left side is function
      else

        -- pipe_to is function
        if pipe_is_callable then
          return q(function(...) return pipe_to(t(...)) end)

        -- pipe_to is table
        else
          return packFor(pipe_to, t)
        end
      end
    end,
  }
  if qIsFunction then
    return setmetatable({}, mt)
  end

  function mt:__index(key)
    local exact = t[key]
    local v
    if exact ~= nil then
      v = exact
    else
      if key:sub(1,1) == '_' then
        -- Lodash
        local subCommand = key:sub(2)
        if subCommand == '' then
          v = function(...)
            print(...)
          end
        end
        local num = tonumber(subCommand)
        if num then
          local arr={}
          for i=1,num do arr[i]=i end
          v = arr
        end
      elseif key:match'^[A-Z]' then
        -- Big letter shortand
        local c = key:sub(1,1)
        local C = t[c]
        if C then
          local rest = key:sub(2)
          v = C[getKey(rest, C)]
        end
      end
      if v == nil then
        v = t[getKey(key, t)]
      end
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

local transpile
local tab = 0

local __id = 0
local function nextID() __id=__id+1; return __id-1 end

local function transpileTabbed(str,from,to)
  return transpile(str:sub(from, to)):gsub('\n', '\n'..string.rep('  ',tab))
end

local WRD = '[_%a][_%a%d]*'
local IFS = WRD..'[,_%a%d]*'

local function captureGen(fnc)
  return function (r)
    local from,to = r:match'(){()'
    if not from then return '' end
    local head = r:sub(1, from-1)
    local body = transpileTabbed(r, to, -2)
    if type(fnc)=='function' then return fnc(head, body) or ''
    else
      return fnc:gsub('HEAD', head):gsub('BODY', body)
    end
  end
end

local function replLetter(str, letter, to)
  return str
    :gsub('^'..letter..'([^_%a%d])', to..'%1')
    :gsub('([^_%a%d])'..letter..'$', '%1'..to)
    :gsub('([^_%a%d])'..letter..'([^_%a%d])', '%1'..to..'%2')
end

local _MACROS = {}

local function addMacro(rgx, fnc_or_str)
  _MACROS[#_MACROS+1] = {rgx, fnc_or_str}
end

local function addCaptureMacro(prefix, fnc)
  addMacro(prefix..'(.-%b{})', captureGen(fnc))
end

addMacro('`T', [[~:Tg(){?!v{tr}}]]) -- Trade all trades
addMacro('`Z', [[a=`!a ;; ??`!Rm(3){ Rtn(a) c=`!Rm(3) Rtn(a) ??c{Rtn(a)Rm(3)} a=`!a}]]) -- Zig-Zag move
addMacro('`&', ' and ')
addMacro('`!', ' not ')

-- Syntax Sugar
for _,c in pairs{'%+','%-'} do
  local from, to = '('..WRD..'[%._%a%d]*)('..c..')'..c, '(function() %1=__number(%1)%21 return %1 end)'
  addMacro(from..c, to)
  addMacro(from, to..'()')
end

-- Add Macros
addCaptureMacro('@', addMacro)

-- Conditional
local function makeCondition(cond, body, falsy)
  return [[

local __if = (]].. cond ..[[)
if __if ]].. (falsy and 'and __truthy(__if) ' or '') ..[[then
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

-- For Each inventory slot
addCaptureMacro('~#', function (head, body)
  local i = 'i'..nextID()
  body = replLetter(body, 'i', i)
  head = replLetter(head, 'i', i)
  local haveP = head ~= nil and not head:match"^%s*$"
  return 'for '..i..'=1, R.inventorySize(), 1 do\n'
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

-- Run only once
local is_first_run = true
function on_first_run(fnc)
  if is_first_run then fnc() is_first_run = false end
end
addMacro('(.+);;(.*)', function(once, rest)
  return 'on_first_run(function()\n  '..once..'\n  \nend)\n'..rest
end)

transpile = function(text)
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


local __ENV = q(_ENV)

-- __ENV._ = q(function(n) local a={} for i=1,n do a[i]=i end return a end)
__ENV.__truthy = function(a)
  if a and a ~= '' and a ~= 0 then return true end
  return false
end
__ENV.__number = function(a)
  local t = type(a)
  if t=='number' then return a end
  if t=='string' then return tonumber(a) end
  return __ENV.__truthy(a) and 1 or 0
end

local function run(input)
  local code = transpile(input)
  if code == nil or code:match'^%s*$' then return end
  code = code:gsub('^%s*',''):gsub('%s*$',''):gsub('[%s\n]*\n','\n')
  print(code)
  local res, err = load('return '..code, nil, nil, __ENV)
  if err then res, err = load(code, nil, nil, __ENV) end
  if err then
    print(err)
  else
    while not res() do
      if debug.upvalueid then os.exit(0) end
    end
  end
end


-- Assemble --

-- Dump everything down and suck 4 slots from top then trade
-- ~#Rc*i{Rsel(i)Rd(0)}Rs(2)~~1,5{IsFS(1,i)`T}
-- ~#Rc*i{Rsel(i)Rd(0)}~~1,5{IsFS(1,i)}Rsk(3)~:Tg(){~~1,5{?!v{tr}}}

-- Test environment run
-- if debug.upvalueid then
--   run[[
-- pt'\nFor pairs() test'

-- j=5
-- ~:_G{??t*v=='table'{
--   j=j-1
--   ??j>0{
--     pt('\n-- '..k..':')
--     ~:v{
--       i.w(' '..k)
--     }
--   }
-- }}

-- pt'\n\nSafe pointer and call'

-- ?.io{write'Hello\n'}
-- ?!__G{print}
-- ;;]]

if debug.upvalueid then
Dd = function(...) print('Dd',...) end
Dsu = function(...) print('Dsu',...) end
run[[
_4|(a+++|Dsu|Dd&a)
]]
end


if debug.upvalueid then os.exit(0) end

-- Play music
local cmd, prog = ...
if cmd then prog = cmd
elseif D then prog = D.name() elseif R then prog = R.name() end
if not prog then error'No program defined' end
for s in prog:sub(1,5):gmatch"%S" do
  computer.beep(200 + s:byte() * 10, 0.05)
end
run(prog)

