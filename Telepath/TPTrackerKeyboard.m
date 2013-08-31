//
//  TPTrackerKeyboard.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerKeyboard.h"
#import "TPUtilities.h"
#import "TPTracker.h"

@interface TPTrackerKeyboard ()
@property NSMutableString *recentCharacters;
@property NSArray *reallyBadStuff;
@property NSArray *punctuation;
@property id eventMonitor;

@end

// TODO: Look at how Selfspy does it, since it probably handles all the modifier flags and special keys and such better.

@implementation TPTrackerKeyboard

- (id)init
{
    self = [super init];
    if (self) {
        self.recentCharacters = [NSMutableString new];
        [self loadModifierKeys];
        [self loadReallyBadStuff];

        uint logMask = (NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask);
        self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:logMask handler:^(NSEvent *e) { [self onInputEvent:e]; }];
    }
    return self;
}

- (void)loadReallyBadStuff {
    // Reading list of terrible words, upon typing of which we shall beep castigatorally!
    NSString *filepath = [@"~/Dropbox/code/really_bad_stuff.txt" stringByExpandingTildeInPath];
    NSString *contents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    self.reallyBadStuff = [contents componentsSeparatedByString:@"\n"];
    self.punctuation = @[@" ", @",", @".", @";", @"?", @"!", @"'", @"\"", @"-", @"/", @"(", @")", @"[", @"]", @"\n"];
}

- (void)loadModifierKeys {
    self.modifierKeys =
    @[[NSMutableArray arrayWithObjects:@"<capslock>", @(NSAlphaShiftKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<shift>", @(NSShiftKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<ctrl>", @(NSControlKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<alt>", @(NSAlternateKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<cmd>", @(NSCommandKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<numlock>", @(NSNumericPadKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<help>", @(NSHelpKeyMask), @(NO), nil],
      [NSMutableArray arrayWithObjects:@"<fn>", @(NSFunctionKeyMask), @(NO), nil],
      ];
}

- (void)checkReallyBadStuff {
    if(!self.reallyBadStuff) return;
    // Warn the user if she types despicable words
    for(NSString *thing in self.reallyBadStuff)
        for(NSString *punct in self.punctuation) {
            if([thing length] && [self.recentCharacters rangeOfString:[NSString stringWithFormat:@"%@%@", thing, punct] options:NSCaseInsensitiveSearch].location != NSNotFound) {
                NSLog(@"You shouldn't use %@!", thing);
                [self.recentCharacters deleteCharactersInRange:NSMakeRange(0, [self.recentCharacters length])];
                NSBeep();
            }
        }
}

- (void)onInputEvent:(NSEvent *)e {
	NSEventType t = [e type];
	if (t == NSKeyDown)
        [self onKeyEvent:e up:NO];
	else if(t == NSKeyUp)
        [self onKeyEvent:e up:YES];
	else if(t == NSFlagsChanged)
        [self onFlagsChangedEvent:e];
}

- (void)onKeyEvent:(NSEvent *)e up:(BOOL)keyUp {
	NSMutableArray *event = [NSMutableArray array];
	[event addObject:@(now())];
	if(keyUp)
		[event addObject:@"keyUp"];
	else
		[event addObject:@"keyDown"];
	
	int code = [e keyCode];
	if(code == 36)
		[event addObject:@"<return>"];
	else if (code == 48)
		[event addObject:@"<tab>"];
	else if (code == 49)
		[event addObject:@"<space>"];
	else if (code == 51)
		[event addObject:@"<delete>"];
	else if (code == 53)
		[event addObject:@"<esc>"];
	else if (code == 123)
		[event addObject:@"<left>"];
	else if (code == 124)
		[event addObject:@"<right>"];
	else if (code == 125)
		[event addObject:@"<down>"];
	else if (code == 126)
		[event addObject:@"<up>"];
	else
		[event addObject:[e characters]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityKeyboard object:self userInfo:@{@"event": event}];
    
    if(keyUp) {
        [self.recentCharacters appendString:[e characters]];
        if([self.recentCharacters length] > 100)
            [self.recentCharacters deleteCharactersInRange:NSMakeRange(0, 1)];
        [self checkReallyBadStuff];
    }
}

- (void)onFlagsChangedEvent:(NSEvent *)e {
	NSMutableArray *event = [NSMutableArray array];
	[event addObject:@(now())];
    
    unsigned long flags = [e modifierFlags];
    for(NSMutableArray *modifierKey in self.modifierKeys) {
        BOOL oldState = !![[modifierKey objectAtIndex:2] boolValue];
        BOOL newState = !!(flags & [[modifierKey objectAtIndex:1] unsignedIntValue]);
        //NSLog(@"modifierKey: %@, oldState: %d, newState: %d", modifierKey, oldState, newState);
        if(oldState == newState) continue;
        [modifierKey replaceObjectAtIndex:2 withObject:[NSNumber numberWithBool:newState]];
        [event addObject:newState ? @"keyDown" : @"keyUp"];
        [event addObject:[modifierKey objectAtIndex:0]];
        break;
    }
    if([event count] == 1)
        ;//NSLog(@"Hmm; modifier flags changed, but we didn't match any of the flags...? %d", flags); // happens with left/right mods
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityKeyboard object:self userInfo:@{@"event": event}];
    
    /*
     Later we could make this fancier to get left/right modifier keys by using this:
     (Found from Googling at http://www.libsdl.org/tmp/SDL/src/video/cocoa/SDL_cocoakeyboard.m )
     #ifndef NX_DEVICERCTLKEYMASK
     #define NX_DEVICELCTLKEYMASK    0x00000001
     #endif
     #ifndef NX_DEVICELSHIFTKEYMASK
     #define NX_DEVICELSHIFTKEYMASK  0x00000002
     #endif
     #ifndef NX_DEVICERSHIFTKEYMASK
     #define NX_DEVICERSHIFTKEYMASK  0x00000004
     #endif
     #ifndef NX_DEVICELCMDKEYMASK
     #define NX_DEVICELCMDKEYMASK    0x00000008
     #endif
     #ifndef NX_DEVICERCMDKEYMASK
     #define NX_DEVICERCMDKEYMASK    0x00000010
     #endif
     #ifndef NX_DEVICELALTKEYMASK
     #define NX_DEVICELALTKEYMASK    0x00000020
     #endif
     #ifndef NX_DEVICERALTKEYMASK
     #define NX_DEVICERALTKEYMASK    0x00000040
     #endif
     #ifndef NX_DEVICERCTLKEYMASK
     #define NX_DEVICERCTLKEYMASK    0x00002000
     #endif
     */
}

@end
