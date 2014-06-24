//
//  Contact.m
//  Heard
//
//  Created by Bastien Beurier on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "Contact.h"

@implementation Contact

+ (Contact *)createContactWithId:(NSUInteger)identifier
                     phoneNumber:(NSString *)phoneNumber
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName
{
    Contact *contact = [[Contact alloc] init];
    
    contact.identifier = identifier;
    contact.phoneNumber = phoneNumber;
    contact.firstName = firstName;
    contact.lastName = lastName;
    
    return contact;
}

+ (NSArray *)rawContactsToInstances:(NSArray *)rawContacts
{
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawContact in rawContacts) {
        [contacts addObject:[Contact rawContactToInstance:rawContact]];
    }
    
    return contacts;
}

+ (Contact *)rawContactToInstance:(NSDictionary *)rawContact
{
    Contact *contact= [[Contact alloc] init];
    contact.identifier = [[rawContact objectForKey:@"id"] integerValue];
    contact.phoneNumber = [rawContact objectForKey:@"phone_number"];
    contact.firstName = [rawContact objectForKey:@"first_name"];
    contact.lastName = [rawContact objectForKey:@"last_name"];
    return contact;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Phone number:%@ - First name:%@ - Last name: %@", self.phoneNumber, self.firstName, self.lastName];
}

@end
