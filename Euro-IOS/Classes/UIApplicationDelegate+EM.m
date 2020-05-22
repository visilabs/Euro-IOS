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


@interface EuroManager (UN_extra)
//TODO: didRegisterForRemoteNotifications a gerek yok sanki
+ (void) didRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken;
+ (void) handleDidFailRegisterForRemoteNotification:(NSError*)error;
+ (void) updateNotificationTypes:(int)notificationTypes;
+ (NSString*) app_id;
+ (void)notificationReceived:(NSDictionary*)messageDict foreground:(BOOL)foreground isActive:(BOOL)isActive wasOpened:(BOOL)opened;
+ (BOOL) remoteSilentNotification:(UIApplication*)application UserInfo:(NSDictionary*)userInfo completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (void) processLocalActionBasedNotification:(UILocalNotification*) notification identifier:(NSString*)identifier;
@end

@implementation EMAppDelegate

+ (void) emLoadedTagSelector
{}

static Class delegateClass = nil;

static NSArray* delegateSubclasses = nil;

+(Class)delegateClass {
    return delegateClass;
}

- (void) setEMDelegate:(id<UIApplicationDelegate>)delegate {
    if (delegateClass) {
        [self setEMDelegate:delegate];
        return;
    }
    
    Class newClass = [EMAppDelegate class];
    
    delegateClass = getClassWithProtocolInHierarchy([delegate class], @protocol(UIApplicationDelegate));
    delegateSubclasses = ClassGetSubclasses(delegateClass);
    

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
    
    injectToProperClass(@selector(emApplicationDidEnterBackground:),
                        @selector(applicationDidEnterBackground:), delegateSubclasses, newClass, delegateClass);
    
    injectToProperClass(@selector(emApplicationDidBecomeActive:),
                        @selector(applicationDidBecomeActive:), delegateSubclasses, newClass, delegateClass);
    
    injectToProperClass(@selector(emApplicationWillTerminate:),
                        @selector(applicationWillTerminate:), delegateSubclasses, newClass, delegateClass);

    [self setEMDelegate:delegate];
}


+ (void)sizzlePreiOS10MethodsPhase1 {
    if ([EMTools isIOSVersionGreaterThanOrEqual:@"10.0"])
        return;
    
    //TODO: local notification ile işimiz yok
    
    injectToProperClass(@selector(emLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:),
                        @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:), delegateSubclasses, [EMAppDelegate class], delegateClass);
    
    injectToProperClass(@selector(emDidRegisterUserNotifications:settings:),
                        @selector(application:didRegisterUserNotificationSettings:), delegateSubclasses, [EMAppDelegate class], delegateClass);
}

+ (void)sizzlePreiOS10MethodsPhase2 {
    if ([EMTools isIOSVersionGreaterThanOrEqual:@"10.0"])
        return;
    
    injectToProperClass(@selector(emReceivedRemoteNotification:userInfo:),
                        @selector(application:didReceiveRemoteNotification:), delegateSubclasses, [EMAppDelegate class], delegateClass);
    
    //TODO: local notification ile işimiz yok
    
    injectToProperClass(@selector(emLocalNotificationOpened:notification:),
                        @selector(application:didReceiveLocalNotification:), delegateSubclasses, [EMAppDelegate class], delegateClass);
     
}


- (void)emDidRegisterForRemoteNotifications:(UIApplication*)app deviceToken:(NSData*)inDeviceToken {
    
    if (EuroManager.applicationKey)
    {
        [[EuroManager sharedManager:EuroManager.applicationKey] registerToken:inDeviceToken];
    }
    
    if ([self respondsToSelector:@selector(emDidRegisterForRemoteNotifications:deviceToken:)])
        [self emDidRegisterForRemoteNotifications:app deviceToken:inDeviceToken];
}

- (void)emDidFailRegisterForRemoteNotification:(UIApplication*)app error:(NSError*)err {
    if ([self respondsToSelector:@selector(emDidFailRegisterForRemoteNotification:error:)])
        [self emDidFailRegisterForRemoteNotification:app error:err];
}

- (void)emDidRegisterUserNotifications:(UIApplication*)application settings:(UIUserNotificationSettings*)notificationSettings {
    if ([self respondsToSelector:@selector(emDidRegisterUserNotifications:settings:)])
        [self emDidRegisterUserNotifications:application settings:notificationSettings];
}


- (void)emReceivedRemoteNotification:(UIApplication*)application userInfo:(NSDictionary*)userInfo {
    
    if (EuroManager.applicationKey)
    {
        [[EuroManager sharedManager:EuroManager.applicationKey] handlePush:userInfo];
    }
    
    if ([self respondsToSelector:@selector(emReceivedRemoteNotification:userInfo:)])
        [self emReceivedRemoteNotification:application userInfo:userInfo];
}

- (void) emRemoteSilentNotification:(UIApplication*)application UserInfo:(NSDictionary*)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult)) completionHandler {
    
    BOOL callExistingSelector = [self respondsToSelector:@selector(emRemoteSilentNotification:UserInfo:fetchCompletionHandler:)];
    BOOL startedBackgroundJob = false;

    if (callExistingSelector) {
        [self emRemoteSilentNotification:application UserInfo:userInfo fetchCompletionHandler:completionHandler];
        return;
    }

    if ([self respondsToSelector:@selector(emReceivedRemoteNotification:userInfo:)])
        [self emReceivedRemoteNotification:application userInfo:userInfo];
    
    if (!startedBackgroundJob)
        completionHandler(UIBackgroundFetchResultNewData);
}

//TODO: local notification ile işimiz yok

- (void) emLocalNotificationOpened:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier forLocalNotification:(UILocalNotification*)notification completionHandler:(void(^)()) completionHandler {
    if ([self respondsToSelector:@selector(emLocalNotificationOpened:handleActionWithIdentifier:forLocalNotification:completionHandler:)])
        [self emLocalNotificationOpened:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    completionHandler();
}

- (void)emLocalNotificationOpened:(UIApplication*)application notification:(UILocalNotification*)notification {
    if([self respondsToSelector:@selector(emLocalNotificationOpened:notification:)])
        [self emLocalNotificationOpened:application notification:notification];
}
 

- (void)emApplicationWillResignActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(emApplicationWillResignActive:)])
        [self emApplicationWillResignActive:application];
}

- (void)emApplicationDidEnterBackground:(UIApplication*)application {
    if ([self respondsToSelector:@selector(emApplicationDidEnterBackground:)])
        [self emApplicationDidEnterBackground:application];
}

- (void)emApplicationDidBecomeActive:(UIApplication*)application {
    if ([self respondsToSelector:@selector(emApplicationDidBecomeActive:)])
        [self emApplicationDidBecomeActive:application];
}

-(void)emApplicationWillTerminate:(UIApplication *)application {
    if ([self respondsToSelector:@selector(emApplicationWillTerminate:)])
        [self emApplicationWillTerminate:application];
}

@end

