//
//  GeneralUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GeneralUtils : NSObject

+ (void)showMessage:(NSString *)text withTitle:(NSString *)title;

+ (void)addBottomBorder:(UIView *)view borderSize:(float)borderSize;

+ (void)addTopBorder:(UIView *)view borderSize:(float)borderSize;

+ (void)addRightBorder:(UIView *)view borderSize:(float)borderSize;

+ (BOOL)validName:(NSString *)name;

+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId;

+ (BOOL)isFirstOpening;

@end
