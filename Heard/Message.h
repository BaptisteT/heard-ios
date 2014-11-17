//
//  Message.h
//  temp_heard
//
//  Created by Baptiste Truchot on 6/19/14.
//  Copyright (c) 2014 Baptiste Truchot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

+ (Message *)createMessageWithId:(NSInteger)identifier
                        senderId:(NSInteger)senderId
                      receiverId:(NSInteger)receiverId
                         groupId:(NSInteger)groupId
                    creationTime:(NSInteger)creationTime
                     messageData:(NSData *)messageData
                     messageType:(NSString *)messageType;
+ (NSArray *)rawMessagesToInstances:(NSArray *)rawMessages;
+ (Message *)rawMessageToInstance:(id)rawMessage;
- (NSURL *)getMessageURL;
+ (NSURL *)getMessageURL:(NSUInteger)messageId;
- (NSInteger)getSenderOrGroupIdentifier;
- (BOOL)isGroupMessage;

@property (nonatomic) NSUInteger identifier;
@property (nonatomic) NSUInteger senderId;
@property (nonatomic) NSUInteger receiverId;
@property (nonatomic) NSUInteger groupId;
@property (nonatomic) NSInteger createdAt;
@property (nonatomic) NSData *messageData;
@property (nonatomic) NSString *messageType;

@end
