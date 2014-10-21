//
//  GeneralUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#define FIRST_EMOJI_BUTTON_PREF @"First Time Emoji Button Clicked"

#define ONE_MINUTE 60
#define ONE_HOUR (60 * ONE_MINUTE)
#define ONE_DAY (24 * ONE_HOUR)
#define ONE_WEEK (7 * ONE_DAY)

#import "GeneralUtils.h"
#import "Constants.h"
#import "SessionUtils.h"
#import "AddressbookUtils.h"
#import "UIImageView+AFNetworking.h"
#import "ImageUtils.h"

@implementation GeneralUtils

// Show an alert message
+ (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title ? title : @""
                                message:text ? text : @""
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

+ (void)setProfilePicture:(UIImageView *)imageView fromContact:(Contact *)contact andAddressBook:(ABAddressBookRef)addressBook
{
    if (contact.isFutureContact && contact.facebookId.length == 0) {
        imageView.image = [AddressbookUtils getPictureFromRecordId:contact.recordId andAddressBook:addressBook];
    } else {
        NSURL *url;
        if (contact.isFutureContact) {
            url = [GeneralUtils getUserProfilePictureURLFromFacebookId:contact.facebookId];
        } else {
            url = [GeneralUtils getUserProfilePictureURLFromUserId:contact.identifier];
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        __weak __typeof(imageView)weakSelf = imageView;
        [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
            weakSelf.image = [ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:0];
        }failure:nil];
    }
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

+ (NSURL *)getUserProfilePictureURLFromFacebookId:(NSString *)facebookId
{
    NSString *baseURL = kFacebookProfilePictureURL;
    return [NSURL URLWithString:[baseURL stringByReplacingOccurrencesOfString:@"id" withString:facebookId]];
}

+ (BOOL)isFirstOpening
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([[prefs objectForKey:kFirstOpeningPref] boolValue]) {
        return NO;
    } else {
        [prefs setObject:[NSNumber numberWithBool:YES] forKey:kFirstOpeningPref];
        return YES;
    }
}

+ (NSURL *)getPlayedAudioURL
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"audioPlayed.m4a"];
    return [NSURL fileURLWithPath:dataPath];
}

+ (BOOL)isAdminContact:(Contact *)contact
{
    return contact.identifier == kAdminId;
}

+ (BOOL)isCurrentUser:(Contact *)contact
{
    return contact.identifier == [SessionUtils getCurrentUserId];
}

+ (void)registerForRemoteNotif
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
//        UIMutableUserNotificationAction *acceptAction = [[UIMutableUserNotificationAction alloc] init];
//        acceptAction.identifier = @"ACCEPT_IDENTIFIER";
//        acceptAction.title = @"Listen";
//        acceptAction.activationMode= UIUserNotificationActivationModeBackground;
//        acceptAction.destructive = NO;
//        acceptAction.authenticationRequired = NO;
//        UIMutableUserNotificationCategory *readCategory = [UIMutableUserNotificationCategory new];
//        readCategory.identifier = @"READ_CATEGORY";
//        [readCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextDefault];
//        [readCategory setActions:@[acceptAction] forContext:UIUserNotificationActionContextMinimal];
//        NSSet *categories = [NSSet setWithObject:readCategory];
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else { // ios7
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
}

+ (void)registerForSilentRemoteNotif
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

+ (BOOL)isRegisteredForRemoteNotification
{
     if (!PRODUCTION || DEBUG)return YES;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
        return ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] && [[UIApplication sharedApplication] currentUserNotificationSettings] > 0);
    } else { // ios 7
        return [[UIApplication sharedApplication] enabledRemoteNotificationTypes] > 0;
    }
}

+ (BOOL)systemVersionIsEqualTo:(NSString *)v
{
    return [[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame;
}

+ (BOOL)systemVersionIsGreaterThan:(NSString *)v
{
    return [[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending;
}

+ (BOOL)systemVersionIsGreaterThanOrEqualTo:(NSString *)v
{
    return [[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending;
}

+ (void)openSettings
{
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

+ (NSString *)dateToAgeString:(NSInteger)intDate
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:intDate];
    NSTimeInterval age = -[date timeIntervalSinceNow];
    
    if (age > 0) {
        NSInteger weeks = age / ONE_WEEK;
        NSInteger days = age / ONE_DAY;
        NSInteger hours = age / ONE_HOUR;
        NSInteger minutes = age / ONE_MINUTE;
        
        if (weeks >= 1) {
            if (weeks > 1) {
                return [[NSString stringWithFormat:@"%ld", (long)weeks] stringByAppendingString:@" weeks ago"];
            } else {
                return [[NSString stringWithFormat:@"%ld", (long)weeks] stringByAppendingString:@" week ago"];
            }
        } else if (days >= 1) {
            if (days > 1) {
                return [[NSString stringWithFormat:@"%ld", (long)days] stringByAppendingString:@" days ago"];
            } else {
                return [[NSString stringWithFormat:@"%ld", (long)days] stringByAppendingString:@" day ago"];
            }
        } else if (hours >= 1) {
            if (hours > 1) {
                return [[NSString stringWithFormat:@"%ld", (long)hours] stringByAppendingString:@" hours ago"];
            } else {
                return [[NSString stringWithFormat:@"%ld", (long)hours] stringByAppendingString:@" hour ago"];
            }
        } else if (minutes >= 1) {
            if (minutes > 1) {
                return [[NSString stringWithFormat:@"%ld", (long)minutes] stringByAppendingString:@" minutes ago"];
            } else {
                return [[NSString stringWithFormat:@"%ld", (long)minutes] stringByAppendingString:@" minute ago"];
            }
        } else {
            if (age > 1) {
                return [[NSString stringWithFormat:@"%ld", (long) age] stringByAppendingString:@" seconds ago"];
            } else {
                return [[NSString stringWithFormat:@"%ld", (long) age] stringByAppendingString:@" second ago"];
            }
        }
    } else {
        return @"now";
    }
}

+ (void)incrementOf:(NSInteger)increment objectOfDictionnary:(NSMutableDictionary *)dico forKey:(NSString *)key
{
    NSInteger newValue = [[dico objectForKey:key] integerValue] + increment;
    [dico setObject:[NSNumber numberWithInteger:newValue] forKey:key];
}

+ (BOOL)isFirstClickOnEmojiButton
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([[prefs objectForKey:FIRST_EMOJI_BUTTON_PREF] boolValue]) {
        return NO;
    } else {
        [prefs setObject:[NSNumber numberWithBool:YES] forKey:FIRST_EMOJI_BUTTON_PREF];
        return YES;
    }
}

+ (BOOL)hasNeverSentStats
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if([[prefs objectForKey:kStatSentPref] boolValue]) {
        return NO;
    } else {
        [prefs setObject:[NSNumber numberWithBool:YES] forKey:kStatSentPref];
        return YES;
    }
}


@end
