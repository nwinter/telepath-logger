//
//  TPTrackerGitHub.h
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

/*
 In order to use GitHub tracking (single-repo only for now), create a file called ~/Dropbox/code/telepath_github_token.txt with five lines:
 gitHubUserName (ex: nwinter)
 gitHubRepo (ex: aether)
 gitHubToken (ex: 4d712b826661a8c8e3280da981e99e8f30285eaf)

 To get a GitHub authorization token, just do this: https://help.github.com/articles/creating-an-access-token-for-command-line-use
 */

#import <Foundation/Foundation.h>

@interface TPTrackerGitHub : NSObject
@property (readonly) uint currentCommits;
@property (readonly) uint totalCommits;

@end
