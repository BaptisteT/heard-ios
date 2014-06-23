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
@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *countryCodeButton;
@property (strong, nonatomic) NBAsYouTypeFormatter *formatter;
@property (nonatomic) BOOL USRegionCode;

@end

@implementation RequestPhoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.USRegionCode = YES;
    self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    
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
    
    if (self.USRegionCode) {
        phoneNumber = [util parse:self.phoneTextField.text
        defaultRegion:@"US" error:&aError];
    } else {
        phoneNumber = [util parse:self.phoneTextField.text
                    defaultRegion:@"FR" error:&aError];
    }
    
    if (!aError && [util isValidNumber:phoneNumber]) {
        NSString *formattedPhoneNumber = [NSString stringWithFormat:@"+%@%@", phoneNumber.countryCode, phoneNumber.nationalNumber];
        [self sendCodeRequest:formattedPhoneNumber];
    } else {
        [GeneralUtils showMessage:nil withTitle:@"Invalid phone number"];
    }
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    if (self.USRegionCode) {
        self.USRegionCode = NO;
        self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"FR"];
        [self.countryCodeButton setTitle:@"+33" forState:UIControlStateNormal];
    } else {
        self.USRegionCode = YES;
        self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
        [self.countryCodeButton setTitle:@"+1" forState:UIControlStateNormal];
    }
    
    if (self.phoneTextField.text && [self.phoneTextField.text length] > 0) {
        self.phoneTextField.text = [self.formatter inputDigit:self.phoneTextField.text];
    }
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

@end
