//
//  XPresentation_LoadTrigger.m
//  XPresentation
//
//  Created by kaizei on 2019/7/6.
//  Copyright © 2019 kai wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface XPresentation_LoadTrigger : NSObject
@end

@implementation XPresentation_LoadTrigger
+ (void)load {
    Method m1 = class_getInstanceMethod([UIViewController class], NSSelectorFromString(@"setModalPresentationStyle:"));
    Method m2 = class_getInstanceMethod([UIViewController class], NSSelectorFromString(@"XPresentation_setModalPresentationStyle:"));
    method_exchangeImplementations(m1, m2);
}
@end
