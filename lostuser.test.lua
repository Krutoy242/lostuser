--[[

Test file for LostUser program

Author: Krutoy242

Source and readme:
https://github.com/Krutoy242/lostuser

]]

--[[

■ Preperations:
oppm install crunch

■ Deploy script:
crunch --lz77 lostuser.lua lostuser.min.lua && flash -q lostuser.min.lua LostUser

■ Download and write
wget -f https://raw.githubusercontent.com/Krutoy242/lostuser/main/lostuser.min.lua && flash -q lostuser.min.lua LostUser

■ Download and test
wget -f https://raw.githubusercontent.com/Krutoy242/lostuser/main/lostuser.lua && wget -f https://raw.githubusercontent.com/Krutoy242/lostuser/main/lostuser.test.lua && lostuser.test

]]

local lu
local gpu = require('component').gpu

-- Present only when running on host machine under test/oc-emu.lua
local isEmu, emu = pcall(require, 'ocemu')
emu = isEmu and emu or nil

print'\n< LostUser tests >\n'

--[[
████████╗███████╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║
   ██║   ██╔══╝  ╚════██║   ██║
   ██║   ███████╗███████║   ██║
   ╚═╝   ╚══════╝╚══════╝   ╚═╝
]]
local function serialize(val, name)
  local s = ''

  if name then s = s .. name .. "=" end

  if type(val) == "table" then
    s = s .. "{"

    local i = 1
    for k, v in pairs(val) do
      s =  s.. (i==1 and '' or ',') .. serialize(v, i ~= k and k or nil)
      i = i + 1
    end

    s = s .. "}"
  elseif type(val) == "number" then
    s = s .. tostring(val)
  elseif type(val) == "string" then
    -- s = s .. string.format("%q", val)
    s = s .. val
  elseif type(val) == "boolean" then
    s = s .. (val and "true" or "false")
  else
    s = s .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end

  return s
end

local function argsToString(...)
  local t = table.pack(...)
  t.n = nil
  local s,f = '',true
  for k,v in pairs(t) do
    s = s .. (f and '' or ' ') .. serialize(v)
    f = false
  end
  return s
end

local _print = type(print) == 'function' and print or print.print
local printedMessage = ''
_G.print = setmetatable({
  print = _print
}, {
  __call = function(self, ...)
    -- _print('>>',...)
    if table.pack(...).n == 0 then return end
    printedMessage = printedMessage
      -- .. (printedMessage ~= '' and '\n' or '')
      .. argsToString(...)
  end
})

local function shouldError(errorRgx, ...)
  local args = {...}
  return function()
    local succes, result = pcall(lu, table.unpack(args))
    return (not succes)
      and result
      and errorRgx
      and result:match(errorRgx)
    , result
  end
end

local function shouldPrint(command, message, loopCount)
  return function()
    local succes, result = pcall(lu, command, loopCount or 1000)
    if not succes then return false, result end
    return printedMessage == message, printedMessage
  end
end

local function shouldOutput(command, message, loopCount)
  return function()
    local succes, result = pcall(lu, command, loopCount or 1)
    local resultStr = tostring(result)
    if not succes then return false, resultStr end
    return resultStr == message, resultStr
  end
end

local function shouldRaise(command, message, loopCount)
  return function()
    local succes, result = pcall(lu, command, loopCount or 1)
    local resultStr = tostring(result)
    if succes then return false, 'returned ' .. resultStr end
    return resultStr == message, resultStr
  end
end

local function toVisibleString(str)
  return tostring(str):gsub(' ', '·')--[[ :gsub('\n', '⤶') ]]
end

local function test(description, fn)
  gpu.setForeground(0x005599)
  io.write('■ ')
  gpu.setForeground(0x999999)
  io.write(description..': ')
  local succes, result = fn()
  if emu then emu.total = emu.total + 1 end
  if succes then
    gpu.setForeground(0x009955)
    io.write('✔')
  else
    if emu then emu.fails = emu.fails + 1 end
    gpu.setForeground(0xdd5555)
    io.write('❌\n> ❪' .. toVisibleString(result).. '❫')
  end
  gpu.setForeground(0xffffff)
  io.write('\n')
  printedMessage = ''
end


--[[
██████╗ ██╗   ██╗███╗   ██╗
██╔══██╗██║   ██║████╗  ██║
██████╔╝██║   ██║██╔██╗ ██║
██╔══██╗██║   ██║██║╚██╗██║
██║  ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
]]

lu = loadfile'lostuser.lua'

-- test('  Run without args', shouldError('No program defined'))
-- test('        Empty name', shouldError('No program defined', ''))
-- test('      Expose error', shouldError('^.+: Test Error', ' error"Test Error"'))
-- test('   Global shortand', shouldError('^.+: Exit', ' e"Exit"'))
-- test('     Parsing error', shouldError('^.+: attempt to concat', ' w(c..d)'))

_G.T = {
  {name='n1', index=1},
  {name='n2', take=true},
  {name='n3', take=0, index=3},
  getTrades = function() return {
    {trade=function()return 't','u' end, isEnabled=function()return false end},
    {trade=function()return 'v','w' end, isEnabled=function()return true end},
  } end,
  exp=function(a,b) return a^b end,
}
_G.trading = _G.T

local mi = 0
_G.R = {
  move =function(n)print(({[0]='🡣','🡡','🡠','🡢'})[n] or '⁇') mi=mi+1 return mi % 3 ~= 0 end,
  swing=function(n)print(({[0]='⇓','⇑','⇐','⇒'})[n] or '⁇') return true end,
}

test('        Replaces', shouldOutput("ⓡ⒯ⓐⓝ⒡ⓞ⒡", 'true'))
test('    Shortand  _3', shouldOutput("_3", '_{1,2,3}'))
test('    Shortand _13', shouldOutput("_013", '_{0=0,1,2,3,4,5,6,7,8,9,10,11,12}'))
test('    Shortand  _a', shouldOutput("_{_a(4),a,type(_a(_'Ru3'))==type(a),os._a^3,os.a}", '_{4,4,true,3,3}'))
test('    Shortand  i5', shouldPrint("print(i5)", '1234512', 7))
test('   Ordered Pairs', shouldOutput("_{1,[0]=2,3,c05=4,c4=5}", '_{0=2,1,3,c4=5,c05=4}'))
test('Table num getter', shouldOutput("_{tostring(T5)==tostring(Tg),T6==nil}", '_{true,true}'))
test('            t(f)', shouldOutput("Tg0'tr!'", '_{t,v}'))
test('         Globals', shouldOutput([[_{_"_a(3),_'a*_b(2),b'()"()}]], '_{3,6,2}'))
test('            long', shouldRaise("long'Od0'", 'os.date(0)'))

test('             n^t', shouldOutput("2^_{4,5,6}", '5'))
test('             n/t', shouldOutput("5/_{2,3,4}", '4'))
test('             n~f', shouldPrint("3~Rm", '⁇⁇⁇', 1))
test('             n/f', shouldOutput("(4/Te)(3)", '81.0'))

test('             t^f', shouldOutput("Tg!^'tr!'", '_{t,v}'))
test('             t^n', shouldOutput("_{1,[3]=3,a=6,[4]=4}^5", '_{1,3=3,4=4,5=5,a=6}'))
test('             t/f', shouldOutput("(T/'tk')^'n'", '_{2=n2}'))
test('             t/n', shouldOutput("_3-2", '_{1,3=3}'))

test('             f^n', shouldOutput("Te/3&4", '81.0'))
test('             f^t', shouldOutput("Te^{4,5}", '1024.0'))
test('             f/t', shouldOutput("'e/3&4'/T", '81.0'))
test('             f~n', shouldPrint("Rm~3", '🡡🡠🡢', 1))
test('             f~f', shouldPrint("_'print(k)'~'Rm3'", '🡢1🡢2🡢', 1))

test('              -t', shouldOutput("_{'a','b','c'}", '_{a,b,c}'))
test('              ~t', shouldOutput("~~_{1,{2,3},{4,a=5,b=_{6,c=7}}}", '_{1,2,3,4,5,6,7}'))
test('              -f', shouldOutput("a=-_'k,v'ⓡ_{a(0),a(1),a(2),a(false),a(nil,true)}", '_{1,0,0,1,1}'))
test('              ~f', shouldPrint("~(Rm/2)", '🡠🡠🡠', 1))
test('              #f', shouldOutput("f=_'2,3,k'ⓡ_{f&4,#f&4}", '_{2,_{2,3,4}}'))


_G.G = {
  scan = function(x,z)
    print(string.format('s(%d,%d)',x,z))
    local t={}for i=1,64 do t[i]=(i+x+z)%4/4-0.5 end
    return t
  end,
}
local offset = 2
_G.D = {
  move = function(x,y,z)print(string.format('m(%g,%g,%g)',x,y,z))offset=2 end,
  place= function(side)print(string.format('p(%d)',side)) return false end,
  suck = function(n)print(({[0]='⮋','⮉','⮈','⮊'})[n]) return true end,
  drop = function(n)print(({[0]='⤓','⤒','⇤','⇥'})[n]) return true end,
  select=function(n)print(string.format('sel(%d)',n)) end,
  getOffset=function()print(string.format('Ô',n)) offset=offset-0.5 return offset end,
}
test('       Drone geo', shouldPrint(
  "x,z=i%8,i%64//8ⓡ_'Dm(x,0,z)s(0.05)Dp(0)Dm(-x,0,-z)s(0.05)'~(Gsn(x,z)[32]==0)",
  's(0,0)s(1,0)s(2,0)m(2,0,0)p(0)m(-2,0,0)s(3,0)',
  4
))

_G.N = {
  findWaypoints = function(dist)print(string.format('find(%g)',dist))return {
    {position={10,0,0}, redstone=0 , label="Dsk/0~4"},
    {position={20,1,0}, redstone=0 , label="Dsk/0~4"},
    {position={30,2,0}, redstone=15, label="_'Dsel(k)Dd(0)'~4"},
  } end,
}
test(' Drone waypoints', shouldPrint(
  "P=i/Nf300ⓡDm^Pp,s/0~'Dg!>1',_(Pl)",
  'find(300)m(10,0,0)ÔÔ⮋⮋⮋⮋'..
  'find(300)m(20,1,0)ÔÔ⮋⮋⮋⮋'..
  'find(300)m(30,2,0)ÔÔsel(1)⤓sel(2)⤓sel(3)⤓sel(4)⤓'..
  'find(300)m(10,0,0)ÔÔ⮋⮋⮋⮋',
  4
))

--[[
██████╗ ███████╗ █████╗ ██████╗ ███╗   ███╗███████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝
██████╔╝█████╗  ███████║██║  ██║██╔████╔██║█████╗
██╔══██╗██╔══╝  ██╔══██║██║  ██║██║╚██╔╝██║██╔══╝
██║  ██║███████╗██║  ██║██████╔╝██║ ╚═╝ ██║███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚══════╝

Everything below checks that the readme keeps telling the truth:
every operator combination from its tables, every rule from
`Shortening`, and every program from `Examples`.
]]

test('             t^t', shouldOutput('_{4,5,6}^{3,1}', '_{6,4}'))
test('             f^f', shouldOutput("(_'k*2'^_'k+1')&3", '8'))
test('             f/f', shouldOutput("(_'k*2'/_'k+1')&3", '7'))
test('             f/n', shouldOutput("(_'k^v'/3)&4", '81.0'))
test('     map aliases', shouldOutput("_{_{1,2}^'v*2',_{1,2}+'v*2',_{1,2}&'v*2'}", '_{_{2,4},_{2,4},_{2,4}}'))
test('  lambda aliases', shouldOutput("_{_3/'v%2',_3-'v%2',_3|'v%2'}", '_{_{1,3=3},_{1,3=3},_{1,3=3}}'))
test('    loop aliases', shouldPrint("_'print(k)'~2,_'print(k)'*2", '1212', 1))
test(' Call uncallable', shouldOutput("_{1,2,3}'0'", '_{0,0,0}'))
test('          Truthy', shouldOutput("_{1,0,'','x',1/0,-1/0,0/0,false,true}/'v'", '_{1,4=x,9=true}'))
test('     Lodash  _08', shouldOutput('_08', '_{0=0,1,2,3,4,5,6,7}'))
test('     Lodash b._a', shouldOutput('b={}ⓡ_{b._a^3,b.a}', '_{3,3}'))
test('  Lodash _a func', shouldOutput("_{type(_a'k'),a&5}", '_{table,5}'))
test('    Error safe _', shouldOutput("_{_'error(1)'!}", '_{}'))
test('  Return unfolds', shouldPrint("_'print(1)',print(2)", '21', 1))
test('       i counter', shouldPrint('print(i)', '012', 3))

--[[
 ██████╗ ██████╗ ███╗   ███╗██████╗  ██████╗ ███╗   ██╗███████╗███╗   ██╗████████╗███████╗
██╔════╝██╔═══██╗████╗ ████║██╔══██╗██╔═══██╗████╗  ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
██║     ██║   ██║██╔████╔██║██████╔╝██║   ██║██╔██╗ ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
██║     ██║   ██║██║╚██╔╝██║██╔═══╝ ██║   ██║██║╚██╗██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
╚██████╗╚██████╔╝██║ ╚═╝ ██║██║     ╚██████╔╝██║ ╚████║███████╗██║ ╚████║   ██║   ███████║
 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
]]

--- Full in-game method lists, from the OC sources.
--- A shorthand like `Rsel` or `Dg0` is resolved by sorting every key of a
--- component, so one missing or extra method points it at another method.
local componentMethods = {
  robot = [[
    address compare compareFluid compareFluidTo compareTo count detect drain
    drop durability fill getLightColor inventorySize move name place select
    selectTank setLightColor slot space suck swing tankCount tankLevel
    tankSpace transferFluidTo transferTo turn type use
  ]],
  drone = [[
    address compare compareFluid compareFluidTo compareTo count detect drain
    drop fill getAcceleration getLightColor getMaxVelocity getOffset
    getStatusText getVelocity inventorySize move name place select selectTank
    setAcceleration setLightColor setStatusText slot space suck swing tankCount
    tankLevel tankSpace transferFluidTo transferTo type use
  ]],
  inventory_controller = [[
    address areStacksEquivalent compareStackToDatabase compareStacks
    compareToDatabase dropIntoItemInventory dropIntoSlot equip getAllStacks
    getInventoryName getInventorySize getItemInventorySize getSlotMaxStackSize
    getSlotStackSize getStackInInternalSlot getStackInSlot isEquivalentTo slot
    store storeInternal suckFromItemInventory suckFromSlot type
  ]],
  navigation = 'address findWaypoints getFacing getPosition getRange slot type',
  geolyzer = 'address analyze canSeeSky detect isSunVisible scan slot store type',
  generator = 'address count insert remove slot type',
  crafting = 'address craft slot type',
  piston = 'address isSticky pull push slot type',
  trading = 'address getTrades slot type',
  -- Not a component - object returned by `trading.getTrades()`
  trade = 'getInput getMerchantId getOutput isEnabled trade type',
}

--- Wrap `fnc` so every call is printed as `name(args)`
local function logged(name, fnc)
  return function(...)
    local t, s = table.pack(...), ''
    for i = 1, t.n do
      s = s .. (i == 1 and '' or ',') .. (type(t[i]) == 'table' and '{}' or tostring(t[i]))
    end
    print(name .. '(' .. s .. ')')
    if fnc then return fnc(...) end
    return true
  end
end

--- Component with every method of its type, each one printing its call
---@param name string key of `componentMethods`
---@param impl? table method -> implementation, for methods that must return something
local function component(name, impl)
  local c = {}
  for method in componentMethods[name]:gmatch'%S+' do
    c[method] = logged(method, impl and impl[method])
  end
  return c
end

local installed = {}

--- Expose components as globals the same way the BIOS does it:
--- full name first, then the first letter, shortest component name first.
---@param spec table component name -> implementation overrides
local function install(spec)
  for _, name in ipairs(installed) do
    _G[name], _G[name:sub(1,1):upper()] = nil, nil
  end
  installed = {}
  for name in pairs(spec) do installed[#installed+1] = name end
  table.sort(installed, function(a, b) return #a == #b and a < b or #a < #b end)
  for _, name in ipairs(installed) do _G[name:sub(1,1):upper()] = nil end
  for _, name in ipairs(installed) do
    local C = name:sub(1,1):upper()
    _G[name] = component(name, spec[name])
    _G[C] = _G[C] or _G[name]
  end
end

--- Expected trace of a call repeated for `j = from, to`, `%d` replaced with `j`
local function seq(fmt, from, to)
  local s = ''
  for j = from, to do s = s .. (fmt:gsub('%%d', tostring(j))) end
  return s
end

--[[
███████╗██╗  ██╗ ██████╗ ██████╗ ████████╗███████╗███╗   ██╗
██╔════╝██║  ██║██╔═══██╗██╔══██╗╚══██╔══╝██╔════╝████╗  ██║
███████╗███████║██║   ██║██████╔╝   ██║   █████╗  ██╔██╗ ██║
╚════██║██╔══██║██║   ██║██╔══██╗   ██║   ██╔══╝  ██║╚██╗██║
███████║██║  ██║╚██████╔╝██║  ██║   ██║   ███████╗██║ ╚████║
╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝
]]

install{ robot = {} }

test('      Rule 1 R.u', shouldPrint('R.use(3)', 'use(3)', 1))
test('      Rule 3  Rs', shouldRaise("long'Rs'", 'R.slot'))
test('      Rule 3 Rse', shouldRaise("long'Rse'", 'R.space'))
test('     Rule 3 Rsel', shouldRaise("long'Rsel'", 'R.select'))
test('      Rule 4  Ru', shouldPrint('Ru3,Ruse(3)', 'use(3)use(3)', 1))
test('      Rule 5 s10', shouldRaise("long's10'", 'sleep(10)'))
test('      Rule 5 R16', shouldPrint('R16&5', 'select(5)', 1))
test('   Numeric  dict', shouldPrint('R1&3,R14&3', 'use(3)swing(3)', 1))
test('        _ string', shouldPrint("_'Rm,s2'!(0)", 'move(0)', 1))

--[[
███████╗██╗  ██╗ █████╗ ███╗   ███╗██████╗ ██╗     ███████╗███████╗
██╔════╝╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗██║     ██╔════╝██╔════╝
█████╗   ╚███╔╝ ███████║██╔████╔██║██████╔╝██║     █████╗  ███████╗
██╔══╝   ██╔██╗ ██╔══██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝  ╚════██║
███████╗██╔╝ ██╗██║  ██║██║ ╚═╝ ██║██║     ███████╗███████╗███████║
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝╚══════╝
]]

test('       TLDR  use', shouldPrint('robot.use(3)', 'use(3)', 1))
test('       TLDR swng', shouldPrint('robot.swing(3)', 'swing(3)', 1))
test('  Statement+expr', shouldPrint('a = robot.move(3) return a and robot.use(0)', 'move(3)use(0)', 1))

local offset = 2
install{
  navigation = {
    findWaypoints = function() return {
      {position={10,0,0}, redstone=0 , label="_'Dsk0'~2"},
      {position={20,1,0}, redstone=15, label="Dsel-'Dd0'~2"},
    } end,
  },
  drone = {
    move = function() offset = 2 end,
    getOffset = function() offset = offset - 0.5 return offset end,
  },
}

test('  Ex.  waypoints', shouldPrint(
  "_P(i/Nf300),Dm^Pp,s/1~'Dg0>1',_(Pl)",
  'findWaypoints(300)move(10,0,0)getOffset(0)getOffset(0)suck(0)suck(0)'..
  'findWaypoints(300)move(20,1,0)getOffset(0)getOffset(0)select(1)drop(0)select(2)drop(0)',
  2
))
test('  Ex. suck label', shouldPrint("_'Dsk0'~4", ('suck(0)'):rep(4), 1))
test('  Ex. drop label', shouldPrint("Dsel-'Dd0'~4", seq('select(%d)drop(0)', 1, 4), 1))

-- Robot is blocked on every third move, so `~f` loops have an end
local moves = 0
install{ robot = { move = function() moves = moves + 1 return moves % 3 ~= 0 end } }

test('  Ex.    zig-zag', shouldPrint(
  "~_m'Rm3,Ru0',_t(Rtn/(i2>1))!,_'m!,t!'!ⓞt/m",
  ('move(3)use(0)'):rep(3)..'turn(false)move(3)use(0)turn(false)'..
  ('move(3)use(0)'):rep(2)..'turn(true)move(3)use(0)turn(true)',
  2
))

install{ robot = {}, inventory_controller = {} }

test('  Ex. rune maker', shouldPrint(
  "_8/'R16^v,v==7ⓐ{s8,Rm1,Rd(3,1),Rm0}ⓞ{Ie!,Ru3,Ie!}'",
  seq('select(%d)equip()use(3)equip()', 1, 6)..
  'select(7)move(1)drop(3,1)move(0)'..
  'select(8)equip()use(3)equip()',
  1
))

install{
  robot = { detect = function() return true, 'solid' end },
  inventory_controller = {},
}

test('  Ex.  tree farm', shouldPrint(
  '#(1|#Rdt&3)<6ⓐRsw/3-s/1-Rsk/0-Ie-Ru/3-IeⓞRu3,s',
  'detect(3)swing(3)suck(0,1)equip(true)use(3,true)equip(true)',
  1
))

install{ robot = {}, generator = {} }

test('  Ex.      miner', shouldPrint("Gi,_'Rsw3,Rm3'~(i//2*5),Rtn⒯", 'turn(true)insert()', 1))

install{
  robot = {},
  inventory_controller = {
    getInventorySize = function() return 4 end,
    getStackInInternalSlot = function() return {maxDamage=100} end,
  },
}

test('  Ex. drop  sort', shouldPrint(
  'Rd|3%2^(IsF(0,i%Igz0+1)ⓐIgSII!.mDⓞ2)',
  'getInventorySize(0)suckFromSlot(0,1)getStackInInternalSlot()drop(3.0)',
  1
))

local uses = 0
install{
  robot = { use = function() uses = uses + 1 return uses < 3 end },
  inventory_controller = {},
}

test('  Ex.   cat  fur', shouldPrint(
  "Rsk/3&16ⓐIe!,~_'Ru0',_16/Rc|R16/'Rd1'",
  'suck(3,16)equip()'..('use(0)'):rep(3)..
  seq('count(%d,%d)', 1, 16)..
  seq('select(%d,%d)drop(1)', 1, 16),
  1
))

install{
  robot = { count = function() return 9 end },
  inventory_controller = {},
  crafting = {},
}

local grid = ''
for _, slot in ipairs{1,2,3,5,6,7,9,10,11} do
  grid = grid .. ('transferTo(%d,1.0)'):format(slot)
end

test('  Ex.   compress', shouldPrint(
  "-(_16-Rc&12)|'Rd3'&R16,IsF/3/'_11/8/4&Rc!/9/RtT'|i81,Cc",
  seq('count(%d,%d)', 1, 16)..
  seq('select(%d,%d)drop(3)', 1, 11)..
  'select(12,17)drop(3)'..
  seq('select(%d,%d)drop(3)', 13, 16)..
  'suckFromSlot(3,1)count()'..grid..'craft()',
  1
))

install{
  robot = { drop = function() return false end },
  inventory_controller = {
    getStackInSlot = function() return {maxSize=1, name='sword'} end,
  },
  piston = {},
}

test('  Ex. unstackble', shouldPrint(
  "(IgSI/3&_a^i1728ⓞ{}).mS^_{_'IsF/3&a,Rd1ⓞ{Pps1,Rsel9,Rp1,Rsel1}'}",
  'getStackInSlot(3,1)suckFromSlot(3,1)drop(1)push(1)select(9)place(1)select(1)',
  1
))

-- Villager stops trading after two deals, or `~tr` would never end
local sold = 0
local function offer(name)
  return component('trade', {
    getInput = function() return {name=name, size=2} end,
    isEnabled = function() return true end,
    trade = function() sold = sold + 1 return sold < 3 end,
  })
end

install{
  trading = {
    getTrades = function() return { offer'minecraft:wheat', offer'minecraft:emerald' } end,
  },
  robot = {},
  inventory_controller = {
    getStackInSlot = function() return {name='minecraft:wheat', size=64} end,
  },
}

test('  Ex.     trader', shouldPrint(
  "_a(-~Tg0'388^-g0ⓞ{g0.n,~tr}'),_16&R16-'Rd0'&IgI/0&'a[n]ⓐI8/0&k'",
  'getTrades(0)'..('getInput(0)'):rep(2)..('trade()'):rep(3)..
  ('getInput(0)'):rep(2)..'trade()'..
  seq('select(%d,%d)drop(0)', 1, 16)..
  seq('getStackInSlot(0,%d,true)', 1, 16)..
  seq('suckFromSlot(0,%d)', 1, 16),
  1
))

install{ trade = {} }

test('  Ex. num.  dict', shouldRaise(
  [[e((~-T'k')"'\\n'..k..' '..v")]],
  '_{\n1 type,\n2 trade,\n3 getInput,\n4 getOutput,\n5 isEnabled,\n6 getMerchantId}'
))
