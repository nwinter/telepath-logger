//
//  TPTrackerScreen.m
//  Telepath
//
//  Created by Nick Winter on 9/16/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerScreen.h"
#import "TPTracker.h"

@interface TPTrackerScreen ()
@property NSTimer *screenshotTimer;
@property BOOL started;
@property CGWindowID currentWindowID;
@property CGRect currentWindowRect;

@end

@implementation TPTrackerScreen

- (id)initWithRecordingInterval:(NSTimeInterval)recordingInterval {
    self = [super init];
    if(self) {
        self.recordingInterval = recordingInterval;  // Starts recording.
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityWindow object:nil queue:nil usingBlock:^(NSNotification *note) {
            self.currentWindowID = (uint)[note.userInfo[@"currentWindowID"] integerValue];
            CGRect bounds;
            CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)note.userInfo[@"currentWindowBounds"], &bounds);
            self.currentWindowRect = bounds;
        }];
    }
    return self;
}

- (void)setRecordingInterval:(NSTimeInterval)recordingInterval {
    if(recordingInterval == _recordingInterval) return;
    _recordingInterval = recordingInterval;
   [self start];
}

- (void)start {
    [self.screenshotTimer invalidate];
    self.screenshotTimer = [NSTimer scheduledTimerWithTimeInterval:self.recordingInterval target:self selector:@selector(takeScreenshot:) userInfo:nil repeats:YES];
    self.started = YES;
}

- (void)stop {
    [self.screenshotTimer invalidate];
    self.screenshotTimer= nil;
    self.started = NO;
}

- (void)takeScreenshot:(NSTimer *)timer {
    // Actually we delay so that the webcam will be sure to have gone first
    [self performSelector:@selector(reallyTakeScreenshot) withObject:nil afterDelay:0.05];
}

- (void)reallyTakeScreenshot {
    NSImage *screenshot = [self captureScreen];
    [self postImage:screenshot];
}

- (NSImage *)captureScreen {
    NSImage *windowImage = nil;
    //if(self.currentWindowID) NSLog(@"Capturing screen with %@?", NSStringFromRect(self.currentWindowRect));
    if(self.currentWindowID && (self.currentWindowRect.origin.y + self.currentWindowRect.size.height > 10 || self.currentWindowRect.origin.x < -10)) {
        CGImageRef windowImageRef = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, self.currentWindowID, kCGWindowImageDefault);
        windowImage = [self imageFromCGImageRef:windowImageRef];
    }
    
    // CGRectInfinite to grab all of all screens
    CGRect topScreen = CGRectMake(0, -1600, 2560, 1600);  // Assume top screen of 2560x1600 is left-aligned and below main screen (of 2560x1600)
    CGImageRef screenshot = CGWindowListCreateImage(topScreen, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);
    NSImage *image = [self imageFromCGImageRef:screenshot];
    CGImageRelease(screenshot);
    if(windowImage)
        [self drawPIP:windowImage onto:image];
    return image;
}

- (void)drawPIP:(NSImage *)pip onto:(NSImage *)screen {
    [screen lockFocus];
    [pip drawAtPoint:CGPointMake(2560 - pip.size.width + 40, 200) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    [screen unlockFocus];
}

- (NSImage *)imageFromCGImageRef:(CGImageRef)cgImage {
    if(cgImage == NULL) return nil;
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    return image;
}

- (void)postImage:(NSImage *)image {
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityScreen object:self userInfo:@{@"image": image}];
}

@end
