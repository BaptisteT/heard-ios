//
//  AdressbookUtils.h
//  Heard
//
//  Created by Bastien Beurier on 7/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>

@interface AddressbookUtils : NSObject

+ (void)createOrEditContactWithDecimalNumber:(NSString *)decimalNumber
                             formattedNumber:(NSString *)formattedNumber
                                   firstName:(NSString *)firstName
                                    lastName:(NSString *)lastName;

+ (NSString *)getDecimalNumber:(NSString *)formattedNumber;

+ (NSMutableDictionary *)getCountriesAndCallingCodesForLetterCodes;

+ (NSMutableDictionary *)getFormattedPhoneNumbersFromAddressBook:(ABAddressBookRef) addressBook;

+ (ABRecordRef)findContactForNumber:(NSString *)formattedNumber;

@end
