//
//  TPTrackerWindow.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerWindow.h"
#import "TPUtilities.h"
#import "TPTracker.h"

@interface TPTrackerWindow ()

@property NSString *lastWindowName;
@property NSString *lastOwnerName;
@property NSString *lastURL;
@property NSTimeInterval lastWindowSwitch;
@property NSTimer *windowSampleTimer;
@property uint previousEvents;
@property (readwrite) uint totalEvents;

@end

/// We'll sample changes to the foremost window this often, and write out events to the log file. This should be often enough to, for example, not miss any tabs when holding down Ctrl+Tab to cycle through Chrome tabs. (My testing showed hitting only 1/2 tabs at 100ms sampling.)
const NSTimeInterval WINDOW_SAMPLE_RATE = 0.025;

@implementation TPTrackerWindow

- (id)init
{
    self = [super init];
    if (self) {
        self.lastWindowSwitch = now();
        self.windowSampleTimer = [NSTimer scheduledTimerWithTimeInterval:WINDOW_SAMPLE_RATE target:self selector:@selector(sample:) userInfo:nil repeats:YES];
        self.totalEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalWindowEvents"];
        self.previousEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousWindowEvents"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"previousWindowEvents"];
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

- (void)sample:(NSTimer *)timer {
    BOOL justTopWindow = YES;
	CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, 0);
	int count = 0;
    NSTimeInterval t = now();
	for(NSDictionary *entry in (__bridge NSArray*)windowList) {
        NSInteger windowLayer = [entry[(id)kCGWindowLayer] integerValue];
        if(windowLayer != 0) continue;
		NSString *windowName = [entry objectForKey:(id)kCGWindowName];
		NSString *ownerName = [entry objectForKey:(id)kCGWindowOwnerName];
        NSString *url = [self getDocumentURLFor:ownerName];  // probably nil
        BOOL sameURL = (!self.lastURL && !url) || [self.lastURL isEqualToString:url];
        //NSLog(@"Got windowName %@, ownerName %@, url %@, sameURL %d", windowName, ownerName, url, sameURL);
        if([self.lastWindowName isEqualToString:windowName] && [self.lastOwnerName isEqualToString:ownerName] && sameURL)
            break;
		
		if(windowName == nil || [windowName isEqualTo:@""] || [ownerName isEqualTo:@"SystemUIServer"] || [ownerName isEqualTo:@"Window Server"] || [ownerName isEqualTo:@"Main Menu"] || [ownerName isEqualTo:@"Dock"] || [ownerName isEqualToString:@"Telepath"])
			continue;
        
		NSMutableArray *event = [[NSMutableArray alloc] init];
		[event addObject:@(t)];
		[event addObject:windowName];
		[event addObject:ownerName];
        [event addObject:@(t - self.lastWindowSwitch)];
        if(url)
            [event addObject:url];
        
        if(!justTopWindow)
            [event addObject:@(count)];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityWindow object:self userInfo:@{@"event": event, @"totalEvents": @(++self.totalEvents), @"currentEvents": @(self.currentEvents), @"currentWindowID": [entry objectForKey:(id)kCGWindowNumber], @"currentWindowBounds": [entry objectForKey:(id)kCGWindowBounds]}];
        [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"totalWindowEvents"];
        if(count++ == 0) {
            self.lastWindowName = windowName;
            self.lastOwnerName = ownerName;
            self.lastWindowSwitch = [[NSDate date] timeIntervalSince1970];
            self.lastURL = url;
        }
        
        if(justTopWindow)
            break;
	}
	CFRelease(windowList);
}

- (NSString *)getDocumentURLFor:(NSString *)ownerName {
    NSString *tabName = nil;
    if([ownerName isEqualToString:@"Safari"])
        tabName = @"front document";
    else if([ownerName isEqualToString:@"Google Chrome"])
        tabName = @"active tab of front window";
    else
        return nil;  // not an Apple-scriptable browser, like Firefox: http://stackoverflow.com/questions/17846948/does-firefox-offer-applescript-support-to-get-url-of-windows
    
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"%@\" to return URL of %@", ownerName, tabName]];
    NSDictionary *scriptError = nil;
    NSString *result = nil;
    NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&scriptError];
    if(scriptError)
        ;//NSLog(@"Error: %@", scriptError);  // doesn't work any more; oh well
    else {
        NSAppleEventDescriptor *unicode = [descriptor coerceToDescriptorType:typeUnicodeText];
        NSData *data = [unicode data];
        result = [[NSString alloc] initWithCharacters:(unichar*)[data bytes] length:[data length] / sizeof(unichar)];
    }
    return result;
}


@end
