//
//  EMNotificationHandler.h
//  Euro-IOS
//
//  Created by Egemen on 15.05.2020.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UserNotifications/UNNotificationContent.h>

@interface EMNotificationHandler : NSObject
    + (void) didReceive:(UNMutableNotificationContent*) bestAttemptContent withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler API_AVAILABLE(ios(10.0));

@end
