//
//  PhoneViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PhoneViewController.h"
#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"
#import "GeneralUtils.h"

@interface PhoneViewController ()
@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *counterCodeButton;
@property (strong, nonatomic) NBAsYouTypeFormatter *formatter;

@end

@implementation PhoneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.formatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:@"US"];
    
    self.phoneTextField.delegate = self;
    
    float borderSize = 0.5;
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.navigationContainer.frame.size.height - borderSize, self.navigationContainer.frame.size.width, borderSize);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.navigationContainer.layer addSublayer:bottomBorder];
    
    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.textFieldContainer.frame.size.height - borderSize, self.textFieldContainer.frame.size.width, borderSize);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.textFieldContainer.layer addSublayer:bottomBorder];
    
    CALayer *rightBorder = [CALayer layer];
    rightBorder.frame = CGRectMake(self.counterCodeButton.frame.size.width - borderSize, 0.0f, borderSize, self.counterCodeButton.frame.size.height);
    rightBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.counterCodeButton.layer addSublayer:rightBorder];
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
    NBPhoneNumber *phoneNumber = [util parse:self.phoneTextField.text
                            defaultRegion:@"US" error:&aError];
    
    if (!aError && [util isValidNumber:phoneNumber]) {
        [GeneralUtils showMessage:nil withTitle:[NSString stringWithFormat:@"VALID: %@", phoneNumber.nationalNumber]];
    } else {
        [GeneralUtils showMessage:nil withTitle:@"Invalid phone number"];
    }
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    
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
