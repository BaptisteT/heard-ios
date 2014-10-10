//
//  PotentialContact.m
//  Heard
//
//  Created by Baptiste Truchot on 9/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PotentialContact.h"
#import "SessionUtils.h"
#import "Constants.h"
#import "GeneralUtils.h"
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

+ (PotentialContact *)createContactFromABRecord:(ABRecordRef)person andPhoneNumber:(NBPhoneNumber *)nbPhoneNumber andSaveStats:(NSMutableDictionary *)stats {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    if ((!firstName || firstName.length == 0) && (!lastName || lastName.length == 0) ) {
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
    contact.hasPhoto = ABPersonHasImageData(person);
    if ([phoneUtil getNumberType:nbPhoneNumber] == NBEPhoneNumberTypeMOBILE) { // Make sure favorites are mobile
        [contact checkIfFavoriteContact:person andSaveStats:stats];
    }

    if (stats) {
        [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactKey];
        if (contact.hasPhoto) [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactPhotoKey];
        if (facebookUsername.length > 0) [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactFbKey];
        if (contact.hasPhoto && facebookUsername.length == 0) [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactPhotoOnlyKey];
        if (contact.isFavorite) [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactFavoriteKey];
    
        if ([contact.phoneNumber isEqualToString:[SessionUtils getCurrentUserPhoneNumber]]) {
            for (CFIndex i = 0 ; i < CFArrayGetCount(ABPersonCopyArrayOfAllLinkedPeople(person)); i++) {
                ABRecordRef friend = CFArrayGetValueAtIndex(ABPersonCopyArrayOfAllLinkedPeople(person), i);
                NSString *firstNameFriend = (__bridge NSString *)ABRecordCopyValue(friend, kABPersonFirstNameProperty);
                NSString *lastNameFriend = (__bridge NSString *)ABRecordCopyValue(friend, kABPersonLastNameProperty);
                if (![firstName isEqualToString:firstNameFriend] || ![lastName isEqualToString:lastNameFriend]) {
                    if (contact.isFavorite) [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactLinkedKey];
                }
            }
            [GeneralUtils incrementOf:ABMultiValueGetCount(ABRecordCopyValue(person, kABPersonRelatedNamesProperty)) objectOfDictionnary:stats forKey:kNbContactRelatedKey];
        }
    }
    return contact;
}

- (void)checkIfFavoriteContact:(ABRecordRef)person andSaveStats:(NSMutableDictionary *)stats
{
    if (self.hasPhoto && (!self.facebookId || self.facebookId.length == 0)) {
        self.isFavorite = YES;
    }
    if ([self.lastName isEqualToString:[SessionUtils getCurrentUserLastName]]) {
        if ([self.firstName isEqualToString:[SessionUtils getCurrentUserFirstName]]) {
            self.isFavorite = NO;
        } else {
            self.isFavorite = YES;
            if (stats) [GeneralUtils incrementOf:1 objectOfDictionnary:stats forKey:kNbContactFamilyKey];
        }
    }
}

@end
