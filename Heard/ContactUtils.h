//
//  ContactUtils.h
//  Heard
//
//  Created by Baptiste Truchot on 7/1/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "Contact.h"

@interface ContactUtils : NSObject

+ (NSMutableArray *)retrieveContactsInMemory;

+ (void)saveContactsInMemory:(NSArray *)contacts;

+ (void)updateContacts:(NSMutableArray *)contacts withNewMessage:(Message *)message;

+ (Contact *)findContactFromId:(NSInteger)contactId inContactsArray:(NSArray *)contacts;

+ (Contact *)findContact:(Contact *)contact inContactsArray:(NSArray *)contacts;

+ (NSInteger)numberOfNonHiddenContacts:(NSArray *)contacts;

@end
