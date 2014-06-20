//
//  ApiUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface ApiUtils : AFHTTPSessionManager

+ (ApiUtils *)sharedClient;

+ (void)requestSignupCode:(NSString *)phoneNumber
                  success:(void(^)(NSString *code))successBlock
                  failure:(void(^)())failureBlock;

+ (void)createUserWithPhoneNumber:(NSString *)phoneNumber
                        firstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                          picture:(NSString *)picture
                          success:(void(^)(NSString *authToken))successBlock
                          failure:(void(^)())failureBlock;

+ (void)sendMessage:(NSData *)audioData
           fromUser:(NSInteger)sender_id
             toUser:(NSInteger)receiverId
            success:(void(^)())successBlock
            failure:(void (^)())failureBlock;

@end
