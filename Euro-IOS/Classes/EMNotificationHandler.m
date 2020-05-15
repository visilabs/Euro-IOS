//
//  EMNotificationHandler.m
//  Euro-IOS
//
//  Created by Egemen on 15.05.2020.
//

#import <Foundation/Foundation.h>
#import "EMNotificationHandler.h"
#import "EMMessage.h"

@implementation EMNotificationHandler

+ (void) didReceive:(UNMutableNotificationContent*) bestAttemptContent withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler API_AVAILABLE(ios(10.0));
{
    if(bestAttemptContent == nil || bestAttemptContent.userInfo == nil)
    {
        return;
    }
    
    NSError *error;
    EMMessage *pushDetail = [[EMMessage alloc] initWithDictionary:bestAttemptContent.userInfo error:&error];
    UNMutableNotificationContent *modifiedBestAttemptContent = bestAttemptContent;
    
    if(pushDetail != nil && pushDetail.pushType == @"Image" || pushDetail.pushType == @"Video")
    {
        
    }
    
}

@end
