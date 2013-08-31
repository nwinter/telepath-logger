//
//  TPHUDWindowController.m
//  Telepath
//
//  Created by Nick Winter on 8/30/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPHUDWindowController.h"
#import "ImageSnap.h"
#import "TPLightSensor.h"
#import "TPTracker.h"


@interface TPHUDWindowController ()
@property (weak) IBOutlet NSTextField *updateField;
@property (weak) IBOutlet NSImageView *cameraImage;
@property (weak) IBOutlet NSTextField *cameraTimerLabel;
@property (weak) IBOutlet NSTextFieldCell *timeLabel;
@property (weak) IBOutlet NSTextFieldCell *dayLabel;

@property TPTracker *tracker;
@property NSTimer *timeUpdateTimer;

@end

@implementation TPHUDWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary];
    self.tracker = [TPTracker new];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:TPActivityAny object:self.tracker queue:nil usingBlock:^(NSNotification *note) {
        [self.updateField setStringValue:[NSString stringWithFormat:@"%d", self.tracker.totalEvents]];
    }];
    [nc addObserver:self selector:@selector(onActivityCamera:) name:TPActivityCamera object:nil];
    self.timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onActivityCamera:(NSNotification *)note {
    self.cameraImage.image = note.userInfo[@"image"];
    NSTimeInterval countdown = [note.userInfo[@"countdown"] doubleValue];
    self.cameraTimerLabel.alphaValue = countdown < 0.5 ? 0 : countdown < 5 ? 1.0 : countdown < 10 ? 0.5 : 0.2;
    [self.cameraTimerLabel setStringValue:[NSString stringWithFormat:@"%.0f", countdown]];
}

- (void)updateTime:(NSTimer *)timer {
    NSDate *date = [NSDate date];
    NSDateFormatter *dayFormat = [NSDateFormatter new];
    [dayFormat setDateFormat:@"EEEE"];
    NSDateFormatter *timeFormat = [NSDateFormatter new];
    [timeFormat setDateFormat:@"HH:mm"];
    [self.timeLabel setStringValue:[timeFormat stringFromDate:date]];
    [self.dayLabel setStringValue:[dayFormat stringFromDate:date]];
}

@end
