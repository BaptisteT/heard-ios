//
//  ContactUtils.m
//  Heard
//
//  Created by Baptiste Truchot on 7/1/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ContactUtils.h"
#import "Contact.h"


#define CONTACTS_ID_PREF @"Contact Id Preference"
#define CONTACTS_PHONE_PREF @"Contact Phone Preference"
#define CONTACTS_FIRST_NAME_PREF @"Contact First Name Preference"
#define CONTACTS_LAST_NAME_PREF @"Contact Last Name Preference"
#define CONTACTS_PENDING_PREF @"Contact Pending Preference"
#define CONTACTS_HIDDEN_PREF @"Contact Hidden Preference"
#define CONTACTS_LAST_MESSAGE_DATE_PREF @"Contact Last Message Date Preference"
#define CONTACTS_LAST_MESSAGE_IDENTIFIER_PREF @"Contact Last Message Identifier Preference"

@implementation ContactUtils

+ (NSMutableArray *)retrieveContactsInMemory
{
    NSArray *idArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_ID_PREF];
    NSArray *phoneArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_PHONE_PREF];
    NSArray *firstNameArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_FIRST_NAME_PREF];
    NSArray *lastNameArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_LAST_NAME_PREF];
    NSArray *pendingArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_PENDING_PREF];
    NSArray *hiddenArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_HIDDEN_PREF];
    NSArray *lastMessageDateArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_LAST_MESSAGE_DATE_PREF];
    NSArray *lastMessageIdArray = [[NSUserDefaults standardUserDefaults] arrayForKey:CONTACTS_LAST_MESSAGE_IDENTIFIER_PREF];
    
    NSInteger contactCount = [idArray count];
    NSMutableArray *contacts = [[NSMutableArray alloc] initWithCapacity:contactCount];
    for (int i=0;i<contactCount;i++) {
        Contact *contact = [Contact createContactWithId:[idArray[i] integerValue] phoneNumber:phoneArray[i] firstName:firstNameArray[i] lastName:lastNameArray[i]];
        contact.lastMessageDate = [lastMessageDateArray[i] integerValue];
        contact.isPending = [pendingArray[i] boolValue];
        contact.isHidden = hiddenArray ? [hiddenArray[i] boolValue] : NO;
        contact.lastPlayedMessageId = [lastMessageIdArray[i] integerValue];
        [contacts addObject:contact];
    }
    return contacts;
}

+ (void)saveContactsInMemory:(NSArray *)contacts
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger contactCount = [contacts count];
    NSMutableArray *idArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *phoneArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *firstNameArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *lastNameArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *pendingArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *hiddenArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *lastMessageDateArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    NSMutableArray *lastMessageIdArray = [[NSMutableArray alloc] initWithCapacity:contactCount];
    for (Contact * contact in contacts) {
        [idArray addObject:[NSNumber numberWithInteger:contact.identifier]];
        [phoneArray addObject:contact.phoneNumber ? contact.phoneNumber : @""];
        [firstNameArray addObject:(contact.firstName && contact.firstName!=(id)[NSNull null]) ? contact.firstName : @""];
        [lastNameArray addObject:(contact.lastName && contact.lastName!=(id)[NSNull null])? contact.lastName : @""];
        [pendingArray addObject:[NSNumber numberWithInteger:contact.isPending]];
        [hiddenArray addObject:[NSNumber numberWithInteger:contact.isHidden]];
        [lastMessageDateArray addObject:[NSNumber numberWithInteger:contact.lastMessageDate]];
        [lastMessageIdArray addObject:[NSNumber numberWithInteger:contact.lastPlayedMessageId]];
    }
    [prefs setObject:idArray forKey:CONTACTS_ID_PREF];
    [prefs setObject:phoneArray forKey:CONTACTS_PHONE_PREF];
    [prefs setObject:firstNameArray forKey:CONTACTS_FIRST_NAME_PREF];
    [prefs setObject:lastNameArray forKey:CONTACTS_LAST_NAME_PREF];
    [prefs setObject:pendingArray forKey:CONTACTS_PENDING_PREF];
    [prefs setObject:hiddenArray forKey:CONTACTS_HIDDEN_PREF];
    [prefs setObject:lastMessageDateArray forKey:CONTACTS_LAST_MESSAGE_DATE_PREF];
    [prefs setObject:lastMessageIdArray forKey:CONTACTS_LAST_MESSAGE_IDENTIFIER_PREF];
    [prefs synchronize];
}

+ (void)updateContacts:(NSMutableArray *)contacts withNewMessage:(Message *)message
{
    BOOL contactExists = NO;
    for (Contact *contact in contacts) {
        if (contact.identifier == message.senderId) {
            contact.lastMessageDate = message.createdAt;
            contactExists = YES;
            break;
        }
    }
    // If not found, create contact
    if (!contactExists) {
        Contact *contact = [Contact createContactWithId:message.senderId phoneNumber:nil firstName:nil lastName:nil];
        contact.lastMessageDate = message.createdAt;
        contact.isPending = YES;
        [contacts addObject:contact];
    }
}

+ (Contact *)findContact:(NSInteger)contactId inContactsArray:(NSArray *)contacts
{
    for (Contact * existingContact in contacts) {
        if (existingContact.identifier == contactId) {
            return existingContact;
        }
    }
    return nil;
}

+ (NSInteger)numberOfNonHiddenContacts:(NSArray *)contacts
{
    NSInteger count = 0;
    for (Contact * contact in contacts) {
        if (!contact.isHidden) {
            count ++;
        }
    }
    return count;
}

@end
