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
    
    

    //TODO: burada reportRetention received gönderilecek
    
    if(pushDetail.category == "carousel")
    {
        addCarouselActionButtons();
    }
    
    UNMutableNotificationContent *modifiedBestAttemptContent = bestAttemptContent;
    
    
    
    
    if(pushDetail != nil && pushDetail.mediaURL != nil && ([pushDetail.pushType  isEqual: @"Image"] || [pushDetail.pushType  isEqual: @"Video"]))
    {
        
        NSURL *mUrl = [NSURL URLWithString:pushDetail.mediaURL];
        
        
        
        
        NSURLRequest *request = [NSURLRequest requestWithURL: mUrl];
        
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

+ (void) addCarouselActionButtons API_AVAILABLE(ios(10.0))
{
    NSString *categoryIdentifier = @"carousel";
    UNNotificationAction *carouselNext = [UNNotificationAction actionWithIdentifier:@"carousel.next" title:@"▶" options:UNNotificationActionOptionNone];
    UNNotificationAction *carouselPrevious = [UNNotificationAction actionWithIdentifier:@"carousel.previous" title:@"◀" options:UNNotificationActionOptionNone];
    UNNotificationCategory *carouselCategory = [UNNotificationCategory categoryWithIdentifier:categoryIdentifier actions:@[carouselNext,carouselPrevious] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
    NSSet *categories = [NSSet setWithObject:carouselCategory];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:categories];
}

+ (void) loadAttachments:(NSURL*) mediaUrl withModifiedBestAttemptContent:(UNMutableNotificationContent*)modifiedBestAttemptContent withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler API_AVAILABLE(ios(10.0))
{
    
}

+ (NSString *) determineType:(NSString *)fileType {
    if([fileType isEqualToString:@"video/mp4"])
        return @".mp4";
    else if([fileType isEqualToString:@"image/jpeg"])
        return @".jpg";
    else if([fileType isEqualToString:@"image/gif"])
        return @".gif";
    else if([fileType isEqualToString:@"image/png"])
        return @".png";
    else
        return @".tmp";
}

@end
