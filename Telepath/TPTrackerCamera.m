//
//  TPTrackerCamera.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerCamera.h"
#import "TPUtilities.h"
#import "ImageSnap.h"
#import "TPTracker.h"

@interface TPTrackerCamera ()

@property NSTimer *cameraTimer;
@property ImageSnap *camera;
@property NSMutableArray *images;
@property NSTimeInterval lastSnapshotTime;

/// Whether our camera has a session going.
@property BOOL started;

@end

@implementation TPTrackerCamera

- (id)initWithRecordingInterval:(NSTimeInterval)recordingInterval andPreviewInterval:(NSTimeInterval)previewInterval
{
    self = [super init];
    if (self) {
        self.lastSnapshotTime = now();
        self.previewInterval = previewInterval;  // Starts recording
        self.recordingInterval = recordingInterval;  // Starts recording
        self.cropRatio = 0.6;
    }
    return self;
}

- (void)dealloc
{
    [self stopCamera];
}

- (void)setRecordingInterval:(NSTimeInterval)recordingInterval {
    if(recordingInterval == _recordingInterval) return;
    _recordingInterval = recordingInterval;
    if(self.previewInterval)
        [self startCamera];
}

- (void)setPreviewInterval:(NSTimeInterval)previewInterval {
    if(previewInterval == _previewInterval) return;
    _previewInterval = previewInterval;
    if(self.previewInterval)
        [self startCamera];
    else
        [self stopCamera];
}

- (void)startCamera {
    if(!self.camera) {
        self.camera = [ImageSnap new];
        [self.camera startSession:[ImageSnap defaultVideoDevice]];
    }
    if(!self.images)
        self.images = [NSMutableArray array];
    [self.cameraTimer invalidate];
    self.cameraTimer = [NSTimer scheduledTimerWithTimeInterval:self.previewInterval target:self selector:@selector(takeSnapshot:) userInfo:nil repeats:YES];
    self.started = YES;
}

- (void)stopCamera {
    [self.camera stopSession];
    self.camera = nil;
    [self.cameraTimer invalidate];
    self.cameraTimer = nil;
    self.started = NO;
}

- (void)takeSnapshot:(NSTimer *)timer {
    NSTimeInterval t = now();
    if(!self.started)
        [self.camera startSession:[ImageSnap defaultVideoDevice]];
    NSImage *largeImage = [self.camera snapshot];
    if(!largeImage) return;
    NSImage *image = [self cropImage:largeImage toSize:NSMakeSize(largeImage.size.width * self.cropRatio, largeImage.size.height * self.cropRatio)];
    static int snapshotsTaken = 0;
    ++snapshotsTaken;
    NSTimeInterval countdown = self.recordingInterval - (t - self.lastSnapshotTime);
    if(countdown <= 0 || ![self.images count]) {
        self.lastSnapshotTime = t;
        [self.images addObject:image];
        if([self.images count] > 3)
            [self.images removeObjectAtIndex:0];
        [self.camera stopSession];  // Hack: since sometimes the camera dies, we stop and restart it every time this happens.
        self.started = NO;
    }
    else if(NO && countdown < 10) {
        float oldImageRatio = (snapshotsTaken % 4) ? 1 / countdown / [self.images count] : 0;
        for(NSImage *oldImage in self.images)
            image = [self mergeImage:image withImage:oldImage withRatio:oldImageRatio];
    }
    [self postImage:image withCountdown:countdown];
}

- (void)postImage:(NSImage *)image withCountdown:(NSTimeInterval)countdown {
    [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityCamera object:self userInfo:@{@"image": image, @"countdown": @(countdown)}];
}

- (NSImage *)mergeImage:(NSImage *)first withImage:(NSImage *)second withRatio:(float)ratio {
    NSImage *resultImage = [[NSImage alloc] initWithSize:first.size];
    [resultImage lockFocus];
    [first drawAtPoint:CGPointMake(0, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    [second drawAtPoint:CGPointMake(0, 0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:ratio];
    [resultImage unlockFocus];
    return resultImage;
}

/// Grab just the bottom middle of the source image.
- (NSImage *)cropImage:(NSImage *)source toSize:(NSSize)size {
    NSImage *resultImage = [[NSImage alloc] initWithSize:size];
    [resultImage lockFocus];
    [source drawAtPoint:NSMakePoint(0, 0) fromRect:NSMakeRect((source.size.width - size.width) / 2, 0, size.width, size.height) operation:NSCompositeSourceOver fraction:1];
    [resultImage unlockFocus];
    return resultImage;
}

@end
