//
//  Contact.h
//  Heard
//
//  Created by Bastien Beurier on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject

@property (nonatomic) NSUInteger identifier;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (nonatomic) NSInteger lastMessageDate;
@property (nonatomic) BOOL isPending;
@property (nonatomic) NSUInteger lastPlayedMessageId;


+ (Contact *)createContactWithId:(NSUInteger)identifier
                     phoneNumber:(NSString *)phoneNumber
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName;

+ (NSArray *)rawContactsToInstances:(NSArray *)rawContacts;

+ (Contact *)rawContactToInstance:(NSDictionary *)rawContact;

- (NSString *)description;

@end
