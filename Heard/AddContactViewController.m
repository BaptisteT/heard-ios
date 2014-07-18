//
//  AddContactViewController.m
//  Heard
//
//  Created by Bastien Beurier on 7/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AddContactViewController.h"
#import "GeneralUtils.h"
#import "SessionUtils.h"
#import <AddressBook/AddressBook.h>
#import "RMPhoneFormat.h"
#import "ApiUtils.h"
#import "MBProgressHUD.h"
#import "Constants.h"

#define INVITE_ADDED_CONTACT_ALERT_TITLE @"Invite recently added contact alert"
#define BORDER_WIDTH 0.5
#define ALERT_VIEW_DONE_BUTTON @"Done"
#define ALERT_VIEW_INVITE_BUTTON @"Invite"

@interface AddContactViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (weak, nonatomic) IBOutlet UIView *phoneNumberContainer;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (nonatomic, strong) NSString *rawPhoneNumber;

@end

@implementation AddContactViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_WIDTH];
    [GeneralUtils addBottomBorder:self.firstNameField borderSize:BORDER_WIDTH];
    [GeneralUtils addBottomBorder:self.lastNameField borderSize:BORDER_WIDTH];
    [GeneralUtils addBottomBorder:self.phoneNumberContainer borderSize:BORDER_WIDTH];
    [GeneralUtils addRightBorder:self.countryCodeButton borderSize:BORDER_WIDTH];
    
    self.firstNameField.delegate = self;
    self.lastNameField.delegate = self;
    self.phoneNumberField.delegate = self;
    
    [self.firstNameField becomeFirstResponder];
    
    self.rawPhoneNumber = @"";
    
    //TODO Put default country code
    [self updateCountryName:@"USA" code:[NSNumber numberWithInt:1] letterCode:@"us"];
}

- (IBAction)nextButtonClicked:(id)sender {    
    NSString *formattedPhoneNumber = [self.countryCodeButton.titleLabel.text stringByAppendingString:self.rawPhoneNumber];
    
    if (![self.phoneFormat isPhoneNumberValid:formattedPhoneNumber]) {
        [GeneralUtils showMessage:@"Invalid phone number." withTitle:nil];
        return;
    }
    
    if ((!self.firstNameField.text || [self.firstNameField.text length] == 0) &&
        (!self.lastNameField.text || [self.lastNameField.text length] == 0)) {
        [GeneralUtils showMessage:@"Please provide a first name or a last name." withTitle:nil];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self createOrEditContact:formattedPhoneNumber];
    
    NSString *contactName = self.firstNameField.text ? self.firstNameField.text : self.lastNameField.text;
    
    [ApiUtils checkUserPresenceByPhoneNumber:formattedPhoneNumber success:^(BOOL present){
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        //Already on Waved
        if (present) {
            [self dismissViewControllerAnimated:YES completion:^{
                [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ is now a contact.", contactName]
                                withTitle:nil];

            }];
        //Not on Waved
        } else {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:@"Successfully added! But %@ is not yet on Waved and will not be visible in your contacts. You should invite %@!", contactName, contactName]
                                       delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:ALERT_VIEW_DONE_BUTTON, ALERT_VIEW_INVITE_BUTTON, nil] show];

        }
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [GeneralUtils showMessage:[NSString stringWithFormat:@"Failed to add %@, please try again.", contactName]
                        withTitle:nil];
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField != self.phoneNumberField) return YES;
    
    if (string.length > 0) {
        self.rawPhoneNumber = [self.rawPhoneNumber stringByAppendingString:string];
    } else {
        NSString *newString = [[textField.text substringToIndex:range.location] stringByAppendingString:[textField.text substringFromIndex:range.location + range.length]];
        
        NSString *numberString = @"";
        
        for (int i=0; i<[newString length]; i++) {
            if (isdigit([newString characterAtIndex:i])) {
                numberString = [numberString stringByAppendingFormat:@"%c",[newString characterAtIndex:i]];
            }
        }
        
        self.rawPhoneNumber = numberString;
    }
    
    textField.text = [self.phoneFormat format:self.rawPhoneNumber];
    
    return NO;
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Country Code Segue From Add Contact" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;

    if ([segueName isEqualToString: @"Country Code Segue From Add Contact"]) {
        ((CountryCodeViewController *) [segue destinationViewController]).delegate = self;
    }
}

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode
{
    self.phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:letterCode];
    
    [self.countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", code] forState:UIControlStateNormal];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.firstNameField) {
        [self.lastNameField becomeFirstResponder];
    } else if (theTextField == self.lastNameField) {
        [self.phoneNumberField becomeFirstResponder];
    }
    
    return YES;
}

- (void)createOrEditContact:(NSString *)reformattedNumber
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
                NSString *numericalPhoneNumber = [[rawPhoneNumber componentsSeparatedByCharactersInSet:
                                          [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                                         componentsJoinedByString:@""];
                
                if ([numericalPhoneNumber rangeOfString:self.rawPhoneNumber].location != NSNotFound) {
                    match = YES;
                }
                
                if ([numericalPhoneNumber isEqualToString:[reformattedNumber substringFromIndex:1]]) {
                    duplicate = YES;
                }
            }
            
            //Save formatted phone number but do not duplicate
            if (match && !duplicate) {
                ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutableCopy (ABRecordCopyValue(person, kABPersonPhoneProperty));
                ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)reformattedNumber, kABPersonPhoneMobileLabel, NULL);
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
        
        if (self.firstNameField.text) {
            ABRecordSetValue(person, kABPersonFirstNameProperty, (__bridge CFTypeRef)self.firstNameField.text, &error);
        }
        
        if (self.lastNameField.text) {
            ABRecordSetValue(person, kABPersonLastNameProperty, (__bridge CFTypeRef)self.lastNameField.text, &error);
        }
        
        //Set phone number
        ABMutableMultiValueRef multiPhone =     ABMultiValueCreateMutable(kABMultiStringPropertyType);
        ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)reformattedNumber, kABPersonPhoneMobileLabel, NULL);
        ABRecordSetValue(person, kABPersonPhoneProperty, multiPhone,nil);
        CFRelease(multiPhone);
        
        ABAddressBookAddRecord(addressBook, person, &error);
        ABAddressBookSave(addressBook, &error);
        CFRelease(person);
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:ALERT_VIEW_INVITE_BUTTON]) {
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"Hey %@, let's start chating on Waved! Download at %@", self.firstNameField.text ? self.firstNameField.text : self.lastNameField.text, kProdAFHeardWebsite];
        viewController.recipients = @[[self.countryCodeButton.titleLabel.text stringByAppendingString:self.rawPhoneNumber]];
        viewController.messageComposeDelegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        //TODO track invite with property add success yes number 1
        
    } else {
        //TODO track invite with property add success no number 1
    }
    
    [self dismissViewControllerAnimated:NO completion:^{
        [self dismissViewControllerAnimated:NO completion:^{
            [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ successfully invited!", self.firstNameField.text ? self.firstNameField.text : self.lastNameField.text]
                            withTitle:nil];
        }];
    }];
}

@end
