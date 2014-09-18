//
//  GeneralUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#define FIRST_OPENING_PREF @"First Opening"
#define PUSH_NOTIF_SEEN_PREF @"Push Notif Seen"
#define MICRO_REQUEST_SEEN_PREF @"Micro Request Seen"

#import "GeneralUtils.h"
#import "Constants.h"
#import "SessionUtils.h"

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
    
    if([[prefs objectForKey:FIRST_OPENING_PREF] boolValue]) {
        return NO;
    } else {
        [prefs setObject:[NSNumber numberWithBool:YES] forKey:FIRST_OPENING_PREF];
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
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:YES] forKey:PUSH_NOTIF_SEEN_PREF];
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else { // ios7
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
}

+ (BOOL)pushNotifRequestSeen
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if([[prefs objectForKey:PUSH_NOTIF_SEEN_PREF] boolValue]) {
        return YES;
    } else {
        return NO;
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


@end
