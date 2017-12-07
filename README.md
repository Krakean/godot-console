# Godot Console

A Quake/CryEngine-style console for Godot. Requires a Godot 3.0-beta1 or newer

![Main Screen](https://github.com/Krakean/godot-console/blob/master/Screenshot.png)

## Features

- Commands (CComs)
- Variables (CVars), with strict types registration and ability to specify range of min/max and allowed values
- Scrolling
- Toggleable console with fast fade animation (use <kbd>~</kbd> to toggle)
- Easily extensible with new commands & cvars
- Rich text format (colors, bold, italic, and more) using a RichTextLabel
- Full-featured tab completion, with command history
- Ability to declare commands/cvars in any file
- Simple logging with timing
- Very verbose in context of ccoms/cvars registration and usage. If you made a mistake, console will tell you about it
- Warm color scheme by default
- Transparency for console by default.
- Always on top of others elements (an issue of original console implementation).
- Example #1: Unittest-like file with variety amount of examples of how to use console and how to _not_ use (see ConsoleUnitTest.gd).
- Example #2: PerfMon simple script as example of "clean usage"

## License

Copyright (c) 2017 Dmitry Koteroff and contributors

Licensed under the MIT license, see `LICENSE.md` for more information.
