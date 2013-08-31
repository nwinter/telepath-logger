//
//  TPTrackerLight.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerLight.h"
#import "TPUtilities.h"
#import "TPLightSensor.h"
#import "TPTracker.h"

@interface TPTrackerLight ()

@property TPLightSensor *lightSensor;
@property NSMutableArray *events;

@end

@implementation TPTrackerLight

- (id)init
{
    self = [super init];
    if (self) {
        self.lightSensor = [TPLightSensor new];
        [self.lightSensor start];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLightChanged:) name:TPLightChanged object:self.lightSensor];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onLightChanged:(NSNotification *)note {
	NSMutableArray *event = [NSMutableArray array];
	[event addObject:@(now())];
	[event addObject:@"lightChanged"];
	[event addObject:[NSNumber numberWithFloat:self.lightSensor.brightness]];
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityLight object:self userInfo:@{@"light": @(self.lightSensor.brightness), @"event": event}];
}

@end
