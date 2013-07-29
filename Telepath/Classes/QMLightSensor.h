//
//  QMLightSensor.h
//  Telepath
//
//  Created by Nick Winter on 10/23/12.
//

#import <Foundation/Foundation.h>

#define QM_NOTIFICATION_LIGHT_CHANGED @"qm_light_changed"

@interface QMLightSensor : NSObject
@property (readonly) BOOL started;
@property (readonly) float left;
@property (readonly) float right;
@property (readonly) float brightness;  // dB 0-100 (100 is shining flashlight into sensor or more)
@property (readonly) float typicalBrightness;  /// Indoors, indirect partly cloudy
@property (readonly) float lastBrightness;  // brightness level before the last change
@property (nonatomic, assign) double updateInterval;   /// Default: 0.1, which is twice as fast as the sensor can update on Nick's 2010 MBP

- (BOOL)start;
- (void)stop;

@end
