//
//  EMTools.m
//  EuroPush
//
//  Created by Ozan Uysal on 20/04/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import "EMTools.h"

@implementation EMTools


+ (BOOL) validatePhone:(NSString *) phone {
    if(phone) {
        return [phone length] > 9;
    }
    return false;
}

+ (BOOL) validateEmail:(NSString *) email {
    
    if(email) {
        
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        
        return [emailTest evaluateWithObject:email];
    }
    return false;
}

+ (id) retrieveUserDefaults:(NSString *) userKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:userKey] != nil)
        return [defaults objectForKey:userKey];
    else
        return nil;
}

+ (void) removeUserDefaults:(NSString *) userKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:userKey] != nil)
       [defaults removeObjectForKey:userKey];
}

+ (void) saveUserDefaults:(NSString *)key andValue:(id)value {
    if(key && value) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:value forKey:key];
        [defaults synchronize];
    }
}

+ (NSString *) getInfoString : (NSString *) key {
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSDictionary* infoDict = [bundle infoDictionary];
    return [infoDict objectForKey:key];
}

+ (NSString *)getCurrentDeviceVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (BOOL)isIOSVersionGreaterThanOrEqual:(NSString *)version {
    return [[self getCurrentDeviceVersion] compare:version options:NSNumericSearch] != NSOrderedAscending;
}

+ (BOOL)isIOSVersionLessThan:(NSString *)version {
    return [[self getCurrentDeviceVersion] compare:version options:NSNumericSearch] == NSOrderedAscending;
}

//Shared instance as OneSignal is delegate of UNUserNotificationCenterDelegate and CLLocationManagerDelegate
static EuroManager* singleInstance = nil;
+(EuroManager*)sharedInstance {
    @synchronized( singleInstance ) {
        if (!singleInstance )
            singleInstance = [EuroManager new];
    }
    
    return singleInstance;
}

+ (void)registerAsUNNotificationCenterDelegate {
    let curNotifCenter = [UNUserNotificationCenter currentNotificationCenter];
    
    /*
        Sets the OneSignal shared instance as a delegate of UNUserNotificationCenter
        OneSignal does not implement the delegate methods, we simply set it as a delegate
        in order to swizzle the UNUserNotificationCenter methods in case the developer
        does not set a UNUserNotificationCenter delegate themselves
    */
    
    if (!curNotifCenter.delegate)
        curNotifCenter.delegate = (id)[self sharedInstance];
}

+ (NSMutableDictionary*)formatApsPayloadIntoStandard:(NSDictionary*)remoteUserInfo identifier:(NSString*)identifier {
    NSMutableDictionary* userInfo = [remoteUserInfo mutableCopy];
    return userInfo;
}


@end


@interface UIApplication (Swizzling)
+(Class)delegateClass;
@end
