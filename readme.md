# `Lost User` - simpliest robot

Robot (or drone!) BIOS program for Minecraft OpenComputers mod.

- [`Lost User` - simpliest robot](#lost-user---simpliest-robot)
  - [Why?](#why)
  - [Setup](#setup)
    - [Assemble](#assemble)
    - [E2E-E](#e2e-e)
    - [Write program on EEPROM.](#write-program-on-eeprom)
    - [Insert in robot](#insert-in-robot)
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
    - [Map `^` or `&`](#map--or-)
    - [Lambda `-` `/` `|`](#lambda----)
    - [Loop `~` or `..`](#loop--or-)
    - [Unary](#unary)
    - [Truthy](#truthy)
  - [Macros](#macros)
  - [Examples](#examples)
  - [Links](#links)

## Why?

OC robots are very difficult to assemble and program. This program for the BIOS will help to use robots as "users" and in many other ways.

## Setup

### Assemble

Assemble the robot in the minimum configuration:

- Case
- CPU
- RAM

<img src="https://i.imgur.com/sBP2y0N.png" width="350">

### E2E-E


If you play [Enigmatica 2: Expert - Extended](https://www.curseforge.com/minecraft/modpacks/enigmatica-2-expert-extended), modpack have predefined recipe of EEPROM.  
Just find it in JEI and craft. It would have colored shining.

![](https://i.imgur.com/GuT7Ke6.gif)

If you crafted it, you can skip next step `Write program on EEPROM`.

### Write program on EEPROM.

> You need a working OC computer to write the BIOS. See [this tutorial](https://www.youtube.com/watch?v=KDqXJzacdQQ) to assemble your first computer.

1. Download file from the internet (need ![](https://is.gd/zrPusF 'Internet Card')), run from command line:

```
wget https://raw.githubusercontent.com/Krutoy242/lostuser/main/lostuser.min.lua
```

2. To write on existing EEPROM run:

```
flash -q lostuser.min.lua LostUser
```

### Insert in robot

Take EEPROM from computer case and merge with robot.

![Combining robot with EEPROM](https://i.imgur.com/7AHXvdm.png)

## Usage

Robot programmed by **renaming it**. You must rename Robot on ![](https://is.gd/pYpuM1 'Anvil') or with ![](https://is.gd/VgGaLN 'Labeller').

Name your Robot `robot.use(3)`, place on ground, turn on, and see how its clicking blocks in front.

![](https://i.imgur.com/ATnKS34.gif)


## Syntax

**TL;DR**

If you don't want to learn Lua and you need the robot to right/left click, a few simple names for the robot and the result:

- `robot.use(3)` The robot will right click on the block on the front.
- `robot.swing(3)` The robot will swing with a sword or break the block in front of it.

### Statements and Expressions

#### Execution

Robot will execute it's name as Lua code in `while true` loop.

Code could be run in any variation - `statement` or `expressions`, but still must follow Lua code flow rules.

> This is statement
> ```lua
> sleep(1)
> ```
> 
> This is expression
> ```lua
> 1, sleep(1)
> ```
> 
> Combining statement and expression
> ```lua
> a = robot.move(3) return a and robot.use(0)
> ```

#### Return

If expression return one or many functions, they would be executed recursively.

Note that all return values are calculated first, and only then will the functions be called.

> Calling `robot.use(3)`, and then `sleep()`
> ```lua
> function() return sleep end, robot.use(3)
> ```

### Globals

<!-- components -->
1. All components exposed as globals
2. Components sorted naturally and added to globals by big first letter

  ```less
  C	=>	computer
  E	=>	eeprom
  I	=>	inventory_controller
  R	=>	robot
  T	=>	trading
  ...
  ```
<!--  -->

Additional globals:

- `i` - current loop index, starting from 0
  > You can add number after `i` to get it by modulus +1.
  > ```lua
  > i16 = i % 16 + 1
  > ```
- `sleep(seconds: number = 1)`
- `write(...)` - error with serialized output
- `api(shortName: string, obj?: table)` - write long name of shortand

## Shortening

Since Robot or Drone name could have only `64` characters, pointers must be shortened.

So, instead wrighting full pointer name, you can shorten it. For example, instead of wrighting `robot.use(3)` you can write `r.u(3)`, or even `Ru3`.

Shortening rules:

1. If key have exact non-nil match it would be returned.  
    > `R.use(3)` - `R` is global represents `robot` component

2. The shorthand must contain the first letter and then, optionally, any number of remaining letters.
    > ```less
    > tbl.unk => table.unpack
    > t.u => table.unpack
    > ```

3. If several names have same first letter, **shortest**, **alphabetically** sorted name would be picked first
    > ```lua
    > robot.s   -- robot.slot
    > robot.se  -- robot.space
    > robot.sel -- robot.select
    > ```

4. Big first letter with dot `.` could be used without dot.
    > ```lua
    > -- Same pointers
    > robot.use == R.use == Ruse == Ru
    > ```

5. Number at the end of shortand would call shortand as function with that number as first argument
    > ```lua
    > Ru3 -- robot.use(3)
    > s10 -- sleep(10)
    > ```

6. Locals can't be shortened
    > ```lua
    > local query = {len=4}
    > q.l -- Exception: q is nil
    > query.l -- l is nil
    > query.len -- 4
    > ```

## Lodash `_`

Low dash `_` is special helper function.

### Indexing `_`

<!-- indexing _ -->
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
<!--  -->

### Calling `_`

<!-- calling _ -->
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
<!--  -->

## Functional Programming

Any table or function that you can get from a global will be converted into special `_{}` table. 

This table enchanced with additional operator metamethods that helps with functional-style programming.

**Operators** behave differently depending or left and right side of operator.

Note that whenever `string` would be detected in right side, it would be loaded and converted to function in manner of `_'fnc'`.

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

### Map `^` or `&`

`^` and `&` operators do the same. There is two of them only to managing precedence.

- **Note¹:** `^` is right associative. This means, right side will be computed first.

- **Note²:** You can also call *uncallable* tables. `t(x)` is the same as `t^x`. *Uncallable* tables is tables without `__call` metatable.
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
Filter, keep only if value is [Truthy](#Truthy)
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
<sub>Not yet implemented</sub>
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

### Loop `~` or `..`

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
> - All keys of table would be converted to inexed
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
<sub>Not yet implemented</sub>
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
Make a funtion that would wrap it result into table.  
Useful for functions that returns several values
```lua
-- Consider `f(n)` returns three values - 2,3,n
f&4   -- 2
#f&4  -- _{2,3,4}
```
<!--  -->

</td></tr>

</table>

### Truthy

Value considered as `truthy` if its not `falsy`.

`falsy` values is:

1. `false` or `nil`
2. `''` empty string
3. `0` number zero
4. `nan` not a number (`n~=n`)
5. `inf` or `-inf` (result of `1/0` or `-1/0`)

## Macros

Program have several predefined macroses - symbols, that will be replaced everywhere with another text.

```js
! => '()'
ⓐ => ' and '
ⓞ => ' or '
ⓝ => ' not '
ⓡ => ' return '
⒯ => '(true)'
⒡ => '(false)'
 ∅ => ' __trash='
```

## Examples

- **Travel between two waypoints and run its label**

  > Required upgrades: *Inventory*, *Navigation*
  
  ![](https://i.imgur.com/36HdGzO.gif)
  
  Drone name:
  ```lua
  P=i/Nf300ⓡDm^Pp,s/1~'Dg!>1',_(Pl)
  ```
  * `Nf300`: Run `navigation.findWaypoints(300)`.
  * `i/Nf300`: `i` is index of script execution. `i / table` is "Get by index modulus" `t[i % #t + 1]`.
  * `P=i/Nf300`: Write into global variable `P` a different waypoint each script cycle.
  * `ⓡ`: will be replaced by ` return `
  * `Dm^Pp`: calling `drone.move(table.unpack(P.position))`.
  * `s/1~'Dg!>1'` => `while drone.getOffset() > 1 do sleep(1) end`.
  * `_(Pl)`: Load `P.label` as Lua code. This loaded function would be [returned and executed](#return).

  Waypoints labels. First one just suck from bottom, second one iterate over 4 slots and drop down.
  ```lua
  _'Dsk0'~4
  Dsel-Dd/0/q~4
  ```

- **Zig-Zag + Use Down, userful for farms**

  > Required upgrades: none
  
  ![](https://i.imgur.com/YTd5idO.gif)
  
  Robot name:
  ```lua
  m,t=_'Rm3,Ru0',Rtn/(i2>1)ⓡ~m,t!,_'m!,t!'!ⓞt/m
  ```
  * `m,t=_'Rm3,Ru0',Rtn/(i2>1)`: define two functions for moving and rotating
    - `_'Rm3,Ru0'`: define function `Rm3,Ru0` that would move forward and use tool down
    - `Rtn/(i2>1)`: this making function, that would call `Rtn` (`robot.turn`) with argument `i2>1`. `i2` is shortand for `i%2+1`
  * `~m`: Makes robot move forward until it cant move.
  * `t!`: just turn
  * `_'m!,t!'!ⓞt/m`: Move and turn. If move wassnt succeed, turn and move again.

- **Trader bot**

  > Required upgrades: *Trading*, *Inventory*, *Inventory Controller*
  
  ![](https://i.imgur.com/HEgNabM.png)

  Robot name:
  ```lua
  Rsel-Rd/0/q~RiS0,IsF/0~Igz0,Tg0/'~tr'
  ```
  * `Rsel-Rd/0/q~RiS0`: Select each slot and dump bottom
    > - `Rd/0/q`: is a function that would call `robot.drop(0, q)` when executed. Note that there is a trick: `q` is undefined global that we used an shortand for `nil`
    > - `RiS0`: is shortand for `robot.inventorySize(0)`. Note that this function not using any arguments so we could call it with `0`
    > - `Rsel`: `robot.select` shortand. Note that we used `-` operator here, that is same as `/` but have lower precedence
  * `IsF/0~Igz0`: For each slot of inventory on the bottom `inventory_controller.getInventorySize(0)` call `inventory_controller.suckFromSlot(0, k)`
  * `Tg0/'~tr'`: Trade all trades.
    > - `~tr`: Call `trade()` while it returns true. Note that inside this function, all arguments exposed as global, so we could acces `trade` as global (actually, its `upvalue`)

  There is another variant of robot name, way advanced. It will pull only items that actually required for trading. This program hardcoded to work with inventory with size 16:
  ```lua
  a=-~Tg0"_{g0}'n',~tr",Rsel-Rd/0/k~16ⓡ_16'IgI/0&k''a[n]ⓐIsF/0&k'
  ```

- **Rune maker**

  > Required upgrades: *Inventory*, *Inventory Controller*

  Place ingredients in first 6 slots of Robot. Living Rock in 7th, wand in 8th.
  
  <img src="https://i.imgur.com/OXRuYs3.png" width=25%>
  <img src="https://i.imgur.com/KqlJqMw.gif">

  Robot name:
  ```less
  _8/'Rsel^v,v==7ⓐ{s3,Rm1,Rd(3,1),Rm0}ⓞ{Ie!,Ru3,Ie!}'
  ```
  * `Rsel^v`: Select iterated slot
  * `v==7ⓐ{s3,Rm1,Rd(3,1),Rm0}`: if its 7th slot with Living Rock, wait 3 seconds until craft finished, then drop Rock on top.
  * `Ie!,Ru3,Ie!`: Other slots - just right-click with item

- **Single tree farm**

  > Required upgrades: *Inventory*, *Inventory Controller*

  This robot intended to use with Forestry saplings, that usually can't be placed as blocks, but need to be right-clicked instead.  
  Also, robot need *unbreakable* Broad Axe from TCon with *Global Traveler* trait. Also, my Axe have *Fertilizing* trait - right click to fertilize.  
  Place robot on top of container with saplings.
  
  <img src="https://i.imgur.com/I9W39B0.gif">

  Robot name:
  ```lua
  #st(2,Rdt(3))<6ⓐ{Rsw3,s2,Rsk/0&1,Ie0,Ru3,Ie0}ⓞRu3,s
  ```
  * `st(2,Rdt(3))`: Detect block in front. Note that `Rdt3` would not work, since it return only 1 value. `st` is shortand for `select`
  * `<6`: trick to determine if block is solid
  * `Rsw3,s2`: Cut whole tree
  * `Rsk(0,1),Ie!,Ru3,Ie!`: Suck one sapling from bottom, then plant it
  * `Ru3,s`: Fertilize sapling

- **Other examples**

  * *Robot sorting mob drop*. Take from bottom, damagable items to top, other - forward
    ```lua
    Rd/_(IsF(0,i%Igz0+1)ⓐIgSII!.mD,1,3)
    ```

  * *Cat opener*. Takes 16 items in front, right-click them and then dump inventory top
    ```lua
    Rsk/3&16ⓐIe!,~_'Ru0',_16/Rc|Rsel-Rd/1/q
    ```

  * *Compressing bot*. Takes from front, craft 3x3 them, dump buttom or forward.
    > Required upgrades: Crafting, Inventory Controller, Inventory
    ```lua
    _16|Rc|Rsel-'Rd0ⓞRd3',IsF/3/'_11/8/4&Rc!/9/RtT'|i%Igz3+1,Ccr
    ```


## Links

- [Repo with source code and readme](https://raw.githubusercontent.com/Krutoy242/lostuser)
- Modpack this robot was programmed for: [Enigmatica 2: Expert - Extended](https://www.curseforge.com/minecraft/modpacks/enigmatica-2-expert-extended)
