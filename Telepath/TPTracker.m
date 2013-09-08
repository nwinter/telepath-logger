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
#import "ImageSnap.h"

@interface TPTracker ()

/* Trackers */
@property TPTrackerKeyboard *trackerKeyboard;
@property TPTrackerMouse *trackerMouse;
@property TPTrackerWindow *trackerWindow;
@property TPTrackerLight *trackerLight;
@property TPTrackerCamera *trackerCamera;
@property TPTrackerGitHub *trackerGitHub;

/* Event logging */
@property (readwrite) uint totalEvents;
@property NSMutableArray *eventsToLog;

/* File state */
@property NSString *outputDir;
@property NSFileHandle *logFile;
@property NSTimer *logFileSwitchTimer;
@property NSTimer *logFileWriteTimer;

@end

NSString * const TPActivityAny = @"TPActivityAny";
NSString * const TPActivityKeyboard = @"TPActivityKeyboard";
NSString * const TPActivityKeyboardVeryBad = @"TPActivityKeyboardVeryBad";
NSString * const TPActivityMouse = @"TPActivityMouse";
NSString * const TPActivityWindow = @"TPActivityWindow";
NSString * const TPActivityLight = @"TPActivityLight";
NSString * const TPActivityCamera = @"TPActivityCamera";
NSString * const TPActivityGitHub = @"TPActivityGitHub";
NSString * const TPActivityClearTotals = @"TPActivityClearTotals";

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
        NSTimeInterval cameraRecordingInterval = 86400.0 / 30.0 / 60.0;  // Default: one minute per day at 30 FPS (1 shot every 48s)
        NSTimeInterval cameraPreviewInterval = 1 / 10.0;
        self.trackerCamera = [[TPTrackerCamera alloc] initWithRecordingInterval:cameraRecordingInterval andPreviewInterval:cameraPreviewInterval];
        self.trackerGitHub = [TPTrackerGitHub new];
        self.totalEvents = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalEvents"];
        [nc addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"totalEvents"];
            self.totalEvents = 0;
        }];
        [nc addObserver:self selector:@selector(onActivityKeyboard:) name:TPActivityKeyboard object:self.trackerKeyboard];
        [nc addObserver:self selector:@selector(onActivityMouse:) name:TPActivityMouse object:self.trackerMouse];
        [nc addObserver:self selector:@selector(onActivityWindow:) name:TPActivityWindow object:self.trackerWindow];
        [nc addObserver:self selector:@selector(onActivityLight:) name:TPActivityLight object:self.trackerLight];
        [nc addObserver:self selector:@selector(onActivityCamera:) name:TPActivityCamera object:self.trackerCamera];
    }
    return self;
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
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"net.nickwinter.Telepath.TrackerEvent" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:event, @"event", nil]];
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
    NSImage *image = note.userInfo[@"image"];
    if(!image || YES) return;  // Don't save images for now
    [self ensureOutputDirExists];
	NSDate *date = [NSDate date];
	unsigned long long ms = (long long)([date timeIntervalSince1970] * 1000);
    NSString *filename = [NSString stringWithFormat:@"%@/%@-%.3d-Z.jpg", self.outputDir, [date descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]], (int)(ms % 1000)];
    [ImageSnap saveImage:image toPath:filename];
}

#pragma mark - File writing

- (void)ensureOutputDirExists {
    self.outputDir = [@"~/Library/Application Support/Telepath/" stringByExpandingTildeInPath];
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

@end
