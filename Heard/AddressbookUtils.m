//
//  AdressbookUtils.m
//  Heard
//
//  Created by Bastien Beurier on 7/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AddressbookUtils.h"
#import <AddressBook/AddressBook.h>
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

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
            ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)lastName, &error);
        }
        
        if (lastName) {
            ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)firstName, &error);
        }
        
        //Set phone number
        ABMutableMultiValueRef multiPhone =     ABMultiValueCreateMutable(kABMultiStringPropertyType);
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

@end

