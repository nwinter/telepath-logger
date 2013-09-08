//
//  TPTrackerGitHub.m
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import "TPTrackerGitHub.h"
#import "TPTracker.h"
#import "TPUtilities.h"

@interface TPTrackerGitHub ()
@property NSTimer *pollTimer;
@property NSString *gitHubUserName;
@property NSString *gitHubRepo;
@property NSString *gitHubToken;
@property uint previousCommits;
@property (readwrite) uint totalCommits;

@end

@implementation TPTrackerGitHub

- (id)init
{
    self = [super init];
    if (self) {
        self.previousCommits = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousGitHubCommits"];
        self.totalCommits = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalGitHubCommits"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalCommits) forKey:@"previousGitHubCommits"];
            self.previousCommits = self.totalCommits;
            self.totalCommits = 0;  // So we send out an event on next poll.
        }];
        NSString *filepath = [@"~/Dropbox/code/telepath_github_token.txt" stringByExpandingTildeInPath];
        NSString *contents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
        if(contents) {
            NSArray *lines = [[contents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"];
            //NSLog(@"Going to poll GitHub: %@", lines);
            self.gitHubUserName = lines[0];
            self.gitHubRepo = lines[1];
            self.gitHubToken = lines[2];
            self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(pollGitHub:) userInfo:nil repeats:YES];
            [self pollGitHub:nil];
        }
    }
    return self;
}

- (uint)currentCommits {
    return self.totalCommits - self.previousCommits;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pollGitHub:(NSTimer *)t {
    NSURL *contributorsURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/stats/contributors", self.gitHubUserName, self.gitHubRepo]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:contributorsURL];
    [request setValue:[NSString stringWithFormat:@"token %@", self.gitHubToken] forHTTPHeaderField:@"Authorization"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        //NSLog(@"Got GitHub response data %@", [NSString stringWithUTF8String:[data bytes]]);
        if([data length] < 50) return;
        NSArray *contributors = arrayFromJSON(data);
        if(![contributors count]) return;
        //NSLog(@"Got %lu contributors: %@", [contributors count], contributors);
        for(NSDictionary *contributor in contributors) {
            if(![contributor[@"author"][@"login"] isEqualToString:self.gitHubUserName]) continue;
            uint newTotalCommits = [contributor[@"total"] intValue];
            //if(newTotalCommits == self.totalCommits) return;
            self.totalCommits = newTotalCommits;
            //NSLog(@"Have total GitHub commits: %d -- current %d", self.totalCommits, self.currentCommits);
            [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityGitHub object:self userInfo:@{@"totalCommits": @(self.totalCommits), @"currentCommits": @(self.currentCommits)}];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalCommits) forKey:@"totalGitHubCommits"];
        }
    }];
}

@end
