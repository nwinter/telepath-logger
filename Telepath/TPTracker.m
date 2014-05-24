//
//  TPTracker.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTracker.h"
#import "TPUtilities.h"
#import "TPTrackerKeyboard.h"
#import "TPTrackerMouse.h"
#import "TPTrackerWindow.h"
#import "TPTrackerLight.h"
#import "TPTrackerCamera.h"
#import "TPTrackerGitHub.h"
#import "TPTrackerTrello.h"
#import "TPTrackerBrunchBuilds.h"
#import "TPTrackerEmail.h"
#import "TPTrackerWorkHours.h"
#import "TPTrackerScreen.h"
#import "TPTrackerHappiness.h"
#import "ImageSnap.h"

@interface TPTracker ()

/* Trackers */
@property TPTrackerKeyboard *trackerKeyboard;
@property TPTrackerMouse *trackerMouse;
@property TPTrackerWindow *trackerWindow;
@property TPTrackerLight *trackerLight;
@property TPTrackerCamera *trackerCamera;
@property TPTrackerGitHub *trackerGitHub;
@property TPTrackerTrello *trackerTrello;
@property TPTrackerBrunchBuilds *trackerBrunchBuilds;
@property TPTrackerEmail *trackerEmail;
@property TPTrackerWorkHours *trackerWorkHours;
@property TPTrackerScreen *trackerScreen;
@property TPTrackerHappiness *trackerHappiness;

/* Event logging */
@property NSInteger previousEvents;
@property (readwrite) NSInteger totalEvents;
@property NSMutableArray *eventsToLog;

/* File state */
@property NSString *outputDir;
@property NSFileHandle *logFile;
@property NSTimer *logFileSwitchTimer;
@property NSTimer *logFileWriteTimer;

@end

NSString * const TPActivityClearTotals = @"TPActivityClearTotals";
NSString * const TPActivityAny = @"TPActivityAny";
NSString * const TPActivityKeyboard = @"TPActivityKeyboard";
NSString * const TPActivityKeyboardVeryBad = @"TPActivityKeyboardVeryBad";
NSString * const TPActivityMouse = @"TPActivityMouse";
NSString * const TPActivityWindow = @"TPActivityWindow";
NSString * const TPActivityLight = @"TPActivityLight";
NSString * const TPActivityCamera = @"TPActivityCamera";
NSString * const TPActivityGitHub = @"TPActivityGitHub";
NSString * const TPActivityTrello = @"TPActivityTrello";
NSString * const TPActivityBrunchBuild = @"TPActivityBrunchBuild";
NSString * const TPActivityEmail = @"TPActivityEmail";
NSString * const TPActivityWorkHours = @"TPActivityWorkHours";
NSString * const TPActivityScreen = @"TPActivityScreen";
NSString * const TPActivityHappiness = @"TPActivityHappiness";

/// We'll switch log files this often.
const double FILE_SWITCH_INTERVAL = 1 * 24 * 60 * 60;

/// We'll write accumulated events to a log file this often.
const double FILE_WRITE_INTERVAL = 1;

@implementation TPTracker

- (id)init
{
    self = [super init];
    if (self) {
        self.eventsToLog = [NSMutableArray array];
        self.logFileSwitchTimer = [NSTimer scheduledTimerWithTimeInterval:FILE_SWITCH_INTERVAL target:self selector:@selector(openNewFile:) userInfo:nil repeats:YES];
        self.logFileWriteTimer = [NSTimer scheduledTimerWithTimeInterval:FILE_WRITE_INTERVAL target:self selector:@selector(writeLogs:) userInfo:nil repeats:YES];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        self.trackerKeyboard = [TPTrackerKeyboard new];
        self.trackerMouse = [TPTrackerMouse new];
        self.trackerWindow = [TPTrackerWindow new];
        self.trackerLight = [TPTrackerLight new];
        //NSTimeInterval cameraRecordingInterval = 86400.0 / 30.0 / 60.0;  // Default: one minute per day at 30 FPS (1 shot every 48s)
        //NSTimeInterval cameraRecordingInterval = 60;  // Once a minute
        NSTimeInterval targetLength = 367;  // Song length 6:07, leads to ~55s
        NSTimeInterval cameraRecordingInterval = 7 * 86400 / 30.0 / targetLength;
        //cameraRecordingInterval = 10;  // Testing: every 10s.
        //NSTimeInterval cameraPreviewInterval = 1 / 10.0;
        //NSTimeInterval cameraPreviewInterval = 1 / 3.0;
        NSTimeInterval cameraPreviewInterval = 1;  // / 3.0;
        //NSLog(@"Would set up screen recording with recording interval %f and preview interval %f, but not recording screen right now", cameraRecordingInterval, cameraPreviewInterval);
        self.trackerCamera = [[TPTrackerCamera alloc] initWithRecordingInterval:cameraRecordingInterval andPreviewInterval:cameraPreviewInterval];
        self.trackerGitHub = [TPTrackerGitHub new];
        self.trackerTrello = [TPTrackerTrello new];
        self.trackerBrunchBuilds = [TPTrackerBrunchBuilds new];
        self.trackerEmail = [TPTrackerEmail new];
        self.trackerWorkHours = [TPTrackerWorkHours new];
        self.trackerScreen = [[TPTrackerScreen alloc] initWithRecordingInterval:cameraRecordingInterval];
        self.trackerHappiness = [[TPTrackerHappiness alloc] initWithPingInterval:3 * 60 * 60];
        self.previousEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousEvents"];
        self.totalEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalEvents"];
        [nc addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalEvents) forKey:@"previousEvents"];
            self.previousEvents = self.totalEvents;
        }];
        [nc addObserver:self selector:@selector(onActivityKeyboard:) name:TPActivityKeyboard object:self.trackerKeyboard];
        [nc addObserver:self selector:@selector(onActivityMouse:) name:TPActivityMouse object:self.trackerMouse];
        [nc addObserver:self selector:@selector(onActivityWindow:) name:TPActivityWindow object:self.trackerWindow];
        [nc addObserver:self selector:@selector(onActivityLight:) name:TPActivityLight object:self.trackerLight];
        [nc addObserver:self selector:@selector(onActivityCamera:) name:TPActivityCamera object:self.trackerCamera];
        [nc addObserver:self selector:@selector(onActivityScreen:) name:TPActivityScreen object:self.trackerScreen];
    }
    return self;
}

- (NSInteger)currentEvents {
    return self.totalEvents - self.previousEvents;
}

- (NSTimeInterval)cameraRecordingInterval {
    return self.trackerCamera.recordingInterval;
}

- (void)setCameraRecordingInterval:(NSTimeInterval)cameraRecordingInterval {
    self.trackerCamera.recordingInterval = cameraRecordingInterval;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.logFile closeFile];
}

#pragma mark - Activity

- (void)logEvent:(NSArray *)event {
    [self.eventsToLog addObject:JSONRepresentation(event)];
    [[NSUserDefaults standardUserDefaults] setObject:@(++self.totalEvents) forKey:@"totalEvents"];
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityAny object:self];
    // Distributed notifications got really slow in 10.9?
    //[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"net.nickwinter.Telepath.TrackerEvent" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:event, @"event", nil]];
}

- (void)onActivityKeyboard:(NSNotification *)note {
    [self logEvent:note.userInfo[@"event"]];
}

- (void)onActivityMouse:(NSNotification *)note {
    [self logEvent:note.userInfo[@"event"]];
}

- (void)onActivityWindow:(NSNotification *)note {
    [self logEvent:note.userInfo[@"event"]];
}

- (void)onActivityLight:(NSNotification *)note {
    [self logEvent:note.userInfo[@"event"]];
}

- (void)onActivityCamera:(NSNotification *)note {
    return;  // Don't save camera images for now
    [self saveImage:note.userInfo[@"image"] withExtension:@"jpg"];
}

- (void)onActivityScreen:(NSNotification *)note {
    [self saveImage:note.userInfo[@"image"] withExtension:@"jpg"];
}

#pragma mark - File writing

- (void)ensureOutputDirExists {
    NSString *path = [@"~/Desktop/Hog/Storage/Telepath/winter/Telepath" stringByExpandingTildeInPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:path])
        self.outputDir = path;
    else
        self.outputDir = [@"~/Library/Application Support/Telepath/" stringByExpandingTildeInPath];  // If you're not me.
	[[NSFileManager defaultManager] createDirectoryAtPath:self.outputDir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)openNewFile:(NSTimer *)t {
    [self.logFile closeFile];
    [self ensureOutputDirExists];
	NSDate *date = [NSDate date];
	unsigned long long ms = (long long)([date timeIntervalSince1970] * 1000);
    NSError *err;
    NSString *path = [NSString stringWithFormat:@"%@/%@-%.3d-Z.log", self.outputDir, [date descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]], (int)(ms % 1000)];
    
    if(![[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil]) {
        NSLog(@"FAIL creating file");
    }
    
    self.logFile = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:path] error:&err];
    if(!self.logFile) {
        NSLog(@"FAIL opening file %@", err);
    }
}

- (void)writeLogs:(NSTimer *)timer {
    if(![self.eventsToLog count]) return;
    if(!self.logFile)
        [self openNewFile:nil];
    NSString *logEntries = [[self.eventsToLog componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    NSData *logEntriesData = [logEntries dataUsingEncoding:NSUTF8StringEncoding];
    [self.logFile writeData:logEntriesData];
    [self.eventsToLog removeAllObjects];
}

- (void)saveImage:(NSImage *)image withExtension:(NSString *)extension {
    if(!image) return;
    [self ensureOutputDirExists];
	NSDate *date = [NSDate date];
	unsigned long long ms = (long long)([date timeIntervalSince1970] * 1000);
    NSString *filename = [NSString stringWithFormat:@"%@/%@-%.3d-Z.%@", self.outputDir, [date descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]], (int)(ms % 1000), extension];
    [ImageSnap saveImage:image toPath:filename];
}

@end
