//
//  QMLightSensor.m
//  Telepath
//
//  Created by Nick Winter on 10/23/12.
//

#import "QMLightSensor.h"
#import <mach/mach.h>
#import <IOKit/IOKitLib.h>
#import <CoreFoundation/CoreFoundation.h>

// http://osxbook.com/book/bonus/chapter10/light/ -- if we want, we can also get and set keyboard backlight brightness and display brightness
enum {
    kGetSensorReadingID   = 0,  // getSensorReading(int *, int *)
    kGetLEDBrightnessID   = 1,  // getLEDBrightness(int, int *)
    kSetLEDBrightnessID   = 2,  // setLEDBrightness(int, int, int *)
    kSetLEDFadeID         = 3,  // setLEDFade(int, int, int, int *)
    
    // other firmware-related functions
    // verifyFirmwareID     = 4,  // verifyFirmware(int *)
    // getFirmwareVersionID = 5,  // getFirmwareVersion(int *)
    
    // other flashing-related functions
    // ...
};

static double DEFAULT_UPDATE_INTERVAL = 0.1;
static double TYPICAL_LIGHT_LEVEL = 1000000;  /// Indoors, indirect partly cloudy
static double MAX_LIGHT_LEVEL =    67092480;  /// Most I recorded with iPhone 4S flashlight right in its face

@interface QMLightSensor()
@property (assign) io_connect_t dataPort;
@property (strong) NSTimer *timer;
@property (assign) double lastLightLevelChangeTime;

- (BOOL)sample:(NSTimer *)t;
- (float)brightnessOf:(unsigned long long)level;
@end

@implementation QMLightSensor
@synthesize left;
@synthesize right;
@synthesize lastBrightness;
@synthesize updateInterval;
@synthesize dataPort;
@synthesize timer;
@synthesize lastLightLevelChangeTime;

- (id)init {
    if(self = [super init]) {
        self.updateInterval = DEFAULT_UPDATE_INTERVAL;
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

- (BOOL)started {
    return !!self.timer;
}

- (void)setUpdateInterval:(double)value {
    if(value == self.updateInterval) return;
    updateInterval = value;
    if(self.started)
        [self start];
}

- (float)brightnessOf:(unsigned long long)level {
    return 10 * log(1 + level * 22026 / MAX_LIGHT_LEVEL);
}

- (float)brightness {
    return [self brightnessOf:0.5 * (self.left + self.right)];
}

- (float)typicalBrightness {
    return [self brightnessOf:TYPICAL_LIGHT_LEVEL];
}

- (BOOL)start {
    if(self.started) [self stop];
    
    // Look up a registered IOService object whose class is AppleLMUController
    io_service_t serviceObject = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleLMUController"));
    if(!serviceObject) {
        NSLog(@"Didn't find ambient light sensor.");
        return NO;
    }
    
    // Create a connection to the IOService object
    kern_return_t kr = IOServiceOpen(serviceObject, mach_task_self(), 0, &dataPort);
    IOObjectRelease(serviceObject);
    if(kr != KERN_SUCCESS) {
        NSLog(@"Couldn't open IO service: %d", kr);
        return NO;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval target:self selector:@selector(sample:) userInfo:nil repeats:YES];
    BOOL worked = [self sample:nil];
    if(!worked)
        [self stop];
    return worked;
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
}

- (BOOL)sample:(NSTimer *)t {
    BOOL isFirstSample = !self.lastLightLevelChangeTime;
    if(!self.lastLightLevelChangeTime)
        self.lastLightLevelChangeTime = [[NSDate date] timeIntervalSince1970];
    IOItemCount scalarInputCount = 0;
    IOItemCount scalarOutputCount = 2;  // Should be, anyway
    unsigned long long leftAndRight[2];
	kern_return_t kr = IOConnectCallScalarMethod(self.dataPort, kGetSensorReadingID, NULL, scalarInputCount, leftAndRight, &scalarOutputCount);
    if(kr == KERN_SUCCESS) {
        float oldLeft = left;
        left = leftAndRight[0];
        right = leftAndRight[1];
        if(left != oldLeft) {
            double now = [[NSDate date] timeIntervalSince1970];
            //NSLog(@"Took %.3fms to update light level", 1000 * (now - self.lastLightLevelChangeTime));
            //NSLog(@"  Light:\t%.2f\t%f\t%f", self.brightness, self.left, self.right);
            self.lastLightLevelChangeTime = now;
            lastBrightness = [self brightnessOf:oldLeft];
            if(!isFirstSample)
                [[NSNotificationCenter defaultCenter] postNotificationName:QM_NOTIFICATION_LIGHT_CHANGED object:self];
        }
        return YES;
    }
    else if(kr == kIOReturnBusy) {
        NSLog(@"   Light sensor busy..?");
        return YES;
    }
    NSLog(@"Couldn't read light levels: %d", kr);
    return NO;
}

@end
