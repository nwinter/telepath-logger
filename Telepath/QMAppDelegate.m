//
//  QMAppDelegate.m
//  Telepath
//
//  Created by Nick Winter on 8/2/12.
//

#import "QMAppDelegate.h"
#import "JSON.h"
#import "ImageSnap.h"
#import "smslib.h"
#import "QMLightSensor.h"
#import <AppKit/AppKit.h>

double now(void);

float ACCELEROMETER_SAMPLE_WINDOW = 2;  // Look at this many recent samples for sharp accelerometer changes

@interface QMAppDelegate()

/* UI */
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *updateField;

/* Word tracking */
@property (nonatomic, retain) NSMutableString *recentCharacters;
@property (nonatomic, retain) NSArray *reallyBadStuff;

/* Modifier key states */
@property (nonatomic, retain) NSArray *modifierKeys;

/* File state */
@property (nonatomic, retain) NSString *outputDir;
@property (nonatomic, retain) NSFileHandle *fileHandle;
@property (nonatomic, retain) NSTimer *fileSwitchTimer;

/* Tracking state */
@property (nonatomic, assign) uint eventsUpdated;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSString *lastWindowName;
@property (nonatomic, retain) NSString *lastOwnerName;
@property (nonatomic, retain) NSString *lastURL;
@property (nonatomic, assign) NSTimeInterval lastWindowSwitch;

/* Events */
@property (nonatomic, retain) id eventMonitor;
@property (nonatomic, retain) NSMutableArray *events;
@property (nonatomic, retain) NSMutableArray *windowEvents;

/* Quantified Mind */
@property (nonatomic, retain) NSTimer *quantifiedMindTimer;

/* Webcam */
@property (nonatomic, retain) NSTimer *webcamTimer;

/* Accelerometer */
@property (nonatomic, assign) BOOL hasAccelerometer;
@property (nonatomic, assign) BOOL hasAccelerometerCalibration;
@property (nonatomic, retain) NSTimer *accelerometerTimer;
@property (nonatomic, retain) NSMutableArray *accelerometerReadings;

/* Sounds */
@property (nonatomic, assign) double lastSoundTime;  /// So we don't play sounds too often
@property (nonatomic, retain) NSSound *wilhelm;
@property (nonatomic, retain) NSSound *drumKick;
@property (nonatomic, retain) NSSound *drumSnare;
@property (nonatomic, retain) NSSound *drumToms;
@property (nonatomic, retain) NSSound *drumHihat;
@property (nonatomic, retain) NSSound *drumTam;
@property (nonatomic, retain) NSMutableArray *drumTraining;

/* Light */
@property (nonatomic, retain) QMLightSensor *lightSensor;

/* Event Handlingr */
- (void)onInputEvent:(NSEvent *)e;
- (void)onKeyEvent:(NSEvent *)e up:(BOOL)keyUp;
- (void)onFlagsChangedEvent:(NSEvent *)e;
- (void)onMouseEvent:(NSEvent *)e type:(NSString *)type;
- (void)recordEvent:(NSArray *)event;  /// Add event string to event log, and send it out to other apps

/* Sampling Windows */
- (void)getWindowInfo;
- (NSString *)getDocumentURLFor:(NSString *)ownerName;  /// nil if not an Apple-Scriptable web browser (Safari, Chrome)

/* Switching logfiles */
- (void)openNewFile:(NSTimer *)t;

/* Prompting for Quantified Mind */
- (void)startQuantifiedMindTimer;
- (void)promptForQuantifiedMind:(NSTimer *)t;
- (void)onQuantifiedMindOkay:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

/* Sampling Webcam */
- (void)startWebcamTimer;
- (void)takeSnapshot:(NSTimer *)t;

/* Sampling Accelerometer */
- (void)onAccelerometerStartupLog:(NSString *)s;
- (SMSAcceleration *)readAccelerometer:(NSTimer *)t;
- (BOOL)detectAccelerometerChanges;  /// Returns whether something interesting crossed a threshold.

/* Light */
- (void)onLightChanged:(NSNotification *)note;
@end

@implementation QMAppDelegate
@synthesize window;
@synthesize updateField;
@synthesize recentCharacters;
@synthesize reallyBadStuff;
@synthesize modifierKeys;
@synthesize outputDir;
@synthesize fileHandle;
@synthesize fileSwitchTimer;
@synthesize eventsUpdated;
@synthesize timer;
@synthesize lastWindowName;
@synthesize lastOwnerName;
@synthesize lastURL;
@synthesize lastWindowSwitch;
@synthesize eventMonitor;
@synthesize events;
@synthesize windowEvents;
@synthesize quantifiedMindTimer;
@synthesize webcamTimer;
@synthesize hasAccelerometer;
@synthesize hasAccelerometerCalibration;
@synthesize accelerometerTimer;
@synthesize accelerometerReadings;
@synthesize wilhelm;
@synthesize drumKick;
@synthesize drumSnare;
@synthesize drumToms;
@synthesize drumHihat;
@synthesize drumTam;
@synthesize drumTraining;
@synthesize lightSensor;

#pragma mark - Setup

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.recentCharacters = [NSMutableString stringWithString:@""];
    
    // Reading list of terrible words
    NSString *filepath = [@"~/Dropbox/code/really_bad_stuff.txt" stringByExpandingTildeInPath];
    NSString *contents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    self.reallyBadStuff = [contents componentsSeparatedByString:@"\n"];
    
    self.modifierKeys = [NSArray arrayWithObjects:
                         [NSMutableArray arrayWithObjects:@"<capslock>", [NSNumber numberWithUnsignedInt:NSAlphaShiftKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<shift>", [NSNumber numberWithUnsignedInt:NSShiftKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<ctrl>", [NSNumber numberWithUnsignedInt:NSControlKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<alt>", [NSNumber numberWithUnsignedInt:NSAlternateKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<cmd>", [NSNumber numberWithUnsignedInt:NSCommandKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<numlock>", [NSNumber numberWithUnsignedInt:NSNumericPadKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<help>", [NSNumber numberWithUnsignedInt:NSHelpKeyMask], [NSNumber numberWithBool:NO], nil],
                         [NSMutableArray arrayWithObjects:@"<fn>", [NSNumber numberWithUnsignedInt:NSFunctionKeyMask], [NSNumber numberWithBool:NO], nil],
                         nil];
    
    self.lightSensor = [[QMLightSensor alloc] init];
    [self.lightSensor start];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLightChanged:) name:QM_NOTIFICATION_LIGHT_CHANGED object:self.lightSensor];
    self.hasAccelerometer = smsStartup(self, @selector(onAccelerometerStartupLog:)) == SMS_SUCCESS;  // start capturing accelerometer data
    if(self.hasAccelerometer) {
        self.hasAccelerometerCalibration = smsLoadCalibration();
        //NSLog(@"Got calibration: %@", smsGetCalibrationDescription());
        self.accelerometerReadings = [NSMutableArray array];
        self.accelerometerTimer = [NSTimer scheduledTimerWithTimeInterval:ACCELEROMETER_SAMPLE_RATE target:self selector:@selector(readAccelerometer:) userInfo:nil repeats:YES];
        self.wilhelm = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FXWilhelm" ofType:@"caf"] byReference:NO];
        self.drumKick = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FXKick" ofType:@"caf"] byReference:NO];
        self.drumSnare = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FXSnare" ofType:@"caf"] byReference:NO];
        self.drumToms = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FXToms" ofType:@"caf"] byReference:NO];
        self.drumHihat = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FXHihat" ofType:@"caf"] byReference:NO];
        self.drumTam = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FXTam" ofType:@"caf"] byReference:NO];
        self.drumTraining = [NSMutableArray array];
        for(uint i = 0; i < 5; ++i)
            [self.drumTraining addObject:[NSMutableArray array]];
    }
    uint logMask = (NSLeftMouseDraggedMask|NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask|NSMouseMovedMask|NSLeftMouseDownMask|NSRightMouseDownMask|NSLeftMouseUpMask|NSRightMouseUpMask);
    self.eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:logMask handler:^(NSEvent *e) { [self onInputEvent:e]; }];
    self.events = [NSMutableArray array];
    self.windowEvents = [NSMutableArray array];
    self.lastWindowSwitch = [[NSDate date] timeIntervalSince1970];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:WINDOW_SAMPLE_RATE target:self selector:@selector(sample) userInfo:nil repeats:YES];
    self.fileSwitchTimer = [NSTimer scheduledTimerWithTimeInterval:FILE_SWITCH_INTERVAL target:self selector:@selector(openNewFile:) userInfo:nil repeats:YES];
    if(NO && ![NSUserName() isEqualToString:@"winter"])
        [self startQuantifiedMindTimer];
    //[self startWebcamTimer];  // Not if you are worried about it getting you when you're naked!
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Quantified Mind prompting

- (void)startQuantifiedMindTimer {
    self.quantifiedMindTimer = [NSTimer scheduledTimerWithTimeInterval:QUANTIFIED_MIND_PROMPT_INTERVAL * (1 + QUANTIFIED_MIND_RANDOMIZATION * (arc4random() / (double)RAND_MAX - 0.5)) target:self selector:@selector(promptForQuantifiedMind:) userInfo:nil repeats:NO];
}

- (void)promptForQuantifiedMind:(NSTimer *)t {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Quantified Mind Time"
                                     defaultButton:@"Take the Telepath battery"
                                   alternateButton:nil
                                       otherButton:@"Skip it"
                         informativeTextWithFormat:@"If you haven't yet, join and enter participant code: Telepath"];
    
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(onQuantifiedMindOkay:returnCode:contextInfo:)
                        contextInfo:nil];
    
    [self startQuantifiedMindTimer];
}

- (void)onQuantifiedMindOkay:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if(returnCode == NSAlertDefaultReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.quantified-mind.com/"]];
    }
}

#pragma mark - Webcam

- (void)startWebcamTimer {
    self.webcamTimer = [NSTimer scheduledTimerWithTimeInterval:WEBCAM_INTERVAL target:self selector:@selector(takeSnapshot:) userInfo:nil repeats:YES];
}

- (void)takeSnapshot:(NSTimer *)t {
    [self ensureOutputDirExists];
	NSDate *date = [NSDate date];
	unsigned long long ms = (long long)([date timeIntervalSince1970] * 1000);
    NSString *filename = [NSString stringWithFormat:@"%@/%@-%.3d-Z.jpg", self.outputDir, [date descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]], (int)(ms % 1000)];
    [ImageSnap saveSingleSnapshotFrom:[ImageSnap defaultVideoDevice] toFile:filename withWarmup:nil];
}

#pragma mark - File writing

- (void)ensureOutputDirExists {
    self.outputDir = [@"~/Library/Application Support/Telepath/" stringByExpandingTildeInPath];
	[[NSFileManager defaultManager] createDirectoryAtPath:self.outputDir withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)openNewFile:(NSTimer *)t {
    [self.fileHandle closeFile];
    [self ensureOutputDirExists];
	NSDate *date = [NSDate date];
	unsigned long long ms = (long long)([date timeIntervalSince1970] * 1000);
    NSError *err;
    NSString *path = [NSString stringWithFormat:@"%@/%@-%.3d-Z.log", self.outputDir, [date descriptionWithCalendarFormat:@"%Y-%m-%d-%H-%M-%S" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]], (int)(ms % 1000)];
    
    if(![[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil]) {
        NSLog(@"FAIL creating file");
    }
    
    self.fileHandle = [NSFileHandle fileHandleForWritingToURL:[NSURL fileURLWithPath:path] error:&err];
    if(!self.fileHandle) {
        NSLog(@"FAIL opening file %@", err);
    }
}

- (void)logData:(NSData *)data {
	if(!self.fileHandle)
        [self openNewFile:nil];
	[self.fileHandle writeData:data];
}

#pragma mark - Sampling

- (void)sample {
    [self getWindowInfo];
    if(![self.events count]) return;
    NSString *logEntries = [[self.events componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    NSData *logEntriesData = [logEntries dataUsingEncoding:NSUTF8StringEncoding];
    [self logData:logEntriesData];
    [self.events removeAllObjects];
}

-(void)getWindowInfo {
    BOOL justTopWindow = YES;
	CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, 0);
	int count = 0;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	for(NSDictionary *entry in (__bridge NSArray*)windowList) {
		NSString *windowName = [entry objectForKey:(id)kCGWindowName];
		NSString *ownerName = [entry objectForKey:(id)kCGWindowOwnerName];
        NSString *url = [self getDocumentURLFor:ownerName];  // probably nil
        BOOL sameURL = (!self.lastURL && !url) || [self.lastURL isEqualToString:url];
        if([self.lastWindowName isEqualToString:windowName] && [self.lastOwnerName isEqualToString:ownerName] && sameURL)
            break;
		
		if(windowName == nil || [windowName isEqualTo:@""] || [ownerName isEqualTo:@"SystemUIServer"] || [ownerName isEqualTo:@"Window Server"] || [ownerName isEqualTo:@"Main Menu"] || [ownerName isEqualTo:@"Dock"])
			continue;
        
		NSMutableArray *info = [[NSMutableArray alloc] init];
		[info addObject:[NSNumber numberWithDouble:now]];
		[info addObject:windowName];
		[info addObject:ownerName];
        [info addObject:[NSNumber numberWithDouble:now - self.lastWindowSwitch]];
        if(url)
            [info addObject:url];
        
        if(!justTopWindow)
            [info addObject:[NSNumber numberWithInt:count]];
        
        [self recordEvent:info];
        if(count++ == 0) {
            self.lastWindowName = windowName;
            self.lastOwnerName = ownerName;
            self.lastWindowSwitch = [[NSDate date] timeIntervalSince1970];
            self.lastURL = url;
        }
        
        if(justTopWindow)
            break;
	}
	CFRelease(windowList);
}

- (NSString *)getDocumentURLFor:(NSString *)ownerName {
    NSString *tabName = nil;
    if([ownerName isEqualToString:@"Safari"])
        tabName = @"front document";
    else if([ownerName isEqualToString:@"Google Chrome"])
        tabName = @"active tab of front window";
    else
        return nil;  // not an Apple-scriptable browser
    
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"%@\" to return URL of %@ as string", ownerName, tabName]];
    NSDictionary *scriptError = nil;
    NSString *result = nil;
    NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&scriptError];
    if(scriptError)
        NSLog(@"Error: %@", scriptError);
    else {        
        NSAppleEventDescriptor *unicode = [descriptor coerceToDescriptorType:typeUnicodeText];
        NSData *data = [unicode data];
        result = [[NSString alloc] initWithCharacters:(unichar*)[data bytes] length:[data length] / sizeof(unichar)];
    }
    return result;
}

#pragma mark - Input event handling

- (void)recordEvent:(NSArray *)event {
    NSString *logLine = JSONRepresentation(event);
    [self.events addObject:logLine];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.telepath.Telepath.TrackerEvent" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:event, @"event", logLine, @"json", nil]];
}

-(void)onInputEvent:(NSEvent *)e {
	NSEventType t = [e type];
	if (t == NSKeyDown)
        [self onKeyEvent:e up:NO];
	else if(t == NSKeyUp)
        [self onKeyEvent:e up:YES];
	else if(t == NSFlagsChanged)
        [self onFlagsChangedEvent:e];
	else if(t == NSMouseMoved)
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
    
	[self.updateField setStringValue:[NSString stringWithFormat:@"%d", ++self.eventsUpdated]];
}

- (void)onKeyEvent:(NSEvent *)e up:(BOOL)keyUp {
	NSMutableArray *info = [NSMutableArray array];
	[info addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
	if(keyUp)
		[info addObject:@"keyUp"];
	else 
		[info addObject:@"keyDown"];
	
	int code = [e keyCode];
	if(code == 36)
		[info addObject:@"<return>"];
	else if (code == 48)
		[info addObject:@"<tab>"];
	else if (code == 49)
		[info addObject:@"<space>"];
	else if (code == 51)
		[info addObject:@"<delete>"];
	else if (code == 53)
		[info addObject:@"<esc>"];
	else if (code == 123)
		[info addObject:@"<left>"];
	else if (code == 124)
		[info addObject:@"<right>"];
	else if (code == 125)
		[info addObject:@"<down>"];
	else if (code == 126)
		[info addObject:@"<up>"];
	else
		[info addObject:[e characters]];
    
    if(self.hasAccelerometer) {
        SMSAcceleration *lastAcceleration = [self.accelerometerReadings count] ? [self.accelerometerReadings lastObject] : nil;
        SMSAcceleration *acceleration = [self readAccelerometer:nil];
        [info addObject:[NSNumber numberWithFloat:acceleration.magnitude]];  // always include absolute magnitude
        if(lastAcceleration) {
            SMSAcceleration *distance = [acceleration distanceFromAcceleration:lastAcceleration];
            [info addObject:[NSNumber numberWithFloat:distance.absoluteMagnitude]];  // if available, include magnitude change from last record
        }
    }
    [self recordEvent:info];
    
    if(!keyUp || !self.reallyBadStuff) return;
    // Warn the user if he types despicable words
    [self.recentCharacters appendString:[[e characters] lowercaseString]];
    if([self.recentCharacters length] > 100)
        [self.recentCharacters deleteCharactersInRange:NSMakeRange(0, 1)];
    NSArray *punctuation = [NSArray arrayWithObjects:@" ", @",", @".", @";", @"?", @"!", @"'", @"\"", @"-", @"/", @"(", @")", @"[", @"]", @"\n", nil];
    for(NSString *thing in self.reallyBadStuff)
        for(NSString *punct in punctuation) {
            if([thing length] && [self.recentCharacters rangeOfString:[NSString stringWithFormat:@"%@%@", thing, punct]].location != NSNotFound) {
                NSLog(@"You shouldn't use %@!", thing);
                [self.recentCharacters deleteCharactersInRange:NSMakeRange(0, [self.recentCharacters length])];
                NSBeep();
            }
        }
}

- (void)onFlagsChangedEvent:(NSEvent *)e {
	NSMutableArray *info = [NSMutableArray array];
	[info addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
    
    unsigned long flags = [e modifierFlags];
    for(NSMutableArray *modifierKey in self.modifierKeys) {
        BOOL oldState = !![[modifierKey objectAtIndex:2] boolValue];
        BOOL newState = !!(flags & [[modifierKey objectAtIndex:1] unsignedIntValue]);
        //NSLog(@"modifierKey: %@, oldState: %d, newState: %d", modifierKey, oldState, newState);
        if(oldState == newState) continue;
        [modifierKey replaceObjectAtIndex:2 withObject:[NSNumber numberWithBool:newState]];
        [info addObject:newState ? @"keyDown" : @"keyUp"];
        [info addObject:[modifierKey objectAtIndex:0]];
        break;
    }
    if([info count] == 1)
        ;//NSLog(@"Hmm; modifier flags changed, but we didn't match any of the flags...? %d", flags); // happens with left/right mods
    else
        [self recordEvent:info];
    
    /*
     Later we could make this fancier to get left/right modifier keys by using this:
     (Found from googling at http://www.libsdl.org/tmp/SDL/src/video/cocoa/SDL_cocoakeyboard.m )
     #ifndef NX_DEVICERCTLKEYMASK
     #define NX_DEVICELCTLKEYMASK    0x00000001
     #endif
     #ifndef NX_DEVICELSHIFTKEYMASK
     #define NX_DEVICELSHIFTKEYMASK  0x00000002
     #endif
     #ifndef NX_DEVICERSHIFTKEYMASK
     #define NX_DEVICERSHIFTKEYMASK  0x00000004
     #endif
     #ifndef NX_DEVICELCMDKEYMASK
     #define NX_DEVICELCMDKEYMASK    0x00000008
     #endif
     #ifndef NX_DEVICERCMDKEYMASK
     #define NX_DEVICERCMDKEYMASK    0x00000010
     #endif
     #ifndef NX_DEVICELALTKEYMASK
     #define NX_DEVICELALTKEYMASK    0x00000020
     #endif
     #ifndef NX_DEVICERALTKEYMASK
     #define NX_DEVICERALTKEYMASK    0x00000040
     #endif
     #ifndef NX_DEVICERCTLKEYMASK
     #define NX_DEVICERCTLKEYMASK    0x00002000
     #endif
     */
}

- (void)onMouseEvent:(NSEvent *)e type:(NSString *)type {
	NSPoint p = [NSEvent mouseLocation];
	NSMutableArray *info = [NSMutableArray array];
	[info addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
	[info addObject:type];
	[info addObject:[NSNumber numberWithFloat:p.x]];
	[info addObject:[NSNumber numberWithFloat:p.y]];
    [self recordEvent:info];
}

#pragma mark - Sampling aceelerometer

- (void)onAccelerometerStartupLog:(NSString *)s {
    NSLog(@"%@", s);
}

- (SMSAcceleration *)readAccelerometer:(NSTimer *)t {
    double t0 = now();
    sms_acceleration *acceleration = (sms_acceleration *)malloc(sizeof(sms_acceleration));
    int result = smsGetData(acceleration);
    if(result != SMS_SUCCESS) {
        NSLog(@"Couldn't get accelerometer data, code %d", result);
        return NULL;
    }
    double t1 = now();
    SMSAcceleration *ret = [[SMSAcceleration alloc] initWithStruct:acceleration];
    free(acceleration);

    [self.accelerometerReadings addObject:ret];
    if([self.accelerometerReadings count] > ACCELEROMETER_SAMPLE_WINDOW)
        [self.accelerometerReadings removeObjectAtIndex:0];
    float magnitude = ret.magnitude;
    NSString *graph = [@"-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------" substringToIndex:MIN(199, (int)(magnitude / 0.005))];
    BOOL didSomething = [self detectAccelerometerChanges];
    if(didSomething || [graph length] > 40)
        NSLog(@"Accelerometer:\t%d\t%.1ffms\t%.3f\t%.3f\t%.3f\t%@", didSomething, (t1 - t0) * 1000, ret.x, ret.y, ret.z, graph);
    
    //NSLog(@"  Light:\t%.2f\t%f\t%f", self.lightSensor.brightness, self.lightSensor.left, self.lightSensor.right);
    return ret;
}

- (BOOL)detectAccelerometerChanges {
    if([self.accelerometerReadings count] < ACCELEROMETER_SAMPLE_WINDOW || now() - self.lastSoundTime < 0.05) return NO;
    if(![NSUserName() isEqualToString:@"winter"]) return NO;  // Let's not inflict my bad drumming on anyone else yet.
    SMSAcceleration *last = [self.accelerometerReadings lastObject];
    SMSAcceleration *first = [self.accelerometerReadings objectAtIndex:0];
    BOOL reset = NO;
    float dx = last.x - first.x, dy = last.y - first.y, dz = last.z - first.z;
    if((dz < -0.25 || dz > 0.4) && fabsf(dx) < 0.05 && fabsf(dy) < 0.05) {
        [self.drumKick play];
        NSLog(@"Kick");
        reset = YES;
    }
    else if(dz < -0.05 && dx < -0.03) {
        [self.drumToms play];

        reset = YES;
    }
    else if(dx > 0.15 && dy > 0.1) {
        [self.drumSnare play];
        NSLog(@"Snare");
        reset = YES;
    }
    else if(dx > 0.15) {
        [self.drumHihat play];
        NSLog(@"Hihat");
        reset = YES;
    }
    else if([last distanceFromAcceleration:first].absoluteMagnitude > 0.4) {
        // Something is happening, but we don't know what.
        [self.drumTam play];
        NSLog(@"Tam");
        reset = YES;
    }
    else if(last.absoluteMagnitude < 0.02) {
        // No gravity!
        NSLog(@"AAAAAAH");
        [self.wilhelm play];
        reset = YES;
    }
    
    // Collecting drum training
    if(last.magnitude - first.magnitude > 0.1 && [self.recentCharacters length]) {
        NSString *c = [self.recentCharacters substringFromIndex:[self.recentCharacters length] - 1];
        if([@"01234" rangeOfString:c].location != NSNotFound) {
            NSInteger type = [c integerValue];
            [[self.drumTraining objectAtIndex:type] addObject:last];
            reset = true;
            for(size_t i = 0; i < [self.drumTraining count]; ++i) {
                float meanX = 0, meanY = 0, meanZ = 0, count = [[self.drumTraining objectAtIndex:i] count];
                for(SMSAcceleration *sample in [self.drumTraining objectAtIndex:i]) {
                    meanX += sample.x / count;
                    meanY += sample.y / count;
                    meanZ += sample.z / count;
                }
                NSLog(@"Drum %zd had mean:\t%.3f\t%.3f\t%.3f with:\t%.0f samples.", i, meanX, meanY, meanZ, count);
            }
        }
    }
    
    if(reset) {
        NSLog(@"%.2f\t%.2f\t%.2f", dx, dy, dz);
        self.lastSoundTime = now();
    }
    return reset;
}

#pragma mark - Light

- (void)onLightChanged:(NSNotification *)note {
	NSMutableArray *info = [NSMutableArray array];
	[info addObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]];
	[info addObject:@"lightChanged"];
	[info addObject:[NSNumber numberWithFloat:self.lightSensor.brightness]];
    [self recordEvent:info];
}

@end

NSString *JSONRepresentation(id object) {
    //return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil] encoding:NSUTF8StringEncoding];
    return [object JSONRepresentation];
}

double now(void) {
    return [[NSDate date] timeIntervalSince1970];
}
