//
//  TPTracker.h
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const TPActivityAny;
extern NSString * const TPActivityKeyboard;
extern NSString * const TPActivityKeyboardVeryBad;
extern NSString * const TPActivityMouse;
extern NSString * const TPActivityWindow;
extern NSString * const TPActivityLight;
extern NSString * const TPActivityCamera;
extern NSString * const TPActivityGitHub;
extern NSString * const TPActivityTrello;
extern NSString * const TPActivityBrunchBuild;
extern NSString * const TPActivityEmail;
extern NSString * const TPActivityClearTotals;

@interface TPTracker : NSObject

@property (readonly) uint currentEvents;
@property (readonly) uint totalEvents;
@property NSTimeInterval cameraRecordingInterval;

@end
