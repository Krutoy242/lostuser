# `Lost User` - The Simplest Robot

Robot (or drone!) BIOS program for the Minecraft OpenComputers mod.

- [`Lost User` - The Simplest Robot](#lost-user---the-simplest-robot)
  - [Why?](#why)
  - [Setup](#setup)
    - [Assemble](#assemble)
    - [E2E-E](#e2e-e)
    - [Write the Program to EEPROM](#write-the-program-to-eeprom)
    - [Insert into Robot](#insert-into-robot)
  - [Usage](#usage)
  - [Syntax](#syntax)
    - [Statements and Expressions](#statements-and-expressions)
      - [Execution](#execution)
      - [Return](#return)
    - [Globals](#globals)
  - [Shortening](#shortening)
  - [Lodash `_`](#lodash-_)
    - [Indexing `_`](#indexing-_)
    - [Calling `_`](#calling-_)
  - [Functional Programming](#functional-programming)
    - [Precedence](#precedence)
    - [Map `^`, `+`, or `&`](#map---or-)
    - [Lambda `-` `/` `|`](#lambda----)
    - [Loop `~` or `*`](#loop--or-)
    - [Unary](#unary)
    - [Truthy](#truthy)
  - [Macros](#macros)
  - [Examples](#examples)
  - [Additionals](#additionals)
    - [Numeric Dictionary](#numeric-dictionary)
  - [Links](#links)

## Why?

OC robots are complex to assemble and program. This BIOS program helps to use robots as "users" and in many other ways.

## Setup

### Assemble

Assemble the robot in the minimum configuration:

- Case
- CPU
- RAM

<img src="https://i.imgur.com/sBP2y0N.png" width="350">

### E2E-E

If you play [Enigmatica 2: Expert - Extended](https://www.curseforge.com/minecraft/modpacks/enigmatica-2-expert-extended), the modpack has a predefined EEPROM recipe.  
Find it in JEI and craft it. It will have a colored glow.

![EEPROM Crafting](https://i.imgur.com/GuT7Ke6.gif)

If you crafted it, you can skip the next step `Write the Program to EEPROM`.

### Write the Program to EEPROM

> You need a working OC computer to write the BIOS. See [this tutorial](https://www.youtube.com/watch?v=KDqXJzacdQQ) to assemble your first computer.

1. Download the file from the internet (requires an [Internet Card](https://is.gd/zrPusF 'Internet Card')), run from the command line:

```shell
wget https://raw.githubusercontent.com/Krutoy242/lostuser/main/lostuser.min.lua
```

2. To write to an existing EEPROM, run:

```shell
flash -q lostuser.min.lua LostUser
```

### Insert into Robot

Take the EEPROM from the computer case and insert it into the robot.

![Combining robot with EEPROM](https://i.imgur.com/7AHXvdm.png)

## Usage

Program the robot by **renaming it**. Rename the Robot on an [Anvil](https://is.gd/pYpuM1 'Anvil') or with a [Labeller](https://is.gd/VgGaLN 'Labeller').

Name your Robot `robot.use(3)`, place it on the ground, turn it on, and watch it click blocks in front.

![Robot activating lever](https://i.imgur.com/ATnKS34.gif)

## Syntax

**TL;DR**

If you don't want to learn Lua and you need the robot to right/left click, here are a few simple names for the robot and the result:

- `robot.use(3)` - The robot will right-click on the block in front.
- `robot.swing(3)` - The robot will swing with a sword or break the block in front of it.

### Statements and Expressions

#### Execution

The robot will execute its name as Lua code in a `while true` loop.

Code can be run in any variation - `statement` or `expression`, but must still follow Lua code flow rules.

> This is a statement
> ```lua
> sleep(1)
> ```
>
> This is an expression
> ```lua
> 1, sleep(1)
> ```
>
> Combining a statement and an expression
> ```lua
> a = robot.move(3) return a and robot.use(0)
> ```

#### Return

If an expression returns one or more functions, they will be executed recursively.

Note that all return values are calculated first, and only then will the functions be called.

> Calling `robot.use(3)`, and then `sleep()`
> ```lua
> function() return sleep end, robot.use(3)
> ```

### Globals

<!-- components -->
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
<!--  -->

Additional globals:

- `i` - current loop index, starting from 0.
  > You can add a number after `i` to get it by modulus +1.
  > ```lua
  > i16 = i % 16 + 1
  > ```
- `sleep(seconds: number = 1)`
- `api(shortName: string, obj?: table)` - write the long name of the shorthand.

## Shortening

Since a Robot or Drone name can have only `64` characters, pointers must be shortened.

So, instead of writing the full pointer name, you can shorten it. For example, instead of writing `robot.use(3)`, you can write `r.u(3)`, or even `Ru3`.

Shortening rules:

1. If a key has an exact non-nil match, it will be returned.
    > `R.use(3)` - `R` is a global representing the `robot` component.

2. The shorthand must contain the first letter and then, optionally, any number of remaining letters.
    > ```lua
    > tbl.unk => table.unpack
    > t.u => table.unpack
    > ```

3. If several names have the same first letter, the **shortest**, **alphabetically** sorted name will be picked first.
    > ```lua
    > robot.s   -- robot.slot
    > robot.se  -- robot.space
    > robot.sel -- robot.select
    > ```

4. A big first letter with a dot `.` can be used without the dot.
    > ```lua
    > -- Same pointers
    > robot.use == R.use == Ruse == Ru
    > ```

5. A number at the end of a shorthand will call the shorthand as a function with that number as the first argument.
    > ```lua
    > Ru3 -- robot.use(3)
    > s10 -- sleep(10)
    > ```
    At the same time, if it's a table instead of a function, all keys of the table will be naturally sorted and the `N`th element returned.
    > ```lua
    > R16 -- robot.select
    > ```
    See more in [Numeric Dictionary](#numeric-dictionary).

6. Local variables can't be shortened.
    > ```lua
    > local query = {len=4}
    > q.l -- Exception: q is nil
    > query.l -- l is nil
    > query.len -- 4
    > ```

## Lodash `_`

The low dash `_` is a special helper function.

### Indexing `_`

<!-- indexing _ -->
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
<!--  -->

### Calling `_`

<!-- calling _ -->
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
<!--  -->

## Functional Programming

Any table or function that you can get from a global will be converted into a special `_{}` table.

This table is enhanced with additional operator metamethods that help with functional-style programming.

Any iteration or `pairs()` calls on these converted tables will output elements in naturally sorted order.

**Operators** behave differently depending on the left and right side of the operator.

Note that whenever a `string` is detected, it will be loaded and converted to a function in the manner of `_'fnc'`.

### Precedence

Operator precedence in Lua follows the table below, from higher to lower priority:

1. `^`
2. unary `not` `#` `-` `~`
3. `*` `/` `//` `%`
4. `+` `-`
5. `..`
6. `<<` `>>`
7. `&`
8. `~`
9. `|`
10. `<` `>` `<=` `>=` `~=` `==`
11. `and`
12. `or`

<!--
███╗   ███╗ █████╗ ██████╗ 
████╗ ████║██╔══██╗██╔══██╗
██╔████╔██║███████║██████╔╝
██║╚██╔╝██║██╔══██║██╔═══╝ 
██║ ╚═╝ ██║██║  ██║██║     
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     
-->

### Map `^`, `+`, or `&`

`^`, `+`, and `&` operators do the same. There are three of them only to manage precedence.

> ```lua
> -- Assume that f,g and h is functions
> f&g+h -- equal to `f & g(h())`
> f+g&h -- equal to `f(g()) & h`
> ```

- **Note¹:** `^` is right associative. This means the right side will be computed first.

- **Note²:** You can also call *uncallable* tables. `t(x)` is the same as `t^x`. *Uncallable* tables are tables without a `__call` metatable.
  Example (map `t^f`):
  ```lua
  _{1,2,3}'0' -- _{0,0,0}
  ```

<table>
<tr>
  <th>Left</th><th>Right</th><th>Result</th>
</tr>

<tr>
  <td rowspan=3>Table</td><td>Function</td><td>

<!-- t^f -->
Classical map
```lua
_{4,5,6}^f -- {f(4),f(5),f(6)}
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- t^t -->
Pick indexes
```lua
_{4,5,6}^{3,1} -- {6,4}
```
<!--  -->

</td></tr>
<tr><td>Number, Boolean</td><td>

<!-- t^n -->
Push value in END of table
```lua
_{1,[3]=3,a=6,[4]=4}^5
-- _{1,3=3,4=4,5=5,a=6}
```
<!--  -->

</td></tr>
<tr><td rowspan=3>Function</td><td>Function</td><td>

<!-- f^f -->
Composition
```lua
f^g -- (...)=>f(g(...))
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- f^t -->
Unpack as arguments
```lua
f^{1,2,3} -- f(1,2,3)
```
<!--  -->

</td></tr>
<tr><td>Number, Boolean</td><td>

<!-- f^n -->
Simple call
```lua
f^1 -- f(1)
```
<!--  -->

</td></tr>
<tr><td rowspan=2>Number, Boolean</td><td>Table</td><td>

<!-- n^t -->
Get by numerical or boolean index
```lua
2^_{4,5,6} -- 5
```
<!--  -->

</td></tr>
<tr><td>Function</td><td>

<!-- n^f -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
</table>

<!--
██╗      █████╗ ███╗   ███╗██████╗ ██████╗  █████╗
██║     ██╔══██╗████╗ ████║██╔══██╗██╔══██╗██╔══██╗
██║     ███████║██╔████╔██║██████╔╝██║  ██║███████║
██║     ██╔══██║██║╚██╔╝██║██╔══██╗██║  ██║██╔══██║
███████╗██║  ██║██║ ╚═╝ ██║██████╔╝██████╔╝██║  ██║
╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝
-->

### Lambda `-` `/` `|`

<table>
<tr>
  <th>Left</th><th>Right</th><th>Result</th>
</tr>

<tr>
  <td rowspan=3>Table</td><td>Function</td><td>

<!-- t/f -->
Filter, keep only if value is [Truthy](#truthy)
```lua
_{4,5,6,7}/'v%2' -- {5,7}
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- t/t -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
<tr><td>Number, Boolean</td><td>

<!-- t/n -->
Remove index
```lua
_3/2 -- {1=1,3=3}
```
<!--  -->

</td></tr>
<tr><td rowspan=3>Function</td><td>Function</td><td>

<!-- f/f -->
Reversed composition
```lua
f/g -- (...)=>g(f(...))
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- f/t -->
Simple call
```lua
f/R -- f(R)
```
<!--  -->

</td></tr>
<tr><td>Number, Boolean</td><td>

<!-- f/n -->
Composition
```lua
f/1 -- (...)=>f(1,...)
```
<!--  -->

</td></tr>
<tr><td rowspan=2>Number, Boolean</td><td>Table</td><td>

<!-- n/t -->
Get by modulus
```lua
i/t -- t[i % #t + 1]
```
<!--  -->

</td></tr>
<tr><td>Function</td><td>

<!-- n/f -->
Rotated composition
```lua
2/f -- (...)=>f(..., 2)
```
<!--  -->

</td></tr>
</table>

<!--
██╗      ██████╗  ██████╗ ██████╗
██║     ██╔═══██╗██╔═══██╗██╔══██╗
██║     ██║   ██║██║   ██║██████╔╝
██║     ██║   ██║██║   ██║██╔═══╝
███████╗╚██████╔╝╚██████╔╝██║
╚══════╝ ╚═════╝  ╚═════╝ ╚═╝
-->

### Loop `~` or `*`

<table>
<tr>
  <th>Left</th><th>Right</th><th>Result</th>
</tr>

<tr>
  <td rowspan=3>Table</td><td>Function</td><td>

<!-- t~f -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- t~t -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
<tr><td>Number, Boolean</td><td>

<!-- t~n -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
<tr><td rowspan=3>Function</td><td>Function</td><td>

<!-- f~f -->
While truthy do
```lua
f~g -- while truthy(g(j++)) do f(j) end
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- f~t -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
<tr><td>Number, Boolean</td><td>

<!-- f~n -->
For loop
```lua
f~n -- for j=1,TONUMBER(n) do f(j) end
```
<!--  -->

</td></tr><tr><td rowspan=2>Number, Boolean</td><td>Table</td><td>

<!-- n~t -->
<sub>Not yet implemented</sub>
<!--  -->

</td></tr>
<tr><td>Function</td><td>

<!-- n~f -->
Same as `f~n`, but without passing index
```lua
n~f -- for j=1,TONUMBER(n) do f() end
```
<!--  -->

</td></tr>
</table>

<!--
██╗   ██╗███╗   ██╗ █████╗ ██████╗ ██╗   ██╗
██║   ██║████╗  ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
██║   ██║██╔██╗ ██║███████║██████╔╝ ╚████╔╝
██║   ██║██║╚██╗██║██╔══██║██╔══██╗  ╚██╔╝
╚██████╔╝██║ ╚████║██║  ██║██║  ██║   ██║
 ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
-->

### Unary

<table>
<tr>
  <th>Unary</th><th>Object</th><th>Result</th>
</tr>

<tr><td rowspan=2>

`~`</td><td>Function</td><td>

<!-- ~f -->
While truthy do
```lua
~f -- repeat until not truthy(f())
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- ~t -->
Flatten table, using numerical indexes.

> - Order of elements can be different
> - All keys of the table would be converted to indexed
> - Only 1 level of flattening

```lua
~_{1,{2,3},{4,a=5,b={6,c=7}}}
-- {1,2,3,4,5,{6,c=7}}
```
<!--  -->

</td></tr>

<tr><td rowspan=2>

`-`</td><td>Function</td><td>

<!-- -f -->
Make a function whose result will be flipped.
If the result is `truthy`, returns `0`. Return `1` otherwise.
```lua
-- id here is function that returns its first arg
(-id)(0) -- 1
(-id)(4) -- 0
(- -id)(4) -- 1
```
<!--  -->

</td></tr>
<tr><td>Table</td><td>

<!-- -t -->
Swap keys and values

```lua
-_{'a','b','c'}
-- {a=1,b=2,c=3}
```
<!--  -->

</td></tr>

<tr><td>

`#`</td><td>Function</td><td>

<!-- #f -->
Make a function that would wrap its result into a table.
Useful for functions that return several values.
```lua
-- Consider `f(n)` returns three values - 2,3,n
f&4   -- 2
#f&4  -- _{2,3,4}
```
<!--  -->

</td></tr>

</table>

### Truthy

A value is considered `truthy` if it is not `falsy`.

`falsy` values are:

1. `false` or `nil`
2. `''` (empty string)
3. `0` (number zero)
4. `nan` (not a number, `n ~= n`)
5. `inf` or `-inf` (result of `1/0` or `-1/0`)

## Macros

The program has several predefined macros - symbols that will be replaced everywhere with another text.

```javascript
! => '()'
ⓐ => ' and '
ⓞ => ' or '
ⓝ => ' not '
ⓡ => ' return '
⒯ => '(true)'
⒡ => '(false)'
```

## Examples

- **Travel between two waypoints and run its label**

  > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__19.png "Navigation Upgrade")

  ![Drone navigating waypoints](https://i.imgur.com/36HdGzO.gif)

  Drone name:
  ```lua
  P=i/Nf300ⓡDm^Pp,s/1~'Dg0>1',_(Pl)
  ```
  * `Nf300`: Run `navigation.findWaypoints(300)`.
  * `i/Nf300`: `i` is the index of script execution. `i / table` is "Get by index modulus" `t[i % #t + 1]`.
  * `P=i/Nf300`: Write into the global variable `P` a different waypoint each script cycle.
  * `ⓡ`: will be replaced by ` return `
  * `Dm^Pp`: calling `drone.move(table.unpack(P.position))`.
  * `s/1~'Dg0>1'` => `while drone.getOffset() > 1 do sleep(1) end`.
  * `_(Pl)`: Load `P.label` as Lua code. This loaded function would be [returned and executed](#return).

  Waypoints labels. The first one just sucks from the bottom, the second one iterates over 4 slots and drops down.
  ```lua
  _'Dsk0'~4
  Dsel-'Dd0'~4
  ```

- **Zig-Zag + Use Down, useful for farms**

  > Required upgrades: none

  ![Robot farming](https://i.imgur.com/YTd5idO.gif)

  Robot name:
  ```lua
  m,t=_'Rm3,Ru0',Rtn/(i2>1)ⓡ~m,t!,_'m!,t!'!ⓞt/m
  ```
  * `m,t=_'Rm3,Ru0',Rtn/(i2>1)`: define two functions for moving and rotating
    - `_'Rm3,Ru0'`: define a function `Rm3,Ru0` that would move forward and use a tool down
    - `Rtn/(i2>1)`: this makes a function that would call `Rtn` (`robot.turn`) with the argument `i2>1`. `i2` is shorthand for `i%2+1`
  * `~m`: Makes the robot move forward until it can't move.
  * `t!`: `t` is Rtn/(i2>1) while `!` replaced with `()` so the line will become `Rtn/(i2>1)()`, which means execute turn immediately.
  * `_'m!,t!'!ⓞt/m`: Move and turn. If the move wasn't successful, turn and move again.

- **Trader bot**

  > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__29.png "Trading Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")

  ![Robot trading](https://i.imgur.com/HEgNabM.png)

  Robot name:
  ```lua
  Rsel-'Rd0'~RiS0,IsF/0~Igz0,Tg0'~tr'
  ```
  * `Rsel-'Rd0'~RiS0`: Select each slot and dump to the bottom
    > - `'Rd0'`: is a function that would call `robot.drop(0)` when executed.
    > - `RiS0`: is shorthand for `robot.inventorySize(0)`. Note that this function is not using any arguments so we could call it with `0`
    > - `Rsel`: `robot.select` shorthand. Note that we used `-` operator here, which is the same as `/` but has lower precedence
  * `IsF/0~Igz0`: For each slot of the inventory on the bottom `inventory_controller.getInventorySize(0)` call `inventory_controller.suckFromSlot(0, k)`
  * `Tg0'~tr'`: Trade all trades.
    > - `~tr`: Call `trade()` while it returns true. Note that inside this function, all arguments are exposed as global, so we could access `trade` as global (actually, it's an `upvalue`)

  There is another variant of the robot name, way advanced. It will pull only items that are actually required for trading. This program is hardcoded to work with **internal and external** inventory with size 16:
  ```lua
  -- Trade everything
  a=-~Tg0"_{g!}'n',~tr"ⓡ_16&R16-'Rd0'&IgI/0&'a[n]ⓐI8/0&k'

  -- Do not sell emeralds [id==388]
  a=-~Tg0'388^-g0ⓞ{g0.n,~tr}'ⓡ_16&R16-'Rd0'&IgI/0&'a[n]ⓐI8/0&k'
  ```

- **Rune maker**

  > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")

  Place ingredients in the first 6 slots of the Robot. Living Rock in the 7th, wand in the 8th.

  <img alt="Rune crafting setup" src="https://i.imgur.com/OXRuYs3.png" width=25%>
  <img alt="Robot crafting runes" src="https://i.imgur.com/KqlJqMw.gif">

  Robot name:
  ```lua
  _8/'Rsel^v,v==7ⓐ{s3,Rm1,Rd(3,1),Rm0}ⓞ{Ie!,Ru3,Ie!}'
  ```
  * `Rsel^v`: Select iterated slot
  * `v==7ⓐ{s3,Rm1,Rd(3,1),Rm0}`: if it's the 7th slot with Living Rock, wait 3 seconds until the craft is finished, then drop Rock on top.
  * `Ie!,Ru3,Ie!`: Other slots - just right-click with the item

- **Single tree farm**

  > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")

  This robot is intended to use with Forestry saplings, which usually can't be placed as blocks but need to be right-clicked instead.  
  Also, the robot needs an *unbreakable* Broad Axe from TCon with the *Global Traveler* trait. Additionally, my Axe has the *Fertilizing* trait - right-click to fertilize.  
  Place the robot on top of a container with saplings.

  ![Robot farming trees](https://i.imgur.com/I9W39B0.gif "Robot farming trees")

  Robot name:
  ```lua
  #(1|#Rdt&3)<6ⓐRsw/3-s/1-Rsk/0-Ie-Ru/3-IeⓞRu3,s
  ```
  * `(1|#Rdt&3)`: Detect the block in front, select the second returned value - [block description](https://ocdoc.cil.li/component:robot)
  * `#()<6`: a trick to determine if the block is solid
  * `Rsw/3-s/1`: Cut the whole tree, wait 1 second
  * `Rsk/0-Ie-Ru/3-Ie`: Suck sapling from the bottom, then plant it. Note that `Rsk` derived one value from `sleep` return
  * `Ru3,s`: Fertilize sapling

- **Other examples**

  * *Circular Miner*. Using a Hammer with an Alumite part (Global Traveler trait). Place the Robot underground, place a stack of Charcoal Blocks in the selected robot slot. The Robot will start to circle around, mining everything.
    > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__27.png "Hover Upgrade (Tier 1)")
    > 
    > Optional upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__16.png "Generator Upgrade")
    ```lua
    Gi,_'Rm3,Rsw3'~i*2,Rtn⒯
    ```

  * *Robot sorting mob drop*. Take from the bottom, damageable items to the top, others forward.
    > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")
    ```lua
    Rd|3%2^(IsF(0,i%Igz0+1)ⓐIgSII!.mDⓞ2)
    ```

  * *Cat opener*. Takes 16 items in front, right-clicks them, and then dumps the inventory on top.
    > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")
    ```lua
    Rsk/3&16ⓐIe!,~_'Ru0',_16/Rc|Rsel/'Rd1'
    ```

  * *Compressing bot*. Takes from the front, crafts 3x3, then dumps back.
    > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__11.png "Crafting Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")
    ```lua
    -(_16-Rc&12)|'Rd3'&Rsel,IsF/3/'_11/8/4&Rc!/9/RtT'|i81,Cc
    ```

  * *Unstackable bot*. Takes an item from the front only if they are unstackable and puts it on top. If it can't drop the item on top, pushes up and places a block.
    > Flood all robot slots except 1. Slot 9 should have new inventories for unstackables.
    > 
    > Required upgrades: ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__20.png "Piston Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__17.png "Inventory Upgrade"), ![](https://github.com/Krutoy242/mc-icons/raw/master/i/opencomputers/upgrade__18.png "Inventory Controller Upgrade")
    ```lua
    (IgSI/3&_a^i1728ⓞ{}).mS^_{_'IsF/3&a,Rd1ⓞ{Pps1,Rsel9,Rp1,Rsel1}'}
    ```

## Additionals

### Numeric Dictionary

This is not an actual dictionary - all this information can be generated in-game for every table.

To get sorted numeric values, name the robot this way, where `T` is a pointer to the desired table:
```lua
e((~-T'k')"'\\n'..k..' '..v")
```

Cheatsheet of most common tables:

<table>
<tr><td>

> ```ruby
> robot:
> R1  use
> R2  drop
> R3  fill
> R4  move
> R5  name
> R6  slot
> R7  suck
> R8  turn
> R9  type
> R10 count
> R11 drain
> R12 place
> R13 space
> R14 swing
> R15 detect
> R16 select
> R17 address
> R18 compare
> R19 compareTo
> R20 tankCount
> R21 tankLevel
> R22 tankSpace
> R23 durability
> R24 selectTank
> R25 transferTo
> R26 compareFluid
> R27 getLightColor
> R28 inventorySize
> R29 setLightColor
> R30 compareFluidTo
> R31 transferFluidTo
> ```

</td><td>

> ```ruby
> inventory_controller:
> I1  slot
> I2  type
> I3  equip
> I4  store
> I5  address
> I6  dropIntoSlot
> I7  getAllStacks
> I8  suckFromSlot
> I9  compareStacks
> I10 storeInternal
> I11 getStackInSlot
> I12 isEquivalentTo
> I13 getInventoryName
> I14 getInventorySize
> I15 getSlotStackSize
> I16 compareToDatabase
> I17 areStacksEquivalent
> I18 getSlotMaxStackSize
> I19 getItemInventorySize
> I20 dropIntoItemInventory
> I21 suckFromItemInventory
> I22 compareStackToDatabase
> I23 getStackInInternalSlot
> ```

> ```ruby
> trade:
> 1 type
> 2 trade
> 3 getInput
> 4 getOutput
> 5 isEnabled
> 6 getMerchantId
> ```

</td><td>

> ```ruby
> geolyzer:
> G1 scan
> G2 slot
> G3 type
> G4 store
> G5 detect
> G6 address
> G7 analyze
> G8 canSeeSky
> G9 isSunVisible
> ```

> ```ruby
> tank_controller:
> T1 fill
> T2 slot
> T3 type
> T4 drain
> T5 address
> T6 getTankCount
> T7 getTankLevel
> T8 getFluidInTank
> T9 getTankCapacity
> T10 getTankLevelInSlot
> T11 getFluidInTankInSlot
> T12 getTankCapacityInSlot
> T13 getFluidInInternalTank
> ```

</td></tr>
</table>

## Links

- [Repo with source code and readme](https://github.com/Krutoy242/lostuser)
- Modpack this robot was programmed for: [Enigmatica 2: Expert - Extended](https://www.curseforge.com/minecraft/modpacks/enigmatica-2-expert-extended)
