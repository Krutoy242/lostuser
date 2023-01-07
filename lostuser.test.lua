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

local function tableToString(t)
  local s,f = '',true
  for k,v in pairs(t) do
    s = s .. (f and '' or ' ') .. tostring(v)
    f = false
  end
  return s
end

local function argsToString(...)
  local t = table.pack(...)
  t.n = nil
  return tableToString(t)
end

local _print = print
local printedMessage = ''
_G.print = setmetatable({
  print = type(print) == 'function' and print or print.print
}, {
  __call = function(self, ...)
    -- _print(self, ...)
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
    return printedMessage == message, printedMessage
  end
end

local function toVisibleString(...)
  return argsToString(...):gsub(' ', '◦'):gsub('\n', '⤶')
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
test('  Should print msg', shouldPrint(" pt'test'e!", 'test'))

_G.T = { getTrades = function() return {
  {trade=function()print('t1()')end, isEnabled=function()return true end},
  {trade=function()print('t2()')end, isEnabled=function()return true end},
  n = 2,
} end }
test('        Trade pipe', shouldPrint(" Tg!|'a1.t!'", 't1()\nt2()'))
-- test('   Macros: pairs()', shouldPrint(" Tg!/'t*a2=='table'|'pt*a1'", "trade\ntrade"))
-- test('   Macros: pairs()', shouldPrint(" ~:Tg!{??t*v=='table'{pt*k}}", "trade\ntrade"))
-- test('Macros: safe pntr.', shouldPrint(" ?.io{write'Hello\n'}", ""))

--[[

TODO: Some programs to test

i++Dsw(0)Ds(0)Dp(0)Dm(1>>((i+1)%5),0,(-1)^(i//5))s(1)

]]