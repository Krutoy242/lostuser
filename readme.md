# `Lost User` - simpliest robot

Robot BIOS program for Minecraft OpenComputers mod.


- [`Lost User` - simpliest robot](#lost-user---simpliest-robot)
  - [Why?](#why)
  - [Setup](#setup)
    - [Assemble](#assemble)
    - [E2E-E](#e2e-e)
    - [Write program on EEPROM.](#write-program-on-eeprom)
    - [Insert in robot](#insert-in-robot)
  - [Usage](#usage)
  - [Syntax](#syntax)
    - [TL;DR](#tldr)
    - [Naming mechanic](#naming-mechanic)
  - [Operators](#operators)
    - [Predefined](#predefined)
  - [Debug](#debug)
    - [Debugging with `error()`](#debugging-with-error)
    - [Debugging from advanced robot](#debugging-from-advanced-robot)
  - [Examples](#examples)
    - [IC2 crops](#ic2-crops)
    - [Ferrous-Juniper farm](#ferrous-juniper-farm)
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
wget https://gist.githubusercontent.com/Krutoy242/db63637d605c2c247bc95e939c7f7ddd/raw/lostuser.min.lua
```

2. To write on existing EEPROM run:

```
flash -q lostuser.min.lua LostUser
```

### Insert in robot

Take EEPROM from computer case and merge with robot.

![Combining robot with EEPROM](https://i.imgur.com/7AHXvdm.png)

## Usage

Robot programmed by **renaming it**. You must rename Robot on ![](https://is.gd/pYpuM1 'Anvil') or with ![](https://is.gd/VgGaLN 'Labeller') (from _Integrated Dynamics_ item).

Name your Robot `\3`, place on ground, turn on, and see how its clicking blocks in front.

![](https://i.imgur.com/tgsaqxj.gif)


## Syntax

### TL;DR

If you don't want to learn Lua and you need the robot to right/left click, a few simple names for the robot and the result:

- `\3z` The robot will right click on the block on the front each second.
- `/3z` The robot will swing with a sword or break the block in front of it.

### Naming mechanic

- **Each symbol means _command_**

  Progran run from left to right. Each symbol executed and return its result forward.
  For example:

  > `\3z` - This program would call `robot.use(3)` then call `robot.move(3)`

- **Some actions have _parameters_**

  Parameters can be any value.  
  All **1-digit numbers** parsed as numbers. Usually its [sides](https://ocdoc.cil.li/api:sides).

  > `|0|1m3` - Place blocks under robot (`|` is alias for `robot.place`), then over the robot, then move forward.

- **_Commands_ return values**

  This values can be used for other functions as parameters.

  > `^(#1)` - Select slot equal number of items in first slot. Robot must have ![Inventory Upgrade](https://is.gd/1qkAir 'Inventory Upgrade')
  >
  > Program here run first _command_ `^` (`robot.select`), but it needs a param, so it try to get param from next _command_. `#` is alias for `robot.count`, so its return number used as param for `^` _command_.
  >
  > Notice that without the brackets `^#1`, the `robot.select` function would get the `robot.count` function as a parameter, which would cause an error.

- **Constants**

  There is few constants:

  - `n` - number of inventory slots. Equal to executing `robot.inventorySize()`
  - `i` - if you are inside `for i` loop, or was in it, return last `i`
  - `*` - alias for `nil`

  > `#n` - Select last slot of robot, if it have _inventory upgrade_.

## Operators

Operators is hardcoded symbols that control program flow.

All parameters have default values. You can use defaul values by calling operators with `nil` instead parameters.

| Symbol | Params                                              | Description                                                                                                             | Example                                                                                                                                                    |
| :----: | :-------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  `-`   | `value=true`                                        | Write `value` into variable with symbol right after `-`.                                                                | `-a5` - writes `5` into variable with name `a`.                                                                                                            |
|  `~`   | `program=''`                                        | Define a symbol right after `~` as alias with code in parameter `program`. This code would run when alias symbol occur. | `~M'm1' MMM` - define symbol `M` as program `m1` (means `robot.move(1)`), and then execute it 3 times.                                                     |
|  `?`   | `condition=false`<br>`onTruthy=''`<br>`onFalthy=''` | if `condition` then return `onTruthy()` else return `onFalthy()` end                                                    | `?M"R"'L'` - If succesfully moved forward, turn right, or turn left otherwise.<br>`?{<#5>>0}'^i'*` - select slot 5 if its non-empty. Do nothing otherwise. |
|  `!`   | `program=''`<br>`from='1'`<br>`to='maxinteger'`     | for i=`from`,`to`,1 do `program()` end<br>Break loop when `program()` return truthy value                               | `!"?{<#i>>0}'^i'*"1n` - Select first non-empty slot.                                                                                                       |

|    Symbol     | Description                                                                                                                | Example                                                                                                                               |
| :-----------: | -------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
|   ' " &#96;   | Takes all text until next quote and return as string.                                                                      | `-a"one'two'"` - writes string `one'two'` into variable `a`                                                                           |
|  `(`code`)`   | Run code inside parenthesis and return its value.(¹)<br>Note that capture is not recursive. `(a(b))` would capture `(a(b)` | `z(#1)` - sleeps for number of seconds equal to number of items in first slot.                                                        |
|   `{`lua`}`   | Return as lua evaluated expression.(²)(³)                                                                                  | `t{true}` - turn right.<br>`^{12}` - select 12th slot.<br>`{proxy'piston'.push}3` - push block in front (if piston upgrade installed) |
| `[`pointer`]` | Return pointer to globals. Can use shortands. First letter is mandatory, other can content any symbols between.            | `[cpr]` or `[computer]` - return global variable `computer`<br>`[cpr.bep]` - return `computer.beep`                                   |

**¹** : Only last result would be returned.

> `-a1 -b2 ^(ab)` - Would select second slot.

**²** : You can use `< >` inside lua code to execute program between `< >` as commands.

> `-a{not <a>}` - Negate variable `a`.

**³** : There is some predefined globals:

- `proxy`
- `r = proxy"robot"`
- `ic = proxy"y_c"`

### Predefined

There is many predefined symbols. See them at the beginning of [source file](https://gist.githubusercontent.com/Krutoy242/db63637d605c2c247bc95e939c7f7ddd/raw/d63a80a7ec6393bad8a44ef6803de9895eec3d43/lostuser.lua).

## Debug

### Debugging with `error()`

Robots without screen and GPU cant show messages. So, there is predefined function `e` that could throw an error that would be visible by right-clicking ![Analyzer](https://is.gd/EYKTlS 'Analyzer').

> `e[r.cT]` - Error with `robot.compareFluidTo` documentation.

### Debugging from advanced robot

If you want a deeper level of debugging, load the program on a robot with a complete package - ![](https://is.gd/Qc1mye 'Screen (Tier 1)')![](https://is.gd/aCba7k 'Hard Disk Drive (Tier 1) (1MB)')![](https://is.gd/q2uLwP 'Keyboard'), etc.

Download program on robot:

```sh
wget https://gist.githubusercontent.com/Krutoy242/db63637d605c2c247bc95e939c7f7ddd/raw/d63a80a7ec6393bad8a44ef6803de9895eec3d43/lostuser.lua
```

The program can accept 2 commands

- The program text to execute (instead of the robot's name)
- Logging output level [1-3]
  1. Programs and subprograms only
  2. All commands
  3. Include initialization commands in the debug

Since the robot screen is very small, I suggest redirecting the output to a file.

Example:

Run this from shell. Robot would move forward and then stop program.

```sh
lostuser.lua "MX" 2 > out
```

Rich debug info would be output into `out` file:

```c#
PROGRAM "MX" {
  ALIAS M == "m3"
  PROGRAM "m3" {
    VAR m == "function(direction:number):boolean -- Move in the specified direction."
  } return true
  ALIAS X == "[os.exit]*"
  PROGRAM "[os.exit]*" {
    api: os.exit os.exit
```

## Examples

### IC2 crops

We would use this robot to breeding **Industrial Craft 2** crops.

To do this, you need to plant the seeds in a checker order, and put cross sticks between them. Also, the robot has to run along the bed and right-click Weeding Trowel to pick up the weeds.

### Ferrous-Juniper farm

In this example, the robot runs a complex program: `?(y0)'E9nS18''^9/0s18|0'Z`.

This program:
1. Tosses items from slots 9-16 down
2. Picks up items in slots 1-8 from top
3. Moves in a zig-zag pattern, breaks the block underneath and puts a new one


## Links

- [Gist with source code and readme](https://gist.github.com/Krutoy242/db63637d605c2c247bc95e939c7f7ddd)
- Modpack this robot was programmed for: [Enigmatica 2: Expert - Extended](https://www.curseforge.com/minecraft/modpacks/enigmatica-2-expert-extended)
