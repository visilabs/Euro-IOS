//
//  EMDefines.h
//  Euro-IOS
//
//  Created by Egemen on 10.05.2020.
//

#ifndef EMDefines_h
#define EMDefines_h

// To avoid undefined symbol compiler errors on older versions of Xcode,
// instead of using UNAuthorizationOptionProvisional directly, we will use
// it indirectly with these macros
#define PROVISIONAL_UNAUTHORIZATIONOPTION (UNAuthorizationOptions)(1 << 6)

#endif /* EMDefines_h */
