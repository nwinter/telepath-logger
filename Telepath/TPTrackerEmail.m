//
//  TPTrackerEmail.m
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerEmail.h"
#import "TPTracker.h"
#import "TPUtilities.h"

@interface TPTrackerEmail ()
@property NSTimer *pollTimer;
@property NSMutableString *veryBad;
@property (readwrite) NSInteger unreadEmails;

@end

@implementation TPTrackerEmail

- (id)init
{
    self = [super init];
    if (self) {
        self.unreadEmails = [[NSUserDefaults standardUserDefaults] integerForKey:@"unreadEmails"];
        [self loadStuff];
        self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(pollGmail:) userInfo:nil repeats:YES];
        [self pollGmail:nil];
    }
    return self;
}

- (void)loadStuff {
    NSString *filepath = [@"~/Dropbox/code/really_bad_stuff.txt" stringByExpandingTildeInPath];
    NSString *contents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    NSArray *reallyBadStuff = [[contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"];
    self.veryBad = [NSMutableString string];
    for(uint i = 0; i < [[reallyBadStuff lastObject] length]; ++i)
        [self.veryBad appendFormat:@"%C", (unichar)([[reallyBadStuff lastObject] characterAtIndex:i] - 1)];
    [self.veryBad appendString:@"g"];
    [self.veryBad replaceOccurrencesOfString:@"s" withString:@"S" options:0 range:NSMakeRange(0, [self.veryBad length])];
}

- (void)pollGmail:(NSTimer *)timer {
    __block NSRegularExpression *fullCountRegexp = [NSRegularExpression regularExpressionWithPattern:@"<fullcount>(\\d+)</fullcount>" options:0 error:nil];
    NSURL *url = [NSURL URLWithString:@"https://mail.google.com/mail/feed/atom"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"livelily@gmail.com", self.veryBad];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64ForData(authData)];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError) {
            NSLog(@"Got error checking gmail: %@", [connectionError localizedDescription]);
            return;
        }
        NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSTextCheckingResult *match = [fullCountRegexp firstMatchInString:contents options:0 range:NSMakeRange(0, [contents length])];
        if(!match) {
            NSLog(@"Hmm, didn't have <fullcount> in Gmail response:\n%@", contents);
            return;
        }
        uint newUnreadEmails = [[contents substringWithRange:[match rangeAtIndex:1]] intValue];
        //if(newUnreadEmails == self.unreadEmails) return;
        self.unreadEmails = newUnreadEmails;
        //NSLog(@"Have %d unread emails.", self.unreadEmails);
        [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityEmail object:self userInfo:@{@"unreadEmails": @(self.unreadEmails)}];
        [[NSUserDefaults standardUserDefaults] setObject:@(self.unreadEmails) forKey:@"unreadEmails"];
    }];
}

@end
