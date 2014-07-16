//
//  SessionUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "SessionUtils.h"
#import "GeneralUtils.h"

#define USER_AUTH_TOKEN_PREF @"User authentication token preference"
#define USER_ID_PREF @"User id preference"
#define USER_PHONE_NUMBER_PREF @"User phone number preference"
#define USER_FIRST_NAME_PREF @"User first name preference"
#define USER_LAST_NAME_PREF @"User last name preference"

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

+ (void)saveUserInfo:(Contact *)contact
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setObject:[NSNumber numberWithLong:contact.identifier] forKey:USER_ID_PREF];
    [prefs setObject:contact.phoneNumber forKey:USER_PHONE_NUMBER_PREF];
    [prefs setObject:contact.firstName forKey:USER_FIRST_NAME_PREF];
    [prefs setObject:contact.lastName forKey:USER_LAST_NAME_PREF];
    
    [prefs synchronize];
}

// Get user id
+ (NSInteger)getCurrentUserId
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [[prefs objectForKey:USER_ID_PREF] integerValue];
}

// Get user phone number
+ (NSString *)getCurrentUserPhoneNumber
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [prefs objectForKey:USER_PHONE_NUMBER_PREF];
}

// Get user first name
+ (NSString *)getCurrentUserFirstName
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [prefs objectForKey:USER_FIRST_NAME_PREF];
}

// Get user last name
+ (NSString *)getCurrentUserLastName
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    return [prefs objectForKey:USER_LAST_NAME_PREF];
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
    
    UINavigationController *navigationController = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    [navigationController popToRootViewControllerAnimated:NO];
    [GeneralUtils showMessage:@"Please, sign in again" withTitle:@"Authentification error"];
}

// Remove FB session and user token
+ (void)wipeOffCredentials
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

// Check if this is an invalid token response
+ (BOOL)invalidTokenResponse:(NSURLSessionDataTask *)task
{
    return task && [(NSHTTPURLResponse *) task.response statusCode] == 401;
}



@end
