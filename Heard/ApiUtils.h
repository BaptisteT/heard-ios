//
//  ApiUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "Contact.h"

@interface ApiUtils : AFHTTPSessionManager

+ (ApiUtils *)sharedClient;

+ (void)requestSmsCode:(NSString *)phoneNumber
                  success:(void(^)())successBlock
                  failure:(void(^)())failureBlock;

+ (void)validateSmsCode:(NSString *)code
            phoneNumber:(NSString *)phoneNumber
                success:(void(^)(NSString *authToken, Contact *contact))successBlock
                failure:(void(^)())failureBlock;

+ (void)createUserWithPhoneNumber:(NSString *)phoneNumber
                        firstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                          picture:(NSString *)picture
                             code:(NSString *)code
                          success:(void(^)(NSString *authToken, Contact *contact))successBlock
                          failure:(void(^)())failureBlock;

+ (void)sendMessage:(NSData *)audioData
             toUser:(NSInteger)receiverId
            success:(void(^)())successBlock
            failure:(void (^)())failureBlock;

+ (void)updatePushToken:(NSString *)token success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getUnreadMessagesAndExecuteSuccess:(void(^)(NSArray *messages))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)markMessageAsOpened:(NSInteger)messageId success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getMyContacts:(NSArray *)phoneNumbers success:(void(^)(NSArray *contacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)downloadAudioFileAtURL:(NSURL *)url success:(void(^)(NSData *audioData))successBlock failure:(void(^)())failureBlock;

+ (void)getNewContactInfo:(NSInteger)userId AndExecuteSuccess:(void(^)(Contact *contact))successBlock failure:(void(^)())failureBlock;

+ (void)blockUser:(NSInteger)userId AndExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)sendCrashData:(NSString *)data andExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock;

@end
