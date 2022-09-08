-- If we run from PC
if debug.upvalueid then goto OC end

-- If we run from OpenOS
if require then
  component = require'component'
  computer = require'computer'
else
  if not print then print = function()end end
end

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
    _G[v[1]:sub(1, 1):upper()] = component.proxy(v[2])
  end
end

sleep = os and os.sleep or function(t)
  local u = computer.uptime
  local d = u() + (t or 0)
  repeat computer.pullSignal(d - u())
  until u() >= d
end

::OC::

-----------------------------------------------------------------
-----------------------------------------------------------------
local getmetatable, setmetatable, print, rawget, type, table, pairs, rawset, tostring, next, load
    = getmetatable, setmetatable, print, rawget, type, table, pairs, rawset, tostring, next, load

local function sortByLen(t)
  table.sort(t, function(a,b)return#a<#b end)
end

-- Get first object field key by shortand
local function getKey(short, obj)
  local t,rgx = {},'^'..short:gsub('.','%1.*')
  for k in pairs(obj)do
    if type(k)=='string' and k:match(rgx) then t[#t+1] = k end
  end
  sortByLen(t)
  return t[1]
end

-- Get value from global
local function api(s, p)
  if p==nil then p = _G end
  local t,k = {}
  for c in s:gmatch'[^.]+' do
    if p==nil or type(p)=='function' then break end
    k = getKey(c, p)
    p = p[k]
    t[#t+1] = k
  end
  return p, table.concat(t,'.')
end

local shortened

local function shortFnc(f)
  return function(_, ...)
    -- print('-', _, ...)
    local result = table.pack(f(...))
    for k, v in pairs(result) do
      result[k] = shortened(v)
    end
    -- print('+', table.unpack(result))
    -- error('>calling>')
    return table.unpack(result)
  end
end

shortened = function(t)
  local tp = type(t)
  if tp ~= 'table' and tp ~= 'function' then return t end
  local old = getmetatable(t)
  -- print('old:',tp, t, old)
  if old and old.__short then return t end

  local mt = {
    __short = true,
    __call = shortFnc(t),
    __mul = shortFnc(t),
    __tostring = function() return '{short}'..tostring(t) end,
  }
  if tp == 'function' then
    return setmetatable({}, mt)
  end

  mt.__index = function(self, key)
    local exact = t[key]
    local v
    if exact ~= nil then
      v = exact
    else
      if key:match'^[A-Z]' then
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
    return shortened(v)
  end
  mt.__newindex = t
  mt.__pairs = function(_)
    return function(_, k)
      local k, v = next(t, k)
      return k, shortened(v)
    end, t, nil
  end
  mt.__len = function() return #t end

  return setmetatable({}, mt)
end

local transpile
local tab = 0

local __id = 0
local function nextID() __id=__id+1; return __id-1 end

local function transpileTabbed(str,from,to)
  return --[[ ('  '):rep(tab).. ]]transpile(str:sub(from, to)):gsub('\n', '\n'..('  '):rep(tab))
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

_MACROS = {}

local function addMacro(rgx, fnc_or_str)
  _MACROS[#_MACROS+1] = {rgx, fnc_or_str}
end

local function addCaptureMacro(prefix, fnc)
  addMacro(prefix..'(.-%b{})', captureGen(fnc))
end

addMacro('`T', [[~~Tg(){?!v{tr}}]]) -- Trade all trades
addMacro('`Z', [[a=`!a ;; ??`!Rm(3){ Rtn(a) c=`!Rm(3) Rtn(a) ??c{Rtn(a)Rm(3)} a=`!a}]]) -- Zig-Zag move
addMacro('`&', ' and ')
addMacro('`!', ' not ')

-- Add Macros
addCaptureMacro('@', addMacro)

-- Conditional
local function makeCondition(cond, body, falsy)
  return [[

local __if = (]].. cond ..[[)
if __if ]].. (falsy and [[and __if ~= '' and __if ~= 0 ]] or '') ..[[then
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
  return 'for '..i..'=1, R.inventorySize(), 1 do\n'..
    (haveP and 'if '..head..' then\n  ' or '')..
    body
  ..(haveP and '\nend' or '')..'\nend '
end)

-- Pairs
addCaptureMacro('~~', function (head, body)
  local id = nextID()
  body = replLetter(body, 'k', 'k'..id)
  body = replLetter(body, 'v', 'v'..id)
  return 'for k'..id..', v'..id..' in pairs('..head..') do\n'..body..'\nend '
end)

-- Loop
addCaptureMacro('~', function (head, body)
  local i = 'i'..nextID()
  body = replLetter(body, 'i', i)
  return 'for '..i..'='..head..', 1 do\n'..body..'\nend '
end)


-- global shortand
local function globFnc(r)
  local c = r:sub(1, 1)
  if c:match'[A-Z]' and _G[c] ~= nil then
    local res, way = api(r:sub(2), _G[c])
    return res and c..'.'..way or r
  end
  local res, way = api(r)
  return res and way or r
end
local globRgx = '%.('..WRD..('%.?[_%a%d]*'):rep(5)..')'
addMacro('^'..globRgx, globFnc)
addMacro('([^_%a%d%.])'..globRgx, function(p, r) return p..globFnc(r) end)

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
    -- print('lookup:', _MACROS[i][1])
    result = result:gsub(_MACROS[i][1], function(...)
      local v = _MACROS[i][2]
      return type(v)=='string' and v or v(...)
    end)
    i=i+1
  end
  tab = tab - 1
  return result
end


local __ENV = shortened(_ENV)
local function run(input)
  local code = transpile(input)
  if code == nil or code:match'^%s*$' then
    return
  end
  code = code:gsub('^%s*',''):gsub('%s*$',''):gsub('[%s\n]*\n','\n')
  print('\n'..code)
  local res, err = load(code, nil, nil, __ENV)
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
-- ~#Rc(i)>0{Rsel(i)Rd(0)}~1,5{IsFS(1,i)`T}

-- Test environment run
if debug.upvalueid then
  run[[
pt'\nFor pairs() test'

j=5
~~_G{??t*v=='table'{
  j=j-1
  ??j>0{
    pt('\n-- '..k..':')
    ~~v{
      i.w(' '..k)
    }
  }
}}

pt'\n\nSafe pointer and call'

?.io{write'Hello\n'}
?!__G{print}
;;]]
  os.exit(0)
end

-- Play music
local program = ({...})[1] or R.name()
for s in program:sub(1,5):gmatch"%S" do
  computer.beep(200 + s:byte() * 10, 0.05)
end
run(program)
