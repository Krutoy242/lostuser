--[[

Test file for LostUser program

Author: Krutoy242

Source and readme:
https://gist.githubusercontent.com/Krutoy242/1f18eaf6b262fb7ffb83c4666a93cbcc

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

local serpent = require("serpent/src/serpent")
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
  local tmp = ''

  if name then tmp = tmp .. name .. "=" end
  
  --[[ if type(val) == "table" and getmetatable(val).__call then
    tmp = tmp .. 'f()'
  else ]]if type(val) == "table" then
    tmp = tmp .. "{"

    local i = 1
    for k, v in pairs(val) do
      tmp =  tmp.. (i==1 and '' or ',') .. serialize(v, i ~= k and k or nil)
      i = i + 1
    end

    tmp = tmp .. "}"
  elseif type(val) == "number" then
    tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
    tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
    tmp = tmp .. (val and "true" or "false")
  else
    tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end

  return tmp
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
      .. (printedMessage ~= '' and '\n' or '')
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
      and result:match('^.+: ' .. errorRgx)
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
  return str:gsub(' ', '·')--[[ :gsub('\n', '⤶') ]]
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

test('  Run without args', shouldError('No program defined'))
test('        Empty name', shouldError('No program defined', ''))
test('      Expose error', shouldError('Test Error', ' error"Test Error"'))
test('   Global shortand', shouldError('Exit', ' e"Exit"'))
test('  Should print msg', shouldPrint(" X'test'", '"test"'))

_G.T = {
{name='n1', take=true, index=1},{name='n2'},{name='n3', take=0, index=3},
exp=function(a,b) return a^b end,
getTrades = function() return {
  {trade=function()return 't','u' end, isEnabled=function()return false end},
  {trade=function()return 'v','w' end, isEnabled=function()return true end},
} end}
test('Map:     Tbl x Fnc', shouldPrint(" X(Tg!*'v.t!')",             '{"t","v"}'))
test('Map:     Tbl x Num', shouldPrint(" X(T*2)",                    '{2,2,2,exp=2,getTrades=2}'))
test('Map:     Fnc x Num', shouldPrint(" X((Te*3)^4)",               '81.0'))
test('Map:     Fnc x Tbl', shouldPrint(" X(Te*{4,5})",               '1024.0'))
test('     Truthy Filter', shouldPrint(" X(T /'v.t'*'v.n')",         '{"n1"}'))
test('    No-null Filter', shouldPrint(" X(T//'v.t'*'v.n')",         '{"n1",3="n3"}'))
test('            Reduce', shouldPrint(" X(T*'v.i'/'v'%'a+b')",'4'))
test('        Variable i', shouldPrint(" if i==2 then X! end pt(i)", '0\n1\n2'))
test('            Macros', shouldPrint(" X(⒯ⓐⓝ⒡ⓞ⒡)",             'true'))

--[[

TODO: Some programs to test


? Trade all trades
Tg!*'v.tr!'

? Suck 4 slots from top and bottom
_8*'IsF(v--//4,v%4+1)'

? Dump everything front
_16/'Rsel^v,Rd^3'

? Trader
Tg!*'v.tr!',_16/'Rsel^v,Rd^3',_8*'IsF(v--//4,v%4+1)'


! Other programs


? Line farmer
_4*"Ru^0,_12*'Rm^3'",_2*'Rtn⒯',_80*'Rsel^v,Rd^0',s^120

? WIP zig-zag
Dsw(0)Ds(0)Dp(0)Dm(1>>((i+1)%5),0,(-1)^(i//5))s(1)

]]
