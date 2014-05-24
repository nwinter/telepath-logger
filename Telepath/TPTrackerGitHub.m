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
@property NSInteger previousCommits;
@property (readwrite) NSInteger totalCommits;
@property NSInteger previousAdditions;
@property (readwrite) NSInteger totalAdditions;
@property NSInteger previousDeletions;
@property (readwrite) NSInteger totalDeletions;

@end

@implementation TPTrackerGitHub

- (id)init
{
    self = [super init];
    if (self) {
        self.previousCommits = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousGitHubCommits"];
        self.totalCommits = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalGitHubCommits"];
        self.previousAdditions = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousGitHubAdditions"];
        self.totalAdditions = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalGitHubAdditions"];
        self.previousDeletions = [[NSUserDefaults standardUserDefaults] integerForKey:@"previousGitHubDeletions"];
        self.totalDeletions = [[NSUserDefaults standardUserDefaults] integerForKey:@"totalGitHubDeletions"];
        [[NSNotificationCenter defaultCenter] addObserverForName:TPActivityClearTotals object:nil queue:nil usingBlock:^(NSNotification *note) {
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalCommits) forKey:@"previousGitHubCommits"];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalAdditions) forKey:@"previousGitHubAdditions"];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalDeletions) forKey:@"previousGitHubDeletions"];
            self.previousCommits = self.totalCommits;
            self.previousAdditions = self.totalAdditions;
            self.previousDeletions = self.totalDeletions;
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

- (NSInteger)currentCommits {
    return self.totalCommits - self.previousCommits;
}

- (NSInteger)currentAdditions {
    return self.totalAdditions - self.previousAdditions;
}

- (NSInteger)currentDeletions {
    return self.totalDeletions - self.previousDeletions;
}

- (void)dealloc {
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
            NSInteger newTotalCommits = [contributor[@"total"] intValue];
            NSInteger newTotalAdditions = 0;
            NSInteger newTotalDeletions = 0;
            for(NSDictionary *week in contributor[@"weeks"]) {
                newTotalAdditions += [week[@"a"] intValue];
                newTotalDeletions += [week[@"d"] intValue];
            }
            //NSLog(@"Got %d additions and %d deletions", newTotalAdditions, newTotalDeletions);
            //if(newTotalCommits == self.totalCommits) return;
            self.totalCommits = newTotalCommits;
            self.totalAdditions = newTotalAdditions;
            self.totalDeletions = newTotalDeletions;
            //NSLog(@"Have total GitHub commits: %d -- current %d", self.totalCommits, self.currentCommits);
            [[NSNotificationCenter defaultCenter] postNotificationName:TPActivityGitHub object:self userInfo:@{@"totalCommits": @(self.totalCommits), @"currentCommits": @(self.currentCommits), @"totalAdditions": @(self.totalAdditions), @"currentAdditions": @(self.currentAdditions), @"totalDeletions": @(self.totalDeletions), @"currentDeletions": @(self.currentDeletions)}];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalCommits) forKey:@"totalGitHubCommits"];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalAdditions) forKey:@"totalGitHubAdditions"];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.totalDeletions) forKey:@"totalGitHubDeletions"];
        }
    }];
}

@end
