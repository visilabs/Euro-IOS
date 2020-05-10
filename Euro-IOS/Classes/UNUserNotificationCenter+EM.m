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


//#import "OneSignalInternal.h"
//#import "OneSignalCommonDefines.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface EuroManager (UN_extra)
+ (void)notificationReceived:(NSDictionary*)messageDict foreground:(BOOL)foreground isActive:(BOOL)isActive wasOpened:(BOOL)opened;
+ (BOOL)shouldLogMissingPrivacyConsentErrorWithMethodName:(NSString *)methodName;
@end

// This class hooks into the following iSO 10 UNUserNotificationCenterDelegate selectors:
// - userNotificationCenter:willPresentNotification:withCompletionHandler:
//   - Reads OneSignal.inFocusDisplayType to respect it's setting.
// - userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
//   - Used to process opening notifications.
//
// NOTE: On iOS 10, when a UNUserNotificationCenterDelegate is set, UIApplicationDelegate notification selectors no longer fire.
//       However, this class maintains firing of UIApplicationDelegate selectors if the app did not setup it's own UNUserNotificationCenterDelegate.
//       This ensures we don't produce any side effects to standard iOS API selectors.
//       The `callLegacyAppDeletegateSelector` selector below takes care of this backwards compatibility handling.

@implementation EMUNUserNotificationCenter

static Class delegateUNClass = nil;

// Store an array of all UIAppDelegate subclasses to iterate over in cases where UIAppDelegate swizzled methods are not overriden in main AppDelegate
// But rather in one of the subclasses
static NSArray* delegateUNSubclasses = nil;

//ensures setDelegate: swizzles will never get executed twice for the same delegate object
//captures a weak reference to avoid retain cycles
__weak static id previousDelegate;

+ (void)swizzleSelectors {
    injectToProperClass(@selector(setEMUNDelegate:), @selector(setDelegate:), @[], [EMUNUserNotificationCenter class], [UNUserNotificationCenter class]);
    
    // Overrides to work around 10.2.1 bug where getNotificationSettingsWithCompletionHandler: reports as declined if called before
    //  requestAuthorizationWithOptions:'s completionHandler fires when the user accepts notifications.
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

// This is a swizzled implementation of requestAuthorizationWithOptions:
// in case developers call it directly instead of using our prompt method
- (void)emRequestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler {
    
    // check options for UNAuthorizationOptionProvisional membership
    //TODO: PROVISIONAL_UNAUTHORIZATIONOPTION ne işe yarıyor kontrol et
    
    BOOL notProvisionalRequest = (options & PROVISIONAL_UNAUTHORIZATIONOPTION) == 0;
    
    //we don't want to modify these settings if the authorization is provisional (iOS 12 'Direct to History')
    
    //TODO: bak
    //if (notProvisionalRequest)
    //    OneSignal.currentPermissionState.hasPrompted = true;
    
    useCachedUNNotificationSettings = true;
    id wrapperBlock = ^(BOOL granted, NSError* error) {
        useCachedUNNotificationSettings = false;
        //TODO: bak
        //if (notProvisionalRequest) {
        //    OneSignal.currentPermissionState.accepted = granted;
        //    OneSignal.currentPermissionState.answeredPrompt = true;
        //}
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

// Take the received delegate and swizzle in our own hooks.
//  - Selector will be called once if developer does not set a UNUserNotificationCenter delegate.
//  - Selector will be called a 2nd time if the developer does set one.
- (void) setEMUNDelegate:(id)delegate {
    if (previousDelegate == delegate) {
        [self setEMUNDelegate:delegate];
        return;
    }
    
    previousDelegate = delegate;
    
    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"OneSignalUNUserNotificationCenter setOneSignalUNDelegate Fired!"];
    
    delegateUNClass = getClassWithProtocolInHierarchy([delegate class], @protocol(UNUserNotificationCenterDelegate));
    delegateUNSubclasses = ClassGetSubclasses(delegateUNClass);
    
    injectToProperClass(@selector(emUserNotificationCenter:willPresentNotification:withCompletionHandler:),
                        @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:), delegateUNSubclasses, [EMUNUserNotificationCenter class], delegateUNClass);
    
    injectToProperClass(@selector(emUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:),
                        @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:), delegateUNSubclasses, [EMUNUserNotificationCenter class], delegateUNClass);
    
    [self setEMUNDelegate:delegate];
}

// Apple's docs - Called when a notification is delivered to a foreground app.
// NOTE: iOS behavior - Calling completionHandler with 0 means userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: does not trigger.
//  - callLegacyAppDeletegateSelector is called from here due to this case.
- (void)emUserNotificationCenter:(UNUserNotificationCenter *)center
                willPresentNotification:(UNNotification *)notification
                  withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    
    // return if the user has not granted privacy permissions or if not a OneSignal payload
    //TODO: bak
    //if ([OneSignal shouldLogMissingPrivacyConsentErrorWithMethodName:nil] || ![OneSignalHelper isOneSignalPayload:notification.request.content.userInfo]) {
    //    if ([self respondsToSelector:@selector(emUserNotificationCenter:willPresentNotification:withCompletionHandler:)])
    //        [self emUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    //    else
    //        completionHandler(7);
    //    return;
    //}

    //TODO: bak
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"onesignalUserNotificationCenter:willPresentNotification:withCompletionHandler: Fired!"];
    
    NSDictionary * userInfo = notification.request.content.userInfo;
    
    //TODO: bak
    //OSNotificationPayload *payload = [OSNotificationPayload parseWithApns:userInfo];
    //NSString *uuid = [payload additionalData][ONESIGNAL_IAM_PREVIEW];

    NSUInteger completionHandlerOptions = 0;
    //if (!uuid) {
    //    switch (OneSignal.inFocusDisplayType) {
    //        case OSNotificationDisplayTypeNone: completionHandlerOptions = 0; break; // Nothing
    //        case OSNotificationDisplayTypeInAppAlert: completionHandlerOptions = 3; break; // Badge + Sound
    //        case OSNotificationDisplayTypeNotification: completionHandlerOptions = 7; break; // Badge + Sound + Notification
    //        default: break;
    //    }
    //}
    //let notShown = OneSignal.inFocusDisplayType == OSNotificationDisplayTypeNone && notification.request.content.body != nil;
    
    if (EuroManager.applicationKey)
    {
        //TODO: bak
        //[OneSignal notificationReceived:userInfo foreground:YES isActive:YES wasOpened:notShown];
        [[EuroManager sharedManager:EuroManager.applicationKey] handlePush:userInfo];
    }
        
    
    // Call orginal selector if one was set.
    if ([self respondsToSelector:@selector(emUserNotificationCenter:willPresentNotification:withCompletionHandler:)])
        [self emUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    // Or call a legacy AppDelegate selector
    else {
        [EMUNUserNotificationCenter callLegacyAppDeletegateSelector:notification
                                                isTextReply:false
                                           actionIdentifier:nil
                                                   userText:nil
                                    fromPresentNotification:true
                                      withCompletionHandler:^() {}];
    }
    
    // Calling completionHandler for the following reasons:
    //   App dev may have not implented userNotificationCenter:willPresentNotification.
    //   App dev may have implemented this selector but forgot to call completionHandler().
    // Note - iOS only uses the first call to completionHandler().
    completionHandler(completionHandlerOptions);
}

// Apple's docs - Called to let your app know which action was selected by the user for a given notification.
- (void)emUserNotificationCenter:(UNUserNotificationCenter *)center
         didReceiveNotificationResponse:(UNNotificationResponse *)response
                  withCompletionHandler:(void(^)())completionHandler {
    // return if the user has not granted privacy permissions or if not a OneSignal payload
    
    //TODO: bak
    //if ([OneSignal shouldLogMissingPrivacyConsentErrorWithMethodName:nil] || ![OneSignalHelper isOneSignalPayload:response.notification.request.content.userInfo]) {
    //    if ([self respondsToSelector:@selector(onesignalUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
    //        [self emUserNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    //    else
    //        completionHandler();
    //    return;
    //}
    
    //TODO:
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"onesignalUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: Fired!"];
    
    [EMUNUserNotificationCenter processiOS10Open:response];
    
    // Call orginal selector if one was set.
    if ([self respondsToSelector:@selector(onesignalUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
        [self emUserNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    // Or call a legacy AppDelegate selector
    //  - If not a dismiss event as their isn't a iOS 9 selector for it.
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
    
    //TODO: bak
    
    NSDictionary *  userInfo = [EMTools formatApsPayloadIntoStandard:response.notification.request.content.userInfo identifier:response.actionIdentifier];
    
    /*
    if (![OneSignalHelper isOneSignalPayload:response.notification.request.content.userInfo])
        return;
    
    let isActive = [UIApplication sharedApplication].applicationState == UIApplicationStateActive &&
                    OneSignal.inFocusDisplayType != OSNotificationDisplayTypeNotification;
    
    let userInfo = [OneSignalHelper formatApsPayloadIntoStandard:response.notification.request.content.userInfo
                                                      identifier:response.actionIdentifier];
    let isAppForeground = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;

    [OneSignal notificationReceived:userInfo foreground:isAppForeground isActive:isActive wasOpened:YES];
     */
    

    [[EuroManager sharedManager:EuroManager.applicationKey] handlePush:userInfo];
}

// Calls depercated pre-iOS 10 selector if one is set on the AppDelegate.
//   Even though they are deperated in iOS 10 they should still be called in iOS 10
//     As long as they didn't setup their own UNUserNotificationCenterDelegate
// - application:didReceiveLocalNotification:
// - application:didReceiveRemoteNotification:fetchCompletionHandler:
// - application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:
// - application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:
// - application:handleActionWithIdentifier:forLocalNotification:completionHandler:
// - application:handleActionWithIdentifier:forRemoteNotification:completionHandler:
+ (void)callLegacyAppDeletegateSelector:(UNNotification *)notification
                            isTextReply:(BOOL)isTextReply
                       actionIdentifier:(NSString*)actionIdentifier
                               userText:(NSString*)userText
                fromPresentNotification:(BOOL)fromPresentNotification
                  withCompletionHandler:(void(^)())completionHandler {
    
    //TODO:
    //[OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:@"callLegacyAppDeletegateSelector:withCompletionHandler: Fired!"];
    
    UIApplication *sharedApp = [UIApplication sharedApplication];
    
    /*
     The iOS SDK used to call some local notification selectors (such as didReceiveLocalNotification)
     as a convenience but has stopped due to concerns about private API usage
     the SDK will now print warnings when a developer's app implements these selectors
     */
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
        // Always trigger selector for open events and for non-content-available receive events.
        //  content-available seems to be an odd expection to iOS 10's fallback rules for legacy selectors.
        else if ([sharedApp.delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)] &&
                 (!fromPresentNotification ||
                 ![[notification.request.trigger valueForKey:@"_isContentAvailable"] boolValue])) {
            // NOTE: Should always be true as our AppDelegate swizzling should be there unless something else unswizzled it.
            [sharedApp.delegate application:sharedApp didReceiveRemoteNotification:remoteUserInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
                // Call iOS 10's compleationHandler from iOS 9's completion handler.
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
