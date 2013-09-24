//
//  TPTrackerScreen.h
//  Telepath
//
//  Created by Nick Winter on 9/16/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPTrackerScreen : NSObject
/// We'll take a camera screenshot at this interval (seconds). Set at same time as Camera's recording interval is set to be in sync.
@property (nonatomic) NSTimeInterval recordingInterval;

- (id)initWithRecordingInterval:(NSTimeInterval)recordingInterval;

@end


