//
//  UNUserNotificationCenter+EM.m
//  Euro-IOS
//
//  Created by Egemen on 9.05.2020.
//




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

#import "UNUserNotificationCenter+EM.h"
#import "UIApplicationDelegate+EM.h"
#import "EMSelectorHelpers.h"
#import "EuroManager.h"
#import "EMTools.h"
#import "EMDefines.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface EuroManager (UN_extra)
+ (void)notificationReceived:(NSDictionary*)messageDict foreground:(BOOL)foreground isActive:(BOOL)isActive wasOpened:(BOOL)opened;
+ (BOOL)shouldLogMissingPrivacyConsentErrorWithMethodName:(NSString *)methodName;
@end

@implementation EMUNUserNotificationCenter

static Class delegateUNClass = nil;


static NSArray* delegateUNSubclasses = nil;

__weak static id previousDelegate;

+ (void)swizzleSelectors {
    injectToProperClass(@selector(setEMUNDelegate:), @selector(setDelegate:), @[], [EMUNUserNotificationCenter class], [UNUserNotificationCenter class]);
    
    injectToProperClass(@selector(emRequestAuthorizationWithOptions:completionHandler:),
                        @selector(requestAuthorizationWithOptions:completionHandler:), @[],
                        [EMUNUserNotificationCenter class], [UNUserNotificationCenter class]);
    
    injectToProperClass(@selector(emGetNotificationSettingsWithCompletionHandler:),
                        @selector(getNotificationSettingsWithCompletionHandler:), @[],
                        [EMUNUserNotificationCenter class], [UNUserNotificationCenter class]);
}

static BOOL useiOS10_2_workaround = true;
+ (void)setUseiOS10_2_workaround:(BOOL)enable {
    useiOS10_2_workaround = enable;
}
static BOOL useCachedUNNotificationSettings;
static UNNotificationSettings* cachedUNNotificationSettings;

- (void)emRequestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler {
    
    //TODO: PROVISIONAL_UNAUTHORIZATIONOPTION ne işe yarıyor kontrol et
    
    BOOL notProvisionalRequest = (options & PROVISIONAL_UNAUTHORIZATIONOPTION) == 0;
    

    useCachedUNNotificationSettings = true;
    id wrapperBlock = ^(BOOL granted, NSError* error) {
        useCachedUNNotificationSettings = false;
        completionHandler(granted, error);
    };
    
    [self emRequestAuthorizationWithOptions:options completionHandler:wrapperBlock];
}

- (void)emGetNotificationSettingsWithCompletionHandler:(void(^)(UNNotificationSettings *settings))completionHandler {
    if (useCachedUNNotificationSettings && cachedUNNotificationSettings && useiOS10_2_workaround) {
        completionHandler(cachedUNNotificationSettings);
        return;
    }
    
    id wrapperBlock = ^(UNNotificationSettings* settings) {
        cachedUNNotificationSettings = settings;
        completionHandler(settings);
    };
    
    [self emGetNotificationSettingsWithCompletionHandler:wrapperBlock];
}

- (void) setEMUNDelegate:(id)delegate {
    if (previousDelegate == delegate) {
        [self setEMUNDelegate:delegate];
        return;
    }
    
    previousDelegate = delegate;
    
    delegateUNClass = getClassWithProtocolInHierarchy([delegate class], @protocol(UNUserNotificationCenterDelegate));
    delegateUNSubclasses = ClassGetSubclasses(delegateUNClass);
    
    injectToProperClass(@selector(emUserNotificationCenter:willPresentNotification:withCompletionHandler:),
                        @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:), delegateUNSubclasses, [EMUNUserNotificationCenter class], delegateUNClass);
    
    injectToProperClass(@selector(emUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:),
                        @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:), delegateUNSubclasses, [EMUNUserNotificationCenter class], delegateUNClass);
    
    [self setEMUNDelegate:delegate];
}

- (void)emUserNotificationCenter:(UNUserNotificationCenter *)center
                willPresentNotification:(UNNotification *)notification
                  withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    
    NSDictionary * userInfo = notification.request.content.userInfo;

    NSUInteger completionHandlerOptions = 0;

    if (EuroManager.applicationKey)
    {
        [[EuroManager sharedManager:EuroManager.applicationKey] handlePush:userInfo];
    }
        
    
    if ([self respondsToSelector:@selector(emUserNotificationCenter:willPresentNotification:withCompletionHandler:)])
        [self emUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    else {
        [EMUNUserNotificationCenter callLegacyAppDeletegateSelector:notification
                                                isTextReply:false
                                           actionIdentifier:nil
                                                   userText:nil
                                    fromPresentNotification:true
                                      withCompletionHandler:^() {}];
    }
    
    completionHandler(completionHandlerOptions);
}

- (void)emUserNotificationCenter:(UNUserNotificationCenter *)center
         didReceiveNotificationResponse:(UNNotificationResponse *)response
                  withCompletionHandler:(void(^)())completionHandler {

    [EMUNUserNotificationCenter processiOS10Open:response];
    
    if ([self respondsToSelector:@selector(emUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
        [self emUserNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    else if (![EMUNUserNotificationCenter isDismissEvent:response]) {
        BOOL isTextReply = [response isKindOfClass:NSClassFromString(@"UNTextInputNotificationResponse")];
        NSString* userText = isTextReply ? [response valueForKey:@"userText"] : nil;
        [EMUNUserNotificationCenter callLegacyAppDeletegateSelector:response.notification
                                                isTextReply:isTextReply
                                           actionIdentifier:response.actionIdentifier
                                                   userText:userText
                                    fromPresentNotification:false
                                      withCompletionHandler:completionHandler];
    }
    else
        completionHandler();
}

+ (BOOL) isDismissEvent:(UNNotificationResponse *)response {
    return [@"com.apple.UNNotificationDismissActionIdentifier" isEqual:response.actionIdentifier];
}

+ (void) processiOS10Open:(UNNotificationResponse*)response {
    if (!EuroManager.applicationKey)
        return;
    
    if ([EMUNUserNotificationCenter isDismissEvent:response])
        return;
    
    
    NSDictionary *  userInfo = [EMTools formatApsPayloadIntoStandard:response.notification.request.content.userInfo identifier:response.actionIdentifier];
    [[EuroManager sharedManager:EuroManager.applicationKey] handlePush:userInfo];
}


+ (void)callLegacyAppDeletegateSelector:(UNNotification *)notification
                            isTextReply:(BOOL)isTextReply
                       actionIdentifier:(NSString*)actionIdentifier
                               userText:(NSString*)userText
                fromPresentNotification:(BOOL)fromPresentNotification
                  withCompletionHandler:(void(^)())completionHandler {
    

    UIApplication *sharedApp = [UIApplication sharedApplication];
    
    BOOL isCustomAction = actionIdentifier && ![@"com.apple.UNNotificationDefaultActionIdentifier" isEqualToString:actionIdentifier];
    BOOL isRemote = [notification.request.trigger isKindOfClass:NSClassFromString(@"UNPushNotificationTrigger")];
    
    if (isRemote) {
        NSDictionary* remoteUserInfo = notification.request.content.userInfo;
        
        if (isTextReply &&
            [sharedApp.delegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)]) {
            NSDictionary* responseInfo = @{UIUserNotificationActionResponseTypedTextKey: userText};
            [sharedApp.delegate application:sharedApp handleActionWithIdentifier:actionIdentifier forRemoteNotification:remoteUserInfo withResponseInfo:responseInfo completionHandler:^() {
                completionHandler();
            }];
        }
        else if (isCustomAction &&
                 [sharedApp.delegate respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)])
            [sharedApp.delegate application:sharedApp handleActionWithIdentifier:actionIdentifier forRemoteNotification:remoteUserInfo completionHandler:^() {
                completionHandler();
            }];

        else if ([sharedApp.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)] &&
                 (!fromPresentNotification ||
                 ![[notification.request.trigger valueForKey:@"_isContentAvailable"] boolValue])) {
            [sharedApp.delegate application:sharedApp didReceiveRemoteNotification:remoteUserInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
                completionHandler();
            }];
        }
        else
            completionHandler();
    }
    else
        completionHandler();
}

@end

#pragma clang diagnostic pop
#pragma clang diagnostic pop
