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

@implementation Message

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
    Message *message = [[Message alloc] init];
    message.identifier = [[rawMessage objectForKey:MESSAGE_ID] integerValue];
    message.senderId = [[rawMessage objectForKey:SENDER_ID] integerValue];
    message.receiverId = [[rawMessage objectForKey:RECEIVER_ID] integerValue];
    if ([rawMessage objectForKey:GROUP_ID] != [NSNull null]) {
        message.groupId = [[rawMessage objectForKey:GROUP_ID] integerValue];
    } else {
        message.groupId = 0;
    }
    message.createdAt = [[rawMessage objectForKey:CREATED_AT] integerValue];
    message.audioData = nil;
    return message;
}

- (NSURL *)getMessageURL
{
    if (PRODUCTION) {
        return [NSURL URLWithString:[kProdHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)self.identifier,@"_record"]];
    } else {
        return [NSURL URLWithString:[kStagingHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)self.identifier,@"_record"]];
    }
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



@end
