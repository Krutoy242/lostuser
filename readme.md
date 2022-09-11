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
    - [Loop](#loop)
    - [Globals](#globals)
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
wget https://gist.githubusercontent.com/Krutoy242/1f18eaf6b262fb7ffb83c4666a93cbcc/raw/lostuser2.min.lua
```

2. To write on existing EEPROM run:

```
flash -q lostuser2.min.lua LostUser
```

### Insert in robot

Take EEPROM from computer case and merge with robot.

![Combining robot with EEPROM](https://i.imgur.com/7AHXvdm.png)

## Usage

Robot programmed by **renaming it**. You must rename Robot on ![](https://is.gd/pYpuM1 'Anvil') or with ![](https://is.gd/VgGaLN 'Labeller').

Name your Robot `R.use(3)`, place on ground, turn on, and see how its clicking blocks in front.

![](https://i.imgur.com/tgsaqxj.gif)


## Syntax

### TL;DR

If you don't want to learn Lua and you need the robot to right/left click, a few simple names for the robot and the result:

- `R.use(3)` The robot will right click on the block on the front.
- `R.swing(3)` The robot will swing with a sword or break the block in front of it.

### Loop

Robot will execute it's name as Lua code in `while true` loop.

### Globals

All components are sorted by name length and added to global variables by the first letter.

For example:
```less
R	=>	robot
E	=>	eeprom
T	=>	trading
C	=>	computer
I	=>	inventory_controller
...
```

Additional globals:

- `sleep(seconds)`
- `proxy(partial_name)`


## Debug

### Debugging with `error()`

Robots without screen and GPU cant show messages.
Use `error(msg)` that would be visible by right-clicking ![Analyzer](https://is.gd/EYKTlS 'Analyzer').

> `e(R.cT)` - Error with `robot.compareFluidTo` documentation.

### Debugging from advanced robot

If you want a deeper level of debugging, load the program on a robot with a complete package - ![](https://is.gd/Qc1mye 'Screen (Tier 1)')![](https://is.gd/aCba7k 'Hard Disk Drive (Tier 1) (1MB)')![](https://is.gd/q2uLwP 'Keyboard'), etc.

Download program on robot:

```sh
wget [...]
```

First robot parameter - the program text to execute (instead of the robot's name)

Since the robot screen is very small, I suggest redirecting the output to a file.

Example:

Run this from shell. Robot would move forward and then stop program.

```sh
lostuser "Rm(3)o.e()" > out
```

In `out` file you will see its code.

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
