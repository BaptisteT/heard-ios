//
//  PotentialContact.h
//  Heard
//
//  Created by Baptiste Truchot on 9/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"

@interface PotentialContact : NSObject

@property (nonatomic) ABRecordID recordId;
@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *facebookId;
@property (nonatomic) BOOL hasPhoto;
@property (nonatomic) BOOL isFavorite;

+ (PotentialContact *)createContactFromABRecord:(ABRecordRef)person andPhoneNumber:(NBPhoneNumber *)nbPhoneNumber andSaveStats:(NSMutableDictionary *)stats;

@end
