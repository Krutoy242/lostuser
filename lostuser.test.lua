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

-- for k,v in pairs(_G) do print(k,v)end

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

test('Map:     Tbl x Fnc', shouldOutput("Tg!^'v.t!'",             '{q}{1=t,2=v}'))
test('Map:     Tbl x Num', shouldOutput("T^2",                    '{q}{1=2,2=2,3=2,exp=2,getTrades=2}'))
test('Map:     Fnc x Num', shouldOutput("(Te&3)(4)",              '81.0'))
test('Map:     Fnc x Tbl', shouldOutput("Te^{4,5}",               '1024.0'))
test('     Truthy Filter', shouldOutput("(T-'v.t')^'v.n'",        '{q}{2=n2}'))
test('          Replaces', shouldOutput("ⓡ⒯ⓐⓝ⒡ⓞ⒡",           'true'))
test('            Macros', shouldOutput("`Z..i`T..(i+1)`''TZT",  '101'))


local mi = 3
_G.R = {
  move =function(n)print(({[0]='🡣','🡡','🡠','🡢'})[n]) mi=mi-1 return mi>0 end,
  swing=function(n)print(({[0]='⇓','⇑','⇐','⇒'})[n]) return true end,
}

test('    Lambda and for', shouldPrint("_{Rm,Rsw}&{3}~2,w!", '🡢⇒🡢⇒'))

mi = 3
test('        While loop', shouldPrint("_~'Rm3',w!", '🡢🡢🡢'))
test('       Conditional', shouldPrint("`SRsw(i)`MRm(3)` _'M,S'!ⓐ_'SS'!,w!", '🡢⇓'))


_G.G = {
  scan = function(x,z)
    print(string.format('s(%d,%d)',x,z))
    local t={}for i=1,64 do t[i]=(i+x+z)%4/4-0.5 end
    return t
  end,
}
_G.D = {
  move = function(x,y,z)print(string.format('m(%g,%g,%g)',x,y,z)) end,
  place= function(side)print(string.format('p(%d)',side)) return false end,
}
test(' Sapling drone geo', shouldPrint(
  "`x(i%8)`z(i%64//8)`_'Dm(x,0,z)s!Dp(0)Dm(-x,0,-z)s!'~(Gsn(x,z)[32]==0),i>2ⓐw!",
  's(0,0)s(1,0)s(2,0)m(2,0,0)p(0)m(-2,0,0)s(3,0)'
))

--[[

? Trade all trades
Tg0-'Vtr0'

? Suck 4 slots from top and bottom
_08-'IsF(v//4,v%4+1)'

? Dump everything front
_'Rsel(k)Rd3'~16

? Trader
Tg0-'Vtr0',_'Rsel(k)Rd3'~16,_08-'IsF(v//4,v%4+1)'

? Circular miner
Gi!,_{Rm,Rsw}&{3}~i*3,Rtn⒯

? Zig-Zag move
`TRtn(i%2>0)`MRm3`_~'M',T,_'M,T'!ⓞ_'T,M'

? Zig-Zag and swing forward
`TRtn(i%2>0)S`MRm3S`S,Rsw3`_~'M',T,_'M,T'!ⓞ_'T,M'

? Rune maker
f='Rsel(v)Ie!Ru(3)Ie!'∅_7*f,s7,Rm1,Rd(3,1),Rm0,_2*'v+14'*f

? Travel between two waypoints and run its label
v=Nf300[i%2+1]∅Dm^v.p,s&1~'Dg!>1',_(v.l)!

! Other programs

? Line farmer
_4*"Ru^0,_12*'Rm^3'",_2*'Rtn⒯',_80*'Rsel^v,Rd^0',s^120

? Drone sapling planter
x,z=i%8,i%64//8 u={x,0,z} -- Coords base on `i` variable
Gsn(x,z)[32]==0 -- Is air 1 layer down
_'Dm(v[1],0,v[2]),s!,Dp0'&{u,u*'-v'} -- Move to point, place, and come back

x,z=i%8,i%64//8 u={x,0,z}∅_"_'Dm*u,s!,Dp0'&{u,u*'-v'}"~'Gsn(x,z)[32]'
Gsn(1,1,-1,8,8,1)*"v~=0ⓞ_'Dm(k,0,v)s!Dp(0)Dm(-k,0,-v)s!'(k%8,k/8)"

? Tree harvester with planting
a,b=Rdt3∅#b<6ⓐ{Rsw3,s^6,Rsk(0,1),Ie!,Ru3,Ie!}ⓞRu3,s!

]]


