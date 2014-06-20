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

@implementation ApiUtils

+ (ApiUtils *)sharedClient
{
    static ApiUtils *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[ApiUtils alloc] initWithBaseURL:[NSURL URLWithString:kProdAFSnapbyAPIBaseURLString]];
        
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
                    success:(void(^)(NSString *authToken))successBlock
                    failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"sessions/confirm_sms_code.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    [parameters setObject:phoneNumber forKey:@"phone_number"];
    [parameters setObject:code forKey:@"code"];
    
    [[ApiUtils sharedClient] GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *result = [JSON valueForKeyPath:@"result"];
        
        NSString *authToken = [result objectForKey:@"auth_token"];
        
        if (successBlock) {
            successBlock(authToken);
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
                          success:(void(^)(NSString *authToken, NSInteger userId))successBlock
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
        NSInteger userId = [[result objectForKey:@"user_id"] integerValue];
        
        if (successBlock) {
            successBlock(authToken, userId);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failureBlock) {
            failureBlock();
        }
    }];
}

// Send message
+ (void)sendMessage:(NSData *)audioData
           fromUser:(NSInteger)sender_id
             toUser:(NSInteger)receiverId
            success:(void(^)())successBlock
            failure:(void (^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"messages.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithLong:sender_id] forKey:@"sender_id"];
    [parameters setObject:[NSNumber numberWithLong:receiverId] forKey:@"receiver_id"];
    
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
+ (void)updatePushToken:(NSString *)token ofUser:(NSInteger)user_id success:(void(^)())successBlock failure:(void(^)())failureBlock
{
    NSString *path =  [[ApiUtils getBasePath] stringByAppendingString:@"users/update_push_token.json"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithLong:user_id] forKey:@"user_id"];
    [parameters setObject:token forKey:@"push_token"];
    
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


@end
