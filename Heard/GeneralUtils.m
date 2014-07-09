//
//  GeneralUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#define FIRST_OPENING_PREF @"First Opening"

#import "GeneralUtils.h"
#import "Constants.h"

@implementation GeneralUtils

// Show an alert message
+ (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

+ (void)addBottomBorder:(UIView *)view borderSize:(float)borderSize
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f,
                                    view.frame.size.height - borderSize,
                                    view.frame.size.width,
                                    borderSize);
    
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [view.layer addSublayer:bottomBorder];
}

+ (void)addTopBorder:(UIView *)view borderSize:(float)borderSize
{
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f,
                                    0.0f,
                                    view.frame.size.width,
                                    borderSize);
    
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [view.layer addSublayer:bottomBorder];
}

+ (void)addRightBorder:(UIView *)view borderSize:(float)borderSize
{
    CALayer *rightBorder = [CALayer layer];
    rightBorder.frame = CGRectMake(view.frame.size.width - borderSize,
                                   0.0f,
                                   borderSize,
                                   view.frame.size.height);
    rightBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [view.layer addSublayer:rightBorder];
}

+ (BOOL)validName:(NSString *)name
{
    return [name length] > 0 && [name length] <= kMaxNameLength;
}

+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId
{
    NSString *baseURL;
    
    if (PRODUCTION) {
        baseURL = kProdHeardProfilePictureBaseURL;
    } else {
        baseURL = kStagingHeardProfilePictureBaseURL;
    }
    
    return [NSURL URLWithString:[baseURL stringByAppendingFormat:@"%lu%@",(unsigned long)userId,@"_profile_picture"]];
}

+ (BOOL)isFirstOpening
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([prefs objectForKey:FIRST_OPENING_PREF]) {
        return NO;
    } else {
        [prefs setObject:[NSNumber numberWithBool:YES] forKey:FIRST_OPENING_PREF];
        return YES;
    }
}


@end
