# Godot Console

A Quake/CryEngine-style console for Godot. Requires a Godot 3.0-beta1 or newer

![Main Screen](https://github.com/Krakean/godot-console/blob/master/Screenshot.png)

## Features

- Toggleable console with fast fade animation (use <kbd>~</kbd> to toggle)
- Commands (CComs) with limitless amount of arguments (no strict type checking, though)
- Variables (CVars), with strict type checking and ability to specify range of min/max and allowed values
- Rich text format (colors, bold, italic, and more) using a RichTextLabel, with scrolling support
- Full-featured tab completion, with command history
- Ability to declare commands/cvars in any file (an issue of original console implementation)
- Simple logging (normal, warning, error) with timing. Could be useful when use console also for logging purposes
- Very verbose in context of ccoms/cvars registration and usage. If you made a mistake, console will tell you about it
- Warm color scheme by default, should be nice for eyes :-)
- Semi-transparent console by default.
- Always on top of others elements (an issue of original console implementation).
- Example #1: Unittest-like file with variety amount of examples of how to use console and how to _not_ use (see ConsoleUnitTest.gd).
- Example #2: PerfMon simple script as example of "production-like usage"

## Some background on my implementation

Contains some parts of code from another one good enhanced implementation of original Calinou's console - https://github.com/DmitriySalnikov/godot-console
That one particulary support strict type checking to commands arguments.

Mine and DmitriySalnikov's (in cooperation with QuentinCaffeino) implementations were started in the same time at Godot's telegram channel, after I started discussion about flaws of Calinou's original.
Take a look at their implementation, if you want either strict type checking for commands arguments or you don't like surplus usage/error verbose or color scheme of my implementation.
Despite the fact our implementations actually do the same thing, we do it very differently.

## License

Copyright (c) 2017 Dmitry Koteroff and contributors

Licensed under the MIT license, see `LICENSE.md` for more information.
