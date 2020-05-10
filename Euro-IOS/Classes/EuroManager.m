//
//  EuroManager.m
//  EuroPush
//
//  Created by Ozan Uysal on 11/11/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "EuroManager.h"
#import "EMLocation.h"
#import "EMBaseRequest.h"
#import "EMSettingsRequest.h"
#import "EMRegisterRequest.h"
#import "EMRetentionRequest.h"
#import "EMLogging.h"


#import "EMSelectorHelpers.h"
#import "UIApplicationDelegate+EM.h"
#import "UNUserNotificationCenter+EM.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


#define TOKEN_KEY @"EURO_TOKEN_KEY"
#define REGISTER_KEY @"EURO_REGISTER_KEY"
#define LAST_REQUEST_DATE_KEY @"EURO_LAST_REQUEST_DATE_KEY"

#define TIMEOUT_INTERVAL 60
#define IS_PROD YES

#define TEST_BASE_URL @"http://77.79.84.82"
#define PROD_BASE_URL @".euromsg.com"

static NSString * const EURO_KEYID_KEY = @"keyID";
static NSString * const EURO_MSISDN_KEY = @"msisdn";
static NSString * const EURO_EMAIL_KEY = @"email";
static NSString * const EURO_LOCATION_KEY = @"location";
static NSString * const EURO_FACEBOOK_KEY = @"facebook";
static NSString * const EURO_TWITTER_KEY = @"twitter";
static NSString * const EURO_LAST_MESSAGE_KEY = @"em.lastMessage";

static NSString * const EURO_RECEIVED_STATUS = @"D";
static NSString * const EURO_READ_STATUS = @"O";

@interface EuroManager()

@property (nonatomic, assign) BOOL debugMode;
@property (nonatomic, strong) __block EMRegisterRequest *registerRequest;

- (void) reportRetention:(EMMessage *) message status:(NSString *) status;

- (void) request : (EMBaseRequest *) request
          success:(void (^)(id response)) success
          failure:(void (^)(NSError *error)) failure;
- (void) request : (NSString *) url;

@end

@implementation EuroManager

static NSString* applicationKey;
static NSDictionary* userInfo;
static NSDate *sessionLaunchTime;static NSDate *sessionLaunchTime;

+ (NSString*)applicationKey {
    return applicationKey;
}

+ (void)setApplicationKey:(NSString*)key {
    applicationKey = key;
}

+ (NSDictionary*)userInfo {
    return userInfo;
}

+ (void)setUserInfo:(NSDictionary*)info {
    userInfo = info;
}

- (void) reportVisilabs : (NSString *) visiUrl {
    
    [self request:visiUrl];
    
}

- (void) reportRetention:(EMMessage *) message status:(NSString *)status {
    
    if(message.pushId == nil) {return;}
    
    if(self.debugMode) {
        LogInfo(@"reportRetention: %@",message.toDictionary);
    }
    
    EMRetentionRequest *rRequest = [EMRetentionRequest new];
    rRequest.key = self.registerRequest.appKey;
    rRequest.token = self.registerRequest.token;
    rRequest.status = status;
    rRequest.pushId = message.pushId;
    rRequest.choiceId = @"";
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self request:rRequest success:^(id response) {
            // retention report success
            [EMTools removeUserDefaults:EURO_LAST_MESSAGE_KEY];
            
        } failure:^(NSError *error) {
            
        }];
    });
}

#pragma mark Singleton Methods

+ (EuroManager *)sharedManager:(NSString *) applicationKey {
    return [EuroManager instance:applicationKey launchOptions:nil];
}

+ (EuroManager *)sharedManager:(NSString *) applicationKey launchOptions:(NSDictionary*)launchOptions {
    return [EuroManager instance:applicationKey launchOptions:launchOptions];
}

+ (EuroManager *)instance:(NSString *) applicationKey launchOptions:(NSDictionary*)launchOptions{
    static EuroManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        sharedMyManager.registerRequest.token = [EMTools retrieveUserDefaults:TOKEN_KEY];
    });
    
    if(applicationKey){
        EuroManager.applicationKey = applicationKey;
        sharedMyManager.registerRequest.appKey = applicationKey;
    }
    
    if (launchOptions != nil)
    {
        NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo != nil)
        {
            EuroManager.userInfo = userInfo;
            [sharedMyManager handlePush:userInfo];
        }
    }
    return sharedMyManager;
}


- (id)init {
    if (self = [super init]) {
        // set the register request object ready
        self.registerRequest = [EMRegisterRequest new];
        NSString *lastRegister = [NSString stringWithFormat:@"%@",[EMTools retrieveUserDefaults:REGISTER_KEY]];
        NSError *jsonError = nil;
        EMRegisterRequest *lastRequest = [[EMRegisterRequest alloc] initWithString:lastRegister error:&jsonError];
        if(jsonError == nil) {
            self.registerRequest.extra = lastRequest.extra;
        }
        self.registerRequest.sdkVersion = SDK_VERSION;
        // set the observers ready - update user information on every application close
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronize)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronize)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronize)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidEnterBackgroundNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillTerminateNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidBecomeActiveNotification];
}

#pragma mark public methods
#pragma mark user information
/*
 - (void) setBackgroundHandler:(id) handler {
 _backgroundHandler = handler;
 }
 */
- (void) setAdvertisingIdentifier:(NSString *) adIdentifier {
    self.registerRequest.advertisingIdentifier = adIdentifier;
}

- (void) setAppVersion:(NSString *) appVersion {
    self.registerRequest.appVersion = appVersion;
}

- (void) setDebug:(BOOL) enable {
    self.debugMode = enable;
}

- (void) synchronize {
    
    // check whether the user have an unreported message
    NSString *messageJson = [EMTools retrieveUserDefaults:EURO_LAST_MESSAGE_KEY];
    if(messageJson) {
        
        if(self.debugMode){
            LogInfo(@"Old message : %@",messageJson);
        }
        
        NSError *jsonError;
        EMMessage *lastMessage = [[EMMessage alloc] initWithString:messageJson usingEncoding:NSUTF8StringEncoding error:&jsonError];
        if(!jsonError) {
            [self reportRetention:lastMessage status:EURO_READ_STATUS];
            [EMTools removeUserDefaults:EURO_LAST_MESSAGE_KEY];
        }
    }
    
    __block NSString *currentRegister = self.registerRequest.toJSONString;
    NSString *lastRegister = [NSString stringWithFormat:@"%@",[EMTools retrieveUserDefaults:REGISTER_KEY]];
    
    if ([EMTools retrieveUserDefaults:TOKEN_KEY]) { // set whether it is the first request or not
        self.registerRequest.firstTime = [NSNumber numberWithInt:0];
    }
    
    if (self.debugMode) {
        LogInfo(@"Current registration settings %@",currentRegister);
    }
    
    [EMTools saveUserDefaults:TOKEN_KEY andValue:self.registerRequest.token]; // save the token just in case
    
    NSDate *now = [NSDate date];
    NSDate *fiveMinsLater = [NSDate dateWithTimeInterval:15 * 60 sinceDate:now]; // check every 15 minutes
    
    if(![[EMTools getInfoString:@"CFBundleIdentifier"] isEqualToString:@"com.euromsg.EuroFramework"]) {
        
        NSComparisonResult result = [now compare:[EMTools retrieveUserDefaults:LAST_REQUEST_DATE_KEY]];
        if ((result == NSOrderedAscending && [lastRegister isEqualToString:currentRegister]) || self.registerRequest.token == nil) {
            if (self.debugMode) {
                LogInfo(@"Register request not ready : %@",self.registerRequest.toDictionary);
            }
            return;
        }
    }
    
    if(self.registerRequest.appKey == nil || [@"" isEqual:self.registerRequest.appKey]) { return; } // appkey should not be empty
    
    __weak __typeof__(self) weakSelf = self;
    [self request:self.registerRequest success:^(id response) {
        
        [EMTools saveUserDefaults:LAST_REQUEST_DATE_KEY andValue:fiveMinsLater]; // save request date
        
        [EMTools saveUserDefaults:REGISTER_KEY andValue:currentRegister];
        
        if (weakSelf.debugMode) {
            LogInfo(@"Token registered to EuroMsg : %@",self.registerRequest.token);
        }
        
        
    } failure:^(NSError *error) {
        if (weakSelf.debugMode) {
            LogInfo(@"Request failed : %@",error);
        }
    }];
    
}

- (void) setUserEmail:(NSString *) email {
    if([EMTools validateEmail:email]) {
        [self.registerRequest.extra setObject:email forKey:EURO_EMAIL_KEY];
    }
}

- (void) addParams:(NSString *) key value:(id) value {
    if(value) {
        [self.registerRequest.extra setObject:value forKey:key];
    }
}

- (void) setUserKey:(NSString *) userKey {
    if(userKey) {
        [self.registerRequest.extra setObject:userKey forKey:EURO_KEYID_KEY];
    }
}

- (void) setTwitterId:(NSString *) twitterId {
    if(twitterId) {
        [self.registerRequest.extra setObject:twitterId forKey:EURO_TWITTER_KEY];
    }
}

- (void) setFacebookId:(NSString *) facebookId {
    if(facebookId) {
        [self.registerRequest.extra setObject:facebookId forKey:EURO_FACEBOOK_KEY];
    }
}

- (void) setPhoneNumber:(NSString *) msisdn {
    if([EMTools validatePhone:msisdn]) {
        [self.registerRequest.extra setObject:msisdn forKey:EURO_MSISDN_KEY];
    }
}

- (void) setUserLatitude:(double) lat andLongitude:(double) lon {
    EMLocation *location = [EMLocation new];
    location.latitude = [NSNumber numberWithDouble:lat];
    location.longitude = [NSNumber numberWithDouble:lon];
    [self.registerRequest.extra setObject:location.toDictionary forKey:EURO_LOCATION_KEY];
}

- (void) addCustomUserParameter:(NSString *) key value:(id) value {
    if (key && value) {
        [self.registerRequest.extra setObject:value forKey:key];
    }
}

- (void) removeUserParameters {
    [self.registerRequest.extra removeAllObjects];
}

#pragma mark API Related

- (void) registerToken:(NSData *) tokenData {
    if(self.debugMode) {
        LogDebug(@"registerToken : %@", tokenData);
    }
    if(tokenData == nil) {
        LogInfo(@"Token data cannot be nil");
        return;
    }
    
    /*NSString *tokenString = [[[tokenData description] stringByTrimmingCharactersInSet:
                              [NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                             stringByReplacingOccurrencesOfString:@" " withString:@""];
    */
    
    NSString *tokenString = [self stringFromDeviceToken:tokenData];
    
    if(self.debugMode) {
        LogInfo(@"Your token is %@",tokenString);
    }
    
    self.registerRequest.token = tokenString;
    
    [self synchronize];
    
}

- (void) handlePush:(NSDictionary *) pushDictionary {
    
    if(pushDictionary == nil || [pushDictionary objectForKey:@"pushId"] == nil) {
        return;
    }
    EuroManager.userInfo = pushDictionary;
    
    if(self.debugMode) {
        LogInfo(@"handlePush: %@",pushDictionary);
    }
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    
    NSError *error;
    EMMessage *message = [[EMMessage alloc] initWithDictionary:pushDictionary error:&error];
    
    if (state != UIApplicationStateActive) {
        [EMTools saveUserDefaults:EURO_LAST_MESSAGE_KEY andValue:message.toJSONString];
    } else {
        if (!error) {
            // report retention
            [self reportRetention:message status:EURO_READ_STATUS];
            
        }
    }
}

- (void) registerForPush {
    if (@available(iOS 10.0, *)) {
        
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];       
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error){
                if(!error ){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        LogInfo(@"registerForRemoteNotifications");
                        [[UIApplication sharedApplication] registerForRemoteNotifications];
                    });
                }
            }];
        UNNotificationAction *nextButton = [UNNotificationAction actionWithIdentifier:@"euro-action-next" title:@">>>" options:UNNotificationActionOptionNone];
        UNNotificationAction *goButton = [UNNotificationAction actionWithIdentifier:@"euro-action-go" title:@"Go" options:UNNotificationActionOptionNone];
        UNNotificationCategory *euroCategory = [UNNotificationCategory categoryWithIdentifier:@"euro-rich-push" actions:@[nextButton, goButton] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];
        NSSet *categories = [NSSet setWithObject:euroCategory];
        [center setNotificationCategories:categories];
        LogInfo(@"Register for iOS 10+");
    } else if (@available(iOS 8.0, *)) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        LogInfo(@"Register for iOS 8+");
    }
    //TODO: bu kısım kaldırılabilir iOS 8 den eski sistemlere gerek yok
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
        LogInfo(@"Register for iOS older");
    }
}

#pragma private methods

- (void) request : (EMBaseRequest *) requestModel
          success:(void (^)(id response)) success
          failure:(void (^)(NSError *error)) failure {
    
    BOOL isProd = IS_PROD;
    if([EMTools retrieveUserDefaults:@"em_is_prod"]) {
        isProd = [[EMTools retrieveUserDefaults:@"em_is_prod"] intValue] == 1;
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = TIMEOUT_INTERVAL;
    configuration.timeoutIntervalForResource = TIMEOUT_INTERVAL;
    configuration.HTTPMaximumConnectionsPerHost = 3;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURL *url;
    if(isProd) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@/%@",requestModel.getSubdomain,PROD_BASE_URL,requestModel.getPath]];
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@/%@",TEST_BASE_URL,requestModel.getPort,requestModel.getPath]];
        //url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",TEST_BASE_URL,requestModel.getPath]];
    }
    LogDebug(@"URL : %@",url);
    
    //UIApplicationState appState = [UIApplication sharedApplication].applicationState;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = requestModel.getMethod;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request setTimeoutInterval:TIMEOUT_INTERVAL];
    
    [request setValue:[NSString stringWithFormat:@"Euro Mobile SDK iOS %@",SDK_VERSION] forHTTPHeaderField:@"User-Agent"];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    if([requestModel.getMethod isEqualToString:@"POST"] || [requestModel.getMethod isEqualToString:@"PUT"]) {
        // pass parameters from request object
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:requestModel.toDictionary options:NSJSONWritingPrettyPrinted error:nil]];
    } else if([requestModel.getMethod isEqualToString:@"GET"]) {
        
    }
    
    if (request.HTTPBody) {
        LogDebug(@"Request to %@ with body %@",url,[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    }
    
    __weak __typeof__(self) weakSelf = self;
    id connectionHandler = ^(NSData *data,NSURLResponse *response,NSError *connectionError) {
        
        NSHTTPURLResponse *remoteResponse = (NSHTTPURLResponse *) response;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(connectionError == nil && (remoteResponse.statusCode == 200 || remoteResponse.statusCode == 201)) {
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response code : %ld",(long)remoteResponse.statusCode);
                }
                __autoreleasing NSError *jsonError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response with success : %@",jsonObject);
                }
                
                if(jsonError == nil) {
                    success(jsonObject);
                } else {
                    success([NSDictionary new]);
                }
            } else {
                failure(connectionError);
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response with failure : %@",remoteResponse);
                }
            }
        });
    };
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:connectionHandler];
    [dataTask resume];
    
}

- (void) request : (NSString *) url {
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = TIMEOUT_INTERVAL;
    configuration.timeoutIntervalForResource = TIMEOUT_INTERVAL;
    configuration.HTTPMaximumConnectionsPerHost = 3;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    [request setHTTPMethod:@"GET"];
    LogInfo(@"Request to : %@",url);
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *connectionError) {
        LogInfo(@"Server responded. Error  : %@",connectionError);
    }];
    [dataTask resume];
}

- (NSString *) stringFromDeviceToken:(NSData *)deviceToken {
    NSUInteger length = deviceToken.length;
    if (length == 0) {
        return nil;
    }
    const unsigned char *buffer = deviceToken.bytes;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(length * 2)];
    for (int i = 0; i < length; ++i) {
        [hexString appendFormat:@"%02x", buffer[i]];
    }
    return [hexString copy];
}


@end


@implementation UIApplication (EuroManager)



+ (void)load {

    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([[processInfo processName] isEqualToString:@"IBDesignablesAgentCocoaTouch"] || [[processInfo processName] isEqualToString:@"IBDesignablesAgent-iOS"])
        return;
    
    
    
    if ([EMTools isIOSVersionLessThan:@"8.0"])
        return;

    // Double loading of class detection.
    BOOL existing = injectSelector([EMAppDelegate class], @selector(emLoadedTagSelector:), self, @selector(emLoadedTagSelector:));
    
    if (existing) {
        //TODO: bak
        //[OneSignal onesignal_Log:ONE_S_LL_WARN message:@"Already swizzled UIApplication.setDelegate. Make sure the OneSignal library wasn't loaded into the runtime twice!"];
        return;
    }

    // Swizzle - UIApplication delegate
    injectToProperClass(@selector(setEMDelegate:), @selector(setDelegate:), @[], [EMAppDelegate class], [UIApplication class]);
    
    //TODO: buna gerek var mı kaldırılmalı mı?
    //injectToProperClass(@selector(emSetApplicationIconBadgeNumber:), @selector(setApplicationIconBadgeNumber:), @[], [EMAppDelegate class], [UIApplication class]);
    
    [self setupUNUserNotificationCenterDelegate];

    sessionLaunchTime = [NSDate date];
     
}

+(void)setupUNUserNotificationCenterDelegate {
    //TODO:
    
    // Swizzle - UNUserNotificationCenter delegate - iOS 10+
    if (!NSClassFromString(@"UNUserNotificationCenter"))
        return;

    [EMUNUserNotificationCenter swizzleSelectors];

    // Set our own delegate if one hasn't been set already from something else.
    [EMTools registerAsUNNotificationCenterDelegate];
     
}

@end
