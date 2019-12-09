//
//  BaseRequest.h
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMMessage.h"

@implementation EMMessage

@synthesize pushId;
@synthesize altUrl;
@synthesize messageContent;
@synthesize URL;
@synthesize mediaURL;
@synthesize category;
@synthesize settings;
@synthesize pushType;
@synthesize sound;
@synthesize contentAvailable;
@synthesize body;
@synthesize subtitle;
@synthesize title;

+(EMJSONKeyMapper*)keyMapper
{
    return [[EMJSONKeyMapper alloc] initWithDictionary:@{
                                                         @"aps.alert": @"messageContent",
                                                         @"aps.alert.body": @"body",
                                                         @"aps.alert.subtitle": @"subtitle",
                                                         @"aps.alert.title": @"title",
                                                         @"aps.category": @"category",
                                                         @"aps.content-available": @"contentAvailable",
                                                         @"aps.sound" : @"sound",
                                                         @"pushType" : @"pushType",
                                                         @"mediaUrl" : @"mediaURL",
                                                         @"url" : @"URL",
                                                         @"altUrl" : @"altUrl",
                                                         @"cid" : @"cId",
                                                         @"pushId" : @"pushId",
                                                         @"settings": @"settings"
                                                         }];
}

- (NSDictionary *) getInteractiveSettings {
    if (self.settings) {
        return [NSJSONSerialization JSONObjectWithData:[self.settings dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    }
    return nil;
}

- (BOOL) hasUrl {
    return self.URL != nil;
}

@end
