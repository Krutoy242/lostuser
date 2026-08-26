--[[

Minimal OpenComputers host emulator.

Runs LostUser and its test suite in a plain Lua 5.3 interpreter on the
host machine, without Minecraft. It recreates only what an EEPROM-level
program can see: `component`, `computer`, `require`, a virtual machine
clock, and the sandbox restrictions listed in machine.lua.

Usage (cwd must be the repo root, paths inside are relative):

  lua53 test/oc-emu.lua                        -- run lostuser.test.lua
  lua53 test/oc-emu.lua lostuser.lua "Rm3" 1   -- run one program, 1 iteration
  lua53 test/oc-emu.lua my-scenario.lua        -- run any host script

A scenario script gets the emulator with `require'ocemu'` and can add
components before loading LostUser:

  local emu = require 'ocemu'
  emu.register('robot', { move = function(side) print('move', side) end })
  local lu = loadfile 'lostuser.lua'
  print(pcall(lu, 'Rm3', 1))   -- program, iterations

Exit code: 0 all tests passed, 1 some failed, 2 crash, 124 machine died.

Env:
  NO_COLOR=1       disable ANSI colors
  OCEMU_BUDGET=n   instructions (millions) allowed between yields, default 40
  OCEMU_TIMEOUT=n  wall clock limit in seconds, default 10

]]

--- Emulator state. Deliberately NOT a global: every extra global would
--- shift LostUser's single-letter name resolution. Reach it from a test
--- script with `require'ocemu'`.
local emu = { fails = 0, total = 0 }

-- Unrestricted stdlib captured before the sandbox is narrowed
local rawgetmetatable, rawload = getmetatable, load
local sethook, exit = debug.sethook, os.exit

-----------------------------------------------------------------
-- Virtual machine clock + "too long without yielding" watchdog
-----------------------------------------------------------------

local clock, ticks = 0, 0
local BUDGET = tonumber(os.getenv 'OCEMU_BUDGET') or 40
local TIMEOUT = tonumber(os.getenv 'OCEMU_TIMEOUT') or 10
local started = os.clock()

--- Two guards, both of which end the process instead of hanging a terminal:
--- 1. yield deadline - OC kills a machine that runs ~5s without pullSignal
--- 2. wall clock - a program that yields forever would otherwise loop forever
local function die(reason)
  io.stderr:write('\27[0m\n[ocemu] machine died: ', reason, '\n')
  exit(124)
end

sethook(function()
  if os.clock() - started > TIMEOUT then
    die(('no result after %gs (OCEMU_TIMEOUT)'):format(TIMEOUT))
  end
  ticks = ticks + 1
  if ticks > BUDGET then
    die(('too long without yielding (%dM instructions, OCEMU_BUDGET)'):format(BUDGET))
  end
end, '', 1e6)

-----------------------------------------------------------------
-- Components
-----------------------------------------------------------------

--- OC exposes component methods as callable tables, not functions,
--- so `type(Ru) == 'table'`. Reproduce that.
--- The metatable stays reachable: LostUser's `isCallable` looks for
--- `getmetatable(t).__call`, and it works on a real robot.
local function callable(f, name)
  return setmetatable({}, {
    __call = function(_, ...) return f(...) end,
    __tostring = function() return 'function: ' .. (name or '?') end,
  })
end

local registered = {} -- address -> { name = string, proxy = table }
local addrSeed = 0

--- Add a fake component visible to `component.list()` / `component.proxy()`
---@param name string component type, e.g. 'robot'
---@param methods table map of method name -> function
---@return string address
function emu.register(name, methods)
  addrSeed = addrSeed + 1
  local address = ('%08x-0000-4000-8000-%012d'):format(addrSeed * 0x1111111, addrSeed)
  local proxy = { address = address, type = name, slot = -1 }
  for k, v in pairs(methods or {}) do
    proxy[k] = type(v) == 'function' and callable(v, name .. '.' .. k) or v
  end
  registered[address] = { name = name, proxy = proxy }
  return address
end

local component = {
  list = function(filter)
    local t = {}
    for address, c in pairs(registered) do
      if not filter or c.name:find(filter, 1, true) then t[address] = c.name end
    end
    return t
  end,
  proxy = function(address)
    local c = registered[address]
    if not c then return nil, 'no such component' end
    return c.proxy
  end,
  type = function(address)
    local c = registered[address]
    return c and c.name
  end,
  invoke = function(address, method, ...)
    local c = registered[address] or error 'no such component'
    return c.proxy[method](...)
  end,
  slot = function() return -1 end,
  methods = function(address)
    local t, c = {}, registered[address]
    for k, v in pairs(c and c.proxy or {}) do
      if type(v) == 'table' then t[k] = true end
    end
    return t
  end,
}

local computer = {
  address = '00000000-0000-4000-8000-000000000000',
  uptime = function() return clock end,
  --- Virtual: never really sleeps, just advances the clock and
  --- clears the yield watchdog, so tests stay fast and deterministic.
  pullSignal = function(timeout)
    clock = clock + math.max(tonumber(timeout) or 0, 0.05)
    ticks = 0
    return nil
  end,
  pushSignal = function() return true end,
  beep = function() end,
  energy = function() return 1000 end,
  maxEnergy = function() return 1000 end,
  totalMemory = function() return 2 * 1024 * 1024 end,
  freeMemory = function() return 1024 * 1024 end,
  getDeviceInfo = function() return {} end,
  users = function() return end,
  shutdown = function() error 'computer.shutdown' end,
}

-----------------------------------------------------------------
-- GPU (only for the test harness output; not in component.list())
-----------------------------------------------------------------

local color = not os.getenv 'NO_COLOR'
local fg = 0xffffff

local gpu = {
  setForeground = function(c)
    local old = fg
    fg = c
    if color then io.write(('\27[38;2;%d;%d;%dm'):format(c >> 16 & 255, c >> 8 & 255, c & 255)) end
    return old
  end,
  getForeground = function() return fg end,
  setBackground = function(c) return 0 end,
  getBackground = function() return 0 end,
  getResolution = function() return 80, 25 end,
  setResolution = function() return true end,
  maxResolution = function() return 160, 50 end,
  getDepth = function() return 8 end,
  maxDepth = function() return 8 end,
  set = function() return true end,
  get = function() return ' ', 0xffffff, 0 end,
  fill = function() return true end,
  copy = function() return true end,
  bind = function() return true end,
}

--- `component.gpu` and friends: primary component of that type,
--- falling back to the harness GPU above.
setmetatable(component, {
  __index = function(_, name)
    for _, c in pairs(registered) do
      if c.name == name then return c.proxy end
    end
    if name == 'gpu' then return gpu end
  end,
})

-----------------------------------------------------------------
-- unicode (OC global, host-side via utf8)
-----------------------------------------------------------------

local unicode = {
  char = utf8.char,
  len = function(s) return utf8.len(s) or #s end,
  sub = function(s, i, j)
    local n = utf8.len(s) or #s
    i, j = i or 1, j or -1
    if i < 0 then i = n + i + 1 end
    if j < 0 then j = n + j + 1 end
    if i < 1 then i = 1 end
    if j > n then j = n end
    if i > j then return '' end
    local from = utf8.offset(s, i)
    local to = (j < n) and utf8.offset(s, j + 1) - 1 or #s
    return s:sub(from, to)
  end,
  upper = string.upper,
  lower = string.lower,
  wlen = function(s) return utf8.len(s) or #s end,
  charWidth = function() return 1 end,
  isWide = function() return false end,
}

-----------------------------------------------------------------
-- Sandbox restrictions from OC machine.lua
-----------------------------------------------------------------

-- String metatable is unreachable, so programs can't give strings operators
function _G.getmetatable(v)
  if type(v) == 'string' then return nil end
  return rawgetmetatable(v)
end

-- allowBytecode = false
function _G.load(chunk, name, mode, env)
  return rawload(chunk, name, 't', env)
end

-- Only these debug primitives exist in the sandbox
_G.debug = {
  getinfo = debug.getinfo,
  traceback = debug.traceback,
  getlocal = debug.getlocal,
  getupvalue = debug.getupvalue,
}

_G.component, _G.computer, _G.unicode = component, computer, unicode

-----------------------------------------------------------------
-- require (OpenOS-side, what lostuser.test.lua uses)
-----------------------------------------------------------------

local modules = {
  ocemu = emu,
  component = component,
  computer = computer,
  unicode = unicode,
  filesystem = {
    exists = function(p)
      local f = io.open(p)
      if f then f:close() return true end
      return false
    end,
    size = function(p)
      local f = io.open(p)
      if not f then return 0 end
      local n = f:seek 'end'
      f:close()
      return n
    end,
    remove = os.remove,
  },
  shell = {
    execute = function(cmd) return false, 'shell.execute is not emulated: ' .. tostring(cmd) end,
    getWorkingDirectory = function() return '/home' end,
  },
  term = { write = io.write, clear = function() end },
  event = { pull = function() return nil end },
}

function _G.require(name)
  return modules[name] or error(("module '%s' not found"):format(name), 2)
end

-----------------------------------------------------------------
-- Run
-----------------------------------------------------------------

io.stdout:setvbuf 'no'

local args = table.pack(...)
local script = args[1] or 'lostuser.test.lua'

-- Numeric-looking arguments are passed as numbers, not strings:
-- LostUser only honors its iteration counter when `type(runCount) == 'number'`
for i = 2, args.n do args[i] = tonumber(args[i]) or args[i] end
local chunk, err = loadfile(script)
if not chunk then
  io.stderr:write(tostring(err), '\n')
  exit(2)
end

local ok, runErr = pcall(chunk, table.unpack(args, 2, args.n))
if color then io.write '\27[0m' end
if not ok then
  io.stderr:write('\n', tostring(runErr), '\n')
  exit(2)
end

if emu.total > 0 then
  io.write(('\n%d/%d passed\n'):format(emu.total - emu.fails, emu.total))
end
exit(emu.fails > 0 and 1 or 0)
