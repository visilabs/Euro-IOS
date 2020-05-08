//
//  EMSelectorHelpers.h
//  Euro-IOS
//
//  Created by Egemen on 8.05.2020.
//

#ifndef EMSelectorHelpers_h
#define EMSelectorHelpers_h


BOOL checkIfInstanceOverridesSelector(Class instance, SEL selector);
Class getClassWithProtocolInHierarchy(Class searchClass, Protocol* protocolToFind);
NSArray* ClassGetSubclasses(Class parentClass);
void injectToProperClass(SEL newSel, SEL makeLikeSel, NSArray* delegateSubclasses, Class myClass, Class delegateClass);
BOOL injectSelector(Class newClass, SEL newSel, Class addToClass, SEL makeLikeSel);

#endif /* EMSelectorHelpers_h */
