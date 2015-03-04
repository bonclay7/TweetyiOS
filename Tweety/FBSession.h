//
//  FBSession.h
//  Federated Birds
//
//  Created by Yoann Gini on 18/02/2015.
//  Copyright (c) 2015 iNig-Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBSession;

/**
 *  Generic completion handler used in most session API.
 *
 *  @param session The current session.
 *  @param answer  An Cocoa object return by the API or nil.
 *  @param error   If an error occurs, contains an NSError object that describes the problem.
 */
typedef void(^FBSessionGenericCompletionHandler)(FBSession *session, id answer, NSError *error);

@interface FBSession : NSObject

@property (readonly) BOOL isAuthenticated;

/**
 *  Return a shared FBSession dedicated to unauthenticated actions with the user's server.
 *
 *  @param username Username in format user@server or user@server:port. user@domain.tld is not yet supported.
 *  @param error    If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return a session object or nil if the username format is invalid.
 */
+ (instancetype)sessionForUsername:(NSString*)username withError:(NSError **)error;

/**
 *  Return a shared FBSession dedicated to authenticated actions for a specific user on a specific server.
 *
 *  @param username Username in format user@server or user@server:port. user@domain.tld is not yet supported.
 *  @param error    If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return a session object or nil if the username format is invalid.
 */
+ (instancetype)sessionForAuthenticatedUsername:(NSString*)username withError:(NSError **)error;


/**
 *  Initiate the authentication phase for an authenticated session.
 *
 *  @param password          The user password.
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary with fields created_at, handle, id, token and updated_at.
 */
- (void)loginWithPassord:(NSString*)password withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Invalidate the current session object. After this call the object is still usable but removed from the session cache.
 *	The object itself will be release when all current communication are done and all referecences are removed.
 */
- (void)invalidate;

/**
 *  Post a new message for the current user on the current server. Can be used only on authenticated session after a successfull login.
 *
 *  @param message           The message to send.
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary with fields at, by, and content.
 */
- (void)postMessage:(NSString*)message withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Retrieve all messages from the current server
 *
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {tweets:({at:, by:, content:}, {at:, by:, content:})}.
 */
- (void)allLocalMessagesWithCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Retrieve all messages from the current server from followed people
 *
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {tweets:({at:, by:, content:}, {at:, by:, content:})}.
 */
- (void)allMessagesFromReadingListWithCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Retrieve the users list from the current server from followed people
 *
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {users:(user1, user2), server: servername}.
 */
- (void)allUsersWithCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Follow a new user.
 *
 *  @param username          The username to follow.
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {at:, follow:, from:}.
 */
- (void)follow:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Unfollow a user
 *
 *  @param username          The username to unfollow
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {status_code:} with the HTTP status code.
 */
- (void)unfollow:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Retrieve the list of following for a specific user
 *
 *  @param username          The user to look for or nil for the current authenticated one.
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {followings:({at:, user:}, {at:, user:})}.
 */
- (void)followingsFor:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

/**
 *  Retrieve the list of followers for a specific user
 *
 *  @param username          The user to look for or nil for the current authenticated one.
 *  @param completionHandler The block to execute when the operation is done. The answer object will be a dictionary structured like {followers:({at:, user:}, {at:, user:})}.
 */
- (void)followersFor:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler;

@end
