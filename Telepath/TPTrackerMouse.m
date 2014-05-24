//
//  TPTrackerMouse.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerMouse.h"
#import "TPUtilities.h"
#import "TPTracker.h"

@interface TPTrackerMouse ()

@property NSMutableArray *events;
@property id eventMonitor;
@property NSInteger previousEvents;
@property (readwrite) NSInteger totalEvents;

@end

@implementation TPTrackerMouse

- (id)init
{
    self = [super init];
    if (self) {
        NSInteger logMask = (NSLeftMouseDraggedMask|NSMouseMovedMask|NSLeftMouseDownMask|NSRightMouseDownMask|NSLeftMouseUpMask|NSRightMouseUpMask);
        self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:logMask handler:^(NSEvent *e) { [self onInputEvent:e]; }];
        self.previousEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousMouseEvents"];
        self.totalEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalMouseEvents"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"previousMouseEvents"];
            self.previousEvents = self.totalEvents;
        }];
    }
    return self;
}

- (NSInteger)currentEvents {
    return self.totalEvents - self.previousEvents;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)onInputEvent:(NSEvent *)e {
	NSEventType t = [e type];
	if(t == NSMouseMoved)
        [self onMouseEvent:e type:@"mouseMoved"];
	else if(t == NSLeftMouseDown)
        [self onMouseEvent:e type:@"leftMouseDown"];
	else if(t == NSLeftMouseUp)
        [self onMouseEvent:e type:@"leftMouseUp"];
	else if(t == NSRightMouseDown)
        [self onMouseEvent:e type:@"rightMouseDown"];
	else if(t == NSRightMouseUp)
        [self onMouseEvent:e type:@"rightMouseUp"];
	else if(t == NSLeftMouseDragged)
        [self onMouseEvent:e type:@"leftMouseDragged"];
}

- (void)onMouseEvent:(NSEvent *)e type:(NSString *)type {
	NSPoint p = [NSEvent mouseLocation];
	NSMutableArray *event = [NSMutableArray array];
	[event addObject:@(now())];
	[event addObject:type];
	[event addObject:@(p.x)];
	[event addObject:@(p.y)];
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityMouse object:self userInfo:@{@"event": event, @"totalEvents": @(++self.totalEvents), @"currentEvents": @(self.currentEvents)}];
    [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"totalMouseEvents"];
}

@end
