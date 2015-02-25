telepath-logger
===============

A happy Mac keylogger for Quantified Self purposes. It also now serves as a time lapse heads-up-display thing. Really only I use this, so you'll want to either just use its code as inspiration or heavily tweak it for your purposes.

![Time lapse HUD screengrab example.](https://dl.dropboxusercontent.com/u/138899/GitHub%20Wikis/telepath-logger-example-screencrab.jpg)

See also these blog posts:

[Telepath Logger Now Open Source](http://blog.nickwinter.net/telepath-logger-now-open-source)

[Upcoming Maniac Week](http://blog.nickwinter.net/upcoming-maniac-week)

[The 120-Hour Workweek - Epic Coding Time-Lapse](http://blog.nickwinter.net/the-120-hour-workweek-epic-coding-time-lapse)

==============
In case you do want to try running this yourself, here are some quickly-thrown-together instructions.

1. Clone the Telepath repository.
1. Open Telepath.xcodeproj in Xcode
1. Hit Run. It should open up a Telepath window that's way too big and in the wrong place.
1. Change the 2560 size to the width of the screen you want to use [here](https://github.com/nwinter/telepath-logger/blob/master/Telepath/TPWindow.m#L17-L17).
1. Find the main window in the Interface Builder for TPHUDWindowController.xib, select the Window, turn on the righthand sidebar, switch to the size tab, and update its size and position to be the place that you want. You might also want to set it to be a Textured Window so that you can drag it around.
1. Comment in or out the TPTracker subclasses that you do/don't want to use [here](https://github.com/nwinter/telepath-logger/blob/master/Telepath/TPTracker.m#L87-L106). Some of these require additional configuration, so you'll probably want to turn some of them off if they don't apply to you.

If it seems to run okay and records what you want it to record, then you can build it into an app and set that app to autostart when you start OS X.