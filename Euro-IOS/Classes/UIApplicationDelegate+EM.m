//
//  UIApplicationDelegate+EM.m
//  Euro-IOS
//
//  Created by Egemen on 8.05.2020.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "UIApplicationDelegate+EM.h"
#import "EuroManager.h"
#import "EMTools.h"
#import "EMSelectorHelpers.h"



//#import "OSNotificationPayload+Internal.h"
//#import "OneSignal.h"
//#import "OneSignalCommonDefines.h"
//#import "OneSignalTracker.h"
//#import "OneSignalLocation.h"

//#import "OneSignalHelper.h"
//#import "OSMessagingController.h"

@interface EuroManager (UN_extra)
//TODO: didRegisterForRemoteNotifications a gerek yok sanki
+ (void) didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void) handleDidFailRegisterForRemoteNotification:(NSError*)error;
+ (void) updateNotificationTypes:(int)notificationTypes;
+ (NSString*) app_id;
+ (void)notificationReceived:(NSDictionary*)messageDict foreground:(BOOL)foreground isActive:(BOOL)isActive wasOpened:(BOOL)opened;
+ (BOOL) remoteSilentNotification:(UIApplication*)application UserInfo:(NSDictionary*)userInfo completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (void) processLocalActionBasedNotification:(UILocalNotification*) notification identifier:(NSString*)identifier;
//+ (void) onesignal_Log:(ONE_S_LOG_LEVEL)logLevel message:(NSString*) message;
@end

// This class hooks into the UIApplicationDelegate selectors to receive iOS 9 and older events.
//   - UNUserNotificationCenter is used for iOS 10
//   - Orignal implementations are called so other plugins and the developers AppDelegate is still called.

@implementation EMAppDelegate

+ (void) emLoadedTagSelector
{}

static Class delegateClass = nil;

// Store an array of all UIAppDelegate subclasses to iterate over in cases where UIAppDelegate swizzled methods are not overriden in main AppDelegate
// But rather in one of the subclasses
static NSArray* delegateSubclasses = nil;

+(Class)delegateClass {
    return delegateClass;
}

- (void) setEMDelegate:(id<UIApplicationDelegate>)delegate {
    
    //TODO
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:[NSString stringWithFormat:@"ONESIGNAL setOneSignalDelegate CALLED: %@", delegate]];
    
    if (delegateClass) {
        [self setEMDelegate:delegate];
        return;
    }
    
    Class newClass = [EMAppDelegate class];
    
    delegateClass = getClassWithProtocolInHierarchy([delegate class], @protocol(UIApplicationDelegate));
    delegateSubclasses = ClassGetSubclasses(delegateClass);
    
    // Need to keep this one for iOS 10 for content-available notifiations when the app is not in focus
    //   iOS 10 doesn't fire a selector on UNUserNotificationCenter in this cases most likely becuase
    //   UNNotificationServiceExtension (mutable-content) and UNNotificationContentExtension (with category) replaced it.
    injectToProperClass(@selector(emRemoteSilentNotification:UserInfo:fetchCompletionHandler:),
                        @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:), delegateSubclasses, newClass, delegateClass);
    
    [EMAppDelegate sizzlePreiOS10MethodsPhase1];

    injectToProperClass(@selector(emDidFailRegisterForRemoteNotification:error:),
                        @selector(application:didFailToRegisterForRemoteNotificationsWithError:), delegateSubclasses, newClass, delegateClass);
    
    //TODO: CoronaAppDelegate nedir?
    if (NSClassFromString(@"CoronaAppDelegate")) {
        [self setEMDelegate:delegate];
        return;
    }
    
    injectToProperClass(@selector(emDidRegisterForRemoteNotifications:deviceToken:),
                        @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), delegateSubclasses, newClass, delegateClass);
    
    [EMAppDelegate sizzlePreiOS10MethodsPhase2];
    
    injectToProperClass(@selector(emApplicationWillResignActive:),
                        @selector(applicationWillResignActive:), delegateSubclasses, newClass, delegateClass);
    
    // Required for background location
    injectToProperClass(@selector(emApplicationDidEnterBackground:),
                        @selector(applicationDidEnterBackground:), delegateSubclasses, newClass, delegateClass);
    
    injectToProperClass(@selector(emApplicationDidBecomeActive:),
                        @selector(applicationDidBecomeActive:), delegateSubclasses, newClass, delegateClass);
    
    // Used to track how long the app has been closed
    injectToProperClass(@selector(emApplicationWillTerminate:),
                        @selector(applicationWillTerminate:), delegateSubclasses, newClass, delegateClass);

    [self setEMDelegate:delegate];
}


+ (void)sizzlePreiOS10MethodsPhase1 {
    if ([EMTools isIOSVersionGreaterThanOrEqual:@"10.0"])
        return;
    
    //TODO: local notification ile işimiz yok
    /*
    injectToProperClass(@selector(emLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:),
                        @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:), delegateSubclasses, [EMAppDelegate class], delegateClass);
    */
     
    // iOS 10 requestAuthorizationWithOptions has it's own callback
    //   We also check the permssion status from applicationDidBecomeActive: each time.
    //   Keeping for fallback in case of a race condidion where the focus event fires to soon.
    injectToProperClass(@selector(emDidRegisterUserNotifications:settings:),
                        @selector(application:didRegisterUserNotificationSettings:), delegateSubclasses, [EMAppDelegate class], delegateClass);
}

+ (void)sizzlePreiOS10MethodsPhase2 {
    if ([EMTools isIOSVersionGreaterThanOrEqual:@"10.0"])
        return;
    
    injectToProperClass(@selector(emReceivedRemoteNotification:userInfo:),
                        @selector(application:didReceiveRemoteNotification:), delegateSubclasses, [EMAppDelegate class], delegateClass);
    
    //TODO: local notification ile işimiz yok
    /*
    injectToProperClass(@selector(emLocalNotificationOpened:notification:),
                        @selector(application:didReceiveLocalNotification:), delegateSubclasses, [EMAppDelegate class], delegateClass);
     */
}


- (void)emDidRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emDidRegisterForRemoteNotifications:deviceToken:"];
    //[OneSignal didRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
    
    if (EuroManager.applicationKey)
    {
        [[EuroManager sharedManager:EuroManager.applicationKey] registerToken:inDeviceToken];
    }
    
    if ([self respondsToSelector:@selector(emDidRegisterForRemoteNotifications:deviceToken:)])
        [self emDidRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
}

- (void)emDidFailRegisterForRemoteNotification:(UIApplication*)app error:(NSError*)err {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emDidFailRegisterForRemoteNotification:error:"];
    //if ([OneSignal app_id])
    //    [OneSignal handleDidFailRegisterForRemoteNotification:err];
    
    if ([self respondsToSelector:@selector(emDidFailRegisterForRemoteNotification:error:)])
        [self emDidFailRegisterForRemoteNotification:app error:err];
}

// iOS 8 & 9 Only
- (void)emDidRegisterUserNotifications:(UIApplication*)application settings:(UIUserNotificationSettings*)notificationSettings {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emDidRegisterUserNotifications:settings:"];
    //if ([OneSignal app_id])
    //    [OneSignal updateNotificationTypes:notificationSettings.types];
    
    if ([self respondsToSelector:@selector(emDidRegisterUserNotifications:settings:)])
        [self emDidRegisterUserNotifications:application settings:notificationSettings];
}


// Fallback method - Normally this would not fire as oneSignalRemoteSilentNotification below will fire instead. Was needed for iOS 6 support in the past.
- (void)emReceivedRemoteNotification:(UIApplication*)application userInfo:(NSDictionary*)userInfo {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emReceivedRemoteNotification:userInfo:"];
    //if ([OneSignal app_id]) {
    //    let isActive = [application applicationState] == UIApplicationStateActive;
    //    [OneSignal notificationReceived:userInfo foreground:isActive isActive:isActive wasOpened:true];
    //}
    
    if (EuroManager.applicationKey)
    {
        [[EuroManager sharedManager:EuroManager.applicationKey] handlePush:userInfo];
    }
    
    if ([self respondsToSelector:@selector(emReceivedRemoteNotification:userInfo:)])
        [self emReceivedRemoteNotification:application userInfo:userInfo];
}

// Fires when a notication is opened or recieved while the app is in focus.
//   - Also fires when the app is in the background and a notificaiton with content-available=1 is received.
// NOTE: completionHandler must only be called once!
//          iOS 10 - This crashes the app if it is called twice! Crash will happen when the app is resumed.
//          iOS 9  - Does not have this issue.
- (void) emRemoteSilentNotification:(UIApplication*)application UserInfo:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult)) completionHandler {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emRemoteSilentNotification:UserInfo:fetchCompletionHandler:"];
    
    BOOL callExistingSelector = [self respondsToSelector:@selector(emRemoteSilentNotification:UserInfo:fetchCompletionHandler:)];
    BOOL startedBackgroundJob = false;
    
    //TODO: bak
    //if ([OneSignal app_id]) {
    //    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && userInfo[@"aps"][@"alert"])
    //        [OneSignal notificationReceived:userInfo foreground:YES isActive:YES wasOpened:NO];
    //    else
    //        startedBackgroundJob = [OneSignal remoteSilentNotification:application UserInfo:userInfo completionHandler:callExistingSelector ? nil : completionHandler];
    //}
    
    if (callExistingSelector) {
        [self emRemoteSilentNotification:application UserInfo:userInfo fetchCompletionHandler:completionHandler];
        return;
    }
    
    // Make sure not a cold start from tap on notification (OS doesn't call didReceiveRemoteNotification)
    //TODO: bak
    if ([self respondsToSelector:@selector(emReceivedRemoteNotification:userInfo:)] /*&& ![[OneSignal valueForKey:@"coldStartFromTapOnNotification"] boolValue] */)
        [self emReceivedRemoteNotification:application userInfo:userInfo];
    
    if (!startedBackgroundJob)
        completionHandler(UIBackgroundFetchResultNewData);
}

//TODO: local notification ile işimiz yok
/*
- (void) emLocalNotificationOpened:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier forLocalNotification:(UILocalNotification*)notification completionHandler:(void(^)()) completionHandler {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:"];
    //if ([OneSignal app_id])
    //    [OneSignal processLocalActionBasedNotification:notification identifier:identifier];
    
    if ([self respondsToSelector:@selector(emLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:)])
        [self emLocalNotificationOpened:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    
    completionHandler();
}

- (void)emLocalNotificationOpened:(UIApplication*)application notification:(UILocalNotification*)notification {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emLocalNotificationOpened:notification:"];
    //if ([OneSignal app_id])
    //    [OneSignal processLocalActionBasedNotification:notification identifier:@"__DEFAULT__"];
    
    if([self respondsToSelector:@selector(emLocalNotificationOpened:notification:)])
        [self emLocalNotificationOpened:application notification:notification];
}
 */

- (void)emApplicationWillResignActive:(UIApplication*)application {
    
    ///TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emApplicationWillResignActive"];
    //if ([OneSignal app_id])
    //    [OneSignalTracker onFocus:YES];
    
    if ([self respondsToSelector:@selector(emApplicationWillResignActive:)])
        [self emApplicationWillResignActive:application];
}

- (void)emApplicationDidEnterBackground:(UIApplication*)application {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emApplicationDidEnterBackground"];
    //if ([OneSignal app_id])
    //    [OneSignalLocation onFocus:NO];
    
    if ([self respondsToSelector:@selector(emApplicationDidEnterBackground:)])
        [self emApplicationDidEnterBackground:application];
}

- (void)emApplicationDidBecomeActive:(UIApplication*)application {
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"emApplicationDidBecomeActive"];
    //if ([OneSignal app_id]) {
    //    [OneSignalTracker onFocus:NO];
    //    [OneSignalLocation onFocus:YES];
    //    [[OSMessagingController sharedInstance] onApplicationDidBecomeActive];
    //}
    
    if ([self respondsToSelector:@selector(emApplicationDidBecomeActive:)])
        [self emApplicationDidBecomeActive:application];
}

-(void)emApplicationWillTerminate:(UIApplication *)application {
    
    //TODO: bak
    //if ([OneSignal app_id])
    //    [OneSignalTracker onFocus:YES];
    
    if ([self respondsToSelector:@selector(emApplicationWillTerminate:)])
        [self emApplicationWillTerminate:application];
}

@end

