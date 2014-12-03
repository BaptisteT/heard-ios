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

+ (BOOL)validFullname:(NSString *)name;

+ (NSURL *)getUserProfilePictureURLFromUserId:(NSInteger)userId;

+ (NSURL *)getUserProfilePictureURLFromFacebookId:(NSString *)facebookId;

+ (void)setProfilePicture:(UIImageView *)imageView fromContact:(Contact *)contact andAddressBook:(ABAddressBookRef)addressBook;

+ (BOOL)isFirstOpening;

+ (BOOL)displayReplayTuTo;

+ (NSURL *)getPlayedAudioURL;

+ (BOOL)isAdminContact:(Contact *)contact;

+ (BOOL)isCurrentUser:(Contact *)contact;

+ (void)registerForRemoteNotif;

+ (void)registerForSilentRemoteNotif;

+ (BOOL)isRegisteredForRemoteNotification;

+ (BOOL)systemVersionIsEqualTo:(NSString *)v;

+ (BOOL)systemVersionIsGreaterThan:(NSString *)v;

+ (BOOL)systemVersionIsGreaterThanOrEqualTo:(NSString *)v;

+ (void)openSettings;

+ (NSString *)dateToAgeString:(NSInteger)intDate;

+ (void)incrementOf:(NSInteger)increment objectOfDictionnary:(NSMutableDictionary *)dico forKey:(NSString *)key;

+ (BOOL)isFirstClickOnEmojiButton;

+ (BOOL)hasNeverSentStats;

+ (NSString *)getDataTypeForMessageType:(NSString *)messageType;

+ (UIViewController *)getVisibleController;

@end
