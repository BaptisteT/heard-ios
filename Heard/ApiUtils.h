//
//  ApiUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "ContactView.h"
#import "Group.h"

@interface ApiUtils : AFHTTPSessionManager

+ (ApiUtils *)sharedClient;

+ (void)requestSmsCode:(NSString *)phoneNumber
                 retry:(BOOL)retry
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

+ (void)createUserWithFBInfoPhoneNumber:(NSString *)phoneNumber
                                   fbId:(NSString *)fbId
                              firstName:(NSString *)firstName
                               lastName:(NSString *)lastName
                                 gender:(NSString *)gender
                                 locale:(NSString *)locale
                                   code:(NSString *)code
                                success:(void(^)(NSString *authToken, Contact *contact))successBlock
                                failure:(void(^)())failureBlock;

+ (void)sendMessage:(NSData *)audioData
      toContactView:(ContactView *)contactView
            success:(void(^)())successBlock
            failure:(void (^)())failureBlock;

+ (void)sendFutureMessage:(NSData *)audioData
            toFutureUsers:(NSArray *)userPhoneNumbers
                  success:(void(^)())successBlock
                  failure:(void (^)())failureBlock;

+ (void)updatePushToken:(NSString *)token success:(void(^)())successBlock failure:(void(^)())failureBlock;
+ (void)updateProfilePicture:(NSString *)picture success:(void(^)())successBlock failure:(void(^)())failureBlock;
+ (void)updateFirstName:(NSString *)firstName success:(void(^)())successBlock failure:(void(^)())failureBlock;
+ (void)updateLastName:(NSString *)lastName success:(void(^)())successBlock failure:(void(^)())failureBlock;
+ (void)updateAppInfoAndExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getUnreadMessagesAndExecuteSuccess:(void(^)(NSArray *messages, BOOL newContactOnServer, NSArray *unreadMessageContacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)markMessageAsOpened:(NSInteger)messageId success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)getMyContacts:(NSMutableDictionary *)contactsInfo atSignUp:(BOOL)isSignUp success:(void(^)(NSArray *contacts, NSArray *futureContacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock;

+ (void)downloadAudioFileAtURL:(NSURL *)url success:(void(^)(NSData *audioData))successBlock failure:(void(^)())failureBlock;

+ (void)getNewContactInfo:(NSInteger)userId AndExecuteSuccess:(void(^)(Contact *contact))successBlock failure:(void(^)())failureBlock;

+ (void)blockUser:(NSInteger)userId AndExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)sendCrashData:(NSString *)data andExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)checkAppVersionAndExecuteSucess:(void(^)(NSDictionary *))successBlock;

+ (void)checkUserPresenceByPhoneNumber:(NSString *)phoneNumber success:(void(^)(BOOL present))successBlock failure:(void(^)())failureBlock;

+ (void)updateAddressBookStats:(NSMutableDictionary *)stats success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)currentUserIsRecording:(BOOL)flag toUser:(NSInteger)receivedId success:(void(^)())successBlock failure:(void(^)())failureBlock;

+ (void)createGroupWithName:(NSString *)groupName members:(NSArray *)membersId success:(void(^)(NSInteger groupId))successBlock failure:(void(^)())failureBlock;
+ (void)getNewGroupInfo:(NSInteger)groupId AndExecuteSuccess:(void(^)(Group *group))successBlock failure:(void(^)())failureBlock;
@end
