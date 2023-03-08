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

All components exposed to globals.

Also, they are sorted by name length and added to global variables by the first letter.

```less
R	=>	robot
E	=>	eeprom
T	=>	trading
C	=>	computer
I	=>	inventory_controller
...
```

Additional globals:

- `i` - current loop index, starting from 0
- `sleep(seconds: number = 1)`
- `api(shortName: string, obj?: table)` - output long name of shortand
- `write(...)` - error with serialized output

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

- **Using `_` with numbers `_123`**  
  Will return new array-like list with length of number.  
  If first digit is `0` - table will be zero-based
  > ```lua
  > _8  -- return {1,2,3,4,5,6,7,8}
  > _08 -- return {[0]=0,1,2,3,4,5,6,7}
  > ```

- **Using `_` on string**  
  Will load code inside this string and return it as function.
  > ```lua
  > _'Rm,s2'()(0) -- call `sleep(2),robot.move(0)`
  > ```
  > Note that in this example, the `_` function returns two values - the `robot.move` function and the result `sleep(2)`. Only when we call the returned values a second time, `robot.move(0)` called

- **Using `_` on *table* or *function***  
  Will convert them into `{q}` table or `{q}` function to use with [Functional Programming](#functional-programming)
  > ```lua
  >  {1,2}^1 -- would error
  > _{1,2}^1 -- would return {1,1} (see Functional Programming)
  > ```

## Functional Programming

Any table or function that you can get from a global will be converted into special `{q}` table. 

This table enchanced with additional operator metamethods that helps with functional-style programming.

Simple example - fill all values of array with `1`:

> ```lua
> _{1,2,3}^1 -- return {1,1,1}
> ```

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

Note, that `^` is right associative. This means, right side will be computed first.

<table>
<tr>
  <th>Left</th><th>Right</th><th>Result</th>
</tr>

<tr>
  <td rowspan=3>Table</td><td>Function</td><td>

Classical map
```lua
_{4,5,6}^f -- {f(4),f(5),f(6)}
```

</td></tr>
<tr><td>Table</td><td>

Pick indexes
```lua
_{4,5,6}^{3,1} -- {6,4}
```

</td></tr>
<tr><td>Number, Boolean</td><td>

Fill with value
```lua
_{1,2,3}^n -- {n,n,n}
```

</td></tr>
<tr><td rowspan=3>Function</td><td>Function</td><td>

Composition
```lua
f^g -- (...)=>f(g(...))
```

</td></tr>
<tr><td>Table</td><td>

Unpack as arguments
```lua
f^{1,2,3} -- f(1,2,3)
```

</td></tr>
<tr><td>Number, Boolean</td><td>

Simple call
```lua
f^1 -- f(1)
```

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

Filter, keep only if value is [Truthy](#Truthy)
```lua
_{4,5,6,7}/'v%2' -- {5,7}
```

</td></tr>
<tr><td>Table</td><td>

Unpack map
```lua
_{f,g}/{0,1} -- {f(0,1),g(0,1)}
```

</td></tr>
<tr><td>Number, Boolean</td><td>

Remove index
```lua
_3/2 -- {1=1,3=3}
```

</td></tr>
<tr><td rowspan=3>Function</td><td>Function</td><td>

Reversed composition
```lua
f/g -- (...)=>g(f(...))
```

</td></tr>
<tr><td>Table</td><td>

Reversed map
```lua
f/{a,b} -- {f(a),f(b)}
```

</td></tr>
<tr><td>Number, Boolean</td><td>

Composition
```lua
f/1 -- (...)=>f(1,...)
```

</td></tr>
<tr><td rowspan=2>Number, Boolean</td><td>Table</td><td>

Get by modulus
```lua
i/t -- t[i % #t + 1]
```

</td></tr>
<tr><td>Function</td><td>

Rotated composition
```lua
2/f -- (...)=>f(..., 2)
```

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

While truthy do
```lua
_{f,g}~h -- while truthy(h(j++)) do f(j)g(j) end
```

</td></tr>
<tr><td>Table</td><td>

<sub>Not yet implemented</sub>

</td></tr>
<tr><td>Number, Boolean</td><td>

For loop
```lua
_{f,g}~n -- for j=1,n do f(j)g(j) end
```

</td></tr>
<tr><td rowspan=3>Function</td><td>Function</td><td>

While truthy do
```lua
f~g -- while truthy(g(j++)) do f(j) end
```

</td></tr>
<tr><td>Table</td><td>

<sub>Not yet implemented</sub>

</td></tr>
<tr><td>Number, Boolean</td><td>

For loop
```lua
f~n -- for j=1,TONUMBER(n) do f(j) end
```

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

While truthy do
```lua
~f -- repeat until not truthy(f())
```

</td></tr>
<tr><td>Table</td><td>

Flatten table, using numerical indexes.

> - Order of elements can be different
> - All keys of table would be converted to inexed
> - Only 1 level of flattening

```lua
~_{1,{2,3},{4,a=5,b={6,c=7}}}
-- {1,2,3,4,5,{6,c=7}}
```

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

You can define your own macroses with special syntax:
- <code>&#96;A...&#96;</code> where `A` can be any symbol that would be replaced with everything before <code>&#96;</code>
- You can make several macroses at once devide them with <code>&#96;</code>
- Macroses could replace values in previous macroses

Example:
> ```less
> `TRtn⒯S`MRm3S,`S,Rsw3` MMT
> // =>
> Rm3,Rsw3,Rm3,Rsw3,Rtn(true),Rsw3
> ```

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
  _'Dsel(k)Dd(0)'~4
  ```

- **Zig-Zag + Use Down, userful for farms**

  > Required upgrades: none
  
  ![](https://i.imgur.com/YTd5idO.gif)
  
  Robot name:
  ```lua
  `TRtn(i%2>0)`MRm3,Ru0`_~'M',T,_'M,T'!ⓞ_'T,M'
  ```
  * `TRtn(i%2>0)`: add macros `T` that would turned into `Rtn(i%2>0)`. Makes robot turn sometimes left, sometimes right.
  * `MRm3,Ru0`: add macros `M` that would turned into `Rm3,Ru0`. This would make robot move and use item down.
  * `_~'M'`: Makes robot move forward until it cant move.
  * `_'M,T'!ⓞ_'T,M'`: Move and turn. If cant move, turn and move again.

- **Trader bot**

  > Required upgrades: *Trading*, *Inventory*, *Inventory Controller*
  
  ![](https://i.imgur.com/72eLfym.png)

  Robot name:
  ```lua
  Tg0/'~v.tr',Rsel-Rd/3/q~16,_08/'IsF(k//4,k%4+2)'
  ```
  * `~v.tr`: Call `trade()` while it returns true.
  * `Tg0/'_~v.tr'`: Trade all trades.
  * `_08/'IsF(v//4,v%4+2)'`: Suck 4 slots from top and bottom. Note that 2x2 drawers accessible slots is 2 - 5.
  * `Rsel-Rd/3/q~16`: Select each slot and dump front

- **Rune maker**

  > Required upgrades: *Inventory*, *Inventory Controller*

  Place ingredients in first 6 slots of Robot. Living Rock in 7th, wand in 8th.
  
  <img src="https://i.imgur.com/OXRuYs3.png" width=25%>
  <img src="https://i.imgur.com/KqlJqMw.gif">

  Robot name:
  ```lua
  _8/'Rsel^v,v==7ⓐ{s3,Rm1,Rd(3,1),Rm0}ⓞ{Ie!,Ru3,Ie!}'
  ```
  * `Rsel^v`: Select iterated slot
  * `v==7ⓐ{s3,Rm1,Rd(3,1),Rm0}`: if its 7th slot with Living Rock, wait 3 seconds until craft finished, then drop Rock on top.
  * `Ie!,Ru3,Ie!`: Other slots - just right-click with item

- **Single tree farm**

  > Required upgrades: *Inventory*, *Inventory Controller*

  This robot intended to use with Forestry saplings, that usually can't be placed as blocks, but need to be right-clicked instead.  
  Also, robot need *unbreakable* Broad Axe from TCon with *Global Traveler* trait. Also, my Axe have *Fertilizing* trait - right click to fertilize.
  
  <img src="https://i.imgur.com/I9W39B0.gif">

  Robot name:
  ```lua
  a,b=Rdt(3)ⓡ#b<6ⓐ{Rsw3,s^2,Rsk(0,1),Ie!,Ru3,Ie!}ⓞRu3,s
  ```
  * `a,b=Rdt(3)`: Detect block in front. Note that `Rdt3` would not work, since it return only 1 value
  * `#b<6`: trick to determine if block is solid
  * `Rsw3,s^2`: Cut whole tree
  * `Rsk(0,1),Ie!,Ru3,Ie!`: Plant 1 sapling
  * `Ru3,s`: Fertilize sapling


## Links

- [Repo with source code and readme](https://raw.githubusercontent.com/Krutoy242/lostuser)
- Modpack this robot was programmed for: [Enigmatica 2: Expert - Extended](https://www.curseforge.com/minecraft/modpacks/enigmatica-2-expert-extended)
