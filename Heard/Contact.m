//
//  Contact.m
//  Heard
//
//  Created by Bastien Beurier on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "Contact.h"
#import "GeneralUtils.h"

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
    contact.isPending = NO;
    
    if ([GeneralUtils isAdminContact:identifier]) {
        contact.isHidden = YES;
    } else {
        contact.isHidden = NO;
    }
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
    return [Contact createContactWithId:[[rawContact objectForKey:@"id"] integerValue]
                            phoneNumber:[rawContact objectForKey:@"phone_number"]
                              firstName:[rawContact objectForKey:@"first_name"]
                               lastName:[rawContact objectForKey:@"last_name"]];
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Phone number:%@ - First name:%@ - Last name: %@", self.phoneNumber, self.firstName, self.lastName];
}

@end
