//
//  TPUtilities.m
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPUtilities.h"

double now(void) {
    return [[NSDate date] timeIntervalSince1970];
}

NSString *JSONRepresentation(id object) {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil] encoding:NSUTF8StringEncoding];
}


