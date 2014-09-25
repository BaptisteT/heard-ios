//
//  PhoneViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "RequestPhoneViewController.h"
#import "GeneralUtils.h"
#import "CodeConfirmationViewController.h"
#import "ApiUtils.h"
#import "MBProgressHUD.h"
#import "RMPhoneFormat.h"
#import "AddressbookUtils.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "Constants.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define BORDER_SIZE 0.5
#define DEFAULT_COUNTRY @"USA"
#define DEFAULT_COUNTRY_CODE 1
#define DEFAULT_COUNTRY_LETTER_CODE @"us"


@interface RequestPhoneViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (nonatomic, strong) NSString *decimalPhoneNumber;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *tutoLabel;
@property (weak, nonatomic) IBOutlet UIView *countryNameContainer;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation RequestPhoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.decimalPhoneNumber = @"";
    
    [self setInitialCountryInfo];
    
    self.phoneTextField.delegate = self;
    
    //Weird bug on 3.5 screen screen
    if ([[UIScreen mainScreen] bounds].size.height>480.0f) {
        [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    }
    [GeneralUtils addBottomBorder:self.textFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addTopBorder:self.textFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addRightBorder:self.countryCodeButton borderSize:BORDER_SIZE];
    
    //Autoresize bug
    [self.tutoLabel sizeToFit];
    
    if([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)])
    {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {}];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.phoneTextField becomeFirstResponder];
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

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeButton.titleLabel.text substringFromIndex:1], self.decimalPhoneNumber];
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:nil error:&aError];
    
    if (aError || ![phoneUtil isValidNumber:myNumber]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"phone_number_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    }
    NSString *formattedPhoneNumber = [phoneUtil format:myNumber
                                          numberFormat:NBEPhoneNumberFormatE164
                                                 error:&aError];
    if (aError) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"phone_number_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    }
    
    [self sendCodeRequest:formattedPhoneNumber];
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Country Code Segue" sender:nil];
}


- (IBAction)countryNameButtonPressed:(UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case 1: // object pressed
        case 2:
            [self.countryNameContainer.layer setBackgroundColor:[UIColor lightGrayColor].CGColor];
            [self.countryNameContainer.layer setOpacity:0.4];
            break;
        case 3: // object released
            [self.countryNameContainer.layer setBackgroundColor:[UIColor clearColor].CGColor];
            [self.countryNameContainer.layer setOpacity:1];
            [self performSegueWithIdentifier:@"Country Code Segue" sender:nil];
            break;
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Code Confirmation Push Segue"]) {
        ((CodeConfirmationViewController *) [segue destinationViewController]).phoneNumber = (NSString *)sender;
    }
    
    if ([segueName isEqualToString: @"Country Code Segue"]) {
        ((CountryCodeViewController *) [segue destinationViewController]).delegate = self;
    }
}

- (void)sendCodeRequest:(NSString *)phoneNumber
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [ApiUtils requestSmsCode:phoneNumber retry:NO success:^() {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"Code Confirmation Push Segue" sender:phoneNumber];
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"confirmation_code_error_message",kStringFile,@"comment") withTitle:nil];
    }];
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
    
    return NO;
}

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode
{
    self.phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:letterCode];
    
    [self.countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", code] forState: UIControlStateNormal];
    self.phoneTextField.text = [self.phoneFormat format:self.decimalPhoneNumber];
    
    self.countryNameLabel.text = countryName;
}

@end
