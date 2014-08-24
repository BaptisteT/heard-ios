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
#import "TrackingUtils.h"
#import "AddressbookUtils.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

#define INVITE_ADDED_CONTACT_ALERT_TITLE @"Invite recently added contact alert"
#define BORDER_WIDTH 0.5
#define ALERT_VIEW_DONE_BUTTON @"Done"
#define ALERT_VIEW_INVITE_BUTTON @"Invite"

#define DEFAULT_COUNTRY @"USA"
#define DEFAULT_COUNTRY_CODE 1
#define DEFAULT_COUNTRY_LETTER_CODE @"us"

@interface AddContactViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (weak, nonatomic) IBOutlet UIView *phoneNumberContainer;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (nonatomic, strong) NSString *decimalPhoneNumber;

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
    
    self.decimalPhoneNumber = @"";
    
    [self setInitialCountryInfo];
}

- (void)setInitialCountryInfo
{
    NSDictionary *letterCodeToCountryNameAndCallingCode = [AddressbookUtils getCountriesAndCallingCodesForLetterCodes];
    
    //Warning: need to convert to lower case to work with our file PhoneCountries.txt
    NSString *localLetterCode = [[[NSLocale currentLocale] objectForKey: NSLocaleCountryCode] lowercaseString];
    
    NSString *localCountry = [letterCodeToCountryNameAndCallingCode objectForKey:localLetterCode][0];
    NSNumber *localCallingCode = [letterCodeToCountryNameAndCallingCode objectForKey:localLetterCode][1];
    
    if (localLetterCode && localCountry && localCallingCode) {
        [self updateCountryName:localCountry code:localCallingCode letterCode:localLetterCode];
    } else {
        [self updateCountryName:DEFAULT_COUNTRY code:[NSNumber numberWithInt:DEFAULT_COUNTRY_CODE] letterCode:DEFAULT_COUNTRY_LETTER_CODE];
    }
}

- (IBAction)nextButtonClicked:(id)sender {
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeButton.titleLabel.text substringFromIndex:1], self.decimalPhoneNumber];
 
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:nil error:&aError];

    if (aError || ![phoneUtil isValidNumber:myNumber]) {
        [GeneralUtils showMessage:@"Invalid phone number." withTitle:nil];
        return;
    }
    NSString *formattedPhoneNumber = [phoneUtil format:myNumber
                                          numberFormat:NBEPhoneNumberFormatE164
                                                 error:&aError];
    if (aError) {
        [GeneralUtils showMessage:@"Invalid phone number." withTitle:nil];
        return;
    }
    
    if ((!self.firstNameField.text || [self.firstNameField.text length] == 0) &&
        (!self.lastNameField.text || [self.lastNameField.text length] == 0)) {
        [GeneralUtils showMessage:@"Please provide a first name or a last name." withTitle:nil];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [AddressbookUtils createOrEditContactWithDecimalNumber:(NSString *)self.decimalPhoneNumber
                                           formattedNumber:(NSString *)formattedPhoneNumber
                                                 firstName:(NSString *)self.firstNameField.text
                                                  lastName:(NSString *)self.lastNameField.text];
    
    NSString *contactName = self.firstNameField.text ? self.firstNameField.text : self.lastNameField.text;
    
    [ApiUtils checkUserPresenceByPhoneNumber:formattedPhoneNumber success:^(BOOL present){
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        //Already on Waved
        if (present) {
            [self dismissViewControllerAnimated:YES completion:^{
                [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ is now a contact.", contactName]
                                withTitle:nil];
                
                [self.delegate didFinishedAddingContact];
            }];
            
            [TrackingUtils trackAddContactSuccessful:YES Present:YES Pending:NO];
        //Not on Waved
        } else {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[NSString stringWithFormat:@"Successfully added. But %@ is not yet on Waved and will not be visible in your contacts. You should invite %@!", contactName, contactName]
                                       delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:ALERT_VIEW_DONE_BUTTON, ALERT_VIEW_INVITE_BUTTON, nil] show];
            
            [TrackingUtils trackAddContactSuccessful:YES Present:NO Pending:NO];
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
        self.decimalPhoneNumber = [self.decimalPhoneNumber stringByAppendingString:string];
    } else {
        NSString *newString = [[textField.text substringToIndex:range.location] stringByAppendingString:[textField.text substringFromIndex:range.location + range.length]];
        
        NSString *numberString = @"";
        
        for (int i=0; i<[newString length]; i++) {
            if (isdigit([newString characterAtIndex:i])) {
                numberString = [numberString stringByAppendingFormat:@"%c",[newString characterAtIndex:i]];
            }
        }
        
        self.decimalPhoneNumber = numberString;
    }
    
    textField.text = [self.phoneFormat format:self.decimalPhoneNumber];
    
    return NO;
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [TrackingUtils trackAddContactSuccessful:NO Present:NO Pending:NO];
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



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:ALERT_VIEW_INVITE_BUTTON] && [MFMessageComposeViewController canSendText]) {
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"Hey %@, let's start chatting on Waved! Download at %@", self.firstNameField.text ? self.firstNameField.text : self.lastNameField.text, kProdAFHeardWebsite];
        viewController.recipients = @[[self.countryCodeButton.titleLabel.text stringByAppendingString:self.decimalPhoneNumber]];
        viewController.messageComposeDelegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackInviteContacts:1 successful:YES justAdded:YES];
        
        [self dismissViewControllerAnimated:NO completion:^{
            [self dismissViewControllerAnimated:NO completion:^{
                [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ successfully invited.", self.firstNameField.text ? self.firstNameField.text : self.lastNameField.text]
                                withTitle:nil];
            }];
        }];
    } else {
        [TrackingUtils trackInviteContacts:1 successful:NO justAdded:YES];
        
        [self dismissViewControllerAnimated:NO completion:^{
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
    }
}

@end
