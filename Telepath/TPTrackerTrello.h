//
//  TPTrackerTrello.h
//  Telepath
//
//  Created by Nick Winter on 9/8/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

/*
 In order to use Trello tracking, create a file called ~/Dropbox/code/telepath_trello_token.txt with six lines:
 trelloUserName (ex: nwinter)
 trelloBoardIDs, separated, by, commaSpace (ex: 4e3f29a024e0c004633abdc3, c8e3280da981e99e8f30285e)
 trelloDoneListIDs, separated, by, commaSpace
 trelloApplicationKey (ex: 4d712b826661a8c8e3280da981e99e8f)
 trelloApplicationSecret (ex: 4d712b826661a8c8e3280da981e99e8f30285eaf4d712b826661a8c8e3280da981)
 trelloToken (ex: 4d712b826661a8c8e3280da981e99e8f30285eaf4d712b826661a8c8e3280da981)
 
 To get the first two, sign into Trello to see your username, and also grab the board ID (like 4e3f29a024e0c004633abdc3) for each board you care about. They said it should be part of the URL, but it wasn't for me (I got some shorter base64 string instead of hex), so I used https://trello.com/1/members/my/boards?key=substitutewithyourapplicationkey&token=substitutewithyourapplicationtoken
 
 Then to get the lists which represent "Done" items for your boards, for each board, check https://trello.com/1/boards/substitutewithsomeboardid/lists?key=substitutewithyourapplicationkey&token=substitutewithyourapplicationtoken
 
 To get the application key and application secret, go to https://trello.com/1/appKey/generate
 
 To get an indefinite read-only authorization token, go to https://trello.com/1/authorize?key=substitutewithyourapplicationkey&name=Telepath&expiration=never&response_type=token
 */

#import <Foundation/Foundation.h>

@interface TPTrackerTrello : NSObject
@property (readonly) NSInteger currentTrellosSlain;
@property (readonly) NSInteger totalTrellosSlain;
@property (readonly) NSInteger trellosAlive;

@end
