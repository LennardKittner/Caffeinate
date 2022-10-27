# Caffeinate
A macOS menubar app to temporarily prevent the Mac from sleeping.

## How does it work
Left-clicking the cup will toggle Caffeinate. If the cup is filled, your Mac won't go to sleep anymore.
Right clicking the cup will open the settings. From there, you can also quit the app.

![cup1](./Images/cup1.png) dark mode Caffeinate active
![cup2](./Images/cup2.png) dark mode Caffeinate inactive

![cup3](./Images/cup3.png) light mode Caffeinate active
![cup4](./Images/cup4.png) light mode Caffeinate inactive


## Requirements
The app requires macOS 11 or later to run. If you are using macOS 13, you can add the app to the login items via the app settings.

## Installation
You can compile the app yourself using xcode `xcodebuild -configuration Release` or you can download a compiled version from [releases](https://github.com/Lennard599/Caffeinate/releases).

## FAQ
**How do I quit?**

Right-click the menu bar item, then go to Settings and press Quit.

## TODO
Even if the lid is closed, prevent the Mac from sleeping. This probably requires root privelages.

## Links
[CPUMonitor menu bar app](https://github.com/Lennard599/CPUMonitor)

[ClipBoardManager menu bar app](https://github.com/Lennard599/ClipBoardManager)