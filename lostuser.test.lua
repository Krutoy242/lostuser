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

local function toVisibleString(str)
  return tostring(str):gsub(' ', '·')--[[ :gsub('\n', '⤶') ]]
end

local function test(description, fn)
  gpu.setForeground(0x005599)
  io.write('■ ')
  gpu.setForeground(0x999999)
  io.write(description..': ')
  local succes, result = fn()
  if succes then
    gpu.setForeground(0x009955)
    io.write('✔')
  else
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

test('      Shortand  _3', shouldOutput("_3",                     '_{1,2,3}'))
test('      Shortand _13', shouldOutput("_013",                   '_{0=0,1,2,3,4,5,6,7,8,9,10,11,12}'))
test('      Shortand  _a', shouldOutput("_{_a(4),a,type(_a(_'Ru3'))==type(a),os._a^3,os.a}", '_{4,4,true,3,3}'))
test('      Shortand  i5', shouldPrint("print(i5)",               '1234512', 7))
test('     Ordered Pairs', shouldOutput("_{1,[0]=2,3,c05=4,c4=5}", '_{0=2,1,3,c4=5,c05=4}'))
test('  Table num getter', shouldOutput("_{tostring(T5)==tostring(Tg),T6==nil}", '_{true,true}'))
test('Map:     Tbl x Fnc', shouldOutput("Tg!^'tr!'",              '_{t,v}'))
test('Map(call)Tbl x Fnc', shouldOutput("Tg0'tr!'",              '_{t,v}'))
test('Map:     Fnc x Num', shouldOutput("Te/3&4",                 '81.0'))
test('Map:     Fnc x Tbl', shouldOutput("Te^{4,5}",               '1024.0'))
test('               t^n', shouldOutput("_{1,[3]=3,a=6,[4]=4}^5",     '_{1,3=3,4=4,5=5,a=6}'))
test('               n^t', shouldOutput("2^_{4,5,6}",             '5'))
test('     Truthy Filter', shouldOutput("(T/'tk')^'n'",           '_{2=n2}'))
test('          Replaces', shouldOutput("ⓡ⒯ⓐⓝ⒡ⓞ⒡",           'true'))
test('          Unary ~T', shouldOutput("~~_{1,{2,3},{4,a=5,b=_{6,c=7}}}", '_{1,2,3,4,5,6,7}'))
test('          Unary -T', shouldOutput("_{'a','b','c'}", '_{a,b,c}'))
test('          Unary ~F', shouldPrint("~_'i=i+1ⓡi<3',w(i)", '3'))
test('          Unary -F', shouldOutput("a=-_'k,v'ⓡ_{a(0),a(1),a(2),a(false),a(nil,true)}", '_{1,0,0,1,1}'))
test('          Unary #f', shouldOutput("f=_'2,3,k'ⓡ_{f&4,#f&4}", '_{2,_{2,3,4}}'))

local mi = 3
_G.R = {
  move =function(n)print(({[0]='🡣','🡡','🡠','🡢'})[n] or '⁇') mi=mi-1 return mi>0 end,
  swing=function(n)print(({[0]='⇓','⇑','⇐','⇒'})[n] or '⁇') return true end,
}

test('Lambda:      T x N', shouldOutput("_3-2"          , '_{1,3=3}'))
test('Loop:        F x N', shouldPrint("Rm~3"           , '🡡🡠🡢', 1))
test('Loop:        N x F', shouldPrint("3~Rm"           , '⁇⁇⁇', 1))

mi = 3
test('        While loop', shouldPrint("_..'Rm3',w!", '🡢🡢🡢'))


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
test(' Sapling drone geo', shouldPrint(
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
test('   Drone waypoints', shouldPrint(
  "P=i/Nf300ⓡDm^Pp,s/0~'Dg!>1',_(Pl)",
  'find(300)m(10,0,0)ÔÔ⮋⮋⮋⮋'..
  'find(300)m(20,1,0)ÔÔ⮋⮋⮋⮋'..
  'find(300)m(30,2,0)ÔÔsel(1)⤓sel(2)⤓sel(3)⤓sel(4)⤓'..
  'find(300)m(10,0,0)ÔÔ⮋⮋⮋⮋',
  4
))

--[[

? Oredict filtering robot
IsF/3&i255ⓐRd(1&IgSII!.o'({ore=1,dus=0})[sg.s(v,1,3)]'ⓞ3)

! Other programs

? Drone sapling planter
x,z=i%8,i%64//8 u={x,0,z} -- Coords base on `i` variable
Gs(x,z)[32]==0 -- Is air 1 layer down
_'Dm(v[1],0,v[2]),s!,Dp0'/{u,u*'-v'} -- Move to point, place, and come back

x,z=i%8,i%64//8 u={x,0,z}∅_"_'Dm*u,s!,Dp0'/{u,u*'-v'}"~'Gs(x,z)[32]'
Gs(1,1,-1,8,8,1)*"v~=0ⓞ_'Dm(k,0,v)s!Dp(0)Dm(-k,0,-v)s!'(k%8,k/8)"
a=-1,Gs_11a881
_6^1

?========================================================
-- Unstackable extractor

_'IsF/3&a,Rd1ⓞ{Pps1,Rsel9,Rp1,Rd^Rsel1}'
IsF/3/a|'Pps1,Rsel9,Rp1,Rd^Rsel1'~-Rd/1 -- require -f
IsF/3/a|'Pps1,sel9,p1,d^sel1'/R~-Rd/1 -- require f/t signature (expose t to function)

-- How it would be with f.pointer
(IgSI-3-_a/i1728).mS&(IsF/3/a-'Pps1,sel9,p1,d^sel1'/R~-Rd/1)

-- Need somehow fix nil and number comparison
_'BmS<2'~_b&IgSI/3/_a^i1728

]]


