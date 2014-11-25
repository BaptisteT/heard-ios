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
#define MESSAGE_TEXT @"text"
#define TEXT_POSITION @"text_position"

@implementation Message

+ (Message *)createMessageWithId:(NSInteger)identifier
                        senderId:(NSInteger)senderId
                      receiverId:(NSInteger)receiverId
                         groupId:(NSInteger)groupId
                    creationTime:(NSInteger)creationTime
                     messageData:(NSData *)messageData
                     messageType:(NSString *)messageType
                     messageText:(NSString *)messageText
                    textPosition:(float)textPosition
{
    Message *message = [[Message alloc] init];
    message.identifier = identifier;
    message.senderId = senderId;
    message.receiverId = receiverId;
    message.groupId = groupId;
    message.createdAt = creationTime;
    message.messageData = messageData;
    message.messageType = messageType;
    message.messageText = messageText;
    message.textPosition = textPosition;
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
                                         messageType:[rawMessage objectForKey:MESSAGE_TYPE]
                                         messageText:[rawMessage objectForKey:MESSAGE_TEXT]
                                        textPosition:[rawMessage objectForKey:TEXT_POSITION] ? [[rawMessage objectForKey:TEXT_POSITION] floatValue] : 0];
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
    if (PRODUCTION) {
        return [NSURL URLWithString:[kProdHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)messageId,@"_record"]];
    } else {
        return [NSURL URLWithString:[kStagingHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)messageId,@"_record"]];
    }
}

- (BOOL)isPhotoMessage {
    if (self.messageType && [self.messageType isEqualToString:kPhotoMessageType]) {
        return YES;
    } else {
        return NO;
    }
}


@end
