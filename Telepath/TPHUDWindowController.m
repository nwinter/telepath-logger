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
@property (unsafe_unretained) IBOutlet NSImageView *cameraImage;
@property (weak) IBOutlet NSTextField *cameraTimerLabel;
@property (weak) IBOutlet NSTextFieldCell *timeLabel;
@property (weak) IBOutlet NSTextFieldCell *dayLabel;

// Random Stats Area
@property (weak) IBOutlet NSTextField *keystrokesField;
@property (weak) IBOutlet NSTextField *mouseMovementsField;
@property (weak) IBOutlet NSTextField *windowSwitchesField;
@property (weak) IBOutlet NSTextField *commitsField;
@property (weak) IBOutlet NSTextField *trellosSlainField;
@property (weak) IBOutlet NSTextField *trellosRemainingField;
@property (weak) IBOutlet NSTextField *buildsField;
@property (weak) IBOutlet NSTextField *unreadEmailsField;

// Keyboard Area
@property (weak) IBOutlet NSTextField *currentWindowField;
@property (weak) IBOutlet NSTextField *currentDocumentField;
@property (unsafe_unretained) IBOutlet NSTextView *recentKeysView;


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
    [nc addObserver:self selector:@selector(onActivityKeyboard:) name:TPActivityKeyboard object:nil];
    [nc addObserver:self selector:@selector(onActivityMouse:) name:TPActivityMouse object:nil];
    [nc addObserver:self selector:@selector(onActivityWindow:) name:TPActivityWindow object:nil];
    [nc addObserver:self selector:@selector(onActivityLight:) name:TPActivityLight object:nil];
    [nc addObserver:self selector:@selector(onActivityCamera:) name:TPActivityCamera object:nil];
    self.timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onActivityKeyboard:(NSNotification *)note {
    [self.keystrokesField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"totalEvents"]]];
    NSArray *event = note.userInfo[@"event"];
    BOOL down = [event[1] isEqualToString:@"keyDown"];
    if(down) {
        NSInteger fontSize = [note.userInfo[@"isText"] boolValue] ? 24 : 13;
        NSAttributedString *newText = [[NSAttributedString alloc] initWithString:event[2] attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontSize]}];
        [self.recentKeysView.textStorage appendAttributedString:newText];
        [self.recentKeysView scrollToEndOfDocument:nil];
    }
}

- (void)onActivityMouse:(NSNotification *)note {
    [self.mouseMovementsField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"totalEvents"]]];
}

- (void)onActivityWindow:(NSNotification *)note {
    [self.windowSwitchesField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"totalEvents"]]];
    NSArray *event = note.userInfo[@"event"];
    [self.currentWindowField setStringValue:event[2]];
    [self.currentDocumentField setStringValue:event[1]];
}

- (void)onActivityLight:(NSNotification *)note {
    
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
