//
//  EMTools.h
//  EuroPush
//
//  Created by Ozan Uysal on 20/04/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EuroManager.h"

@interface EMTools : NSObject

+ (BOOL) validatePhone:(NSString *) phone;
+ (BOOL) validateEmail:(NSString *) email;
+ (id) retrieveUserDefaults:(NSString *) userKey;
+ (void) removeUserDefaults:(NSString *) userKey;
+ (void) saveUserDefaults:(NSString *)key andValue:(id)value;
+ (NSString *) getInfoString : (NSString *) key;

+ (NSString *)getCurrentDeviceVersion;
+ (BOOL)isIOSVersionGreaterThanOrEqual:(NSString *)version;
+ (BOOL)isIOSVersionLessThan:(NSString *)version;

+ (void)registerAsUNNotificationCenterDelegate;
+ (NSMutableDictionary*) formatApsPayloadIntoStandard:(NSDictionary*)remoteUserInfo identifier:(NSString*)identifier;

@end


// Defines let and var in Objective-c for shorter code
// __auto_type is compatible with Xcode 8+
#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

#if defined(__cplusplus)
#define var auto
#else
#define var __auto_type
#endif
