//
//  UNUserNotificationCenter+EM.h
//  Euro-IOS
//
//  Created by Egemen on 9.05.2020.
//

#ifndef UNUserNotificationCenter_EM_h
#define UNUserNotificationCenter_EM_h

#import "EuroManager.h"

@interface EMUNUserNotificationCenter : NSObject
+ (void)swizzleSelectors;
+ (void)setUseiOS10_2_workaround:(BOOL)enable;
@end


#endif /* UNUserNotificationCenter_EM_h */
