# CrashStation!

PocketStation GIF generator & Twitter bot

## What?!

CrashStation! is intended to launch the _Crash Bandicoot 3: Buttobi! Sekai Isshu_ PocketStation game, and return a GIF of the virtual pet portion of the game.

You can get the PocketStation game by loading up _Crash Bandicoot 3: Buttobi! Sekai Isshu_ in an emulator, choosing the third option at the main menu, followed by the first option (which is to download the PocketStation game), then the right-hand option (hai!). More information about this can be found in [this FAQ!](http://www.neoseeker.com/crash-bandicoot-3/faqs/27795-jp.html)

## How?

CrashStation! is made up of three parts;

1. `crashstation.lua`, a LUA script to run within MAME, controlling the emulator's execution and outputting frame data
2. `crashstation.rb`, a Ruby script which launches MAME, and preprocesses the frame data sent by `crashstation.lua` into a GIF
3. `crashstationbot.rb`, a `twitter_ebooks` robot which interfaces the above with Twitter

You need a copy of the PocketStation game saved as `crash.gme`.

Running `./crashstation.rb` will generate a GIF in the current working directory.

Information on configuring the twitter bot can be found in the [`twitter_ebooks`](https://github.com/mispy/twitter_ebooks) repository.

### No, but really, how?

MAME includes LUA scripting functionality, through which it is possible to send keystrokes to the emulator, read the emulator's state and memory, and consequently to pull data out of it.

The included LUA script is run within MAME, alongside a PocketStation game loaded from a `.gme` PlayStation Memory Card image. It sets the clock to the current local time, then launches the first application found on the PocketStation.

Then, once the game starts, it starts dumping frames and the time between frames from the PocketStation framebuffer to `STDOUT`. Framebuffer data is presented as 32 rows of 32-bit integers (as stored in the PocketStation's RAM!), as text, followed by a frame delay listed in seconds. An example of this frame data can be found in the `fixtures` directory.

`crashstation.lua` will continue collecting frame data for 30 seconds, at which point it will exit MAME.

`crashstation.rb` takes the frame data output by `crashstation.lua`, and converts it into a GIF using ImageMagick (via `rmagick`). It also accepts an optional time zone offset listed in seconds (i.e. UTC+10 is 36000, UTC-7 is -25200), which it will override the `TZ` variable to before launching MAME, effectively setting the PocketStation clock to any local time. If the time zone offset isn't set, it will choose a random offset.
