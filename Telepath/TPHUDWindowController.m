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
// Camera Area
@property (unsafe_unretained) IBOutlet NSImageView *cameraImage;
@property (weak) IBOutlet NSTextField *cameraTimerLabel;

// Time Area
@property (weak) IBOutlet NSTextFieldCell *timeLabel;
@property (weak) IBOutlet NSTextFieldCell *dayLabel;
@property (weak) IBOutlet NSTextField *sessionHoursLabel;
@property (weak) IBOutlet NSTextField *dayHoursLabel;
@property (weak) IBOutlet NSTextField *weekHoursLabel;

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

// Activity Area
@property (weak) IBOutlet NSComboBox *activityBox;
@property (weak) IBOutlet NSTextField *activityDetailField;

@property TPTracker *tracker;
@property NSTimer *timeUpdateTimer;
@property NSString *currentActivity;

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
    [self.window becomeKeyWindow];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(onActivityKeyboard:) name:TPActivityKeyboard object:nil];
    [nc addObserver:self selector:@selector(onActivityKeyboardVeryBad:) name:TPActivityKeyboardVeryBad object:nil];
    [nc addObserver:self selector:@selector(onActivityMouse:) name:TPActivityMouse object:nil];
    [nc addObserver:self selector:@selector(onActivityWindow:) name:TPActivityWindow object:nil];
    [nc addObserver:self selector:@selector(onActivityLight:) name:TPActivityLight object:nil];
    [nc addObserver:self selector:@selector(onActivityCamera:) name:TPActivityCamera object:nil];
    [nc addObserver:self selector:@selector(onActivityGitHub:) name:TPActivityGitHub object:nil];
    [nc addObserver:self selector:@selector(onActivityTrello:) name:TPActivityTrello object:nil];
    [nc addObserver:self selector:@selector(onActivityBrunchBuild:) name:TPActivityBrunchBuild object:nil];
    [nc addObserver:self selector:@selector(onActivityEmail:) name:TPActivityEmail object:nil];
    self.timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onWorkChanged:) name:@"net.nickwinter.Telepath.WorkChanged" object:nil];
    //nc.addObserver_selector_name_object_(listener, 'getSong:', 'com.apple.iTunes.playerInfo', None)
    //nc.addObserver_selector_name_object_(listener, 'getEvent:', 'com.telepath.Telepath.TrackerEvent', None)

    [self setUpActivityBox];
    self.tracker = [TPTracker new];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onActivityKeyboard:(NSNotification *)note {
    [self.keystrokesField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentEvents"]]];
    NSArray *event = note.userInfo[@"event"];
    BOOL down = [event[1] isEqualToString:@"keyDown"];
    if(down) {
        NSInteger fontSize = [note.userInfo[@"isText"] boolValue] ? 24 : 13;
        NSAttributedString *newText = [[NSAttributedString alloc] initWithString:event[2] attributes:@{NSFontAttributeName: [NSFont systemFontOfSize:fontSize]}];
        [self.recentKeysView.textStorage appendAttributedString:newText];
        NSInteger length = [self.recentKeysView.textStorage length];
        if(length > 500)
            [self.recentKeysView.textStorage replaceCharactersInRange:NSMakeRange(0, length - 500) withString:@""];
        [self.recentKeysView scrollToEndOfDocument:nil];
    }
}

- (void)onActivityKeyboardVeryBad:(NSNotification *)note {
    [self.recentKeysView.textStorage replaceCharactersInRange:NSMakeRange([self.recentKeysView.textStorage length] - [note.userInfo[@"badLength"] intValue], [note.userInfo[@"badLength"] intValue]) withString:@""];
}

- (void)onActivityMouse:(NSNotification *)note {
    [self.mouseMovementsField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentEvents"]]];
}

- (void)onActivityWindow:(NSNotification *)note {
    [self.windowSwitchesField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentEvents"]]];
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

- (void)onActivityGitHub:(NSNotification *)note {
    [self.commitsField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentCommits"]]];
}

- (void)onActivityTrello:(NSNotification *)note {
    [self.trellosSlainField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentTrellosSlain"]]];
    [self.trellosRemainingField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"trellosAlive"]]];
}

- (void)onActivityBrunchBuild:(NSNotification *)note {
    [self.buildsField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentEvents"]]];
}

- (void)onActivityEmail:(NSNotification *)note {
    [self.unreadEmailsField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"unreadEmails"]]];
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


- (void)setUpActivityBox {
    NSArray *pastActivities = [[NSUserDefaults standardUserDefaults] arrayForKey:@"activities"];
    NSMutableArray *activities = [NSMutableArray arrayWithArray:pastActivities ? pastActivities : @[@"Coding", @"Sleeping", @"Eating"]];
    self.currentActivity = [[NSUserDefaults standardUserDefaults] stringForKey:@"currentActivity"];
    if(self.currentActivity && ![activities containsObject:self.currentActivity])
        [activities addObject:self.currentActivity];
    [self.activityBox addItemsWithObjectValues:activities];
    if(self.currentActivity)
        [self.activityBox selectItemWithObjectValue:self.currentActivity];
    void (^onChangedBlock)(NSNotification *note) = ^(NSNotification *note) {
        if([note.name isEqualToString:NSComboBoxSelectionDidChangeNotification])
            self.currentActivity = [self.activityBox objectValueOfSelectedItem];
        else
            self.currentActivity = [self.activityBox stringValue];
        [[NSUserDefaults standardUserDefaults] setObject:self.currentActivity forKey:@"currentActivity"];
        if(![activities containsObject:self.currentActivity]) {
            [activities addObject:self.currentActivity];
            [self.activityBox addItemWithObjectValue:self.currentActivity];
            [[NSUserDefaults standardUserDefaults] setObject:activities forKey:@"activities"];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:NSComboBoxSelectionDidChangeNotification object:self.activityBox queue:nil usingBlock:onChangedBlock];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidEndEditingNotification object:self.activityBox queue:nil usingBlock:onChangedBlock];
    
    NSString *currentActivityDetail = [[NSUserDefaults standardUserDefaults] stringForKey:@"currentActivityDetail"];
    if(currentActivityDetail)
        self.activityDetailField.stringValue = currentActivityDetail;
}

- (IBAction)onActivityDetailChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:self.activityDetailField.stringValue forKey:@"currentActivityDetail"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)onRandomStatsClearClicked:(id)sender {
    NSLog(@"Clear totals!");
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityClearTotals object:self userInfo:nil];
}

#pragma mark - External notifications

- (void)onWorkChanged:(NSNotification *)note {
    float sessionHours = [note.userInfo[@"sessionHours"] floatValue];
    float dayHours = [note.userInfo[@"dayHours"] floatValue];
    float weekHours = [note.userInfo[@"weekHours"] floatValue];
    [self.sessionHoursLabel setStringValue:[NSString stringWithFormat:@"%d:%02d", (int)sessionHours, (int)(60 * sessionHours) % 60]];
    [self.dayHoursLabel setStringValue:[NSString stringWithFormat:@"%d:%02d", (int)dayHours, (int)(60 * dayHours) % 60]];
    [self.weekHoursLabel setStringValue:[NSString stringWithFormat:@"%d:%02d", (int)weekHours, (int)(60 * weekHours) % 60]];
}

@end
