//
//  SessionUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "SessionUtils.h"

#define USER_AUTH_TOKEN_PREF @"User authentication token preference"
#define USER_ID_PREF @"User id preference"

@implementation SessionUtils

//TODO: store securely in keychain
+ (void)securelySaveCurrentUserToken:(NSString *)authToken
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setObject:authToken forKey:USER_AUTH_TOKEN_PREF];
    
    [prefs synchronize];
}

//TODO: get from keychain
+ (NSString *)getCurrentUserToken
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [prefs objectForKey:USER_AUTH_TOKEN_PREF];
}

// Save user id
+ (void)saveCurrentUserId:(NSInteger)currentUserId
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSNumber *userId = [NSNumber numberWithLong:currentUserId];
    [prefs setObject:userId forKey:USER_ID_PREF];
    
    [prefs synchronize];
}

// Get user id
+ (NSInteger)getCurrentUserId
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [[prefs objectForKey:USER_ID_PREF] integerValue];
}

// Check User and token are stored in the phone
+ (BOOL)isSignedIn
{
    return [SessionUtils getCurrentUserToken] != nil;
}

// redirect to entry view (sign in)
+ (void)redirectToSignIn
{
    [SessionUtils wipeOffCredentials];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    window.rootViewController = [storyboard instantiateInitialViewController];
}

// Remove FB session and user token
+ (void)wipeOffCredentials
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}



@end
