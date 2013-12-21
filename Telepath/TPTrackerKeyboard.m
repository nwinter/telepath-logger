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
#include <ApplicationServices/ApplicationServices.h>

@interface TPTrackerKeyboard ()
@property NSMutableString *recentCharacters;
@property NSArray *reallyBadStuff;
@property NSArray *punctuation;
@property NSMutableString *veryBad;
@property id eventMonitor;
@property uint previousEvents;
@property (readwrite) uint totalEvents;

@end

// TODO: Look at how Selfspy does it, since it probably handles all the modifier flags and special keys and such better.

@implementation TPTrackerKeyboard

- (id)init
{
    self = [super init];
    if (self) {
        self.recentCharacters = [NSMutableString new];
        
        [self loadReallyBadStuff];
        
        NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
        BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
        NSLog(@"Accessibility is enabled? %d", accessibilityEnabled);
        
        uint logMask = (NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask);
        self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:logMask handler:^(NSEvent *e) { [self onInputEvent:e]; }];
        self.previousEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousKeyboardEvents"];
        self.totalEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalKeyboardEvents"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"previousKeyboardEvents"];
            self.previousEvents = self.totalEvents;
        }];
    }
    return self;
}

- (uint)currentEvents {
    return self.totalEvents - self.previousEvents;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadReallyBadStuff {
    // Reading list of terrible words, upon typing of which we shall beep castigatorally!
    NSString *filepath = [@"~/Dropbox/code/really_bad_stuff.txt" stringByExpandingTildeInPath];
    NSString *contents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    self.reallyBadStuff = [[contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"];
    self.punctuation = @[@" ", @",", @".", @";", @"?", @"!", @"'", @"\"", @"-", @"/", @"(", @")", @"[", @"]", @"\n"];
    self.veryBad = [NSMutableString string];
    for(uint i = 0; i < [[self.reallyBadStuff lastObject] length]; ++i)
        [self.veryBad appendFormat:@"%C", (unichar)([[self.reallyBadStuff lastObject] characterAtIndex:i] - 1)];
}

- (NSArray *) modifierKeys {
    if (!_modifierKeys) {
        _modifierKeys =  @[@[@"⇪", @(NSAlphaShiftKeyMask), @(NO)].mutableCopy,
                           @[@"⇧", @(NSShiftKeyMask), @(NO)].mutableCopy,
                           @[@"⌃", @(NSControlKeyMask), @(NO)].mutableCopy,
                           @[@"⌥", @(NSAlternateKeyMask), @(NO)].mutableCopy,
                           @[@"⌘", @(NSCommandKeyMask), @(NO)].mutableCopy,
                           @[@"<numlock>", @(NSNumericPadKeyMask), @(NO)].mutableCopy,
                           @[@"<help>", @(NSHelpKeyMask), @(NO)].mutableCopy,
                           @[@"<fn>", @(NSFunctionKeyMask), @(NO)].mutableCopy];
    }
    return _modifierKeys;
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
    if([self.recentCharacters rangeOfString:self.veryBad].location != NSNotFound) {
        [self.recentCharacters deleteCharactersInRange:NSMakeRange(0, [self.recentCharacters length])];
        [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityKeyboardVeryBad object:self userInfo:@{@"badLength": @([self.veryBad length])}];
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
    [event addObject:keyUp ? @"keyUp" : @"keyDown"];
    [event addObject:[self eventCharacters: e]];
    
    NSNumber *isText = @([event.lastObject isEqualToString:e.characters]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityKeyboard object:self
                                                      userInfo:@{@"event": event,
                                                                 @"totalEvents": @(++self.totalEvents),
                                                                 @"currentEvents": @(self.currentEvents),
                                                                 @"isText": isText}];
    
    [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"totalKeyboardEvents"];
    
    if(keyUp) {
        [self.recentCharacters appendString:[e characters]];
        if([self.recentCharacters length] > 100)
            [self.recentCharacters deleteCharactersInRange:NSMakeRange(0, 1)];
        [self checkReallyBadStuff];
    }
}

- (NSString *) eventCharacters: (NSEvent *) e {
    switch (e.keyCode) {
        case 36: return @"↩";
        case 48: return @"⇥";
        case 49: return @" ";
        case 51: return @"⌫";
        case 53: return @"␛";
        case 123: return @"←";
        case 124: return @"→";
        case 125: return @"↓";
        case 126: return @"↑";
        default: return e.characters;
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
        [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityKeyboard object:self userInfo:@{@"event": event, @"totalEvents": @(++self.totalEvents), @"currentEvents": @(self.currentEvents), @"isText": @(NO)}];
    
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
