//
//  EUROAppDelegate.m
//  Euro-IOS
//
//  Created by egemen@visilabs.com on 12/09/2019.
//  Copyright (c) 2019 egemen@visilabs.com. All rights reserved.
//

#import "EUROAppDelegate.h"
#import "EuroManager.h"

@implementation EUROAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[EuroManager sharedManager:@"EuromsgIOSTest"] setDebug:YES];
    //[[EuroManager sharedManager:@"EuromsgIOSTest"] setUserKey: @"12345"];
    //[[EuroManager sharedManager:@"EuromsgIOSTest"] setUserEmail: @"egemen@visilabs.com"];
    [[EuroManager sharedManager:@"EuromsgIOSTest"] registerForPush];
    
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
       completionHandler:^(BOOL granted, NSError * _Nullable error) {
          if (granted)
          {
              //[[EuroManager sharedManager:@"EuromsgIOSTest"] setUserEmail: @"egemen@visilabs.com"];
              [[EuroManager sharedManager:@"EuromsgIOSTest"] addParams:@"pushPermit" value:@"Y"];
              [[EuroManager sharedManager:@"EuromsgIOSTest"] synchronize];
          }
          else
          {
              //[[EuroManager sharedManager:@"EuromsgIOSTest"] setUserEmail: @"egemen@visilabs.com"];
              [[EuroManager sharedManager:@"EuromsgIOSTest"] addParams:@"pushPermit" value:@"N"];
              [[EuroManager sharedManager:@"EuromsgIOSTest"] synchronize];
          }
    }];
    
    
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
