//
//  Message.h
//  temp_heard
//
//  Created by Baptiste Truchot on 6/19/14.
//  Copyright (c) 2014 Baptiste Truchot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

+ (Message *)rawMessageToInstance:(id)rawMessage;
- (NSURL *)getMessageURL;

@property (nonatomic) NSUInteger identifier;
@property (nonatomic) NSUInteger senderId;
@property (nonatomic) NSUInteger receiverId;

@end
