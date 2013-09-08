//
//  TPTrackerBrunchBuilds.m
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerBrunchBuilds.h"
#import "TPTracker.h"

@interface TPTrackerBrunchBuilds ()
@property uint previousEvents;
@property (readwrite) uint totalEvents;

@end

@implementation TPTrackerBrunchBuilds

- (id)init
{
    self = [super init];
    if (self) {
        self.previousEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousBrunchBuildEvents"];
        self.totalEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalBrunchBuildEvents"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"previousBrunchBuildEvents"];
            self.previousEvents = self.totalEvents;
        }];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onBrunchBuild:) name:@"net.nickwinter.Telepath.BrunchBuild" object:nil];
        [self onBrunchBuild:nil];
    }
    return self;
}

- (uint)currentEvents {
    return self.totalEvents - self.previousEvents;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onBrunchBuild:(NSNotification *)note {
    if(note)
        ++self.totalEvents;
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityBrunchBuild object:self userInfo:@{@"totalEvents": @(self.totalEvents), @"currentEvents": @(self.currentEvents)}];
    [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"totalBrunchBuildEvents"];
}

@end
