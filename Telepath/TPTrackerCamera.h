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

- (id)initWithRecordingInterval:(NSTimeInterval)recordingInterval andPreviewInterval:(NSTimeInterval)previewInterval;

@end
