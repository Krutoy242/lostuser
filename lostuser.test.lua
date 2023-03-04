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

  --[[ if type(val) == "table" and getmetatable(val).__call then
    tmp = tmp .. 'f()'
  else ]]if type(val) == "table" then
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

local function shouldPrint(command, message)
  return function()
    local succes, result = pcall(lu, command)
    if not succes then return false, result end
    return printedMessage == message, printedMessage
  end
end

local function shouldOutput(command, message)
  return function()
    local succes, result = pcall(lu, command, true)
    local resultStr = tostring(result)
    if not succes then return false, resultStr end
    return resultStr == message, resultStr
  end
end

local function toVisibleString(str)
  return tostring(str):gsub(' ', '·')--[[ :gsub('\n', '⤶') ]]
end

local function test(description, fn)
  io.write('■ '..description..': ')
  local succes, result = fn()
  io.write((succes and '✔' or ('❌\n> ❪' .. toVisibleString(result).. '❫')) .. '\n')
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
{name='n1', index=1},{name='n2', take=true},{name='n3', take=0, index=3},
exp=function(a,b) return a^b end,
getTrades = function() return {
  {trade=function()return 't','u' end, isEnabled=function()return false end},
  {trade=function()return 'v','w' end, isEnabled=function()return true end},
} end}

test('      Shortand _03', shouldOutput("_03",                    '{q}{1=0,2=1,3=2}'))
test('Map:     Tbl x Fnc', shouldOutput("Tg!^'v.t!'",             '{q}{1=t,2=v}'))
test('Map:     Tbl x Num', shouldOutput("T^2",                    '{q}{1=2,2=2,3=2,exp=2,getTrades=2}'))
test('Map:     Fnc x Num', shouldOutput("Te/3&4",                 '81.0'))
test('Map:     Fnc x Tbl', shouldOutput("Te^{4,5}",               '1024.0'))
test('     Truthy Filter', shouldOutput("(T/'v.t')^'v.n'",        '{q}{2=n2}'))
test('          Replaces', shouldOutput("ⓡ⒯ⓐⓝ⒡ⓞ⒡",           'true'))
test('            Macros', shouldOutput("`Z..i`T..(i+1)`''TZT",  '101'))


local mi = 3
_G.R = {
  move =function(n)print(({[0]='🡣','🡡','🡠','🡢'})[n]) mi=mi-1 return mi>0 end,
  swing=function(n)print(({[0]='⇓','⇑','⇐','⇒'})[n]) return true end,
}

test('Lambda:      T x T', shouldPrint("_{Rm,Rsw}/{3}~2,w!", '🡢⇒🡢⇒'))
test('Lambda:      T x N', shouldOutput("_3-2"             , '{q}{1=1,3=3}'))

mi = 3
test('        While loop', shouldPrint("_..'Rm3',w!", '🡢🡢🡢'))
test('       Conditional', shouldPrint("`SRsw(i)`MRm(3)` _'M,S'!ⓐ_'SS'!,w!", '🡢⇓'))


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
  "`x(i%8)`z(i%64//8)`_'Dm(x,0,z)s(0.05)Dp(0)Dm(-x,0,-z)s(0.05)'~(Gsn(x,z)[32]==0),i>2ⓐw!",
  's(0,0)s(1,0)s(2,0)m(2,0,0)p(0)m(-2,0,0)s(3,0)'
))

_G.N = {
  findWaypoints = function(dist)print(string.format('find(%g)',dist))return {
    {position={10,0,0}, redstone=0 , label="Dsk/0~4"},
    {position={20,1,0}, redstone=0 , label="Dsk/0~4"},
    {position={30,2,0}, redstone=15, label="_'Dsel(k)Dd(0)'~4"},
  } end,
}
test('   Drone waypoints', shouldPrint(
     "∅i>2ⓐw! P=i/Nf300ⓡDm^Pp,s/0~'Dg!>1',_(Pl)",
  -- "P=i/Nf300ⓡDm^Pp,       _(Pl),i>4ⓐw!",
  'find(300)m(10,0,0)ÔÔ⮋⮋⮋⮋'..
  'find(300)m(20,1,0)ÔÔ⮋⮋⮋⮋'..
  'find(300)m(30,2,0)ÔÔsel(1)⤓sel(2)⤓sel(3)⤓sel(4)⤓'..
  'find(300)m(10,0,0)ÔÔ⮋⮋⮋⮋'
))

--[[


? Circular miner
Gi!,_{Rm,Rsw}/{3}~i*3,Rtn⒯

! Other programs

? Line farmer
_4*"Ru^0,_12*'Rm^3'",_2*'Rtn⒯',_80*'Rsel^v,Rd^0',s^120

? Drone sapling planter
x,z=i%8,i%64//8 u={x,0,z} -- Coords base on `i` variable
Gsn(x,z)[32]==0 -- Is air 1 layer down
_'Dm(v[1],0,v[2]),s!,Dp0'/{u,u*'-v'} -- Move to point, place, and come back

x,z=i%8,i%64//8 u={x,0,z}∅_"_'Dm*u,s!,Dp0'/{u,u*'-v'}"~'Gsn(x,z)[32]'
Gsn(1,1,-1,8,8,1)*"v~=0ⓞ_'Dm(k,0,v)s!Dp(0)Dm(-k,0,-v)s!'(k%8,k/8)"

? Robot sorting mob drop
_'O=IgSI(0,k)IsF(0,k)Rd((OⓐOmDⓐOmD>0)ⓐ1ⓞ3)'~IgvS0

? Compressing bot
Cc0

?========================================================

// Possible spread. Need new operators:
//? N/F (rotated composition)
//? T/N (remove index)
_11/8/4&k/9/RtT // F(k) k: number of items in selected slot

// F(k) Suck and spread items
// k: external slot
IsF/3/'_11/8/4&k/9/RtT'

Igv3 // Number of slots in front
IsF(3,k) // Suck from slot

// Suck and spread each i
IsF/3/'_11/8/4&k/9/RtT'/(i%Igv3+1)

_16/Rc/'Rse^k,Rd3' // Select non-empty slots and dump them

_16/Rc/'Rse^k,Rd3',IsF/3/'_11/8/4&k/9/RtT'/(i%Igv3+1),Cc // dump, Suck, spread, craft

equip
store
dropIntoSlot
suckFromSlot
compareStacks
storeInternal
getStackInSlot
getInventorySize
getSlotStackSize
compareToDatabase
getSlotMaxStackSize
getStackInInternalSlot

use
drop
fill
move
name
suck
turn
count
drain
place
space
swing
detect
select
compare
compareTo
item_used
tankCount
tankLevel
tankSpace
durability
selectTank
transferTo
item_placed
compareFluid
getLightColor
inventorySize
setLightColor
compareFluidTo
block_activated
item_interacted
transferFluidTo

]]


