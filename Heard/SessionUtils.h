//
//  SessionUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionUtils : NSObject

+ (void)securelySaveCurrentUserToken:(NSString *)authToken;

+ (NSString *)getCurrentUserToken;

+ (void)saveUserInfo:(NSInteger)userId phoneNumber:(NSString *)phoneNumber;

+ (NSInteger)getCurrentUserId;

+ (NSString *)getCurrentUserPhoneNumber;

+ (BOOL)isSignedIn;

+ (void)redirectToSignIn;

+ (void)wipeOffCredentials;

+ (BOOL)invalidTokenResponse:(NSURLSessionDataTask *)task;

@end
