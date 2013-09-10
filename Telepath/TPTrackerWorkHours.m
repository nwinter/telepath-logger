//
//  TPTrackerWorkHours.m
//  Telepath
//
//  Created by Nick Winter on 9/9/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerWorkHours.h"
#import "TPTracker.h"

@interface TPTrackerWorkHours ()
@property uint previousEvents;
@property BOOL working;
@property float lastSessionHours;
@property float lastDayHours;
@property float lastWeekHours;
@property NSDate *lastUpdate;
@property NSTimer *timeUpdateTimer;

@end

@implementation TPTrackerWorkHours

- (id)init
{
    self = [super init];
    if (self) {
        self.lastSessionHours = [[NSUserDefaults standardUserDefaults] floatForKey:@"lastSessionWorkHours"];
        self.lastDayHours = [[NSUserDefaults standardUserDefaults] floatForKey:@"lastDayWorkHours"];
        self.lastWeekHours = [[NSUserDefaults standardUserDefaults] floatForKey:@"lastWeekWorkHours"];
        self.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults] doubleForKey:@"lastWorkHoursUpdate"]];
        self.working = self.lastSessionHours > 0;
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onWorkChanged:) name:@"net.nickwinter.Telepath.WorkChanged" object:nil];
        //nc.addObserver_selector_name_object_(listener, 'getSong:', 'com.apple.iTunes.playerInfo', None)
        //nc.addObserver_selector_name_object_(listener, 'getEvent:', 'com.telepath.Telepath.TrackerEvent', None)
        self.timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(postUpdate) userInfo:nil repeats:YES];
        [self postUpdate];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onWorkChanged:(NSNotification *)note {
    self.lastSessionHours = [note.userInfo[@"sessionHours"] floatValue];
    self.lastDayHours = [note.userInfo[@"dayHours"] floatValue];
    self.lastWeekHours = [note.userInfo[@"weekHours"] floatValue];
    self.lastUpdate = [NSDate date];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setFloat:self.lastSessionHours forKey:@"lastSessionWorkHours"];
    [d setFloat:self.lastDayHours forKey:@"lastDayWorkHours"];
    [d setFloat:self.lastWeekHours forKey:@"lastWeekWorkHours"];
    [d setDouble:[self.lastUpdate timeIntervalSince1970] forKey:@"lastWorkHoursUpdate"];
    self.working = self.lastSessionHours > 0;
    [self postUpdate];
}

- (float)sessionHours {
    if(!self.working) return 0;
    return self.lastSessionHours + [[NSDate date] timeIntervalSinceDate:self.lastUpdate] / 3600.0;
}

- (float)dayHours {
    if(!self.working) return self.lastDayHours;
    return self.lastDayHours + [[NSDate date] timeIntervalSinceDate:self.lastUpdate] / 3600.0;
}

- (float)weekHours {
    if(!self.working) return self.lastWeekHours;
    return self.lastWeekHours + [[NSDate date] timeIntervalSinceDate:self.lastUpdate] / 3600.0;
}

- (void)postUpdate {
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityWorkHours object:self userInfo:@{@"sessionHours": @(self.sessionHours), @"dayHours": @(self.dayHours), @"weekHours": @(self.weekHours)}];
}

@end
