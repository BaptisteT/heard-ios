//
//  Message.m
//  temp_heard
//
//  Created by Baptiste Truchot on 6/19/14.
//  Copyright (c) 2014 Baptiste Truchot. All rights reserved.
//

#import "Message.h"
#import "Constants.h"

#define MESSAGE_ID @"id"
#define SENDER_ID @"sender_id"
#define RECEIVER_ID @"receiver_id"
#define GROUP_ID @"group_id"
#define CREATED_AT @"date"
#define MESSAGE_TYPE @"message_type"

@implementation Message

+ (Message *)createMessageWithId:(NSInteger)identifier
                        senderId:(NSInteger)senderId
                      receiverId:(NSInteger)receiverId
                         groupId:(NSInteger)groupId
                    creationTime:(NSInteger)creationTime
                     messageData:(NSData *)messageData
                     messageType:(NSString *)messageType
{
    Message *message = [[Message alloc] init];
    message.senderId = senderId;
    message.receiverId = receiverId;
    message.groupId = groupId;
    message.createdAt = creationTime;
    message.messageData = messageData;
    message.messageType = messageType;
    return message;
}

+ (NSArray *)rawMessagesToInstances:(NSArray *)rawMessages
{
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawMessage in rawMessages) {
        [messages addObject:[Message rawMessageToInstance:rawMessage]];
    }
    return messages;
}

+ (Message *)rawMessageToInstance:(id)rawMessage;
{
    Message *message = [Message createMessageWithId:[[rawMessage objectForKey:MESSAGE_ID] integerValue]
                                           senderId:[[rawMessage objectForKey:SENDER_ID] integerValue]
                                         receiverId:[[rawMessage objectForKey:RECEIVER_ID] integerValue]
                                            groupId:[rawMessage objectForKey:GROUP_ID] == [NSNull null] ? 0 : [[rawMessage objectForKey:GROUP_ID] integerValue]
                                       creationTime:[[rawMessage objectForKey:CREATED_AT] integerValue]
                                        messageData:nil
                                        messageType:[rawMessage objectForKey:MESSAGE_TYPE]];
    return message;
}

- (NSURL *)getMessageURL
{
    return [Message getMessageURL:self.identifier];
}

- (NSInteger)getSenderOrGroupIdentifier {
    if ([self isGroupMessage]) {
        return self.groupId;
    } else {
        return self.senderId;
    }
}

- (BOOL)isGroupMessage
{
    return self.groupId != 0;
}

+ (NSURL *)getMessageURL:(NSUInteger)messageId
{
    // todo BT
    // depend on message type
    if (PRODUCTION) {
        return [NSURL URLWithString:[kProdHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)messageId,@"_record"]];
    } else {
        return [NSURL URLWithString:[kStagingHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)messageId,@"_record"]];
    }
}



@end
