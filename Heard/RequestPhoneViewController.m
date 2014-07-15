//
//  PhoneViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "RequestPhoneViewController.h"
#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"
#import "GeneralUtils.h"
#import "CodeConfirmationViewController.h"
#import "ApiUtils.h"
#import "MBProgressHUD.h"

#define BORDER_SIZE 0.5

@interface RequestPhoneViewController ()

@property (strong, nonatomic) NBAsYouTypeFormatter *formatter;
@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (strong, nonatomic) NBPhoneNumberUtil *util;
@property (weak, nonatomic) IBOutlet UIPickerView *countryCodePicker;
@property (strong, nonatomic) NSMutableDictionary *numericalToLetterCodes;
@property (strong, nonatomic) NSMutableArray *numericalCountryCodes;
@property (weak, nonatomic) IBOutlet UITextView *countryCodeInstructions;

@end

@implementation RequestPhoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"FR"];
    
    self.countryCodePicker.hidden = YES;
    self.countryCodeInstructions.hidden = YES;
    
    self.util = [NBPhoneNumberUtil sharedInstance];
    self.numericalToLetterCodes =  [[NSMutableDictionary alloc] init];
    self.numericalCountryCodes = [[NSMutableArray alloc] init];
    
    NSArray *regionLetterCodes = [NSLocale ISOCountryCodes];
    
    for (NSString *regionLetterCode in regionLetterCodes) {
        NSString *numericalCode = [[NBPhoneNumberUtil sharedInstance] countryCodeFromRegionCode:regionLetterCode];
        if (numericalCode) {
            NSNumber *code = [NSNumber numberWithLong:[numericalCode intValue]];
            
            if (![self.numericalCountryCodes containsObject:code]) {
                [self.numericalToLetterCodes setObject:regionLetterCode forKey:code];
                [self.numericalCountryCodes addObject:code];
            }
        }
    }
    
    //Order numericalCountryCodes
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [self.numericalCountryCodes sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    
    self.countryCodePicker.delegate = self;
    self.countryCodePicker.dataSource = self;
    
    self.phoneTextField.delegate = self;
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    [GeneralUtils addBottomBorder:self.textFieldContainer borderSize:BORDER_SIZE];
    [GeneralUtils addRightBorder:self.countryCodeButton borderSize:BORDER_SIZE];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.phoneTextField becomeFirstResponder];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    NSError *aError = nil;
    NBPhoneNumberUtil *util = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *phoneNumber;
    
    NSNumber *code = [self.numericalCountryCodes objectAtIndex:[self.countryCodePicker selectedRowInComponent:0]];
    NSString *letterCode = [self.numericalToLetterCodes objectForKey:code];
    
    phoneNumber = [util parse:self.phoneTextField.text
                defaultRegion:letterCode error:&aError];
    
    if (!aError && [util isValidNumber:phoneNumber]) {
        NSString *formattedPhoneNumber = [NSString stringWithFormat:@"+%@%@", phoneNumber.countryCode, phoneNumber.nationalNumber];
        [self sendCodeRequest:formattedPhoneNumber];
    } else {
        [GeneralUtils showMessage:nil withTitle:@"Invalid phone number"];
    }
}

- (IBAction)countryCodeButtonClicked:(id)sender {
//    self.countryCodePicker.hidden = NO;
//    self.countryCodeInstructions.hidden = NO;
//    
//    [self.phoneTextField endEditing:YES];
    
    [self performSegueWithIdentifier:@"Country Code Segue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Code Confirmation Push Segue"]) {
        ((CodeConfirmationViewController *) [segue destinationViewController]).phoneNumber = (NSString *)sender;
    }
}

- (void)sendCodeRequest:(NSString *)phoneNumber
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [ApiUtils requestSmsCode:phoneNumber success:^() {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"Code Confirmation Push Segue" sender:phoneNumber];
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:@"We failed to send your confirmation code, please try again." withTitle:nil];
    }];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.numericalCountryCodes count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"+%@",[self.numericalCountryCodes objectAtIndex:row]];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSNumber *code = [self.numericalCountryCodes objectAtIndex:row];
    NSString *letterCode = [self.numericalToLetterCodes objectForKey:code];
    
    [self.countryCodeButton setTitle:[NSString stringWithFormat:@"+%@", code] forState:UIControlStateNormal];
    
    self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:letterCode];

    NSString *currentFormattedPhoneNumber = self.phoneTextField.text;
    NSInteger currentFormattedPhoneNumberLength = [currentFormattedPhoneNumber length];
    
    if (currentFormattedPhoneNumber && currentFormattedPhoneNumber > 0) {
        for (NSInteger i = 0; i < currentFormattedPhoneNumberLength; i++) {
            self.phoneTextField.text = [self.formatter inputDigit:[currentFormattedPhoneNumber substringWithRange:NSMakeRange(i, 1)]];
        }
    }

}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.countryCodePicker.hidden = YES;
    self.countryCodeInstructions.hidden = YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (string.length > 0) {
        textField.text = [self.formatter inputDigit:string];
    } else {
        textField.text = [self.formatter removeLastDigit];
    }
    
    return NO;
}

@end
