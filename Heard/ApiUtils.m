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

// Send message
+ (void)sendMessage:(NSData *)audioData
             toUser:(NSInteger)receiverId
            success:(void(^)())successBlock
            failure:(void (^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithLong:receiverId] forKey:@"receiver_id"];
    
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

+ (void)getMyContacts:(NSArray *)phoneNumbers atSignUp:(BOOL)isSignUp success:(void(^)(NSArray *contacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/get_my_contact.json"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:phoneNumbers forKey:@"contact_numbers"];
    [parameters setObject:[NSNumber numberWithBool:isSignUp] forKey:@"sign_up"];
    
    // Add api & app version
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [parameters setObject:appVersion forKey:@"app_version"];
    [parameters setObject:kApiVersion forKey:@"api_version"];
    [parameters setObject:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];
    
    [self enrichParametersWithToken:parameters];
    
    //Need a post, otherwise the URI is too large
    [[ApiUtils sharedClient] POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        NSArray *rawContacts = [result valueForKeyPath:@"contacts"];
        NSArray *contacts = [Contact rawContactsToInstances:rawContacts];
        
        if (successBlock) {
            successBlock(contacts);
        }
    }failure:^(NSURLSessionDataTask *task, NSError *error) {
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
    NSDictionary *parameters = @{@"app_version": appVersion};
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        if (successBlock) {
            successBlock(result);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
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

// Update Micro Auth
+ (void)updateMicroAuth:(BOOL)microAuth success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_micro_auth.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithBool:microAuth] forKey:@"micro_auth"];
    
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

@end
