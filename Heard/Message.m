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

@implementation Message

+ (Message *)rawMessageToInstance:(id)rawMessage;
{
    Message *message = [[Message alloc] init];
    message.identifier = [[rawMessage objectForKey:MESSAGE_ID] integerValue];
    message.senderId = [[rawMessage objectForKey:SENDER_ID] integerValue];
    message.receiverId = [[rawMessage objectForKey:RECEIVER_ID] integerValue];
    return message;
}

- (NSURL *)getMessageURL
{
    return [NSURL URLWithString:[kProdHeardRecordBaseURL stringByAppendingFormat:@"%lu%@",(unsigned long)self.identifier,@"_record"]];
}



@end
