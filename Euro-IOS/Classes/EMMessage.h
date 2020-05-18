//
//  BaseRequest.h
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMJSONModel.h"


@interface EMElement : EMJSONModel

@property (nonatomic, strong) NSString<Optional> *title;
@property (nonatomic, strong) NSString<Optional> *content;
@property (nonatomic, strong) NSString<Optional> *url;
@property (nonatomic, strong) NSString<Optional> *picture;

@end


@interface EMMessage : EMJSONModel

@property (nonatomic, strong) NSString<Optional> *pushId;
@property (nonatomic, strong) NSString<Optional> *altUrl;
@property (nonatomic, strong) NSString<Optional> *cId;
@property (nonatomic, strong) id<Optional> messageContent;
@property (nonatomic, strong) NSString<Optional> *body;
@property (nonatomic, strong) NSString<Optional> *subtitle;
@property (nonatomic, strong) NSString<Optional> *title;
@property (nonatomic, strong) NSString<Optional> *URL;
@property (nonatomic, strong) NSString<Optional> *mediaURL;
@property (nonatomic, strong) NSString<Optional> *category;
@property (nonatomic, strong) NSString<Optional> *sound;
@property (nonatomic, strong) NSString<Optional> *settings;
@property (nonatomic, strong) NSString<Optional> *pushType;
@property (nonatomic, assign) NSNumber<Optional> *contentAvailable;

//TODO: bu sonradan eklendi
@property (nonatomic, strong) NSString<Optional> *deeplink;

- (NSDictionary *) getInteractiveSettings;
- (BOOL) hasUrl;

@end
