//
//  SessionUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface SessionUtils : NSObject

+ (void)securelySaveCurrentUserToken:(NSString *)authToken;

+ (NSString *)getCurrentUserToken;

+ (void)saveUserInfo:(Contact *)contact;

+ (NSInteger)getCurrentUserId;

+ (NSString *)getCurrentUserPhoneNumber;

+ (NSString *)getCurrentUserFirstName;

+ (NSString *)getCurrentUserLastName;

+ (BOOL)isSignedIn;

+ (void)redirectToSignIn;

+ (void)wipeOffCredentials;

+ (BOOL)invalidTokenResponse:(NSURLSessionDataTask *)task;

@end
