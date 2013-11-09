//
//  TPTrackerHappiness.h
//  Telepath
//
//  Created by Nick Winter on 11/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPTrackerHappiness : NSObject
/// We'll randomly ping somewhen around this interval (seconds).
@property (nonatomic) NSTimeInterval pingInterval;

- (id)initWithPingInterval:(NSTimeInterval)pingInterval;

@end
