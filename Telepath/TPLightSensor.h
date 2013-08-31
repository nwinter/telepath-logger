//
//  TPLightSensor.h
//  Telepath
//
//  Created by Nick Winter on 8/30/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TP_NOTIFICATION_LIGHT_CHANGED @"tp_light_changed"

@interface TPLightSensor : NSObject
@property (readonly) BOOL started;
@property (readonly) float left;
@property (readonly) float right;
@property (readonly) float brightness;  // dB 0-100 (100 is shining flashlight into sensor or more)
@property (readonly) float typicalBrightness;  /// Indoors, indirect partly cloudy
@property (readonly) float lastBrightness;  // brightness level before the last change
@property (nonatomic) double updateInterval;   /// Default: 0.1, which is twice as fast as the sensor can update on Nick's 2010 MBP

- (BOOL)start;
- (void)stop;

@end

extern NSString * const TPLightChanged;