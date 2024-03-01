-- local component = require('component')
local shell = require'shell'
local filesystem = require'filesystem'
local gpu = require('component').gpu

local function writeC(text, color)
  gpu.setForeground(color or 0xaaaaaa)
  io.write(text)
end

local log = {
  start = function(s) writeC(s..' ') end,
  succes= function() writeC('✔\n', 0x009955) end,
  fail= function(err)
    writeC('❌\n', 0xdd5555)
    writeC(err..'\n', 0xaa2222)
  end,
}

log.start'Read original source file'
local origHeader = io.open("lostuser.lua")
local orig = origHeader:read("*a")
origHeader:close()
log.succes()

log.start'Remove parts than unused in release'
local cutted = orig
  :gsub('-%-%[%[MINIFY]].--]]', '')
log.succes()

log.start'Save file'
local cuttedHeader = io.open("lostuser.cut.lua","w")
cuttedHeader:write(cutted)
cuttedHeader:close()
log.succes()

local function exec(command)
  log.start(command)
  local succes, err = shell.execute(command)

  if succes then
    log.succes()
  else
    log.fail(err)
  end
end

-- Minify file with Crunch program
local oldSize = filesystem.size'/home/lostuser.min.lua'
exec('crunch --lz77 lostuser.cut.lua lostuser.min.lua')
filesystem.remove'/home/lostuser.cut.lua'

log.start'Minified size:'
local newSize = filesystem.size'/home/lostuser.min.lua'
local newLess = newSize <= oldSize
writeC(oldSize, newLess and 0x999900 or 0x99bb00)
writeC(' => ')
writeC(newSize .. '\n', newLess and 0x00aaaa or 0xbb4444)

if ... then return gpu.setForeground(0xffffff) end

-- Write into EEPROM
exec('flash -q lostuser.min.lua LostUser')

log.start'Update readme'
local function escape(s)
  return s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1')
end
local hReadme = io.open("readme.md")
local readme = hReadme:read("*a")
hReadme:close()
for tab, key, content in orig:gmatch"([ \t]*)-%-%[%[(<[^\n]+)\n(.-)]]" do
  local passed = false
  readme = readme:gsub(
    escape(key)..'.-%-%->',
    function()
      passed = true
      return (key..'\n'..content):gsub('\n'..tab..' ? ?', '\n')
      ..'<!--  -->'
    end
  )
  if not passed then log.fail('Found key but not match in docs: '..key) end
  io.write('.')
  os.sleep(0.05)
end
hReadme = io.open("readme.md","w")
hReadme:write(readme)
hReadme:close()
log.succes()

gpu.setForeground(0xffffff)
