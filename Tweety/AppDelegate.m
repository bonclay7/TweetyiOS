//
//  AppDelegate.m
//  Tweety
//
//  Created by Ro on 04/03/15.
//  Copyright (c) 2015 Ro. All rights reserved.
//

#import "AppDelegate.h"

#import "TWSettingsViewController.h"
#import "TWFeedTableViewController.h"
#import "FBDataProvider.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [FBDataProvider sharedInstance].username = @"bonclay7@54.149.229.137:8080/MicroBlogging/api";
    [FBDataProvider sharedInstance].password = @"aqwzsxedc";
    
    [[FBDataProvider sharedInstance] start];
    
    
    //socle de base de l'application
    UITabBarController *tabBarController = [[UITabBarController alloc] init];

    //vue spécifique pour afficher tous les messages du serveur
    TWFeedTableViewController *allMessagesVC = [[TWFeedTableViewController alloc] initWithStyle:UITableViewStylePlain];
    allMessagesVC.title = @"All messages";
    
    //conteneur permettant la navigation depuis allMessagesVC
    UINavigationController *allMsgNav = [[UINavigationController alloc] initWithRootViewController:allMessagesVC];
    
    
    //vue spécifique pour afficher la reading list
    TWFeedTableViewController *readingListVC = [[TWFeedTableViewController alloc] initWithStyle:UITableViewStylePlain];
    readingListVC.title = @"Reading List";
    UINavigationController *readingLitsNav = [[UINavigationController alloc] initWithRootViewController:readingListVC];
    
    
    //vue de réglages
    TWSettingsViewController *settings = [[TWSettingsViewController alloc] initWithNibName:@"TWSettingsViewController" bundle:nil];
    settings.title = @"Settings";
    
    tabBarController.viewControllers = @[allMsgNav, readingLitsNav, settings];
    
    self.window.rootViewController = tabBarController;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}

@end
