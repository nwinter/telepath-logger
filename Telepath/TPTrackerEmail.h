//
//  TPTrackerEmail.h
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

/*
 Oh whatever, someone else can mod this one if they want to use it. I tried to use PubSub framework, but it is buggy and didn't work.
 */

#import <Foundation/Foundation.h>

@interface TPTrackerEmail : NSObject
@property (readonly) uint unreadEmails;

@end
