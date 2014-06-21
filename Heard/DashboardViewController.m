//
//  DashboardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "DashboardViewController.h"
#import "ContactBubbleView.h"
#import "ApiUtils.h"
#import <AddressBook/AddressBook.h>
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "Contact.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "GeneralUtils.h"
#import "Constants.h"

#define CONTACT_MARGIN 20
#define CONTACT_SIZE 80
#define CONTACT_NAME_HEIGHT 30
#define ACTION_SHEET_OPTION_1 @"Invite contact"
#define ACTION_SHEET_OPTION_2 @"Share this app"
#define ACTION_SHEET_OPTION_3 @"Feedback"
#define ACTION_SHEET_CANCEL @"Cancel"

@interface DashboardViewController ()

@property (strong, nonatomic) UIAlertView *failedToRetrieveFriendsAlertView;
@property (strong, nonatomic) UIAlertView *failedToRetrieveNewFriendAlertView;
@property (strong, nonatomic) NSMutableDictionary *addressBookFormattedContacts;
@property (strong, nonatomic) NSMutableArray *contacts;
@property (weak, nonatomic) IBOutlet UIScrollView *contactScrollView;
@property (strong, nonatomic) UIActionSheet *menuActionSheet;

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
    
    [ApiUtils getMyContacts:phoneNumbers success:^(NSMutableArray *contacts) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        self.contacts = contacts;
        
        for (Contact *contact in self.contacts) {
            contact.firstName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).firstName;
            contact.lastName = ((Contact *)[self.addressBookFormattedContacts objectForKey:contact.phoneNumber]).lastName;
        }
        
        self.addressBookFormattedContacts = nil;
        
        [self displayContacts];
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

- (void)displayContacts
{
    //TODO erase existing views
    
    NSUInteger contactCount = [self.contacts count];
    NSUInteger rows = [self.contacts count] / 3 + 1;
    float rowHeight = CONTACT_MARGIN + CONTACT_SIZE + CONTACT_NAME_HEIGHT;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    self.contactScrollView.contentSize = CGSizeMake(screenWidth, MIN(screenHeight - 20, rows * rowHeight + 2 * CONTACT_MARGIN));
    
    if ([self.contacts count] > 0) {
        Contact* contact = [self.contacts firstObject];
        
        ContactBubbleView *contactView = [[ContactBubbleView alloc] initWithContactBubble:contact andFrame:CGRectMake(2 * CONTACT_MARGIN + CONTACT_SIZE, CONTACT_MARGIN, CONTACT_SIZE, CONTACT_SIZE)];
        
        [self addNameLabelForView:contactView andContact:contact];
        
        contactView.image = [UIImage imageNamed:@"contact_placeholder.png"];
        
        [self.contactScrollView addSubview:contactView];
    }
    
    if ([self.contacts count] > 1) {
        Contact* contact = [self.contacts objectAtIndex:1];
        
        ContactBubbleView *contactView = [[ContactBubbleView alloc] initWithContactBubble:contact andFrame:CGRectMake(3 * CONTACT_MARGIN + 2 * CONTACT_SIZE, CONTACT_MARGIN, CONTACT_SIZE, CONTACT_SIZE)];
        
        [self addNameLabelForView:contactView andContact:contact];
        
        contactView.image = [UIImage imageNamed:@"contact_placeholder.png"];
        
        [self.contactScrollView addSubview:contactView];
    }
    
    for (NSUInteger i = 1; i < rows; i++) {
        if (contactCount > i * 3 - 1) {
            [self addContactViewForContactIndex:i horizontalPosition:0];
        }
        
        if (contactCount > i * 3) {
            [self addContactViewForContactIndex:i horizontalPosition:1];

        }
        
        if (contactCount > i * 3 + 1) {
            [self addContactViewForContactIndex:i horizontalPosition:2];
        }
    }
}

- (void)addContactViewForContactIndex:(NSUInteger)index horizontalPosition:(NSUInteger)position
{
    Contact* contact = [self.contacts objectAtIndex:(index*3 - 1 + position)];
    
    ContactBubbleView *contactView = [[ContactBubbleView alloc] initWithContactBubble:contact andFrame:CGRectMake((position + 1) *CONTACT_MARGIN + position * CONTACT_SIZE, index * (CONTACT_MARGIN + CONTACT_SIZE + CONTACT_NAME_HEIGHT) + CONTACT_MARGIN, CONTACT_SIZE, CONTACT_SIZE)];
    
    [self addNameLabelForView:contactView andContact:contact];
    
    contactView.image = [UIImage imageNamed:@"contact_placeholder.png"];
    
    [self.contactScrollView addSubview:contactView];

}

- (void)addNameLabelForView:(UIView *)contactView andContact:(Contact *)contact
{
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(contactView.frame.origin.x - CONTACT_MARGIN/4, contactView.frame.origin.y + CONTACT_SIZE, contactView.frame.size.width + CONTACT_MARGIN/2, CONTACT_NAME_HEIGHT)];
    
    
    
    nameLabel.text = [NSString stringWithFormat:@"%@ %@", contact.firstName ? contact.firstName : @"", contact.lastName ? contact.lastName : @""];
    nameLabel.font = [UIFont fontWithName:@"Avenir-Light" size:14.0];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.adjustsFontSizeToFitWidth = YES;
    nameLabel.minimumScaleFactor = 0.7;
    
    [self.contactScrollView addSubview:nameLabel];
}

- (IBAction)menuButtonClicked:(id)sender {
    self.menuActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self cancelButtonTitle:ACTION_SHEET_CANCEL
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:ACTION_SHEET_OPTION_1, ACTION_SHEET_OPTION_2, ACTION_SHEET_OPTION_3, nil];
    
    [self.menuActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:ACTION_SHEET_CANCEL]) {
        return;
    }
    
    //Add Friend
    if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_1]) {
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    //Share (in the future, it'd be cool to share a vocal message!)
    } else if ([buttonTitle isEqualToString:ACTION_SHEET_OPTION_2]) {
        NSString *shareString = @"Download Waved, the new vocal messaging app.";
        
        NSURL *shareUrl = [NSURL URLWithString:kProdAFHeardWebsite];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityViewController setValue:@"You should download Waved." forKey:@"subject"];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    //Feedback
    } else {
        NSString *email = [NSString stringWithFormat:@"mailto:%@?subject=Feedback for Waved on iOS (v%@)", kFeedbackEmail,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self dismissViewControllerAnimated:YES completion:^{
        //Check if phone is a contact and phone validity
        
        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
        firstName = firstName ? firstName : @"";
        lastName = lastName ? lastName : @"";
        
        if (!firstName && !lastName) {
            [GeneralUtils showMessage:@"Contact should have a first name or a last name." withTitle:nil];
            return;
        }
        
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        NSMutableArray *selectedContactFormattedPhoneNumbers = [[NSMutableArray alloc] init];
        NSMutableArray *selectedContactPhoneNumbers = [[NSMutableArray alloc] init];
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            
            [selectedContactPhoneNumbers addObject:phoneNumber];
            
            NSError *aError = nil;
            NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:&aError];
            
            if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
                Contact *contact = [Contact createContactWithId:0 phoneNumber:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]
                                                      firstName:firstName
                                                       lastName:lastName];
                
                [selectedContactFormattedPhoneNumbers addObject:contact.phoneNumber];
            }
        }
        
        //No phone number for selected contact
        if ([selectedContactPhoneNumbers count] == 0) {
            [GeneralUtils showMessage:[NSString stringWithFormat:@"We couldn't find any phone number for %@ %@.", firstName, lastName]  withTitle:nil];
            return;
        }
        
        //Check if not already in Waved contacts
        for (NSString *phoneNumber in selectedContactFormattedPhoneNumbers) {
            for (Contact *contact in self.contacts) {
                if ([contact.phoneNumber isEqualToString:phoneNumber]) {
                    [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ %@ is already your contact on Waved!", firstName, lastName]  withTitle:nil];
                    return;
                }
            }
        }
        
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"Download Waved, the new vocal messaging app, at %@", kProdAFHeardWebsite];
        viewController.recipients = selectedContactPhoneNumbers;
        viewController.messageComposeDelegate = self;
        
        
        [self presentViewController:viewController animated:YES completion:nil];
    }];
    
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
