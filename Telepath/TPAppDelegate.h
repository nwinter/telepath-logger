//
//  TPAppDelegate.h
//  Telepath
//
//  Created by Nick Winter on 8/30/13.
//  Copyright (c) 2013 Nick Winter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TPAppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
