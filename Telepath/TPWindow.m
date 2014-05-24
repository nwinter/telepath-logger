//
//  TPWindow.m
//  Telepath
//
//  Created by Nick Winter on 9/7/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPWindow.h"

@implementation TPWindow

- (id)init
{
    self = [super init];
    if (self) {
        [self setContentMaxSize:NSMakeSize(2560, 240)];
    }
    return self;
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

- (BOOL)isMovableByWindowBackground {
    return YES;
}

@end
