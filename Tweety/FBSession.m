//
//  FBSession.m
//  Federated Birds
//
//  Created by Yoann Gini on 18/02/2015.
//  Copyright (c) 2015 iNig-Services. All rights reserved.
//

#import "FBSession.h"

#import "NSString+MD5.h"

typedef enum : NSUInteger {
    FBSessionErrorCodeInvalidUsername,
    FBSessionErrorCodeInvalidUserDomain,
    FBSessionErrorCodeImpossibleToCreateNSURLSessionTask,
    FBSessionErrorCodeMissingArguments,
    FBSessionErrorCodeInvalidSessionType
} FBSessionErrorCode;

@interface FBSession ()

@property NSString *sessionToken;

@property NSString *username;
@property NSString *serverURLString;

@end

@implementation FBSession

#pragma mark - Statics variables

static NSMutableDictionary *sessionList = nil;
static NSMutableDictionary *authenticatedSessionList = nil;
static NSString *hostID = @"Hayabuza-iOS";

#pragma mark - Constructors

#pragma mark Public
+ (instancetype)sessionForUsername:(NSString*)username withError:(NSError **)error {
    return [self sessionForUsername:username authenticated:NO withError:error];
}

+ (instancetype)sessionForAuthenticatedUsername:(NSString*)username withError:(NSError **)error {
    return [self sessionForUsername:username authenticated:YES withError:error];
}

#pragma mark Internal

+ (instancetype)sessionForUsername:(NSString *)username authenticated:(BOOL)authenticated withError:(NSError**)error {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionList = [NSMutableDictionary new];
        authenticatedSessionList = [NSMutableDictionary new];
    });
    
    if (![self validateUsernameWithDomain:username]) {
        *error = [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                     code:FBSessionErrorCodeInvalidUsername
                                 userInfo:@{NSLocalizedDescriptionKey: @"Username should look like alice@203.0.113.42:4567"}];
        return nil;
    }
    
    NSString *serverURLString = [self serverURLStringForUsernameWithDomain:username];
    
    if ([serverURLString length] == 0) {
        *error = [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                     code:FBSessionErrorCodeInvalidUserDomain
                                 userInfo:@{NSLocalizedDescriptionKey: @"Invalid user's domain"}];
        return nil;
    }
    
    NSMutableDictionary *source = nil;
    NSString *key = nil;
    
    if (authenticated) {
        source = authenticatedSessionList;
        key = username;
    }
    else {
        source = sessionList;
        key = serverURLString;
    }
    
    FBSession *session = [source objectForKey:key];
    
    if (!session) {
        session = [FBSession new];
        session.serverURLString = serverURLString;
        if (authenticated) {
            session.username = [self usernameStringForUsernameWithDomain:username];
        }
        [source setObject:session forKey:key];
    }
    
    return session;
}

#pragma mark - Server API
#pragma mark User and session management

- (void)loginWithPassord:(NSString*)password withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    if ([self.username length] > 0) {
        NSURLSessionTask *urlSessionTask = [self authenticateAtPath:[NSString stringWithFormat:@"authentication/:%@", self.username]
                                                       withPassword:password
                                               andCompletionHandler:^(FBSession *session, id answer, NSError *error) {
                                                   if (error) {
                                                       completionHandler(self, nil, error);
                                                   }
                                                   else {
                                                       self.sessionToken = [NSString stringWithFormat:@"%@.%@", [[answer objectForKey:@"session"] objectForKey:@"token"], hostID];
                                                       self.username = [[answer objectForKey:@"session"] objectForKey:@"handle"];
                                                       completionHandler(self, answer, error);
                                                   }
                                               }];

        
        if (!urlSessionTask) {
            completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                             code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                         userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
        }
    }
    else {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeInvalidSessionType
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid session type, unable to login"}]);
    }
}

- (BOOL)isAuthenticated {
    return self.sessionToken != nil;
}

- (void)invalidate {
    NSMutableDictionary *source = nil;
    NSString *key = nil;

    
    if ([self.username length] > 0) {
        source = authenticatedSessionList;
        key = self.username;
    }
    else {
        source = sessionList;
        key = self.serverURLString;
    }
    
    [source setObject:nil forKey:key];
}

#pragma mark Messages

- (void)postMessage:(NSString*)message withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSURLSessionTask *urlSessionTask = [self startURLSessionToPostAtPath:[NSString stringWithFormat:@"tweets/:%@", self.username]
                                                   withAuthenticationToken:YES
                                                                      data:@{@"message": message}
                                                      andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}


- (void)allLocalMessagesWithCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSURLSessionTask *urlSessionTask = [self startURLSessionToGetPath:@"tweets"
                                                  withAuthenticationToken:NO
                                                     andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

- (void)allMessagesFromReadingListWithCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSURLSessionTask *urlSessionTask = [self startURLSessionToGetPath:[NSString stringWithFormat:@"tweets/:%@/reading_list", self.username]
                                                  withAuthenticationToken:YES
                                                     andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

#pragma mark Users

- (void)allUsersWithCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSURLSessionTask *urlSessionTask = [self startURLSessionToGetPath:@"users"
                                                  withAuthenticationToken:NO
                                                     andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

#pragma mark Followers and followings

- (void)follow:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    if (!username) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeMissingArguments
                                                     userInfo:@{NSLocalizedDescriptionKey: @"A username to follow must be specified"}]);
        return;
    }
    
    NSURLSessionTask *urlSessionTask = [self startURLSessionToPostAtPath:[NSString stringWithFormat:@"followings/:%@/follow/:%@", self.username, username]
                                                   withAuthenticationToken:YES
                                                                      data:nil
                                                      andCompletionHandler:completionHandler];
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

- (void)unfollow:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    if (!username) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeMissingArguments
                                                     userInfo:@{NSLocalizedDescriptionKey: @"A username to unfollow must be specified"}]);
        return;
    }
    
    NSURLSessionTask *urlSessionTask = [self startURLSessionToDeletePath:[NSString stringWithFormat:@"followings/:%@/follow/:%@", self.username, username]
                                                     withAuthenticationToken:YES
                                                                        data:@{@"handle": username}
                                                        andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

- (void)followingsFor:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    if (!username) {
        username = self.username;
    }
    
    NSURLSessionTask *urlSessionTask = [self startURLSessionToGetPath:[NSString stringWithFormat:@"followings/:%@", username]
                                                  withAuthenticationToken:YES
                                                     andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

- (void)followersFor:(NSString*)username withCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
   if (!username) {
        username = self.username;
    }
    
    NSURLSessionTask *urlSessionTask = [self startURLSessionToGetPath:[NSString stringWithFormat:@"followers/:%@", username]
                                                  withAuthenticationToken:YES
                                                     andCompletionHandler:completionHandler];
    
    if (!urlSessionTask) {
        completionHandler(self, nil, [NSError errorWithDomain:@"fr.sio.ecp.federated-birds.session"
                                                         code:FBSessionErrorCodeImpossibleToCreateNSURLSessionTask
                                                     userInfo:@{NSLocalizedDescriptionKey: @"Impossible to create NSURLSessionTask"}]);
    }
}

#pragma mark - Internal Only

#pragma mark Toolbox

- (NSURLSessionTask*)startURLSessionToGetPath:(NSString*)relativePath withAuthenticationToken:(BOOL)authenticationToken andCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURLString, relativePath]]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (authenticationToken) {
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSLog(@"%@", request);
    
    NSURLSessionTask *urlSessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                           if (error) {
                                                                               completionHandler(self, nil, error);
                                                                           }
                                                                           else {
                                                                               id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                                               completionHandler(self, object, error);
                                                                           }
                                                                       }];
    [urlSessionTask resume];
    return urlSessionTask;
}

- (NSURLSessionTask*)startURLSessionToPostAtPath:(NSString*)relativePath withAuthenticationToken:(BOOL)authenticationToken data:(NSDictionary*)dict andCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURLString, relativePath]]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPMethod = @"POST";
    
    if (authenticationToken){
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    
    if (dict) {
        NSError *error = nil;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        
        if (error) {
            completionHandler(self, nil, error);
            return nil;
        }
    }
    
    
    NSLog(@"%@", request);
    
    NSURLSessionTask *urlSessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                           if (error) {
                                                                               completionHandler(self, nil, error);
                                                                           }
                                                                           else {
                                                                               id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                                               completionHandler(self, object, error);
                                                                           }
                                                                       }];
    [urlSessionTask resume];
    return urlSessionTask;
}



- (NSURLSessionTask*)authenticateAtPath:(NSString*)relativePath withPassword:(NSString*)password andCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURLString, relativePath]]];
    request.HTTPMethod = @"POST";
    [request addValue:password forHTTPHeaderField:@"password"];
    [request addValue:hostID forHTTPHeaderField:@"hostID"];
    
    NSLog(@"%@", request);
    
    NSURLSessionTask *urlSessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                           if (error) {
                                                                               completionHandler(self, nil, error);
                                                                           }
                                                                           else {
                                                                               id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                                               completionHandler(self, object, error);
                                                                           }
                                                                       }];
    [urlSessionTask resume];
    return urlSessionTask;
}


- (NSURLSessionTask*)startURLSessionToPutAtPath:(NSString*)relativePath withAuthenticationToken:(BOOL)authenticationToken data:(NSDictionary*)dict andCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURLString, relativePath]]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPMethod = @"PUT";
    
    if (authenticationToken) {
        [request addValue:[NSString stringWithFormat:@"%@.%@", self.sessionToken, hostID] forHTTPHeaderField:@"Authorization"];
    }
    
    
    if (dict) {
        NSError *error = nil;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        
        if (error) {
            completionHandler(self, nil, error);
            return nil;
        }
    }
    NSLog(@"%@", request);
    NSURLSessionTask *urlSessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                           if (error) {
                                                                               completionHandler(self, nil, error);
                                                                           }
                                                                           else {
                                                                               id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                                                               completionHandler(self, object, error);
                                                                           }
                                                                       }];
    [urlSessionTask resume];
    return urlSessionTask;
}


- (NSURLSessionTask*)startURLSessionToDeletePath:(NSString*)relativePath withAuthenticationToken:(BOOL)authenticationToken data:(NSDictionary*)dict andCompletionHandler:(FBSessionGenericCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURLString, relativePath]]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPMethod = @"DELETE";
    
    if (authenticationToken) {
        [request addValue:[NSString stringWithFormat:@"%@.%@", self.sessionToken, hostID] forHTTPHeaderField:@"Authorization"];
    }
    
    
    if (dict) {
        NSError *error = nil;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        
        if (error) {
            completionHandler(self, nil, error);
            return nil;
        }
    }
    
    NSLog(@"%@", request);
    
    NSURLSessionTask *urlSessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                           if (error) {
                                                                               completionHandler(self, nil, error);
                                                                           }
                                                                           else {
                                                                               NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
                                                                               completionHandler(self, @{@"http_status": [NSNumber numberWithInteger:HTTPResponse.statusCode]}, error);
                                                                           }
                                                                       }];
    [urlSessionTask resume];
    return urlSessionTask;
}


+ (NSString*)domainForUsernameWithDomain:(NSString*)username {
    NSArray *usernameComponents = [username componentsSeparatedByString:@"@"];
    
    return [usernameComponents lastObject];
}

+ (NSString*)serverURLStringForUsernameWithDomain:(NSString*)username {
    NSArray *usernameComponents = [username componentsSeparatedByString:@"@"];
    
    NSString *domain = [usernameComponents lastObject];
    
    if ([domain containsString:@":"]) {
        return [NSString stringWithFormat:@"http://%@", domain];
    }
    
    // SRV lookup not managed at this time.
    
    return nil;}

+ (NSString*)usernameStringForUsernameWithDomain:(NSString*)username {
    NSArray *usernameComponents = [username componentsSeparatedByString:@"@"];
    
    return [usernameComponents firstObject];
}

+ (BOOL)validateUsernameWithDomain:(NSString*)username {
    NSArray *usernameComponents = [username componentsSeparatedByString:@"@"];
    
    if ([usernameComponents count] != 2) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Other API

- (NSString*)serverDomain {
    return [[self class] domainForUsernameWithDomain:self.username];
}

- (NSString*)serverUniqueID {
    return [[self serverURLString] MD5String];
}


@end
