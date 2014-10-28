//
//  AddContactViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "AddContactViewController.h"
#import "RMPhoneFormat.h"
#import "NBPhoneNumberUtil.h"
#import "AddressbookUtils.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "Contact.h"
#import "UsernameViewController.h"

#define DEFAULT_COUNTRY @"USA"
#define DEFAULT_COUNTRY_CODE 1
#define DEFAULT_COUNTRY_LETTER_CODE @"us"

@interface AddContactViewController ()

@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (nonatomic, strong) NSString *decimalPhoneNumber;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *tutoLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *searchButton;
@property (strong, nonatomic) NSString *formattedNumber;

@end

@implementation AddContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchButton.hidden = YES;
    
    self.decimalPhoneNumber = @"";
    
    [self setInitialCountryInfo];
    
    self.phoneTextField.delegate = self;
    
    //Autoresize bug
    [self.tutoLabel sizeToFit];
    
    if ([self.phoneTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor lightTextColor];
        self.phoneTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.phoneTextField.placeholder attributes:@{NSForegroundColorAttributeName: color}];
    }

}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.phoneTextField becomeFirstResponder];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
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

- (IBAction)validationButtonClicked:(id)sender {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeButton.titleLabel.text substringFromIndex:1], self.decimalPhoneNumber];
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:nil error:&aError];
    
    if (aError || ![phoneUtil isValidNumber:myNumber]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"phone_number_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    } else {
        NSString *formattedPhoneNumber = [phoneUtil format:myNumber
                                              numberFormat:NBEPhoneNumberFormatE164
                                                     error:&aError];
        
        //Todo BB: search for user 1. Go back if no user 2. Alert if user (segue to add first name - last name)
        
        NSInteger count = [self.contacts count];
        
        for (NSInteger i = 0; i < count; i++) {
            if ([((Contact *)[self.contacts objectAtIndex:i]).phoneNumber isEqualToString:formattedPhoneNumber]) {
                [GeneralUtils showMessage:[NSString stringWithFormat:@"%@ (%@ %@).",
                                           NSLocalizedStringFromTable(@"user_already_a_contact",kStringFile,@"comment"),
                                           ((Contact *)[self.contacts objectAtIndex:i]).firstName,
                                           ((Contact *)[self.contacts objectAtIndex:i]).lastName]
                                withTitle:@""];
                 
                 return;
            }
        }
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [ApiUtils checkUserPresenceByPhoneNumber:formattedPhoneNumber success:^(BOOL present){
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            //Already on Waved
            if (present) {
                
                self.formattedNumber = formattedPhoneNumber;

                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"add_contact_user_found_title",kStringFile,@"comment")
                                            message:NSLocalizedStringFromTable(@"add_contact_user_found_message",kStringFile,@"comment")
                                           delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Add Contact", nil] show];
                
            } else {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"add_contact_not_waved_user_title",kStringFile,@"comment")
                                            message:NSLocalizedStringFromTable(@"add_contact_not_waved_user_message",kStringFile,@"comment")
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }
        } failure:^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"add_contact_failure_message",kStringFile,@"comment")  withTitle:@""];
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self performSegueWithIdentifier:@"Username Modal Segue From Add Contact" sender:nil];
    }
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Country Code Segue From Add Contact" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Country Code Segue From Add Contact"]) {
        ((CountryCodeViewController *) [segue destinationViewController]).delegate = self;
    } else if ([segueName isEqualToString: @"Username Modal Segue From Add Contact"]) {
        ((UsernameViewController *) [segue destinationViewController]).formattedNumber = self.formattedNumber;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
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
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeButton.titleLabel.text substringFromIndex:1], self.decimalPhoneNumber];
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:nil error:&aError];
    
    if (aError || ![phoneUtil isValidNumber:myNumber]) {
        self.searchButton.hidden = YES;
    } else {
        self.searchButton.hidden = NO;
    }
    
    return NO;
}

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode
{
    self.phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:letterCode];
    
    [self.countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", code] forState: UIControlStateNormal];
    self.phoneTextField.text = [self.phoneFormat format:self.decimalPhoneNumber];
    
    self.countryNameLabel.text = [letterCode uppercaseString];
}

@end
