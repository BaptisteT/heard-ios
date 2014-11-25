//
//  KeyboardUtils.h
//  Heard
//
//  Created by Baptiste Truchot on 11/25/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyboardUtils : NSObject

+ (void)pushUpTopView:(UIView *)topView whenKeyboardWillShowNotification:(NSNotification *)notification;

+ (void)pushDownTopView:(UIView *)topView whenKeyboardWillhideNotification:(NSNotification *) notification;

@end
