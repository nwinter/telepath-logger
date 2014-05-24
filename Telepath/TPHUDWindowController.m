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
#import <WebKit/WebKit.h>

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
@property (weak) IBOutlet NSTextField *additionsField;
@property (weak) IBOutlet NSTextField *deletionsField;
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

// Affect Area
@property (weak) IBOutlet NSTextField *artistField;
@property (weak) IBOutlet NSTextField *songField;
@property (weak) IBOutlet NSTextField *happinessField;
@property (weak) IBOutlet NSTextField *energyField;
@property (weak) IBOutlet NSTextField *healthField;
@property (weak) IBOutlet NSTextField *happinessLabel;
@property (weak) IBOutlet NSTextField *energyLabel;
@property (weak) IBOutlet NSTextField *healthLabel;

// Timelapse Progress Area (or is it Percentile Feedback Area?)
@property (weak) IBOutlet WebView *percentileFeedbackView;


@property TPTracker *tracker;
@property NSTimer *timeUpdateTimer;
@property NSString *currentActivity;
@property BOOL isWorking;

@end

@implementation TPHUDWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        [self.window setContentBorderThickness:0.0f forEdge:NSMinYEdge];
        [self.window setContentBorderThickness:0.0f forEdge:NSMaxYEdge];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setLevel:NSFloatingWindowLevel];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary];
    [self.window becomeKeyWindow];
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[[self.window backgroundColor] colorWithAlphaComponent:0.75]];
    
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
    [nc addObserver:self selector:@selector(onActivityWorkHours:) name:TPActivityWorkHours object:nil];
    [nc addObserver:self selector:@selector(onActivityHappiness:) name:TPActivityHappiness object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onWorkChanged:) name:@"net.nickwinter.Telepath.WorkChanged" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onActivityHappiness:) name:@"net.nickwinter.Telepath.HappinessChanged" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onSongChanged:) name:@"com.apple.iTunes.playerInfo" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onSongChanged:) name:@"com.spotify.client.PlaybackStateChanged" object:nil];
    //[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onAnyDistributedNotification:) name:nil object:nil];

    self.timeUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];

    [self setUpActivityBox];
    self.tracker = [TPTracker new];
    [self.percentileFeedbackView setMainFrameURL:@"http://www.nickwinter.net/codecombat-stats?just_graph=1"];
    NSView *clipView = [[[self.percentileFeedbackView.mainFrame frameView] documentView] superview];
    [clipView scaleUnitSquareToSize:NSMakeSize(0.586, 0.586)];
    [clipView setNeedsDisplay:YES];
    [self setFonts];
    [self.artistField setHidden:YES];
    [self.songField setHidden:YES];
    [self onActivityHappiness:nil];  // Hide these fields until a ping happens
}

- (NSArray *)allSubviewsOfView:(NSView *)view {
    NSMutableArray *allSubviews = [NSMutableArray arrayWithObject:view];
    NSArray *subviews = [view subviews];
    for (NSView *subview in subviews)
        [allSubviews addObjectsFromArray:[self allSubviewsOfView:subview]];
    return [allSubviews copy];
}

- (void)setFonts {
    NSColor *textColor = [NSColor colorWithWhite:0.35 alpha:1.0];
    for(id view in [self allSubviewsOfView:self.window.contentView]) {
        if(![view respondsToSelector:@selector(setFont:)]) continue;
        NSFont *font = (NSFont *)[view font];
        font = [NSFont fontWithName:@"OpenSans-Light" size:font.pointSize];
        if([view respondsToSelector:@selector(textColor)]) {
            NSColor *color = ((NSTextField *)view).textColor;
            if([color isEqual:[NSColor keyboardFocusIndicatorColor]])
                [view setTextColor:textColor];
            if(font.pointSize < 24 && ![color isEqual:[NSColor controlTextColor]])
                font = [NSFont fontWithName:@"OpenSans-Semibold" size:font.pointSize];
        }
        [view setFont:(id)font];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSImage *)cropImage:(NSImage *)source toSize:(NSSize)size {
    NSImage *resultImage = [[NSImage alloc] initWithSize:size];
    [resultImage lockFocus];
    [source drawAtPoint:NSMakePoint(0, 0) fromRect:NSMakeRect((source.size.width - size.width) / 2, 0, size.width, size.height) operation:NSCompositeSourceOver fraction:1];
    [resultImage unlockFocus];
    return resultImage;
}


- (void)onActivityKeyboard:(NSNotification *)note {
    [self.keystrokesField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"currentEvents"]]];
    NSArray *event = note.userInfo[@"event"];
    BOOL down = [event[1] isEqualToString:@"keyDown"];
    if(down) {
        NSInteger fontSize = [note.userInfo[@"isText"] boolValue] ? 24 : 13;
        NSAttributedString *newText = [[NSAttributedString alloc] initWithString:event[2] attributes:@{NSFontAttributeName: [NSFont fontWithName:@"OpenSans-Semibold" size:fontSize], NSForegroundColorAttributeName: [NSColor colorWithWhite:0.35 alpha:1.0]}];
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
    [self.additionsField setStringValue:[NSString stringWithFormat:@"%@++", note.userInfo[@"currentAdditions"]]];
    [self.deletionsField setStringValue:[NSString stringWithFormat:@"%@--", note.userInfo[@"currentDeletions"]]];
    //[self.additionsField setStringValue:[NSString stringWithFormat:@"%@++", @(57824)]];
    //[self.deletionsField setStringValue:[NSString stringWithFormat:@"%@--", @(13800)]];
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

- (void)onActivityWorkHours:(NSNotification *)note {
    float sessionHours = [note.userInfo[@"sessionHours"] floatValue];
    float dayHours = [note.userInfo[@"dayHours"] floatValue];
    float weekHours = [note.userInfo[@"weekHours"] floatValue];
    [self.sessionHoursLabel setStringValue:[NSString stringWithFormat:@"%d:%02d", (int)sessionHours, (int)(60 * sessionHours) % 60]];
    [self.dayHoursLabel setStringValue:[NSString stringWithFormat:@"%d:%02d", (int)dayHours, (int)(60 * dayHours) % 60]];
    [self.weekHoursLabel setStringValue:[NSString stringWithFormat:@"%d:%02d", (int)weekHours, (int)(60 * weekHours) % 60]];
    BOOL working = [note.userInfo[@"working"] boolValue];
    if(self.isWorking != working) {
        self.isWorking = working;
        NSSound *listen = [NSSound soundNamed:@"listen"];
        [listen play];
    }
}

- (void)onActivityHappiness:(NSNotification *)note {
    self.happinessField.alphaValue = self.energyField.alphaValue = self.healthField.alphaValue = 1.0;
    self.happinessLabel.alphaValue = self.energyLabel.alphaValue = self.healthLabel.alphaValue = 1.0;
    NSTimeInterval fadeDuration = 10 * 60;
    if(!note)
        fadeDuration = 1.0;
    else if(note.userInfo[@"happiness"]) {
        [self.happinessField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"happiness"]]];
        [self.energyField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"energy"]]];
        [self.healthField setStringValue:[NSString stringWithFormat:@"%@", note.userInfo[@"health"]]];
        fadeDuration = 1.5 * 60 * 60;
    }
    else {
        [self.happinessField setStringValue:@"?"];
        [self.energyField setStringValue:@"?"];
        [self.healthField setStringValue:@"?"];
    }
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:fadeDuration];
    [[self.happinessField animator] setAlphaValue:0.0];
    [[self.energyField animator] setAlphaValue:0.0];
    [[self.healthField animator] setAlphaValue:0.0];
    [[self.happinessLabel animator] setAlphaValue:0.0];
    [[self.energyLabel animator] setAlphaValue:0.0];
    [[self.healthLabel animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
}

- (void)onWorkChanged:(NSNotification *)note {
    [self.percentileFeedbackView reload:nil];
}

- (void)onSongChanged:(NSNotification *)note {
    NSString *artist = note.userInfo[@"Artist"];
    NSString *song = note.userInfo[@"Name"];
    BOOL playing = [note.userInfo[@"Player State"] isEqualToString:@"Playing"];
    self.songField.hidden = self.artistField.hidden = !playing;
    [self.artistField setStringValue:artist];
    [self.songField setStringValue:song];
}

- (void)onAnyDistributedNotification:(NSNotification *)note {
    NSLog(@"<%p>%s: object: %@ name: %@ userInfo: %@", self, __PRETTY_FUNCTION__, note.object, note.name, note.userInfo);
}

- (void)updateTime:(NSTimer *)timer {
    NSDate *date = [NSDate date];
    NSDateFormatter *dayFormat = [NSDateFormatter new];
    [dayFormat setDateFormat:@"EEEE"];
    NSDateFormatter *timeFormat = [NSDateFormatter new];
    [timeFormat setDateFormat:@"HH:mm"];
    [self.dayLabel setStringValue:[dayFormat stringFromDate:date]];
    [self.timeLabel setStringValue:[timeFormat stringFromDate:date]];
    //[self.dayLabel setStringValue:@"Wednesday"];
    //[self.timeLabel setStringValue:@"10:32"];
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
    NSString *detail = self.activityDetailField.stringValue;
    [[NSUserDefaults standardUserDefaults] setObject:detail forKey:@"currentActivityDetail"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)onRandomStatsClearClicked:(id)sender {
    NSLog(@"Clear totals!");
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityClearTotals object:self userInfo:nil];
}

@end
