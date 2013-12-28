//
//  TPTrackerHappiness.m
//  Telepath
//
//  Created by Nick Winter on 11/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerHappiness.h"
#import "TPTracker.h"

@interface TPTrackerHappiness ()
@property NSTimer *pingTimer;
@property BOOL started;

/// Whether we've in screensaver (and might not want to play a noise if it's late at night).
@property BOOL screensaver;

@end

@implementation TPTrackerHappiness

- (id)initWithPingInterval:(NSTimeInterval)pingInterval {
    self = [super init];
    if(self) {
        srand48(time(0));
        self.pingInterval = pingInterval;  // Starts ping.
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onScreensaverStart:) name:@"com.apple.screensaver.didstart" object:nil];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onScreensaverStop:) name:@"com.apple.screensaver.didstop" object:nil];
    }
    return self;
}

- (void)setPingInterval:(NSTimeInterval)pingInterval {
    if(pingInterval == _pingInterval) return;
    _pingInterval = pingInterval;
    [self start];
}

- (void)start {
    [self.pingTimer invalidate];
    NSTimeInterval interval = (1 + 0.5 - drand48()) * self.pingInterval;  // 0.5 - 1.5x the interval
    if(!self.started)
        interval -= 0.5 * self.pingInterval;  // start early on first run, since it may have been a while since last ping
    self.pingTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(ping:) userInfo:nil repeats:YES];
    self.started = YES;
}

- (void)stop {
    [self.pingTimer invalidate];
    self.pingTimer= nil;
    self.started = NO;
}

- (void)ping:(NSTimer *)timer {
    NSDateFormatter *timeOfDay = [[NSDateFormatter alloc] init];
    [timeOfDay setDateFormat:@"HHmm"];
    int currentTime = [[timeOfDay stringFromDate:[NSDate date]] intValue];
    if(!self.screensaver || (830 < currentTime && currentTime < 2300)) {
        NSSound *chime = [NSSound soundNamed:@"fez-chime"];
        [chime play];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityHappiness object:self userInfo:@{}];
    [self start];
}

- (void)onScreensaverStart:(NSNotification *)note {
    NSLog(@"Screensaver Start");
    self.screensaver = YES;
}

- (void)onScreensaverStop:(NSNotification *)note {
    NSLog(@"Screensaver Stop");
    self.screensaver = NO;
}

@end
