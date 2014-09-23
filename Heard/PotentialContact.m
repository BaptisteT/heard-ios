//
//  PotentialContact.m
//  Heard
//
//  Created by Baptiste Truchot on 9/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PotentialContact.h"
#import "SessionUtils.h"

@implementation PotentialContact

+ (PotentialContact *)createPotentialContactWithRecordId:(ABRecordID)recordId
                                             PhoneNumber:(NSString *)phoneNumber
                                               firstName:(NSString *)firstName
                                                lastName:(NSString *)lastName
                                              facebookId:(NSString *)facebookId
{
    PotentialContact *contact = [[PotentialContact alloc] init];
    
    contact.recordId = recordId;
    contact.phoneNumber = phoneNumber;
    contact.firstName = firstName;
    contact.lastName = lastName;
    contact.facebookId = facebookId;
    contact.hasPhoto = NO;
    contact.isFavorite = NO;
    return contact;
}

+ (PotentialContact *)createContactFromABRecord:(ABRecordRef)person andPhoneNumber:(NBPhoneNumber *)nbPhoneNumber {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (!firstName && !lastName) {
        return nil;
    }
    ABRecordID recordID = ABRecordGetRecordID(person);
    NSString *phoneNumber = [NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber];
    NSString *facebookUsername = @"";
    ABMultiValueRef socialProfiles = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
    for (int i=0; i<ABMultiValueGetCount(socialProfiles); i++) {
        NSDictionary *socialItem = (__bridge NSDictionary*)ABMultiValueCopyValueAtIndex(socialProfiles, i);
        NSString* SocialLabel =  [socialItem objectForKey:(NSString *)kABPersonInstantMessageServiceKey];
        if([SocialLabel isEqualToString:(NSString *)kABPersonInstantMessageServiceFacebook]) {
            facebookUsername = ([socialItem objectForKey:(NSString *)kABPersonInstantMessageUsernameKey]);
        }
    }
    PotentialContact *contact = [PotentialContact createPotentialContactWithRecordId:recordID
                                                                         PhoneNumber:phoneNumber
                                                                           firstName:firstName
                                                                            lastName:lastName
                                                                          facebookId:facebookUsername];
    if ([phoneUtil getNumberType:nbPhoneNumber] == NBEPhoneNumberTypeMOBILE) {
        contact.hasPhoto = ABPersonHasImageData(person);
        [contact checkIfFavoriteContact:person];
    }
    
//    if (CFArrayGetCount(ABPersonCopyArrayOfAllLinkedPeople(person))>1) {
//        for (CFIndex i = 0 ; i < CFArrayGetCount(ABPersonCopyArrayOfAllLinkedPeople(person)); i++) {
//            ABRecordRef friend = CFArrayGetValueAtIndex(ABPersonCopyArrayOfAllLinkedPeople(person), i);
//            NSString *firstNamef = (__bridge NSString *)ABRecordCopyValue(friend, kABPersonFirstNameProperty);
//            NSString *lastNamef = (__bridge NSString *)ABRecordCopyValue(friend, kABPersonLastNameProperty);
//            NSLog(@"%@ %@ - %@ %@", firstName, lastName, firstNamef, lastNamef);
//        }
//    }
    ABMultiValueRef relatedNames = ABRecordCopyValue(person, kABPersonRelatedNamesProperty);
    if (ABMultiValueGetCount(relatedNames) > 0) {
        NSLog(@"aa");
    }
    return contact;
}

- (void)checkIfFavoriteContact:(ABRecordRef)person
{
    if (self.hasPhoto && (!self.facebookId || self.facebookId.length == 0)) {
        self.isFavorite = YES;
    }
    if ([self.lastName isEqualToString:[SessionUtils getCurrentUserLastName]]) {
        if ([self.firstName isEqualToString:[SessionUtils getCurrentUserFirstName]]) {
            self.isFavorite = NO;
        } else {
            self.isFavorite = YES;
        }
    }
}

@end
