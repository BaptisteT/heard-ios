//
//  CodeConfirmationViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CodeConfirmationViewController.h"
#import "ApiUtils.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"

#define CONFIMATION_CODE_DIGITS 5

@interface CodeConfirmationViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (strong, nonatomic) NSString *userCode;
@property (strong, nonatomic) NSString *serverCode;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@end

@implementation CodeConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self requestConfirmationCode];
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NBPhoneNumber *myNumber = [phoneUtil parse:self.phoneNumber
                                 defaultRegion:@"US" error:nil];

    
    self.phoneNumberLabel.text = [phoneUtil format:myNumber
                                      numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                             error:nil];
    
    self.codeTextField.delegate = self;
    
    float borderSize = 0.5;
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.navigationContainer.frame.size.height - borderSize, self.navigationContainer.frame.size.width, borderSize);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.navigationContainer.layer addSublayer:bottomBorder];
    
    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.textFieldContainer.frame.size.height - borderSize, self.textFieldContainer.frame.size.width, borderSize);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.textFieldContainer.layer addSublayer:bottomBorder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.codeTextField becomeFirstResponder];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length + string.length >= CONFIMATION_CODE_DIGITS) {
        self.userCode = [textField.text stringByAppendingString:string];
        
        if (self.serverCode) {
            if (![self validateCode]){
                return NO;
            };
        } else {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
    
    return YES;
}

- (void)requestConfirmationCode
{
    [ApiUtils requestSignupCode:self.phoneNumber success:^(NSString *code) {
        self.serverCode = code;
        
        if (self.userCode) {
            [self validateCode];
        }
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:@"We failed to send your confirmation code, please try again." withTitle:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}

- (BOOL)validateCode
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if ([self.userCode intValue] == [self.serverCode intValue]) {
        [GeneralUtils showMessage:@"VALIIIID" withTitle:nil];
        return YES;
    } else {
        [GeneralUtils showMessage:@"Invalid code, please try again." withTitle:nil];
        self.codeTextField.text = @"";
        return NO;
    }
}

@end
