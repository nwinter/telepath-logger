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
    NSError *error;
    NSString *json = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:&error] encoding:NSUTF8StringEncoding];
    if(error)
        NSLog(@"Error converting %@ to JSON: %@", object, [error localizedDescription]);
    return json;
}

NSDictionary *dictionaryFromJSON(NSData *json) {
    NSError *error;
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:&error];
    if(error)
        NSLog(@"Error converting %@ from JSON: %@", json, [error localizedDescription]);
    return d;
}

NSArray *arrayFromJSON(NSData *json) {
    NSError *error;
    NSArray *a = [NSJSONSerialization JSONObjectWithData:json options:kNilOptions error:&error];
    if(error)
        NSLog(@"Error converting %@ from JSON: %@", json, [error localizedDescription]);
    return a;
}