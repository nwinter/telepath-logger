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

@end

@implementation TPTrackerCamera

- (id)initWithRecordingInterval:(NSTimeInterval)recordingInterval andPreviewInterval:(NSTimeInterval)previewInterval
{
    self = [super init];
    if (self) {
        self.previewInterval = previewInterval;  // Starts recording
        self.recordingInterval = recordingInterval;  // Starts recording
    }
    return self;
}

- (void)dealloc
{
    [self.camera stopSession];
}

- (void)setRecordingInterval:(NSTimeInterval)recordingInterval {
    if(recordingInterval == _recordingInterval) return;
    _recordingInterval = recordingInterval;
    [self startCamera];
}

- (void)setPreviewInterval:(NSTimeInterval)previewInterval {
    if(previewInterval == _previewInterval) return;
    _previewInterval = previewInterval;
    [self startCamera];
}

- (void)startCamera {
    if(!self.camera) {
        self.camera = [ImageSnap new];
        [self.camera startSession:[ImageSnap defaultVideoDevice]];
        self.images = [NSMutableArray new];
    }
    [self.cameraTimer invalidate];
    self.cameraTimer = [NSTimer scheduledTimerWithTimeInterval:self.previewInterval target:self selector:@selector(takeSnapshot:) userInfo:nil repeats:YES];
}

- (void)takeSnapshot:(NSTimer *)timer {
    NSTimeInterval t = now();
    NSImage *image = [self.camera snapshot];
    NSTimeInterval countdown = self.recordingInterval - (t - self.lastSnapshotTime);
    if(countdown <= 0 || ![self.images count]) {
        self.lastSnapshotTime = t;
        [self.images addObject:image];
        if([self.images count] > 3)
            [self.images removeObjectAtIndex:0];
    }
    else if(countdown < 10) {
        for(NSImage *oldImage in self.images)
            image = [self mergeImage:image withImage:oldImage withRatio:1 / countdown / [self.images count]];
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



@end
