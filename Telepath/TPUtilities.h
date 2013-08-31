//
//  TPUtilities.h
//  Telepath
//
//  Created by Nick Winter on 8/31/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Shorthand: seconds since epoch.
double now(void);

/// Shorthand: serialize object to JSON.
NSString *JSONRepresentation(id object);