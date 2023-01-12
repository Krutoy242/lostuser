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
-- test('     Parsing error', shouldError('^.+: attempt to concat', ' X(c..d)'))
test('  Should print msg', shouldPrint(" X'test'", 'test'))

_G.T = {
{name='n1', take=true, index=1},{name='n2'},{name='n3', take=0, index=3},
exp=function(a,b) return a^b end,
getTrades = function() return {
  {trade=function()return 't','u' end, isEnabled=function()return false end},
  {trade=function()return 'v','w' end, isEnabled=function()return true end},
} end}
test('Map:     Tbl x Fnc', shouldPrint(" X(Tg!*'v.t!')",             '{t,v}'))
test('Map:     Tbl x Num', shouldPrint(" X(T*2)",                    '{2,2,2,exp=2,getTrades=2}'))
test('Map:     Fnc x Num', shouldPrint(" X((Te&3)^4)",               '81.0'))
test('Map:     Fnc x Tbl', shouldPrint(" X(Te*{4,5})",               '1024.0'))
test('     Truthy Filter', shouldPrint(" X(T /'v.t'*'v.n')",         '{n1}'))
test('    No-null Filter', shouldPrint(" X(T//'v.t'*'v.n')",         '{n1,3=n3}'))
test('            Reduce', shouldPrint(" X(T*'v.i'/'v'%'k+v')",      '4'))
test('        Variable i', shouldPrint(" if i==2 then X! end pt(i)", '012'))
test('          Replaces', shouldPrint(" ∅X(⒯ⓐⓝ⒡ⓞ⒡)ⓡ",           'true'))
test('            Macros', shouldPrint(" `Z..i`T..(i+1)`X(''TZT)",   '101'))


local mi = 3
_G.R = {
  move =function(n)print(({[0]='🡣','🡡','🡠','🡢'})[n]) mi=mi-1 return mi>0 end,
  swing=function(n)print(({[0]='⇓','⇑','⇐','⇒'})[n]) return true end,
}

test('    Lambda and for', shouldPrint(" _{Rm,Rsw}&{3}~0.5*4,X()", '🡢⇒🡢⇒'))

mi = 3
test('        While loop', shouldPrint(" _~'Rm(3)',X()", '🡢🡢🡢'))
test('       Conditional', shouldPrint(" `SRsw(i)`MRm(3)` _'M,S'!ⓐ_'SS'!,X()", '🡢⇓'))


_G.G = {
  scan = function(x,z)
    print(string.format('scan(%d,%d)',x,z))
    local t={}for i=1,64 do t[i]=(i+x+z)%4/4-0.5 end
    return t
  end,
}
_G.D = {
  move = function(x,y,z)print(string.format('move(%g,%g,%g)',x,y,z)) end,
  place= function(side)print(string.format('place(%d)',side)) return false end,
}
test(' Sapling drone geo', shouldPrint(
  " `x(i%8),`z(i%64//8))`_'Dm(x0,zs!Dp(0)Dm(-x0,-zs!'~(Gsn(xz[32]==0),i==3ⓐX()",
  'scan(0,0)scan(1,0)scan(2,0)move(2,0,0)place(0)move(-2,0,0)scan(3,0)'
))

--[[

TODO: Error handling when wrong translation


? Trade all trades
Tg!/'v.tr!'

? Suck 4 slots from top and bottom
_8/'IsF(v--//4,v%4+1)'

? Dump everything front
_16/'Rsel^v,Rd^3'

? Trader
Tg!/'v.tr!',_16/'Rsel^v,Rd^3',_8/'IsF(v--//4,v%4+1)'

? Circular miner
Gi!,_{Rm,Rsw}&{3}~i*3,Rtn⒯

? Zig-Zag move
`TRtn(i%2>0)`MRm(3)`_~'M',T,_'M,T'!ⓞ_'TM'!

! Other programs


? Line farmer
_4*"Ru^0,_12*'Rm^3'",_2*'Rtn⒯',_80*'Rsel^v,Rd^0',s^120

? Drone sapling planter
`Xi%8,`Zi%64//8)`_'Dm(X0,Zs!Dp(0)Dm(-X0,-Zs!'~0/Gsn(XZ[32]
u={i%8,i%64//8}∅(Gsn*u)[32]==0ⓐ_'Dm(v[1],0,v[2]),s!,Dp*0'&{u,u*'-v'}
x,z=i%8,i%64//8 u={x,0,z}∅_"_'Dm*u,s!,Dp*0'&{u,u*'-v'}"~'Gsn(x,z)[32]'
u={i%8,0,i%64//8,1,1,1}x,y,z=t.u*u∅_"_'Dm*u,s!,Dp*0'&{u,u*'-v'}"~'(Gsn*u)[1]'
u={i%8,0,i%64//8}x,y,z=t.u*u∅Gsn(x,z)[32]==0ⓐ_'Dm(v[1],0,v[2]),s!,Dp*0'&{u,u*'-v'}
Gsn(1,1,-1,8,8,1)*"v~=0ⓞ_'Dm(k,0,v),s^1,Dp^0,Dm(-k,0,-v),s^1'(k%8,k/8)"
t,u=t or Gsn(1,1,-1,8,8,1),l and {i%8,0,i/8} or u*'-v' TRASH=t[i]==0 and Dm*u s(1)

? Simple saplinger
Ds(0)Dm(i%8,0,i%64//8)

]]
