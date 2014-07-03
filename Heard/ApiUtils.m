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
        _sharedClient = [[ApiUtils alloc] initWithBaseURL:[NSURL URLWithString:kProdAFHeardAPIBaseURLString]];
        
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
    [parameters setObject:[SessionUtils getCurrentUserToken] forKey:@"auth_token"];
}

+ (void)requestSmsCode:(NSString *)phoneNumber
                  success:(void(^)())successBlock
                  failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"sessions.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    
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
+ (void)getUnreadMessagesAndExecuteSuccess:(void(^)(NSArray *messages))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages/unread_messages.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [self enrichParametersWithToken:parameters];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSArray *rawMessages = [result objectForKey:@"messages"];
        
        if (successBlock) {
            successBlock([Message rawMessagesToInstances:rawMessages]);
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

+ (void)getMyContacts:(NSArray *)phoneNumbers success:(void(^)(NSArray *contacts))successBlock failure:(void(^)(NSURLSessionDataTask *task))failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/get_my_contact.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:phoneNumbers forKey:@"contact_numbers"];
    
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

@end
