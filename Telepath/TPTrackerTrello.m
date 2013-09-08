//
//  TPTrackerTrello.m
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerTrello.h"
#import "TPTracker.h"
#import "TPUtilities.h"

@interface TPTrackerTrello ()
@property NSTimer *pollTimer;
@property NSString *trelloUserName;
@property NSArray *trelloBoards;
@property NSArray *trelloDoneLists;
@property NSString *trelloApplicationKey;
@property NSString *trelloApplicationSecret;
@property NSString *trelloToken;
@property uint previousTrellosSlain;
@property (readwrite) uint totalTrellosSlain;
@property (readwrite) uint trellosAlive;

@end

@implementation TPTrackerTrello

- (id)init
{
    self = [super init];
    if (self) {
        self.previousTrellosSlain = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousTrellosSlain"];
        self.totalTrellosSlain = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalTrellosSlain"];
        self.trellosAlive = [[NSUserDefaults standardUserDefaults] integerForKey:@"trellosAlive"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalTrellosSlain) forKey:@"previousTrellosSlain"];
            self.previousTrellosSlain = self.totalTrellosSlain;
            self.totalTrellosSlain = 0;  // So we send out an event on next poll.
        }];
        NSString *filepath = [@"~/Dropbox/code/telepath_trello_token.txt" stringByExpandingTildeInPath];
        NSString *contents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
        if(contents) {
            NSArray *lines = [[contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"];
            //NSLog(@"Going to poll Trello: %@", lines);
            self.trelloUserName = lines[0];
            self.trelloBoards = [lines[1] componentsSeparatedByString:@", "];
            self.trelloDoneLists = [lines[2] componentsSeparatedByString:@", "];
            self.trelloApplicationKey = lines[3];
            self.trelloApplicationSecret = lines[4];
            self.trelloToken = lines[5];
            self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(pollTrello:) userInfo:nil repeats:YES];
            [self pollTrello:nil];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (uint)currentTrellosSlain {
    return self.totalTrellosSlain - self.previousTrellosSlain;
}

- (void)pollTrello:(NSTimer *)t {
    NSURL *cardsURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://trello.com/1/members/my/cards/all?key=%@&token=%@", self.trelloApplicationKey, self.trelloToken]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:cardsURL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        //NSLog(@"Got Trello response data %@", [NSString stringWithUTF8String:[data bytes]]);
        if([data length] < 50) return;
        NSArray *cards = arrayFromJSON(data);
        if(![cards count]) return;
        //NSLog(@"Got %lu cards: %@", [cards count], cards);
        uint newTrellosAlive = 0;
        uint newTrellosSlain = 0;
        for(NSDictionary *card in cards) {
            if(![self.trelloBoards containsObject:card[@"idBoard"]]) continue;
            BOOL done = [self.trelloDoneLists containsObject:card[@"idList"]];
            if(done)
                ++newTrellosSlain;
            else
                ++newTrellosAlive;
        }
        //if(newTrellosAlive == self.trellosAlive && newTrellosSlain == self.totalTrellosSlain) return;
        self.trellosAlive = newTrellosAlive;
        self.totalTrellosSlain = newTrellosSlain;
        //NSLog(@"Have total Trellos alive: %d, slain: %d", self.trellosAlive, self.totalTrellosSlain);
        [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityTrello object:self userInfo:@{@"totalTrellosSlain": @(self.totalTrellosSlain), @"currentTrellosSlain": @(self.currentTrellosSlain), @"trellosAlive": @(self.trellosAlive)}];
        [[NSUserDefaults standardUserDefaults] setObject:@(self.totalTrellosSlain) forKey:@"totalTrellosSlain"];
        [[NSUserDefaults standardUserDefaults] setObject:@(self.trellosAlive) forKey:@"trellosAlive"];
    }];
}

@end
