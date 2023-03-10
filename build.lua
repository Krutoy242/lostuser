-- local component = require('component')
local shell = require'shell'
local filesystem = require'filesystem'
local gpu = require('component').gpu

local log = {
  start = function(s) gpu.setForeground(0xaaaaaa) io.write(s..' ') end,
  succes= function() gpu.setForeground(0x009955) io.write'✔\n' end,
  fail= function(err)
    gpu.setForeground(0xdd5555)
    io.write('❌\n')
    gpu.setForeground(0xaa2222)
    io.write(err..'\n')
  end,
}

log.start'Read original source file'
local origHeader = io.open("lostuser.lua")
local orig = origHeader:read("*a")
origHeader:close()
log.succes()

log.start'Remove parts than unused in release'
local cutted = orig
  :gsub('---MINIFY{{.----}}', '')
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
exec('crunch --lz77 lostuser.cut.lua lostuser.min.lua')
filesystem.remove'lostuser.cut.lua'

-- Write into EEPROM
exec('flash -q lostuser.min.lua LostUser')

gpu.setForeground(0xffffff)
