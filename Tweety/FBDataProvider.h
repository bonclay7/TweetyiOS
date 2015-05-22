//
//  FBDataProvider.h
//  Federated Birds
//
//  Created by Yoann Gini on 21/02/2015.
//  Copyright (c) 2015 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kFBDataProviderLastSyncDone @"kFBDataProviderLastSyncDone"

@interface FBDataProvider : NSObject

@property NSString *username;
@property NSString *password;


@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (instancetype)sharedInstance;
- (void)start;

- (void)updateNow;

- (void)enterInBackground;

- (NSManagedObject*)me;

- (void)sendMessage:(NSString*)message;
- (void)getAllMessages;

@end
