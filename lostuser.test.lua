--[[

Test file for LostUser program

Author: Krutoy242

Source and readme:
https://gist.githubusercontent.com/Krutoy242/1f18eaf6b262fb7ffb83c4666a93cbcc

]]

--[[

■ Deploy script:
crunch --lz77 lostuser.lua lostuser.min.lua && flash -q lostuser.min.lua LostUser

■ Download and test
wget -f https://is.gd/mAN3WA lostuser.lua
wget -f https://is.gd/lostuser_test_lua lostuser.test.lua
lostuser.test

]]

local lu = loadfile'lostuser.lua'

print'\n< LostUser tests >\n'

--[[
████████╗███████╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   
   ██║   ██╔══╝  ╚════██║   ██║   
   ██║   ███████╗███████║   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   
]]

local function tableToString(t)
  local s,f = '',true
  for k,v in pairs(t) do
    s = s .. (f and '' or ' ') .. v
    f = false
  end
  return s
end

-- local _print = print
local printedMessage = ''
-- function print(...)
--   _print(...)
--   local result = table.pack(...)
--   if #result == 0 then return end
--   printedMessage = (printedMessage ~= '' and '\n' or '')
--     .. printedMessage .. tableToString(result)
-- end

local function shouldError(errorRgx, ...)
  local succes, result = pcall(lu, ...)
  return (not succes)
    and result
    and errorRgx
    and result:match('^.+: ' .. errorRgx)
  , result
end

local function shouldPrint(command, message)
  local succes, result = pcall(lu, command)
  return succes and printedMessage == message
  , result
end

local function test(description, succes, result)
  io.write('■ '..description..': ')
  io.write((succes and '✔' or ('❌\n> ' .. tostring(result))) .. '\n')
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

test('  Run without args', shouldError('No program defined'))
test('        Empty name', shouldError('No program defined', ''))
test('      Expose error', shouldError('Test Error', ' error"Test Error"'))
test('   Global shortand', shouldError('Exit', ' e"Exit"'))
test('  Should print msg', shouldPrint(" _'test'o.e!", 'test'))

T = { getTrades = function() return {
  {trade=function()print('t1()')end},
  {trade=function()print('t2()')end},
  n = 2,
} end }
test('        >>output  ', shouldPrint(" io.w(Tg)io.w(Tg!)", ''))
test('        Trade pipe', shouldPrint(" Tg!|'a1.tr!'", 't1()\nt2()'))
test('   Macros: pairs()', shouldPrint(
  " ~:T{??t*v=='table'{_*k}}", "trade\ntrade"
))
test('Macros: safe pntr.', shouldPrint(" ?.io{write'Hello\n'}", ""))

--[[

TODO: Some programs to test

i++Dsw(0)Ds(0)Dp(0)Dm(1>>((i+1)%5),0,(-1)^(i//5))s(1)

]]