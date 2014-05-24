//
//  TPTrackerKeyboard.h
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TPTrackerKeyboard : NSObject
@property (nonatomic, strong) NSArray *modifierKeys;
@property (readonly) NSInteger currentEvents;
@property (readonly) NSInteger totalEvents;
@end
