--[[

  Host build: makes lostuser.min.lua without Minecraft.

    lua53 tools/build.lua        -- cwd must be the repo root

  It runs the project's own build.lua - same cut, same crunch options - on
  top of shims for the OpenOS modules that script uses. The argument given
  to it stops build.lua after minifying: flashing the EEPROM and syncing
  readme.md from the source comments stay in-game steps.

  Exit code: 0 on success, 1 if crunch failed or its output does not load.

  Two builds of the same source are not byte identical: crunch hands out
  short names in hash order, so only the size stays about the same.

]]

local scriptDir = debug.getinfo(1, 'S').source:gsub('^@', ''):gsub('\\', '/'):match'^(.*)/' or '.'

-- crunch.lua already fakes `shell` and `filesystem`, extended below
local crunch = dofile(scriptDir .. '/crunch.lua')
local shell, filesystem = require 'shell', require 'filesystem'

local failed = false

--- The in-game repo lives in /home, on the host it is the working directory
local function resolve(path)
  return (path:gsub('^/home/', ''))
end

function filesystem.size(path)
  local handle = io.open(resolve(path))
  if not handle then return 0 end
  local size = handle:seek 'end'
  handle:close()
  return size
end

function filesystem.remove(path)
  return os.remove(resolve(path))
end

--- Only `crunch` is available here - the rest of OpenOS is not
function shell.execute(command)
  local args = {}
  for word in command:gmatch'%S+' do args[#args + 1] = word end
  local program = table.remove(args, 1)

  if program ~= 'crunch' then
    failed = true
    return false, program .. ': not available on the host'
  end

  local ok, message = crunch(table.unpack(args))
  failed = failed or not ok
  return ok, message
end

local color = not os.getenv 'NO_COLOR'

package.preload.component = function()
  return {
    gpu = {
      setForeground = function(c)
        if color then io.write(('\27[38;2;%d;%d;%dm'):format(c >> 16 & 255, c >> 8 & 255, c & 255)) end
      end,
    },
  }
end

-- Any argument makes build.lua return before flashing and updating readme
assert(loadfile 'build.lua')'host'

-- A minified file that does not even load would be flashed unnoticed.
-- Read as binary: the lz77 payload has bytes Windows would eat in text mode.
local handle = assert(io.open('lostuser.min.lua', 'rb'))
local chunk, err = load(handle:read 'a', '=lostuser.min.lua')
handle:close()
if not chunk then
  failed = true
  io.stderr:write(tostring(err), '\n')
end

io.write(color and '\27[0m' or '', failed
  and 'build failed\n'
  or 'lostuser.min.lua is ready, flash it in-game with `build`\n')

os.exit(failed and 1 or 0)
