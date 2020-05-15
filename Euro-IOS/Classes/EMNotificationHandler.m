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
    
    if(pushDetail != nil && pushDetail.mediaURL != nil && ([pushDetail.pushType  isEqual: @"Image"] || [pushDetail.pushType  isEqual: @"Video"]))
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pushDetail.mediaURL]];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            /*
            if(error) {
                self->failCallback([NSError errorWithDomain:@"Failed to create connection" code:0 userInfo:nil]);
            }
            UIImage *image = [UIImage imageWithData:data];
            self->successCallback(image);
            NSLog(@"In completionHandler");
             */
            
            
            
        } ];
        [task resume];
    }
    
}

@end
