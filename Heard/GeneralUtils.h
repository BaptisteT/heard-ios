//
//  GeneralUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface GeneralUtils : NSObject

+ (void)showMessage:(NSString *)text withTitle:(NSString *)title;

+ (void)addBottomBorder:(UIView *)view borderSize:(float)borderSize;

+ (void)addTopBorder:(UIView *)view borderSize:(float)borderSize;

+ (void)addRightBorder:(UIView *)view borderSize:(float)borderSize;

+ (BOOL)validName:(NSString *)name;

+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId;

+ (BOOL)isFirstOpening;

+ (NSURL *)getPlayedAudioURL;

+ (BOOL)isAdminContact:(Contact *)contact;

+ (BOOL)isCurrentUser:(Contact *)contact;

+ (void)registerForRemoteNotif;

+ (BOOL)pushNotifRequestSeen;

@end
