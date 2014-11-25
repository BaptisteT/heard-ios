//
//  KeyboardUtils.m
//  Heard
//
//  Created by Baptiste Truchot on 11/25/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "KeyboardUtils.h"

@implementation KeyboardUtils

+ (void)pushUpTopView:(UIView *)topView whenKeyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's
    // coordinate system. The bottom of the text view's frame should align with the top
    // of the keyboard's final position
    CGRect keyboardRect = [aValue CGRectValue];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = topView.bounds;
    newTextViewFrame.origin.y = keyboardTop - topView.frame.size.height;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    topView.frame = newTextViewFrame;
    
    [UIView commitAnimations];
}

+ (void)pushDownTopView:(UIView *)topView whenKeyboardWillhideNotification:(NSNotification *) notification {
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the size of the screen (= origin of the keyboard when not displayed)
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    CGRect newTextViewFrame = topView.bounds;
    newTextViewFrame.origin.y = keyboardRect.origin.y - newTextViewFrame.size.height;
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    topView.frame = newTextViewFrame;
    
    [UIView commitAnimations];
}

@end
