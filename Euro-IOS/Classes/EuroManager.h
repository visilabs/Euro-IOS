//
//  EuroManager.m
//  EuroPush
//
//  Created by Ozan Uysal on 11/11/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

#import "EMMessage.h"
#import "EMTools.h"

#define SDK_VERSION @"2.0.1"

//TODO: UNUserNotificationCenterDelegate kaldırdım, bir soruna sebep olur mu kontrol et.
/*
@interface EuroManager : NSObject <UNUserNotificationCenterDelegate> {

}
 */

@interface EuroManager : NSObject

+ (EuroManager *)sharedManager:(NSString *) applicationKey;
+ (EuroManager *)sharedManager:(NSString *) applicationKey launchOptions:(NSDictionary*)launchOptions;
+ (NSString*)applicationKey;
+ (NSDictionary*)userInfo;

- (void) reportVisilabs: (NSString *) visiUrl;

- (void) setDebug:(BOOL) enable;

- (void) setUserEmail:(NSString *) email;
- (void) setUserKey:(NSString *) userKey;
- (void) setTwitterId:(NSString *) twitterId;
- (void) setFacebookId:(NSString *) facebookId;
- (void) setPhoneNumber:(NSString *) msisdn;
- (void) setAppVersion:(NSString *) appVersion;
- (void) setAdvertisingIdentifier:(NSString *) adIdentifier;
- (void) setUserLatitude:(double) lat andLongitude:(double) lon;
- (void) removeUserParameters;
- (void) addParams:(NSString *) key value:(id) value;

- (void) registerToken:(NSData *) tokenData;
- (void) handlePush:(NSDictionary *) pushDictionary;
- (void) registerForPush;

- (void) synchronize;

@end
