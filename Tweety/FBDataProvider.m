//
//  FBDataProvider.m
//  Federated Birds
//
//  Created by Yoann Gini on 21/02/2015.
//  Copyright (c) 2015 iNig-Services. All rights reserved.
//

#import "FBDataProvider.h"

#import "FBSession.h"

#import "NSString+MD5.h"

#include <libkern/OSAtomic.h>

@interface FBDataProvider () {
    OSSpinLock _updateLock;
    NSUInteger _updateCounter;
}

@property NSTimer *cron;

@property (nonatomic) NSManagedObjectContext *privateManagedObjectContext;

@end

@implementation FBDataProvider

#pragma mark - Object Lifecyle

+ (instancetype)sharedInstance {
    static FBDataProvider* sharedInstanceFBDataProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstanceFBDataProvider = [self new];
    });
    return sharedInstanceFBDataProvider;
}

- (void)start {
    if (!self.cron) {
        FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
        [session loginWithPassord:self.password withCompletionHandler:^(FBSession *session, id answer, NSError *error) {
            
            self.cron = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                         target:self
                                                       selector:@selector(periodicUpdate:)
                                                       userInfo:nil
                                                        repeats:YES];
            }];
    }
}

#pragma mark - API

- (void)updateNow {
    [self.cron fire];
}

- (void)enterInBackground {
    [self.cron invalidate];
    self.cron = nil;
    
    [self saveContext];
}

- (NSManagedObject*)me {
    FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
    
    NSManagedObject *privateMeServerObject = [self fetchOrStoreServerFromSession:session];
    NSManagedObject *privateMeObject = [self fetchOrStoreUser:session.username fromServer:privateMeServerObject];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueID LIKE %@", [privateMeObject valueForKey:@"uniqueID"]];
    
    NSArray *result = [self.managedObjectContext executeFetchRequest:request
                                                               error:nil];
    
    return [result firstObject];
}

- (void)sendMessage:(NSString*)message {
    FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
    
    [session postMessage:message withCompletionHandler:^(FBSession *session, id answer, NSError *error) {
        [self.cron fire];
    }];
}

- (void)getAllMessages{
    FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
    [session allLocalMessagesWithCompletionHandler:^(FBSession *session, id answer, NSError *error) {
        for (NSDictionary* tweet in [answer objectForKey:@"tweets"]){
            [self fetchOrStoreMessage:tweet fromSession:session];
        }
    }];
    
}

#pragma mark - Internal

- (void)periodicUpdate:(NSTimer*)timer {
    [self updateFollowings];
    [self updateAllMessagesFromReadingList];
    [self updateAllLocalMessages];
    
    [self saveContext];
}

- (NSString*)uniqueIDForMesssage:(NSDictionary *)message fromSession:(FBSession*)session {
    return [[NSString stringWithFormat:@"%@-%@-%@-%@", [message objectForKey:@"at"], [message objectForKey:@"by"], [message objectForKey:@"content"], [session serverUniqueID]] MD5String];
}

- (NSString*)uniqueIDForUser:(NSString *)username fromServer:(NSManagedObject*)server {
    return [[NSString stringWithFormat:@"%@-%@", username, [server valueForKey:@"uniqueID"]] MD5String];
}

#pragma mark CoreData Request

- (NSManagedObject *)messageWithUniqueID:(NSString *)uniqueID {
    return [self entityWithName:@"Message" andUniqueID:uniqueID];
}

- (NSManagedObject *)userWithUniqueID:(NSString *)uniqueID {
    return [self entityWithName:@"User" andUniqueID:uniqueID];
}

- (NSManagedObject *)serverWithUniqueID:(NSString *)uniqueID {
    return [self entityWithName:@"Server" andUniqueID:uniqueID];
}

- (NSManagedObject *)entityWithName:(NSString*)entityName andUniqueID:(NSString *)uniqueID {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueID LIKE %@", uniqueID];
    
    NSArray *result = [self.privateManagedObjectContext executeFetchRequest:request
                                                                      error:nil];
    
    return [result firstObject];
}

- (NSManagedObject*)fetchOrStoreMessage:(NSDictionary *)message fromSession:(FBSession*)session {
    NSString *uniqueID = [self uniqueIDForMesssage:message
                                       fromSession:session];
    NSManagedObject *messageObject = [self messageWithUniqueID:uniqueID];
    
    if (!messageObject) {
        NSManagedObject *serverObject = [self fetchOrStoreServerFromSession:session];
        NSManagedObject *authorObject = [self fetchOrStoreUser:[message objectForKey:@"by"] fromServer:serverObject];
        
        messageObject = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                      inManagedObjectContext:self.privateManagedObjectContext];
        
        [messageObject setValue:uniqueID
                         forKey:@"uniqueID"];
        [messageObject setValue:authorObject
                         forKey:@"author"];
        [messageObject setValue:[message objectForKey:@"content"]
                         forKey:@"content"];
        [messageObject setValue:[NSDate dateWithTimeIntervalSince1970:[[message objectForKey:@"at"] integerValue]]
                         forKey:@"date"];
    }
    
    return messageObject;
}

- (NSManagedObject*)fetchOrStoreServerFromSession:(FBSession*)session {
    NSString *uniqueID = [session serverUniqueID];
    NSManagedObject *serverObject = [self serverWithUniqueID:uniqueID];
    
    if (!serverObject) {
        serverObject = [NSEntityDescription insertNewObjectForEntityForName:@"Server"
                                                     inManagedObjectContext:self.privateManagedObjectContext];
        
        [serverObject setValue:session.serverDomain
                        forKey:@"displayName"];
        [serverObject setValue:session.serverDomain
                        forKey:@"userDomain"];
        [serverObject setValue:uniqueID
                        forKey:@"uniqueID"];
    }
    
    return serverObject;
}

- (NSManagedObject*)fetchOrStoreUser:(NSString*)username fromServer:(NSManagedObject*)server {
    NSString *uniqueID = [self uniqueIDForUser:username fromServer:server];
    NSManagedObject *userObject = [self userWithUniqueID:uniqueID];
    
    if (!userObject) {
        userObject = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                                   inManagedObjectContext:self.privateManagedObjectContext];
        
        [userObject setValue:username
                      forKey:@"handle"];
        [userObject setValue:server
                      forKey:@"server"];
        [userObject setValue:uniqueID
                      forKey:@"uniqueID"];
    }
    
    return userObject;
}

#pragma mark Content updates

- (void)updateStarted {
    OSSpinLockLock(&_updateLock);
    _updateCounter++;
    OSSpinLockUnlock(&_updateLock);
}

- (void)updateDone {
    OSSpinLockLock(&_updateLock);
    _updateCounter--;
    if (_updateCounter == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFBDataProviderLastSyncDone
                                                            object:self];
    }
    OSSpinLockUnlock(&_updateLock);
}

- (void)updateFollowings {
    [self updateStarted];
    FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
    
    [session followingsFor:nil withCompletionHandler:^(FBSession *session, id answer, NSError *error) {
        [self.privateManagedObjectContext performBlock:^{
            NSManagedObject *serverObject = [self fetchOrStoreServerFromSession:session];
            NSManagedObject *me = [self fetchOrStoreUser:session.username fromServer:serverObject];
            
            NSMutableSet *updatedFollowing = [NSMutableSet new];
            
            for (NSDictionary *following in [answer objectForKey:@"followings"]) {
                NSManagedObject *followingObject = [self fetchOrStoreUser:[following objectForKey:@"user"]
                                                               fromServer:serverObject];
                
                [updatedFollowing addObject:followingObject];
            }
            
            [me setPrimitiveValue:updatedFollowing forKey:@"followings"];
            NSError *error = nil;
            [self.privateManagedObjectContext save:&error];
            
            [self updateDone];
        }];
    }];
}

- (void)updateAllLocalMessages {
    [self updateStarted];
    FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
    
    [session allLocalMessagesWithCompletionHandler:^(FBSession *session, id answer, NSError *error) {
        [self.privateManagedObjectContext performBlock:^{
            for (NSDictionary *message in [answer objectForKey:@"tweets"]) {
                [self fetchOrStoreMessage:message fromSession:session];
            }
            NSError *error = nil;
            [self.privateManagedObjectContext save:&error];
            
            [self updateDone];
        }];
    }];
}

- (void)updateAllMessagesFromReadingList {
    [self updateStarted];
    FBSession *session = [FBSession sessionForAuthenticatedUsername:self.username withError:nil];
    
    [session allMessagesFromReadingListWithCompletionHandler:^(FBSession *session, id answer, NSError *error) {
        [self.privateManagedObjectContext performBlock:^{
            for (NSDictionary *message in [answer objectForKey:@"tweets"]) {
                [self fetchOrStoreMessage:message fromSession:session];
            }
            NSError *error = nil;
            [self.privateManagedObjectContext save:&error];
            
            [self updateDone];
        }];
    }];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize privateManagedObjectContext = _privateManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)privateManagedObjectContext
{
    if (_privateManagedObjectContext != nil) {
        return _privateManagedObjectContext;
    }
    
    NSManagedObjectContext *parentContext = [self managedObjectContext];
    if (parentContext != nil) {
        _privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_privateManagedObjectContext setParentContext:parentContext];
    }
    return _privateManagedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FBModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FBData.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
