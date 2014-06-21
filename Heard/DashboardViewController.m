//
//  DashboardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "DashboardViewController.h"
#import "FriendBubbleView.h"
#import "ApiUtils.h"
#import <AddressBook/AddressBook.h>
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "Contact.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "GeneralUtils.h"

@interface DashboardViewController ()

// test (to delete)
@property (strong, nonatomic) IBOutlet FriendBubbleView *exampleBubble;
@property (strong, nonatomic) UIAlertView *failedToRetrieveFriendsAlertView;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;

@end

@implementation DashboardViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // todo
    // 1 -> retrive all contacts + order (last message exchanged)
    
    // 2 -> Create corresponding bubbles
    // - (id)initBubbleViewWithFriendId:(NSInteger)friendId;
    
    // 3 -> Query all unread message
    [ApiUtils getUnreadMessagesAndExecuteSuccess:nil failure:nil];
    
    // 4 -> Create messages bubles
    //              - (id)initWithMessage:(Message *)message;
    
    [self requestAddressBookAccess];
    
    
    // test (to delete)
    self.exampleBubble = [self.exampleBubble initBubbleViewWithFriendId:6];
}

- (void)requestAddressBookAccess
{
    ABAddressBookRef addressBook =  ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
                [self retrieveFriendsFromAddressBook:addressBook];
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
        [self retrieveFriendsFromAddressBook:addressBook];
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
    }

}

- (void)retrieveFriendsFromAddressBook:(ABAddressBookRef) addressBook
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex peopleCount = CFArrayGetCount(people);
    
    NSMutableArray *countryCodes = [[NSMutableArray alloc] init];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    self.addressBookFormattedContacts = [[NSMutableDictionary alloc] init];
    
    for (CFIndex i = 0 ; i < peopleCount; i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            
            NSError *aError = nil;
            NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:&aError];
            
            if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                   firstName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty)
                                    lastName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty)];
                
                if (contact.firstName != nil || contact.lastName != nil) {
                    [self.addressBookFormattedContacts setObject:contact forKey:contact.phoneNumber];
                }
                
                //Store country codes found in international numbers
                if (![countryCodes containsObject:nbPhoneNumber.countryCode]) {
                    [countryCodes addObject:nbPhoneNumber.countryCode];
                }
            }
        }
    }
    
    NSUInteger count = [countryCodes count];
    
    //Try to rematch invalid phone numbers by using previously stores country codes
    for (NSUInteger i = 0; i < count; i++) {
        
        for (CFIndex j = 0 ; j < peopleCount; j++) {
            ABRecordRef person = CFArrayGetValueAtIndex(people, j);
            
            ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for (CFIndex k = 0; k < ABMultiValueGetCount(phoneNumbers); k++) {
                NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, k);
                
                if (![self.addressBookFormattedContacts objectForKey:phoneNumber]) {
                    NSError *aError = nil;
                    
                    NBPhoneNumber *nbPhoneNumber = [phoneUtil parse:phoneNumber defaultRegion:[[phoneUtil regionCodeFromCountryCode:[countryCodes objectAtIndex:i]] firstObject] error:&aError];
                    
                    if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                        Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                           firstName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty)
                                            lastName:(__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty)];
                        
                        if (contact.firstName != nil || contact.lastName != nil) {
                            [self.addressBookFormattedContacts setObject:contact forKey:contact.phoneNumber];
                        }
                    }
                }
            }
        }
    }
    
    [self getHeardContacts];
    
    CFRelease(people);
}

- (void)getHeardContacts
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
    
    for (NSString* phoneNumber in self.addressBookFormattedContacts) {
        [phoneNumbers addObject:phoneNumber];
    }
    
    [ApiUtils getMyContacts:phoneNumbers success:^(NSArray *contacts) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    } failure:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        self.failedToRetrieveFriendsAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                           message:@"We failed to retrieve your contacts, please try again."
                                                                          delegate:self
                                                                 cancelButtonTitle:@"OK!"
                                                                 otherButtonTitles:nil];
        
        [self.failedToRetrieveFriendsAlertView show];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.failedToRetrieveFriendsAlertView) {
        [self getHeardContacts];
    }
}


@end
