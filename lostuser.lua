--[[

Lost User - simpliest robot

Author: Krutoy242

Source and readme:
https://github.com/Krutoy242/lostuser

]]

-- Some source code is excluded in release build file.
-- Removed code started with "--[[MINIFY]]" and ends with "--]]".
-- This to remove parts of code could be useful for testing and
-- debugging LostUser from computer rather than EEPROM.

-- Forward declarations
local pack, unpack, pairs, tostring, type, tonumber, loadBody, q = table.pack, table.unpack, pairs, tostring, type, tonumber

--[[MINIFY]]
-- If we run from OpenOS
if require then
  component, computer = require'component', require'computer'
end
local skipComponents = {
  computer=true
}
--]]

--- Prepare string for natural sort by adding '0' for every number in it
---@param a string
---@return string
local function padnum(a)
  return a:gsub("%d+", function(d)
    return ('%04d'):format(d)
  end)
end

local function getOrderedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys+1]=k end
  table.sort(keys, function(a,b)
    local c,d = tostring(a), tostring(b)
    local m,n = #c,#d
    return m==n and padnum(c):lower() < padnum(d):lower() or m<n
  end)
  return keys
end

--- Same as default Lua `pairs(t)` but iterating in sorted order
---@param t table Table with one or many keys and values. Keys could be strings, numbers or their combinations.
---@param wrapper? function Wrap values returned by pairs.
---@return function
local function orderedPairs(t, wrapper)
  local keys,i = getOrderedKeys(t),0
  return function()
    i=i+1
    return keys[i], wrapper and wrapper(t[keys[i]]) or t[keys[i]]
  end, t, nil
end

-- Define all components as big letter global, short names first
--[[<!-- components -->
  1. All components exposed as globals
  2. Components added to globals by big first letter

    ```lua
    C	= computer
    E	= eeprom
    I	= inventory_controller
    R	= robot
    T	= trading
    ...
    ```
  > ⚠️ Warning: If two components starts with same letter, only one that shorter and came first after sorting will be exposed by single letter.
  >
  > For example, if robot have `Redstone Card` component, letter `R` will stand for `robot` rather than `redstone`.
]]
--[[ Exapmle of creative robot:
C = computer
C = crafting
E = eeprom
E = experience
F = filesystem
G = geolyzer
G = gpu
I = internet
I = inventory_controller
K = keyboard
M = modem
R = redstone
R = robot
S = screen
T = tank_controller
T = trading
]]
local comps,componentDict = {},{}
for address, name in pairs(component.list()) do comps[name]=address end
for name, address in orderedPairs(comps) do
  --[[MINIFY]]if not skipComponents[name] then--]]
  local C, p = name:sub(1, 1):upper(), component.proxy(address)
  _G[name] = _G[name] or p
  _G[C] = _G[C] or p
  componentDict[C] = componentDict[C] or name
  --[[MINIFY]]end--]]
end

--- Since LostUser will be minified and lz77-compressed,
--- its call stack and error source code will have no meaning.
--- Thats why we wrap default Lua global `error()` into custom function
--- that remove meaningless prefixes and only left error reason.
--- Also, all `%` symbols should be escaped.
---@param err string
local function localError(err)
  -- if computer then computer.beep(1800, 0.5) end
  error(
    tostring(err):gsub('%[string ".+"%]:%d+: ', '')

    --- Escape `%` symbol from chat log since its cause an error FML error
    --- [Client thread/ERROR] [FML]: Exception caught during firing event net.minecraftforge.client.event.ClientChatReceivedEvent@3e83e9ca:
    --- net.minecraft.util.text.TextComponentTranslationFormatException: Error parsing
    :gsub('%%','%%%%')

    -- skipTraceback and tostring(err) or debug.traceback(err)
  , 0)
end

--- Check if value is truthy
--- Falsy values is:
--- empty string, zero, NaN, result of /0
---@param a any
local function truthy(a)
  if not a or a == '' or a == 0 or a ~= a then return false end
  if type(a) == 'number' then
    local s = tostring(a)
    if s == 'inf' or s == '-inf' then return false end
  end
  return true
end

local function TONUMBER(a)
  local t = type(a)
  if t=='number' or t=='string' then return tonumber(a) end
  return truthy(a) and 1 or 0
end

--- Serialize value table
---@param t any
---@return string
local function serialize(t)
  local s,i='',0
  for k,v in orderedPairs(t) do
    if k==1 or i>0 then i=i+1 end
    s=s..(s==''and''or',')..((k==i and k~=0) and '' or tostring(k)..'=')..tostring(v)
  end
  return '{'..s..'}'
end

--[[
███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████║██║
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
]]

--- Filter or map table.
--- Remove values for keys that not pass predicate.
---@param t table
---@param f function(k:integer, v:any): boolean
---@param isFilter? boolean filter instead of map
---@return table<any, any> f(k,v) will be wrapped into table
local function map(t, f, isFilter)
  local r, res = {}
  for k, v in pairs(t) do
    res = f(k,v)
    if isFilter then
      if truthy(res) then r[k] = v end
    else
      r[k] = res
    end
  end
  return r
end

--- Loop to function
---@param self any Function or table of functions
---@param isTbl boolean if `self` is table
---@param trgFnc function
---@return boolean
local function loop(self, isTbl, trgFnc)
  local r
  for j=1, math.maxinteger do
    if not truthy(trgFnc(j)) then return r end
    if isTbl then
      for k,v in pairs(self) do
        r = v(k,v)
      end
    else
      r = self(j)
    end
  end
  -- TODO: Return index of iteration or something else
  return r
end

--[[
████████╗██████╗  █████╗ ███╗   ██╗███████╗██╗      █████╗ ████████╗███████╗
╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ██╔══██╗╚══██╔══╝██╔════╝
   ██║   ██████╔╝███████║██╔██╗ ██║███████╗██║     ███████║   ██║   █████╗
   ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██╔══██║   ██║   ██╔══╝
   ██║   ██║  ██║██║  ██║██║ ╚████║███████║███████╗██║  ██║   ██║   ███████╗
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
]]

--- Replace all macroses
---@param text string
local function translate(text)
  return text
    :gsub('ⓐ', ' and ')
    :gsub('ⓞ', ' or ')
    :gsub('ⓝ', ' not ')
    :gsub('ⓡ', ' return ')
    :gsub('⒯', '(true)')
    :gsub('⒡', '(false)')
    :gsub('!', '()')
end

--[[
 ██████╗    ████████╗ █████╗ ██████╗ ██╗     ███████╗
██╔═══██╗   ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝
██║   ██║█████╗██║   ███████║██████╔╝██║     █████╗
██║▄▄ ██║╚════╝██║   ██╔══██║██╔══██╗██║     ██╔══╝
╚██████╔╝      ██║   ██║  ██║██████╔╝███████╗███████╗
 ╚══▀▀═╝       ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
]]

--- Does this variable can be called
---@param t any
local function isCallable(t)
  local ty = type(t)
  if ty == 'function' then return true end
  if ty ~= 'table' then return false end
  local mt = getmetatable(t)
  return mt and mt.__q ~= 0 and mt.__call
end

--- Turn table of tables into table [[1,2],[3,4]] => [1,2,3,4]
---@param t table QTable
local function flatten(t)
  local r = {}
  for k, v in pairs(t) do
    if type(v) == 'table' and not isCallable(v) then
      for k, o in pairs(v) do
        r[#r+1] = o
      end
    else
      r[#r+1] = v
    end
  end
  return r
end

--- Get first object field key by shortand
---@param short string
---@param obj table
---@param onlyTables? boolean keep only table results
---@return string
local function getKey(short, obj, onlyTables)
  local rgx = '^'..short:gsub('.','%1.*')
  for k,v in orderedPairs(obj) do
    if type(k)=='string' and (not onlyTables or type(v)=='table') and k:match(rgx) then
      return k
    end
  end
end

--- Find value by key in table
---@param keyFull any
---@param t? table
---@return any Queued value q(v)
local function index(keyFull, t)
  t = t or _G
  local exact = t[keyFull]
  if exact ~= nil then return q(exact), componentDict[keyFull] or keyFull end

  -- If key is not a string, this means it cant be a shortand
  if type(keyFull) ~= 'string' then return end

  local C = keyFull:sub(1,1)

  -- Global key that started with _
  if C == '_' or C == 'i' then
    local postfix = keyFull:sub(2)
    local num = tonumber(postfix)
    --[[<!-- indexing _ -->
      - **Using `_` with numbers `_123`**
        Will return a new array-like list with the length of the number.
        If the first digit is `0`, the table will be zero-based.
        > ```lua
        > _8  -- returns {1,2,3,4,5,6,7,8}
        > _08 -- returns {[0]=0,1,2,3,4,5,6,7}
        > ```
      - **Using `_` with words `_abc`**
        Creates a function that will write the result into the `abc` variable.
        The function returns the passed value.
        Note that `_abc` is functional.
        > ```lua
        > -- Writes `4` into global `a`, returns 4
        > _a(4) == (function() a = 4; return a end)()
        >
        > -- Create func. that write result of `Ru` into global `a`
        > _a^Ru == function(...) a = robot.use(...); return a end
        >
        > -- Writes into table member
        > b._a^3 == b.a = 3
        > ```
    ]]
    -- TODO: f_ or t_ return hashed vlue
    if num then
      local from = postfix:sub(1,1) == '0' and 0 or 1
      if C == '_' then
        local arr = {}
        for i = from, num - (1 - from) do arr[i] = i end
        return q(arr)

      -- i modulus
      elseif t.i then
        return t.i % num + from
      end
    elseif C == '_' then
      -- _a(value) => a = value
      return q(function(v) t[postfix] = v return v end)
    end
  end

  local key, num = keyFull:match'(.-)(%d*)$'

  -- Key ends with number - probably function call
  -- Ru3 => robot.use(3)
  if num ~= '' then
    local n,f,long = tonumber(num), index(key, t)
    if isCallable(f) then
      return q(f(n)), long..'('..n..')'
    elseif type(f)=='table' then
      return q(f[getOrderedKeys(f)[n]]), long..'['..n..']'
    end

  -- Big letter shortand Tg => T.g
  elseif keyFull:match'^[A-Z]' then
    -- First, get big letter as is
    local long = getKey(C, t, true)

    -- If not found, get as lowercase shortand
    if t[long] == nil then
      long = getKey(C:lower(), t, true)
    end

    if t[long] ~= nil then
      if #keyFull == 1 then
        return q(t[long]), long
      else
        local r, long2 = index(keyFull:sub(2), t[long])
        return r, long..'.'..(long2 or '')
      end
    end
  end

  -- Other cases
  local long = getKey(keyFull, t)
  return q(t[long]), long
end

local function safeCall(f, safe, ...)
  local safeResult = pack(pcall(f, ...))
  if not safeResult[1] then
    if safe then return end
    localError(safeResult[2])
  end
  return unpack(safeResult, 2)
end

--- Generate helper functions
---@param target any Anything we targeting function to
---@return function, boolean
local function functionize(target)
  if type(target) ~= 'string' then return target, isCallable(target) end

  -- Generate safe function from lua code
  local code = translate(target)
  local p1, p2 = 'return function(...)local k,v=... ', code..' end'
  return function(...) return safeCall(
    loadBody(p1..'return '..p2, p1..p2, code, ...)(), true, ...
  ) end, true
end

--[[
███╗   ███╗████████╗
████╗ ████║╚══██╔══╝
██╔████╔██║   ██║
██║╚██╔╝██║   ██║
██║ ╚═╝ ██║   ██║
╚═╝     ╚═╝   ╚═╝
]]

--- Single value q(t)
q = function(t)
  local qIsCallable = isCallable(t)
  if type(t) ~= 'table' and not qIsCallable then return t end

  -- Already transformed
  local succes, mt = pcall(getmetatable, t)
  if succes and mt and mt.__q then return t end

  --############################################################
  -- Generic operator
  --############################################################
  --- Compute operator result based on different targets
  ---@param op string operator identifier
  ---@return any
  local function generic(op)
    return function(left, right)
      local rightIsTable, leftIsCallable, rightIsCallable, r = type(right) == 'table'
      left, leftIsCallable = functionize(left)
      right, rightIsCallable = functionize(right)

      if not leftIsCallable then
        if type(left) ~= 'table' then
          --?-- N x Table
          if not rightIsCallable then
            --[[<!-- n^t -->
              Get by numerical or boolean index
              ```lua
              2^_{4,5,6} -- 5
              ```
            ]]
            if op=='map' then
              r = t[left]

            --[[<!-- n/t -->
              Get by modulus
              ```lua
              i/t -- t[i % #t + 1]
              ```
            ]]
            elseif op=='lambda' then
              r = right[left % #right + 1]

            --[[<!-- n~t -->
              <sub>Not yet implemented</sub>
            ]]

            end

          --?-- N x Function
          else
            --[[<!-- n^f -->
              <sub>Not yet implemented</sub>
            ]]
            if op=='map' then

            --[[<!-- n/f -->
              Rotated composition
              ```lua
              2/f -- (...)=>f(..., 2)
              ```
            ]]
            elseif op=='lambda' then
              r = function(...) return right(..., left) end

            --[[<!-- n~f -->
              Same as `f~n`, but without passing index
              ```lua
              n~f -- for j=1,TONUMBER(n) do f() end
              ```
            ]]
            else
              for j=1, TONUMBER(left) do r = right() end

            end
          end
        --?-- Table x Function
        elseif rightIsCallable then

          --[[<!-- t^f -->
            Classical map
            ```lua
            _{4,5,6}^f -- {f(4),f(5),f(6)}
            ```
          ]]
          if op=='map' then
            r = map(left, right)

          --[[<!-- t/f -->
            Filter, keep only if value is [Truthy](#truthy)
            ```lua
            _{4,5,6,7}/'v%2' -- {5,7}
            ```
          ]]
          elseif op=='lambda' then
            r = map(left, right, true)

          --[[<!-- t~f -->
            <sub>Not yet implemented</sub>
          ]]
          -- elseif op=='loop' then

          end

        --?-- Table x Table
        elseif rightIsTable then

          --[[<!-- t^t -->
            Pick indexes
            ```lua
            _{4,5,6}^{3,1} -- {6,4}
            ```
          ]]
          if op=='map' then
            r = map(right, function(k,v) return left[v] end)

          --[[<!-- t/t -->
            <sub>Not yet implemented</sub>
          ]]
          -- elseif op=='lambda' then

          --[[<!-- t~t -->
            <sub>Not yet implemented</sub>
          ]]
          --elseif op=='loop' then

          end

        --?-- Table x Number
        else

          if op=='map' then
            --[[<!-- t^n -->
              Push value in END of table
              ```lua
              _{1,[3]=3,a=6,[4]=4}^5
              -- _{1,3=3,4=4,5=5,a=6}
              ```
            ]]
            local max = 0
            for k in pairs(left) do if tonumber(k) then max = math.max(max, k) end end
            t[max+1], r = right, left

          elseif op=='lambda' then
            --[[<!-- t/n -->
              Remove index
              ```lua
              _3/2 -- {1=1,3=3}
              ```
            ]]
            left[right], r = nil, left

          --[[<!-- t~n -->
            <sub>Not yet implemented</sub>
          ]]
          -- elseif op=='loop' then

          end

        end
      else
        --?-- Function x Function
        if rightIsCallable then

          --[[<!-- f^f -->
            Composition
            ```lua
            f^g -- (...)=>f(g(...))
            ```
          ]]
          if op=='map' then
            r = function(...) return left(right(...)) end

          --[[<!-- f/f -->
            Reversed composition
            ```lua
            f/g -- (...)=>g(f(...))
            ```
          ]]
          elseif op=='lambda' then
            r = function(...) return right(left(...)) end

          --[[<!-- f~f -->
            While truthy do
            ```lua
            f~g -- while truthy(g(j++)) do f(j) end
            ```
          ]]
          else
            r = loop(left, false, right)

          end

        --?-- Function x Table
        elseif rightIsTable then

          --[[<!-- f^t -->
            Unpack as arguments
            ```lua
            f^{1,2,3} -- f(1,2,3)
            ```
          ]]
          if op=='map' then
            r = left(unpack(right)) -- f x {1,2,3} => f(1,2,3) (Unpack table)

          --[[<!-- f/t -->
            Simple call
            ```lua
            f/R -- f(R)
            ```
          ]]
          elseif op=='lambda' then
            r = left(right)

          --[[<!-- f~t -->
            <sub>Not yet implemented</sub>
          ]]
          --elseif op=='loop' then

          end

        --?-- Function x Number
        else

          --[[<!-- f^n -->
            Simple call
            ```lua
            f^1 -- f(1)
            ```
          ]]
          if op=='map' then
            r = left(right)

          elseif op=='lambda' then
            --[[<!-- f/n -->
              Composition
              ```lua
              f/1 -- (...)=>f(1,...)
              ```
            ]]
            r = function(...) return left(right, ...) end

          else
            --[[<!-- f~n -->
              For loop
              ```lua
              f~n -- for j=1,TONUMBER(n) do f(j) end
              ```
            ]]
            r = loop(left, false, function(j) return j <= TONUMBER(right) end)

          end

        end
      end
      return q(r)
    end
  end

  --- Compute unary operator result based on different targets
  ---@param op string operator identifier
  ---@return any
  local function unary(op)
    return function(source)

      local r

      if not qIsCallable then
        --?-- Table

        --[[<!-- ~t -->
          Flatten table, using numerical indexes.

          > - Order of elements can be different
          > - All keys of the table would be converted to indexed
          > - Only 1 level of flattening

          ```lua
          ~_{1,{2,3},{4,a=5,b={6,c=7}}}
          -- {1,2,3,4,5,{6,c=7}}
          ```
        ]]
        if op=='lambda' then
          r = flatten(source)

        --[[<!-- -t -->
          Swap keys and values

          ```lua
          -_{'a','b','c'}
          -- {a=1,b=2,c=3}
          ```
        ]]
        elseif op=='map' then
          r = {} for k,v in pairs(source) do r[v]=k end

        end
      else
        --?-- Function

        --[[<!-- ~f -->
          While truthy do
          ```lua
          ~f -- repeat until not truthy(f())
          ```
        ]]
        if op=='lambda' then
          repeat until not truthy(source())

        --[[<!-- -f -->
          Make a function whose result will be flipped.
          If the result is `truthy`, returns `0`. Return `1` otherwise.
          ```lua
          -- id here is function that returns its first arg
          (-id)(0) -- 1
          (-id)(4) -- 0
          (- -id)(4) -- 1
          ```
        ]]
        elseif op=='map' then
          r = function(...) return truthy(source(...)) and 0 or 1 end

        end
      end
      return q(r)
    end
  end
  --############################################################

  local mt = {
    __q = qIsCallable and 1 or 0,
    __tostring = function() return '_'..(qIsCallable and tostring(t) or serialize(t)) end,
  }

  -- 1 --
  --[[ ^ ]] mt.__pow = generic'map'

  -- 2 --
  --[[ - ]] mt.__unm = unary'map'
  --[[ ~ ]] mt.__bnot = unary'lambda'
  -- [[ # ]] mt.__len = unary'??'

  -- 3 --
  --[[ * ]] mt.__mul = generic'loop'
  -- [[ % ]] mt.__mod = generic'??'
  --[[ / ]] mt.__div = generic'lambda'
  -- [[// ]] mt.__idiv = generic'??'

  -- 4 --
  --[[ + ]] mt.__add = mt.__pow
  --[[ - ]] mt.__sub = mt.__div -- lambda

  -- 5 --
  -- [[ .. ]] mt.__concat = generic'loop'

  -- 6 --
  -- [[<< ]] mt.__shl = generic'??'
  -- [[>> ]] mt.__shr = generic'??'

  -- 7 --
  --[[ & ]] mt.__band = mt.__pow -- map

  -- 8 --
  --[[ ~ ]] mt.__bxor = mt.__mul

  -- 9 --
  --[[ | ]] mt.__bor = mt.__div -- lambda

  -- 10 --
  -- [[ < ]] mt.__lt = generic'??'
  -- [[<= ]] mt.__le = generic'??'
  -- [[== ]] mt.__eq = generic'??'

  if qIsCallable then
    function mt:__call(...)
      local r = pack(t(...))
      for k, v in pairs(r) do r[k] = q(v) end
      return unpack(r)
    end
    --[[<!-- #f -->
      Make a function that would wrap its result into a table.
      Useful for functions that return several values.
      ```lua
      -- Consider `f(n)` returns three values - 2,3,n
      f&4   -- 2
      #f&4  -- _{2,3,4}
      ```
    ]]
    mt.__len = function() return q(function(...) return q{t(...)} end) end
    return setmetatable({}, mt)
  end

  -- Calling tables is same as map them
  mt.__call = mt.__pow
  --  TODO: Table and Function `:` indexes
  --* Possible ideas:
  --* • t:f'' | t:f{} -- ??
  --* • f:f'' | f:f{} -- ??

  function mt:__index(key)
    --  TODO: add function indexing
    --* Possible ideas:
    --* • f.n | f[n] => f()?.n -- safe pointer of function result
    --* • f[{}] ??
    return index(key, t)
  end

  -- Possibilities for __newindex:
  -- a.b='func(k,v)'
  -- a._={}
  -- _5='k,v'
  function mt:__newindex(k, v)
    --  TODO: add function new index
    --* Possible ideas:
    --* • f[2]=x
    --* • f.n=x
    --* • f[{}]=x
    rawset(t, k, q(v))
  end

  -- When pairs, returned ORDERED elements wrapped into q(v)
  mt.__pairs = function() return orderedPairs(t, q) end
  function mt:__len() return #t end

  return setmetatable({}, mt)
end

--[[
██╗      ██████╗  █████╗ ██████╗
██║     ██╔═══██╗██╔══██╗██╔══██╗
██║     ██║   ██║███████║██║  ██║
██║     ██║   ██║██╔══██║██║  ██║
███████╗╚██████╔╝██║  ██║██████╔╝
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝
]]

-- Copy of global environment inside loaded code
local q_G = q(_G)

--- Attempt to load code1 or code2
---@param code1 string
---@param code2 string
---@param chunkName string
loadBody = function(code1, code2, chunkName, ...)
  -- If we have table parameters that need to be exposed
  -- add them to upvalue
  local t, expose = q_G, pack(...)

  if expose.n > 0 then
    t = {}
    for k, v in pairs(_G) do t[k] = v end
    for i=1, expose.n do
      if type(expose[i]) == 'table' then
        for k, v in orderedPairs(expose[i]) do
          if t[k] == nil then
            t[k] = v
          end
        end
      end
    end
    t = q(t)
  end

  -- Load
  local res, err = load(code1, chunkName, nil, t)
  if err then
    res, err = load(code2, chunkName, nil, t)
  end
  return err and localError(err) or res
end

q_G.i = 0

q_G.sleep = function(timeout)
  local uptime = computer.uptime
  local delta = uptime() + (timeout or 1)
  repeat computer.pullSignal(delta - uptime())
  until uptime() >= delta
  return timeout or 1
end

--[[<!-- calling _ -->
  - **Using `_` on a string**
    Will load the code inside this string and return it as a function. Calling this function is always error-safe—if an exception occurs inside, the function will simply return `nil`.

    > ```lua
    > _'Rm,s2'()(0) -- calls `sleep(2),robot.move(0)`
    > ```
    > Note that in this example, the `_` function returns two values—the `robot.move` function and the result `sleep(2)`. Only when we call the returned values a second time does `robot.move(0)` get called.

  - **Using `_` on a *table* or *function***
    Will convert them into a `_{}` table or `_''` function to use with [Functional Programming](#functional-programming).
    > ```lua
    >  {1,2}^1 -- would error
    > _{1,2}^1 -- would return {1,1} (see Functional Programming)
    > ```
]]
q_G._ = function(target)
  return q(functionize(target))
end

--- Get full variable name
---@param key any
q_G.long = function(...)
  return localError(select(2, index(...)))
end

-- Recursively call functions that returned
local function unfold(f)
  local r = pack(safeCall(f, false))
  for i=1, r.n do
    if r[i] and isCallable(r[i]) then unfold(r[i]) end
  end
  return r
end

-----------------------------------------------------------------
-- Assemble
-----------------------------------------------------------------

local pointer, prog = robot or drone, ''

--[[MINIFY]]
local shellArg, runCount = ...

-- Program is called from shell
if shellArg then prog = shellArg end
--]]

-- Program defined by Robot/Drone name
if --[[MINIFY]]not prog and--]]
  pointer and pointer.name then prog = pointer.name()
end

if prog=='' then localError'No program' end

-- Play music
--[[MINIFY]]if not shellArg then--]]
for s in prog:sub(1,5):gmatch"%S" do
  computer.beep(math.min(2000, 200 + s:byte() * 10), 0.05)
end
--[[MINIFY]]end--]]

local code = translate(prog)
local fnc = loadBody('return '..code, code, prog)
while true do
  local r = unfold(fnc)
  --[[MINIFY]]
  if type(runCount) == 'number' then
    runCount = runCount - 1
    if runCount <= 0 then return unpack(r) end
  end
  --]]
  q_G.i = q_G.i + 1
  if q_G.i % 100 == 99 then q_G.sleep(0.05) end
end
