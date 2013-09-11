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

//from: http://cocoadev.com/BaseSixtyFour
NSString *base64ForData(NSData *theData) {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}