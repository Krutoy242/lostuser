--[[

Lost User - simpliest robot

Author: Krutoy242

Source and readme:
https://github.com/Krutoy242/lostuser

]]

--[[
██╗███╗   ██╗██╗████████╗
██║████╗  ██║██║╚══██╔══╝
██║██╔██╗ ██║██║   ██║
██║██║╚██╗██║██║   ██║
██║██║ ╚████║██║   ██║
╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝
]]

-- Forward declarations
local pack, unpack, run, loadBody, q, Q = table.pack, table.unpack

--[[MINIFY]]
-- If we run from OpenOS
if require then
  component, computer = require'component', require'computer'
end
local skipComponents = {
  computer=true
}
--]]

-- Define all components as big letter global, short names first
do
  local registered = {} -- Set of registered components
  for address, name in pairs(component.list()) do
    --[[MINIFY]]if not skipComponents[name] then--]]
    local C,p = name:sub(1, 1):upper(),component.proxy(address)
    _G[name] = _G[name] or p
    if _G[C]==nil or (registered[C] and #registered[C] > #name) then
      _G[C] = p
      registered[C] = name
    end
    --[[MINIFY]]end--]]
  end
end

--- Remove `%` symbol from chat log since its cause an error FML error
--- [Client thread/ERROR] [FML]: Exception caught during firing event net.minecraftforge.client.event.ClientChatReceivedEvent@3e83e9ca:
--- net.minecraft.util.text.TextComponentTranslationFormatException: Error parsing
local function escape(s) return s:gsub('%%','%%%%') end

--- Signal that we have error
---@param err string
---@param skipTraceback? number
local function localError(err, skipTraceback)
  if computer then computer.beep(1800, 0.5) end
  error(escape(
    tostring(err):gsub('%[string ".+"%]:%d+: ', '')
    -- skipTraceback and tostring(err) or debug.traceback(err)
  ), 0)
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
  if type(t)~='table' then return tostring(t) end
  local s,keys='',{}
  local function append(l) s=s..(s==''and''or',')..l end
  for i=1,#t do append(tostring(t[i]))keys[i]=true end
  for k,v in pairs(t) do if not keys[k] then append(tostring(k)..'='..tostring(v)) end end
  return s
end

--- Create new table with members from first one plus second one
--- If second table not provided - just copy forst one
---@param a table
---@param b? table
---@return string
-- local function merge(a,b)
--   local t = {}
--   for k, v in pairs(a) do t[k] = v end
--   if b then
--     for k, v in pairs(b) do t[k] = v end
--   end
--   return t
-- end

--[[
███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████║██║
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
]]

--- Filter table.
--- Remove values for keys that not pass predicate
--- {1, '', 3, 0, foo = false, goo=true}  / 'a1' => {1, 3, goo=true}
--- For each t run f(k,v)
--- map({1,2,3}, (k,v)=>k,v*2) == {{1,2},{2,4},{3,6}}
---@param t table
---@param f function(k:integer, v:any): boolean
---@param isFilter? boolean filter instead of map
---@return table<any, any> f(k,v) will be wrapped into table
local function map(t, f, isFilter)
  local r = {}
  for k, v in pairs(t) do
    local res = f(k,v)
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
  return r
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
---@param t table
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
  local t,rgx = {},'^'..short:gsub('.','%1.*')
  for k,v in pairs(obj) do
    if type(k)=='string'
      and (not onlyTables or type(v) == 'table')
      and k:match(rgx)
    then
      t[#t+1] = k
    end
  end
  table.sort(t, function(a,b)
    local m,n=#a,#b
    return m==n and a:upper() < b:upper() or m<n
  end)
  return t[1]
end

--- Find value by key in table
---@param t table
---@param keyFull string
---@return any Queued value q(v)
local function index(t, keyFull)
  local exact = t[keyFull]
  if exact ~= nil then return q(exact) end
  local C = keyFull:sub(1,1)

  -- Global key that started with _
  if C == '_' or C == 'i' then
    local postfix = keyFull:sub(2)
    local num = tonumber(postfix)
    --[[<!-- indexing _ -->
      - **Using `_` with numbers `_123`**  
        Will return new array-like list with length of number.  
        If first digit is `0` - table will be zero-based
        > ```lua
        > _8  -- return {1,2,3,4,5,6,7,8}
        > _08 -- return {[0]=0,1,2,3,4,5,6,7}
        > ```
      - **Using `_` with words `_abc`**  
        Create function that would write result into `abc` variable.  
        Function returns passed value.  
        Note that `_abc` is functionable.
        > ```lua
        > _a(4) -- Writes `4` into global `a`, returns 4
        > _a'Ru3' -- Writes func. that execute `Ru3` into global `a`
        > _a^Ru -- Create func. that write result of `Ru` into global `a`
        > b._a^3 -- b.a = 3
        > ```
    ]]
    if num then
      local from = (postfix:sub(1,1)=='0') and 0 or 1
      if C == '_' then
        local arr = {}
        for i = from, num - (1 - from) do arr[i] = i end
        return q(arr)

      -- i modulus
      elseif t.i then
        return t.i % num + from
      end
    else
      -- _a(value) => a = value
      return q(function(v) t[postfix] = v; return v end)
    end
    -- TODO: add functionality for q{}._
  end

  local key,arg = keyFull:match'(.-)(%d*)$'

  -- Key ends with number - probably function call
  -- Ru3 => robot.use(3)
  if arg ~= '' then
    local f = index(t, key)
    if isCallable(f) then
      return Q(f(tonumber(arg)))
    end

  -- Big letter shortand Tg => T.g
  elseif key:match'^[A-Z]' then
    local obj
    if t[C] ~= nil then
      obj = t[C]
    else
      obj = t[getKey(C:lower(), t, true)]
    end
    if obj then
      return #key == 1 and q(obj) or index(obj, key:sub(2))
    end
  end

  -- Other cases
  return q(t[getKey(key, t)])
end

local function isQ(t)
  local succes, mt = pcall(getmetatable, t)
  return succes and mt and mt.__q
end

local function safeCall(f, ...)
  local safeResult = pack(pcall(f, ...))
  if not safeResult[1] then localError(safeResult[2]) end
  return unpack(safeResult, 2)
end

--- Generate safe function from lua code
---@param txt string Lua code to load as function body
---@param params string param names devided by comma
local function makeRunedFunction(txt, params)
  local p1, p2 = 'return function(...)local '.. params ..'=... ', txt..' end'
  return function(...) return safeCall(
    loadBody(p1..'return '..p2, p1..p2, txt, ...)(), ...
  ) end
end

--- Generate helper functions
---@param target any Anything we targeting function to
---@param params? string param names devided by comma
---@return function, boolean
local function getTarget(target, params)
  local tt = type(target)
  local trgFnc
  if tt == 'string' then
    trgFnc = makeRunedFunction(target, params or 'k,v')
  elseif isCallable(target) then
    trgFnc = target
  end
  return trgFnc, tt == 'table'
end

--- Make call function
---@param f function
---@return function
local function QFnc(f)
  return function(_, ...) return Q(f(...)) end
end

--[[
███╗   ███╗████████╗
████╗ ████║╚══██╔══╝
██╔████╔██║   ██║
██║╚██╔╝██║   ██║
██║ ╚═╝ ██║   ██║
╚═╝     ╚═╝   ╚═╝
]]

--- Pack all parameters as q
Q = function(...)
  local r = {}
  for k, v in pairs(pack(...)) do r[k] = q(v) end
  return unpack(r)
end

--- Single value q(t)
q = function(t)
  local qtype = type(t)
  local qIsCallable = isCallable(t)
  if (qtype ~= 'table' and not qIsCallable) or isQ(t) then return t end

  --############################################################
  -- Generic operator
  --############################################################
  --- Compute operator result based on different targets
  ---@param op string operator identifier
  ---@return any
  local function generic(op)
    return function(source, target)

      -- Determine sides
      local swap
      if type(source) ~= 'table' then
        source, target = target, source
        swap = true
      end

      local trgFnc, trgTable = getTarget(target)
      local r

      if not qIsCallable then
        --?-- Table x Function|String
        if trgFnc then

          --[[<!-- t^f -->
            Classical map
            ```lua
            _{4,5,6}^f -- {f(4),f(5),f(6)}
            ```
          ]]
          if op=='map' then
            r = map(source, trgFnc)

          --[[<!-- t/f -->
            Filter, keep only if value is [Truthy](#Truthy)
            ```lua
            _{4,5,6,7}/'v%2' -- {5,7}
            ```
          ]]
          elseif op=='lambda' then
            r = map(source, trgFnc, true)

          --[[<!-- t~f -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `t~f`
          -- elseif op=='loop' then
          --   r = loop(source, true, trgFnc)

          end

        --?-- Table x Table
        elseif trgTable then

          --[[<!-- t^t -->
            Pick indexes
            ```lua
            _{4,5,6}^{3,1} -- {6,4}
            ```
          ]]
          if op=='map' then
            r = map(target, function(k,v) return source[v] end) -- _{4,5,6}^{3,1} -- {6,4}

          --[[<!-- t/t -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `t/t`
          -- elseif op=='lambda' then
          --   r = map(source, function(k,v) return function() return v(unpack(target)) end end)

          --[[<!-- t~t -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `t~t`, probably merge, union, intersection
          --elseif op=='loop' then r = nil
          -- _{1,2,a=3}~{a=4,5,6} => {1,2,3,4,5,6}
          -- _2~_3 => {1,2,1,2,3}

        end

        --?-- Table x Number|Boolean
        else

          if op=='map' then
            if swap then
              --[[<!-- n^t -->
                Get by numerical or boolean index
                ```lua
                2^_{4,5,6} -- 5
                ```
              ]]
              r = source[target]
            else
              --[[<!-- t^n -->
                Push value in table
                ```lua
                _{1,2,3}^4 -- _{1,2,3,4}
                ```
              ]]
              source[#source + 1] = target; r = source
            end

          elseif op=='lambda' then
            if swap then
              --[[<!-- n/t -->
                Get by modulus
                ```lua
                i/t -- t[i % #t + 1]
                ```
              ]]
              r = source[target % #source + 1]
            else
              --[[<!-- t/n -->
                Remove index
                ```lua
                _3/2 -- {1=1,3=3}
                ```
              ]]
              source[target] = nil; r = source
            end

          --[[<!-- t~n -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `t~n`
          --[[<!-- n~t -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `n~t`
          -- elseif op=='loop' then
          --   r = loop(source, true, function(j) return j <= TONUMBER(target) end)

          end

        end
      else
        --?-- Function x Function|String
        if trgFnc then

          --[[<!-- f^f -->
            Composition
            ```lua
            f^g -- (...)=>f(g(...))
            ```
          ]]
          if op=='map' then
            r = function(...) return source(trgFnc(...)) end

          --[[<!-- f/f -->
            Reversed composition
            ```lua
            f/g -- (...)=>g(f(...))
            ```
          ]]
          elseif op=='lambda' then
            r = function(...) return trgFnc(source(...)) end

          --[[<!-- f~f -->
            While truthy do
            ```lua
            f~g -- while truthy(g(j++)) do f(j) end
            ```
          ]]
          elseif op=='loop' then
            r = loop(source, false, trgFnc)

          end

        --?-- Function x Table
        elseif trgTable then

          --[[<!-- f^t -->
            Unpack as arguments
            ```lua
            f^{1,2,3} -- f(1,2,3)
            ```
          ]]
          if op=='map' then
            r = source(unpack(target)) -- f x {1,2,3} => f(1,2,3) (Unpack table)

          --[[<!-- f/t -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `f/t`
          -- elseif op=='lambda' then
          --   r = map(target, source)

          --[[<!-- f~t -->
            <sub>Not yet implemented</sub>
          ]]
          -- TODO: Implement `f~t`
          --elseif op=='loop' then r = nil

          end

        --?-- Function x Number|Boolean
        else

          --[[<!-- f^n -->
            Simple call
            ```lua
            f^1 -- f(1)
            ```
          ]]
          if op=='map' then
            r = QFnc(source)(source, target)

          elseif op=='lambda' then
            if swap then
              --[[<!-- n/f -->
                Rotated composition
                ```lua
                2/f -- (...)=>f(..., 2)
                ```
              ]]
              r = function(...) return source(..., target) end
            else
              --[[<!-- f/n -->
                Composition
                ```lua
                f/1 -- (...)=>f(1,...)
                ```
              ]]
              r = function(...) return source(target, ...) end
            end

          elseif op=='loop' then
            if swap then
              --[[<!-- n~f -->
                Same as `f~n`, but without passing index
                ```lua
                n~f -- for j=1,TONUMBER(n) do f() end
                ```
              ]]
              for j=1,TONUMBER(target) do r = source() end
            else
              --[[<!-- f~n -->
                For loop
                ```lua
                f~n -- for j=1,TONUMBER(n) do f(j) end
                ```
              ]]
              r = loop(source, false, function(j) return j <= TONUMBER(target) end)
            end

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
          > - All keys of table would be converted to inexed
          > - Only 1 level of flattening

          ```lua
          ~_{1,{2,3},{4,a=5,b={6,c=7}}}
          -- {1,2,3,4,5,{6,c=7}}
          ```
        ]]
        if op=='lambda' then
          r = flatten(t)

        --[[<!-- -t -->
          Swap keys and values

          ```lua
          -_{'a','b','c'}
          -- {a=1,b=2,c=3}
          ```
        ]]
        elseif op=='map' then
          r = {} for k,v in pairs(t) do r[v]=k end
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
          <sub>Not yet implemented</sub>
        ]]
        -- TODO: Implement `-f`, probably composable function `-f (v) => (...) => f(v, ...)`
        elseif op=='map' then

        end
      end
      return q(r)
    end
  end
  --############################################################

  local mt = {
    __q = qIsCallable and 1 or 0,
    __tostring = function() return '_'..(qIsCallable and tostring(t) or '{'..serialize(t)..'}') end,
  }

  -- 1 --
  --[[ ^ ]] mt.__pow = generic'map'

  -- 2 --
  --[[ - ]] mt.__unm = unary'map'
  --[[ ~ ]] mt.__bnot = unary'lambda'
  -- [[ # ]] mt.__len = unary'??'

  -- 3 --
  -- [[ * ]] mt.__mul = generic'??'
  -- [[ % ]] mt.__mod = generic'??'
  --[[ / ]] mt.__div = generic'lambda'
  -- [[// ]] mt.__idiv = generic'??'

  -- 4 --
  -- [[ + ]] mt.__add = generic'??'
  --[[ - ]] mt.__sub = mt.__div -- lambda

  -- 5 --
  --[[ .. ]] mt.__concat = generic'loop'

  -- 6 --
  -- [[<< ]] mt.__shl = generic'??'
  -- [[>> ]] mt.__shr = generic'??'

  -- 7 --
  --[[ & ]] mt.__band = mt.__pow -- map

  -- 8 --
  --[[ ~ ]] mt.__bxor = mt.__concat -- loop

  -- 9 --
  --[[ | ]] mt.__bor = mt.__div -- lambda

  -- 10 --
  -- [[ < ]] mt.__lt = generic'??'
  -- [[<= ]] mt.__le = generic'??'
  -- [[== ]] mt.__eq = generic'??'

  -----------------------------------------------------------------
  --[[
    Possible need to implement:
    - zip
    - flat
    - gsub
  ]]
  -----------------------------------------------------------------

  if qIsCallable then
    mt.__call = QFnc(t)
    --[[<!-- #f -->
      Make a funtion that would wrap it result into table.  
      Useful for functions that returns several values
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

  function mt:__index(key)
    --  TODO: add function indexing
    --* Possible ideas:
    --* • f[2] pop 2 from stack and call
    --* • f.n working with call result, like map table
    --* • f[{}] possible same as above
    return index(t, key)
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

  -- When pairs, returned elements wrapped into q(v)
  function mt:__pairs()
    return function(self, k)
      local k, v = next(t, k)
      return k, q(v)
    end, t, nil
  end
  function mt:__len() return #t end

  return setmetatable({}, mt)
end

--[[
████████╗██████╗  █████╗ ███╗   ██╗███████╗██╗      █████╗ ████████╗███████╗
╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ██╔══██╗╚══██╔══╝██╔════╝
   ██║   ██████╔╝███████║██╔██╗ ██║███████╗██║     ███████║   ██║   █████╗
   ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██╔══██║   ██║   ██╔══╝
   ██║   ██║  ██║██║  ██║██║ ╚████║███████║███████╗██║  ██║   ██║   ███████╗
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
]]

local _MACROS = {
  'ⓐ', ' and ',
  'ⓞ', ' or ',
  'ⓝ', ' not ',
  'ⓡ', ' return ',
  '⒯', '(true)',
  '⒡', '(false)',
  '∅', ' __trash=',
  '!', '()',
}

--- Replace all macroses
---@param text string
local function translate(text)
  local i = 1
  while i <= #_MACROS do
    text = text:gsub(_MACROS[i], _MACROS[i+1])
    i=i+2
  end
  return text
end

--[[
██╗      ██████╗  █████╗ ██████╗
██║     ██╔═══██╗██╔══██╗██╔══██╗
██║     ██║   ██║███████║██║  ██║
██║     ██║   ██║██╔══██║██║  ██║
███████╗╚██████╔╝██║  ██║██████╔╝
╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝
]]

-- Global environment inside loaded code
local __ENV = q(_G)

--- Attempt to load code1 or code2
---@param code1 string
---@param code2 string
---@param chunkName string
loadBody = function(code1, code2, chunkName, ...)
  local t

  -- If we have table parameters that need to be exposed
  -- add them to upvalue
  local expose = pack(...)
  if expose.n > 0 then
    t = q{}
    for k, v in pairs(__ENV) do t[k] = v end
    for k, v in pairs(expose) do
      if type(v) == 'table' then
        for k, v in pairs(v) do t[k] = v end
      end
    end
    -- for k, v in pairs(t) do print(' '..k)end
  else
    t = __ENV
  end

  -- Load
  local res, err = load(code1, chunkName, nil, t)
  if err then
    res, err = load(code2, chunkName, nil, t)
  end
  return err and localError(err) or res
end

__ENV.i = 0

-- Recursively call functions that returned
local function unfold(f)
  local r = pack(safeCall(f))
  for i=1,r.n do
    if r[i] and isCallable(r[i]) then unfold(r[i]) end
  end
  return r
end

--[[MINIFY]]local runCount--]]
run = function(input)
  local code = translate(input)
  local fnc = loadBody('return '..code, code, input)
  while true do
    local r = unfold(fnc)
    --[[MINIFY]]
    if type(runCount) == 'number' then
      runCount = runCount - 1
      if runCount <= 0 then return unpack(r) end
    end
    --]]
    __ENV.i = __ENV.i + 1
    if __ENV.i % 100 == 99 then __ENV.sleep(0.05) end
  end
end

__ENV.write = function(...)
  --[[MINIFY]]if print then runCount = 0 return print(...) end--]]
  localError(q{...}, 0)
end

__ENV.sleep = function(t)
  local u = computer.uptime
  local d = u() + (t or 1)
  repeat computer.pullSignal(d - u())
  until u() >= d
end

--[[<!-- calling _ -->
  - **Using `_` on string**  
    Will load code inside this string and return it as function.
    > ```lua
    > _'Rm,s2'()(0) -- call `sleep(2),robot.move(0)`
    > ```
    > Note that in this example, the `_` function returns two values - the `robot.move` function and the result `sleep(2)`. Only when we call the returned values a second time, `robot.move(0)` called

  - **Using `_` on *table* or *function***  
    Will convert them into `_{}` table or `_''` function to use with [Functional Programming](#functional-programming)
    > ```lua
    >  {1,2}^1 -- would error
    > _{1,2}^1 -- would return {1,1} (see Functional Programming)
    > ```
]]
__ENV._ = function(target, ...)
  -- local args = table.pack(...)
  -- if args.n > 0 then
  --   if truthy(target) then return args[1] else return args[2] end
  -- end
  local trgFnc, trgTable = getTarget(target)
  return q(trgFnc or target)
end

-- Get value from global
__ENV.api = function(s, p)
  return __ENV.write(getKey(s, p or _G))
end

-----------------------------------------------------------------
-- Assemble
-----------------------------------------------------------------

local pointer, prog = R or D, ''

--[[MINIFY]]
local shellArg
shellArg, runCount = ...

-- Program is called from shell
if shellArg then prog = shellArg end
--]]

-- Program defined by Robot/Drone name
if --[[MINIFY]]not prog and--]]
  pointer and pointer.name then prog = pointer.name()
end

if prog=='' then localError'No program' end

-- Play music
if --[[MINIFY]]not shellArg and--]]
prog:sub(1,1) ~= ' ' then
  for s in prog:sub(1,5):gmatch"%S" do
    computer.beep(math.min(2000, 200 + s:byte() * 10), 0.05)
  end
end

return run(prog)
