//
//  ApiUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ApiUtils.h"
#import "Constants.h"
#import "SessionUtils.h"
#import "Message.h"
#import "Contact.h"
#import "GeneralUtils.h"
#import "TrackingUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "Group.h"
#import "ContactView.h"

@implementation ApiUtils

+ (ApiUtils *)sharedClient
{
    static ApiUtils *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (PRODUCTION) {
            _sharedClient = [[ApiUtils alloc] initWithBaseURL:[NSURL URLWithString:kProdAFHeardAPIBaseURLString]];
        } else {
            _sharedClient = [[ApiUtils alloc] initWithBaseURL:[NSURL URLWithString:kStagingAFHeardAPIBaseURLString]];
        }
        
        // Add m4a content type for audio
        _sharedClient.responseSerializer.acceptableContentTypes = [_sharedClient.responseSerializer.acceptableContentTypes setByAddingObject:@"audio/m4a"];
        
        // Stop request if we lose connection
        NSOperationQueue *operationQueue = _sharedClient.operationQueue;
        [_sharedClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if(status == AFNetworkReachabilityStatusNotReachable) {
                [operationQueue cancelAllOperations];
            }
        }];
    });
    
    return _sharedClient;
}

+ (NSString *)getBasePath
{
    return [NSString stringWithFormat:@"api/v%@/", kApiVersion];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (!self) {
        return nil;
    }
    
    return self;
}

// Enrich parameters with token
+ (void) enrichParametersWithToken:(NSMutableDictionary *) parameters
{
    NSString *token = [SessionUtils getCurrentUserToken];
    if (token) {
        [parameters setObject:token forKey:@"auth_token"];
    }
}

+ (void)requestSmsCode:(NSString *)phoneNumber
                 retry:(BOOL)retry
               success:(void(^)())successBlock
               failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"sessions.json"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    
    if (retry) {
        [parameters setObject:@"dummy" forKey:@"retry"];
    }
    
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)validateSmsCode:(NSString *)code
                       phoneNumber:(NSString *)phoneNumber
                    success:(void(^)(NSString *authToken, Contact *contact))successBlock
                    failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"sessions/confirm_sms_code.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    [parameters setObject:code forKey:@"code"];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSString *authToken = [result objectForKey:@"auth_token"];
        Contact *contact = [Contact rawContactToInstance:[result objectForKey:@"user"]];
        
        if (successBlock) {
            successBlock(authToken, contact);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)createUserWithPhoneNumber:(NSString *)phoneNumber
                        firstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                          picture:(NSString *)picture
                             code:(NSString *)code
                          success:(void(^)(NSString *authToken, Contact *contact))successBlock
                          failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    [parameters setObject:firstName forKey:@"first_name"];
    [parameters setObject:lastName forKey:@"last_name"];
    [parameters setObject:picture forKey:@"profile_picture"];
    [parameters setObject:code forKey:@"code"];
    
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSString *authToken = [result objectForKey:@"auth_token"];
        Contact *contact = [Contact rawContactToInstance:[result objectForKey:@"user"]];
        
        if (successBlock) {
            successBlock(authToken, contact);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)createUserWithFBInfoPhoneNumber:(NSString *)phoneNumber
                                   fbId:(NSString *)fbId
                              firstName:(NSString *)firstName
                               lastName:(NSString *)lastName
                                 gender:(NSString *)gender
                                 locale:(NSString *)locale
                                   code:(NSString *)code
                                success:(void(^)(NSString *authToken, Contact *contact))successBlock
                                failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/fb_create.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    [parameters setObject:firstName forKey:@"fb_first_name"];
    [parameters setObject:lastName forKey:@"fb_last_name"];
    [parameters setObject:fbId forKey:@"fb_id"];
    [parameters setObject:gender forKey:@"fb_gender"];
    [parameters setObject:locale forKey:@"fb_locale"];
    
    [parameters setObject:code forKey:@"code"];
    
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSString *authToken = [result objectForKey:@"auth_token"];
        Contact *contact = [Contact rawContactToInstance:[result objectForKey:@"user"]];
        
        if (successBlock) {
            successBlock(authToken, contact);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Send message
+ (void)sendMessage:(NSData *)audioData
      toContactView:(ContactView *)contactView
            success:(void(^)())successBlock
            failure:(void (^)())failureBlock
{
    NSString *path;
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [self enrichParametersWithToken:parameters];
    
    if ([contactView isFutureContact]) {
        path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages/create_future_messages.json"];
        [parameters setObject:[NSArray arrayWithObject:contactView.contact.phoneNumber] forKey:@"future_contact_phones"];
        [parameters setObject:contactView.contact.firstName forKey:@"receiver_first_name"];
    } else {
        path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages.json"];
        [parameters setObject:[NSNumber numberWithLong:[contactView contactIdentifier]] forKey:@"receiver_id"];
        if ([contactView isGroupContactView]) {
            [parameters setObject:@"1" forKey:@"is_group"];
        }
    }
    
    [[ApiUtils sharedClient] POST:path
                       parameters:parameters
        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:audioData name:@"record" fileName:@"data.m4a" mimeType:@"audio/m4a"];
        }
                          success:^(NSURLSessionDataTask *task, id JSON) {
                              if (successBlock) {
                                  successBlock();
                              }
                         }failure:^(NSURLSessionDataTask *task, NSError *error) {
                             [TrackingUtils trackSendingFailed];
                              NSLog(@"ERROR: %@, %@", task.description, error);
                              if (failureBlock) {
                                  failureBlock();   
                              }
                          }];
}

+ (void)sendFutureMessage:(NSData *)audioData
            toFutureUsers:(NSArray *)userPhoneNumbers
                  success:(void(^)())successBlock
                  failure:(void (^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages/create_future_messages.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:userPhoneNumbers forKey:@"future_contact_phones"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] POST:path
                       parameters:parameters
        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:audioData name:@"record" fileName:@"data.m4a" mimeType:@"audio/m4a"];
        }
                          success:^(NSURLSessionDataTask *task, id JSON) {
                              if (successBlock) {
                                  successBlock();
                              }
                          }failure:^(NSURLSessionDataTask *task, NSError *error) {
                              NSLog(@"ERROR: %@, %@", task.description, error);
                              if (failureBlock) {
                                  failureBlock();
                              }
                          }];

}

// Update token
+ (void)updatePushToken:(NSString *)token success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_push_token.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:token forKey:@"push_token"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Get unread messages
+ (void)getUnreadMessagesAndExecuteSuccess:(void(^)(NSArray *messages, BOOL newContactOnServer, NSArray *unreadMessageContacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages/unread_messages.json"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawMessages = [result objectForKey:@"messages"];
        BOOL newContactOnServer = [[result objectForKey:@"retrieve_contacts"] boolValue];
        
        // Should be put somewhere else ?
        NSArray *unreadMessageContacts = [result objectForKey:@"unread_users"];
        
        if (successBlock) {
            successBlock([Message rawMessagesToInstances:rawMessages], newContactOnServer, unreadMessageContacts);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock(task);
        }
    }];
}

// Mark message as opened
+ (void)markMessageAsOpened:(NSInteger)messageId success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages/mark_as_opened.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithLong:messageId] forKey:@"message_id"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

+ (void)getMyContacts:(NSMutableDictionary *)contactsInfo atSignUp:(BOOL)isSignUp success:(void(^)(NSArray *contacts, NSArray *futureContacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/get_contacts_and_futures.json"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:contactsInfo forKey:@"contact_infos"];
    [parameters setObject:[NSNumber numberWithBool:isSignUp] forKey:@"sign_up"];
    
    [self enrichParametersWithToken:parameters];
    
    //Need a post, otherwise the URI is too large
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSArray *rawContacts = [result valueForKeyPath:@"contacts"];
        NSArray *contacts = [Contact rawContactsToInstances:rawContacts];
        NSArray *futureContacts = [result valueForKeyPath:@"future_contacts"];
        if (successBlock) {
            successBlock(contacts, futureContacts);
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock(task);
        }
    }];
}

// Download audio file asynchronously
+ (void)downloadAudioFileAtURL:(NSURL *)url success:(void(^)(NSData *audioData))successBlock failure:(void(^)())failureBlock
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        if (error) {
                                                            NSLog(@"Error: %@", error);
                                                            if (failureBlock) {
                                                                failureBlock();
                                                            }
                                                        } else {
                                                            if (successBlock) {
                                                                successBlock(data);
                                                            }
                                                        }
                                                    }];
    [dataTask resume];
}

// Get new contact info
+ (void)getNewContactInfo:(NSInteger)userId AndExecuteSuccess:(void(^)(Contact *contact))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/get_user_info.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"user_id"];
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSDictionary *rawContact = [result objectForKey:@"contact"];
        
        if (successBlock) {
            successBlock([Contact rawContactToInstance:rawContact]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Block user
+ (void)blockUser:(NSInteger)userId AndExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"blockades.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithInteger:userId] forKey:@"blocked_id"];
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Crash Data
+ (void)sendCrashData:(NSString *)data andExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock {
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"report_crash.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:data forKey:@"data"];
    
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Check API version (retrieve potential message and redirection)
+ (void)checkAppVersionAndExecuteSucess:(void(^)(NSDictionary *))successBlock
{
    NSString *path = [[ApiUtils getBasePath] stringByAppendingString:@"obsolete_api.json"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:appVersion forKey:@"app_version"];
    NSInteger currentUserId = [SessionUtils getCurrentUserId];
    if (currentUserId) {
        [parameters setObject:[NSNumber numberWithInteger:currentUserId] forKey:@"user_id"];
    }
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        if (successBlock) {
            successBlock(result);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        NSLog(@"checkBuildVersion: We should not pass in this block!!!!");
    }];
}

// Update profile picture
+ (void)updateProfilePicture:(NSString *)picture success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_profile_picture.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:picture forKey:@"profile_picture"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Update first name
+ (void)updateFirstName:(NSString *)firstName success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_first_name.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:firstName forKey:@"first_name"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        Contact *contact = [Contact rawContactToInstance:[result objectForKey:@"user"]];
        [SessionUtils saveUserInfo:contact];
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Update Last Name
+ (void)updateLastName:(NSString *)lastName success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_last_name.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:lastName forKey:@"last_name"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        Contact *contact = [Contact rawContactToInstance:[result objectForKey:@"user"]];
        [SessionUtils saveUserInfo:contact];
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Check if user is on Waved
+ (void)checkUserPresenceByPhoneNumber:(NSString *)phoneNumber success:(void(^)(BOOL present))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/user_presence.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        BOOL present = [[result objectForKey:@"presence"] boolValue];

        if (successBlock) {
            successBlock(present);
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Update App info
+ (void)updateAppInfoAndExecuteSuccess:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_app_info.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [parameters setObject:appVersion forKey:@"app_version"];
    [parameters setObject:kApiVersion forKey:@"api_version"];
    [parameters setObject:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];
    [parameters setObject:[NSNumber numberWithBool:[GeneralUtils isRegisteredForRemoteNotification]] forKey:@"push_auth"];
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [parameters setObject:[NSNumber numberWithBool:granted] forKey:@"micro_auth"];
        [self enrichParametersWithToken:parameters];
        
        [[ApiUtils sharedClient] PATCH:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
            if (successBlock) {
                successBlock();
            }
        }failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"ERROR: %@, %@", task.description, error);
            if (failureBlock) {
                failureBlock();
            }
        }];
    }];
}

// Update Stats
+ (void)updateAddressBookStats:(NSMutableDictionary *)stats success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_address_book_stats"];
    
    [self enrichParametersWithToken:stats];
    
    [[ApiUtils sharedClient] PATCH:path parameters:stats success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Is Typing
+ (void)currentUserIsRecording:(BOOL)flag toUser:(NSInteger)receivedId success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages/is_recording"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [self enrichParametersWithToken:parameters];
    [parameters setObject:[NSNumber numberWithInteger:receivedId] forKey:@"receiver_id"];
    [parameters setObject:[NSNumber numberWithBool:flag] forKey:@"is_recording"];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        if (successBlock) {
            successBlock();
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"ERROR: %@, %@", task.description, error);
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Create groups
+ (void)createGroupWithName:(NSString *)groupName
                    members:(NSArray *)membersId
                    success:(void(^)(NSInteger groupId))successBlock
                    failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"groups.json"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [self enrichParametersWithToken:parameters];
    [parameters setObject:groupName forKey:@"group_name"];
    [parameters setObject:membersId forKey:@"members"];
    
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSInteger groupId = [[result valueForKeyPath:@"group_id"] integerValue];
       if (successBlock) {
            successBlock(groupId);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Get new contact info
+ (void)getNewGroupInfo:(NSInteger)groupId AndExecuteSuccess:(void(^)(Group *group))successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"groups/get_group_info.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithInteger:groupId] forKey:@"group_id"];
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSDictionary *rawGroup = [result objectForKey:@"group"];
        
        if (successBlock) {
            successBlock([Group rawGroupToInstance:rawGroup]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

@end
