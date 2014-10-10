//
//  AdressbookUtils.m
//  Heard
//
//  Created by Bastien Beurier on 7/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AddressbookUtils.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "Contact.h"
#import "PotentialContact.h"
#import "ImageUtils.h"
#import "Constants.h"
#import "ApiUtils.h"
#import "GeneralUtils.h"

@implementation AddressbookUtils

//The decimal phone number is the part of the number without country code that is easier to match in the address book (ex: 665278194 for a FR number)
+ (void)createOrEditContactWithDecimalNumber:(NSString *)decimalNumber
                             formattedNumber:(NSString *)formattedNumber
                                   firstName:(NSString *)firstName
                                    lastName:(NSString *)lastName
{
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    //First we try to see if the number matches a contact
    BOOL match = NO;
    BOOL duplicate = NO;
    
    for (CFIndex i = 0 ; i < peopleCount && !match; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        if (ABMultiValueGetCount(phoneNumbers) > 0 &&
            ((firstName && [firstName length] > 0) || (lastName && [lastName length] > 0))) {
            
            for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
                NSString *rawPhoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
                NSString *personDecimalPhoneNumber = [[rawPhoneNumber componentsSeparatedByCharactersInSet:
                                                       [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                                      componentsJoinedByString:@""];
                
                if ([personDecimalPhoneNumber rangeOfString:decimalNumber].location != NSNotFound) {
                    match = YES;
                }
                
                if ([personDecimalPhoneNumber isEqualToString:[formattedNumber substringFromIndex:1]]) {
                    duplicate = YES;
                }
            }
            
            //Save formatted phone number but do not duplicate
            if (match && !duplicate) {
                ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutableCopy (ABRecordCopyValue(person, kABPersonPhoneProperty));
                ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)formattedNumber, kABPersonPhoneMobileLabel, NULL);
                ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone,nil);
                
                CFErrorRef* error = NULL;
                ABAddressBookSave(addressBook, error);
                
                if (error) {
                    NSLog(@"ERROR SAVING!!!");
                }
                
                CFRelease(multiPhone);
            }
        }
        
        CFRelease(person);
        CFRelease(phoneNumbers);
    }
    
    CFRelease(people);
    
    //Create contact if no match
    if (!match) {
        ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
        ABRecordRef person = ABPersonCreate();
        CFErrorRef error = NULL;
        
        if (firstName) {
            ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)firstName, &error);
        }
        
        if (lastName) {
            ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)lastName, &error);
        }
        
        //Set phone number
        ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)formattedNumber, kABPersonPhoneMobileLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone,nil);
        CFRelease(multiPhone);
        
        ABAddressBookAddRecord(addressBook, person, &error);
        ABAddressBookSave(addressBook, &error);
        CFRelease(person);
    }
}

//Formatted number(+33681828384) (only decimal characters preceded by a "+")
//Decimal number (681828384)
+ (NSString *)getDecimalNumber:(NSString *)formattedNumber
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NSError *aError = nil;
    NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:formattedNumber
                                                                    error:&aError];
    
    if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
        NSUInteger countryCodeLength = [[NSString stringWithFormat:@"%ld", [nbPhoneNumber.countryCode integerValue]] length];
        return [formattedNumber substringFromIndex:countryCodeLength + 1];
    } else {
        return nil;
    }
}

// "us" -> @["USA", 1];
+ (NSMutableDictionary *)getCountriesAndCallingCodesForLetterCodes
{
    NSMutableDictionary *letterCodeToCountryAndCallingCode = [[NSMutableDictionary alloc] init];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PhoneCountries" ofType:@"txt"];
    NSData *stringData = [NSData dataWithContentsOfFile:filePath];
    NSString *data = nil;
    if (stringData != nil)
        data = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    
    if (data == nil)
        return nil;
    
    NSString *delimiter = @";";
    NSString *endOfLine = @"\n";
    
    NSInteger currentLocation = 0;
    while (true)
    {
        NSRange codeRange = [data rangeOfString:delimiter options:0 range:NSMakeRange(currentLocation, data.length - currentLocation)];
        if (codeRange.location == NSNotFound)
            break;
        
        int callingCode = [[data substringWithRange:NSMakeRange(currentLocation, codeRange.location - currentLocation)] intValue];
        
        NSRange idRange = [data rangeOfString:delimiter options:0 range:NSMakeRange(codeRange.location + 1, data.length - (codeRange.location + 1))];
        if (idRange.location == NSNotFound)
            break;
        
        NSString *letterCode = [[data substringWithRange:NSMakeRange(codeRange.location + 1, idRange.location - (codeRange.location + 1))] lowercaseString];
        
        NSRange nameRange = [data rangeOfString:endOfLine options:0 range:NSMakeRange(idRange.location + 1, data.length - (idRange.location + 1))];
        if (nameRange.location == NSNotFound)
            nameRange = NSMakeRange(data.length, INT_MAX);
        
        NSString *countryName = [data substringWithRange:NSMakeRange(idRange.location + 1, nameRange.location - (idRange.location + 1))];
        if ([countryName hasSuffix:@"\r"])
            countryName = [countryName substringToIndex:countryName.length - 1];
        
        [letterCodeToCountryAndCallingCode setValue:@[countryName, [[NSNumber alloc] initWithInt:callingCode]] forKey:letterCode];
        
        currentLocation = nameRange.location + nameRange.length;
        if (nameRange.length > 1)
            break;
    }
    
    return letterCodeToCountryAndCallingCode;
}

+ (NSMutableDictionary *)getFormattedPhoneNumbersFromAddressBook:(ABAddressBookRef) addressBook
{
    NSMutableDictionary *addressBookFormattedContacts = [[NSMutableDictionary alloc] init];
    NSNumber *initialInt = [NSNumber numberWithInteger:0];
    NSMutableDictionary *stats = nil;

    stats = [NSMutableDictionary dictionaryWithObjectsAndKeys:initialInt, kNbContactKey, initialInt, kNbContactPhotoKey, initialInt, kNbContactFbKey, initialInt, kNbContactFavoriteKey, initialInt, kNbContactPhotoOnlyKey, initialInt, kNbContactLinkedKey,initialInt, kNbContactRelatedKey, initialInt, kNbContactFamilyKey, nil];
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    NSMutableDictionary *countryCodes = [[NSMutableDictionary alloc] init];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSNumber *defaultCountryCode = [phoneUtil getCountryCodeForRegion:[phoneUtil countryCodeByCarrier]];
    
    for (CFIndex i = 0 ; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        BOOL attributed = NO;
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            NSError *aError = nil;
            NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:&aError];
            
            if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber] && ([phoneUtil getNumberType:nbPhoneNumber] == NBEPhoneNumberTypeMOBILE
                                                                             || [phoneUtil getNumberType:nbPhoneNumber] == NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE) ) {
                PotentialContact *contact = [PotentialContact createContactFromABRecord:person andPhoneNumber:nbPhoneNumber andSaveStats:stats];
                if (contact) {
                    // avoid repetition in favorites
                    if (attributed) {
                        contact.hasPhoto = NO;
                        contact.isFavorite = NO;
                    } else {
                        attributed = YES;
                    }
                    // Stock potential contact
                    [addressBookFormattedContacts setObject:contact forKey:phoneNumber];
                } 
                
                //Store country codes found in international numbers
                if (nbPhoneNumber.countryCode != defaultCountryCode) {
                    if (![countryCodes objectForKey:nbPhoneNumber.countryCode]) {
                        [countryCodes setObject:[NSNumber numberWithInt:1] forKey:nbPhoneNumber.countryCode];
                    } else {
                        [countryCodes setObject:[NSNumber numberWithInt:1+[[countryCodes objectForKey:nbPhoneNumber.countryCode] intValue]] forKey:nbPhoneNumber.countryCode];
                    }
                }
            }
        }
    }
    
    // Retrieve the most common country code (except from the local one)
    NSNumber *mostCommonCountryCode;
    int maxOccurence = 0;
    for (NSNumber *countryCode in countryCodes) {
        if (maxOccurence < [[countryCodes objectForKey:countryCode] intValue]) {
            maxOccurence = [[countryCodes objectForKey:countryCode] intValue];
            mostCommonCountryCode = countryCode;
        }
    }
    
    // Try to rematch invalid phone numbers by using this country code
    for (CFIndex j = 0 ; j < peopleCount; j++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, j);
        BOOL attributed = NO;
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex k = 0; k < ABMultiValueGetCount(phoneNumbers); k++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, k);
            
            if (![addressBookFormattedContacts objectForKey:phoneNumber]) {
                NSError *aError = nil;
                NBPhoneNumber *nbPhoneNumber = [phoneUtil parse:phoneNumber defaultRegion:[[phoneUtil regionCodeFromCountryCode:mostCommonCountryCode] firstObject] error:&aError];
                
                if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                    PotentialContact *contact = [PotentialContact createContactFromABRecord:person andPhoneNumber:nbPhoneNumber andSaveStats:stats];
                    if (contact) {
                        // avoid repetition in favorites
                        if (attributed) {
                            contact.hasPhoto = NO;
                            contact.isFavorite = NO;
                        } else {
                            attributed = YES;
                        }
                        // Stock potential contact
                        [addressBookFormattedContacts setObject:contact forKey:phoneNumber];
                    }
                }
            }
        }
    }
    
    CFRelease(people);
    
    if ([GeneralUtils hasNeverSentStats]) {
        [ApiUtils updateAddressBookStats:stats success:nil failure:nil];
    }
    return addressBookFormattedContacts;
}

+ (ABRecordRef)findContactForNumber:(NSString *)formattedNumber
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NSError *aError = nil;
    
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    for (CFIndex i = 0 ; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        
        if (ABMultiValueGetCount(phoneNumbers) > 0 &&
            ((firstName && [firstName length] > 0) || (lastName && [lastName length] > 0))) {
            
            for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
                NSString *rawPhoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
                NSString *personDecimalPhoneNumber = [[rawPhoneNumber componentsSeparatedByCharactersInSet:
                                                       [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                                      componentsJoinedByString:@""];
                
                NBPhoneNumber *nbPhoneNumber = [phoneUtil parse:formattedNumber defaultRegion:@"US" error:&aError];
                
                if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                    if ([personDecimalPhoneNumber rangeOfString:[nbPhoneNumber.nationalNumber stringValue]].location != NSNotFound) {
                        CFRelease(people);
                        return person;
                    }
                }
            }
        }
        
        CFRelease(person);
        CFRelease(phoneNumbers);
    }
    
    CFRelease(people);
    
    return nil;
}


+ (UIImage *)getPictureFromRecordId:(ABRecordID)recordId andAddressBook:(ABAddressBookRef)addressBook
{
    if (!recordId) {
        return nil;
    }
    ABRecordRef person = ABAddressBookGetPersonWithRecordID (addressBook,recordId);
    if (!person || !ABPersonHasImageData(person)) {
        return nil;
    }
    CFDataRef imageData = ABPersonCopyImageData(person);
    UIImage *image = [ImageUtils cropBiggestCenteredSquareImageFromImage:[UIImage imageWithData:(__bridge NSData *)(imageData)] withSide:0];
    CFRelease(imageData);
    return image;
}


@end

