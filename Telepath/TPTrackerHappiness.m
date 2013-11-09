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

@end

@implementation TPTrackerHappiness

- (id)initWithPingInterval:(NSTimeInterval)pingInterval {
    self = [super init];
    if(self) {
        srand48(time(0));
        self.pingInterval = pingInterval;  // Starts ping.
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
    NSSound *chime = [NSSound soundNamed:@"fez-chime"];
    [chime play];
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityHappiness object:self userInfo:@{}];
    [self start];
}

@end
