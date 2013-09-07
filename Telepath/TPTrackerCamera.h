//
//  TPTrackerCamera.h
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TPTrackerCamera : NSObject
/// We'll take a camera screenshot at this interval (seconds).
@property (nonatomic) NSTimeInterval recordingInterval;

/// We'll update the camera preview at this interval (seconds).
@property (nonatomic) NSTimeInterval previewInterval;

/// Our camera images will be cropped to this much. 1.0 for no crop. Default 0.6.
@property float cropRatio;

- (id)initWithRecordingInterval:(NSTimeInterval)recordingInterval andPreviewInterval:(NSTimeInterval)previewInterval;

@end
