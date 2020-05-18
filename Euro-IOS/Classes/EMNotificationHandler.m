//
//  EMNotificationHandler.m
//  Euro-IOS
//
//  Created by Egemen on 15.05.2020.
//

#import <Foundation/Foundation.h>
#import "EMNotificationHandler.h"
#import "EMMessage.h"
#import "EMLogging.h"

@implementation EMNotificationHandler

+ (void) didReceive:(UNMutableNotificationContent*) bestAttemptContent withContentHandler:(void (^)(UNNotificationContent *contentToDeliver))contentHandler API_AVAILABLE(ios(10.0));
{
    if(bestAttemptContent == nil || bestAttemptContent.userInfo == nil)
    {
        return;
    }
    
    NSError *error;
    EMMessage *pushDetail = [[EMMessage alloc] initWithDictionary:bestAttemptContent.userInfo error:&error];
    
    if(pushDetail == nil)
    {
        return;
    }

    //TODO: burada reportRetention received gönderilecek
    
    if([pushDetail.category  isEqual: @"carousel"])
    {
        [self addCarouselActionButtons];
    }
    
    UNMutableNotificationContent *modifiedBestAttemptContent = bestAttemptContent;
    
    if(modifiedBestAttemptContent != nil  && pushDetail.mediaURL != nil && ([pushDetail.pushType  isEqual: @"Image"] || [pushDetail.pushType  isEqual: @"Video"]))
    {
        NSURL *mUrl = [NSURL URLWithString:pushDetail.mediaURL];
        if(mUrl != nil)
        {
            [self loadAttachments:mUrl withModifiedBestAttemptContent:modifiedBestAttemptContent withContentHandler:contentHandler];
        }
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
    NSURLSession * session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    NSURLSessionDownloadTask * task = [session downloadTaskWithURL:mediaUrl completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error)
        {
            LogDebug(@"loadAttachments : %@", error.localizedDescription);
            contentHandler(modifiedBestAttemptContent);
            return;
        }
        if(response && response.MIMEType)
        {
            NSString *fileType = [self determineType:response.MIMEType];
            if(location != nil && location.lastPathComponent != nil)
            {
                @try {
                    NSString *fileName = [location.lastPathComponent stringByAppendingFormat:@"%@", fileType];
                    NSURL *temporaryFile = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:fileName];
                    NSError *error1;
                    NSError *error2;
                    NSError *error3;
                    [[NSFileManager defaultManager] moveItemAtURL:location toURL:temporaryFile error:&error1];
                    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:temporaryFile options:nil error:&error2];
                    NSMutableArray *attachmentsArray = [[NSMutableArray alloc] init];
                    [attachmentsArray addObject:attachment];
                    modifiedBestAttemptContent.attachments = attachmentsArray;
                    contentHandler(modifiedBestAttemptContent);
                    if([[NSFileManager defaultManager] fileExistsAtPath:temporaryFile.path])
                    {
                        [[NSFileManager defaultManager] removeItemAtURL:temporaryFile error:&error3];
                    }
                }
                @catch (NSException *exception) {
                    LogDebug(@"loadAttachments : %@", error.localizedDescription);
                    contentHandler(modifiedBestAttemptContent);
                }
            }
        }
        
    }];
    [task resume];
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
