--[[
  Host runner for `crunch` - the Lua compressor by mpmxyz that `build.lua`
  calls in-game. Sources are vendored unchanged in tools/crunch/ (MIT).

    lua53 tools/crunch.lua --lz77 lostuser.lua lostuser.min.lua
    lua53 tools/crunch.lua                    -- usage text

  Crunch only needs four OpenOS modules, all faked below: `shell` for
  argument parsing, `computer`+`event` for the in-game timeout guard and
  `filesystem` to enumerate its own pipeline steps in tools/crunch/lib/crunch.

  Exit code: 0 on success, 1 if crunch reported an error.
  Loaded as a module it returns that same call as a function:

    local crunch = dofile 'tools/crunch.lua'
    crunch('--lz77', 'lostuser.cut.lua', 'lostuser.min.lua')
]]

local scriptDir = debug.getinfo(1, 'S').source:gsub('^@', ''):gsub('\\', '/'):match'^(.*)/' or '.'
package.path = scriptDir .. '/crunch/lib/?.lua;' .. package.path

-- OpenOS argument parser, verbatim behaviour of shell.parse
package.preload.shell = function()
  return {
    resolve = function(path)
      return (path:gsub('\\', '/'))
    end,
    parse = function(...)
      local params, args, options, done = table.pack(...), {}, {}, false
      for i = 1, params.n do
        local param = params[i]
        if not done and type(param) == 'string' then
          if param == '--' then
            done = true
          elseif param:sub(1, 2) == '--' then
            local key, value = param:match'%-%-(.-)=(.*)'
            if not key then key, value = param:sub(3), true end
            options[key] = value
          elseif param:sub(1, 1) == '-' and param ~= '-' then
            for j = 2, #param do options[param:sub(j, j)] = true end
          else
            args[#args + 1] = param
          end
        else
          args[#args + 1] = param
        end
      end
      return args, options
    end,
  }
end

-- crunch yields to the OS every 0.1s so the machine survives; harmless here
package.preload.computer = function() return { uptime = os.clock } end
package.preload.event = function() return { pull = function() end } end

package.preload.filesystem = function()
  local isWindows = package.config:sub(1, 1) == '\\'
  local fs = {}

  -- only used to prepend $PWD, which the host resolves on its own
  function fs.concat(_, path)
    return path
  end

  -- renaming onto itself is the pure Lua way to stat a directory
  function fs.exists(path)
    path = path:gsub('/+$', '')
    return path == '' or os.rename(path, path) ~= nil
  end

  function fs.isDirectory(path)
    local handle = io.open(path, 'r')
    -- Windows refuses to open a directory, POSIX opens it but reads nothing
    if not handle then return fs.exists(path) end
    local ok = handle:read(0)
    handle:close()
    return ok == nil
  end

  -- alphabetical, so the `00_`..`25_` step order of crunch is kept
  function fs.list(path)
    local names = {}
    local pipe = io.popen(isWindows
      and ('dir /b "' .. path:gsub('/', '\\') .. '" 2>nul')
      or ('ls -1 "' .. path .. '" 2>/dev/null'))
    if pipe then
      for name in pipe:lines() do names[#names + 1] = name end
      pipe:close()
    end
    table.sort(names)
    local i = 0
    return function()
      i = i + 1
      return names[i]
    end
  end

  return fs
end

--- Run crunch once
---@return boolean success, string|nil error message written by crunch
local function crunch(...)
  -- crunch reports failures on stderr and returns normally - catch that
  local stderr, message = io.stderr, nil
  io.stderr = {
    write = function(_, ...)
      message = table.concat{...}
      stderr:write(message, '\n')
    end,
  }

  local ok, err = pcall(assert(loadfile(scriptDir .. '/crunch/bin/crunch.lua')), ...)

  io.stderr = stderr
  if not ok then return false, tostring(err) end
  return message == nil, message
end

-- Called as a script, not as a library
if not pcall(debug.getlocal, 4, 1) then
  os.exit(crunch(...) and 0 or 1)
end

return crunch
