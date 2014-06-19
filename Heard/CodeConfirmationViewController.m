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
#define BORDER_SIZE 0.5

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
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    [GeneralUtils addBottomBorder:self.textFieldContainer borderSize:BORDER_SIZE];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.codeTextField becomeFirstResponder];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
        //TODO BB: save phoneNumber
        //TODO BB: if signin, go to main screen directly
        [self performSegueWithIdentifier:@"Request User Info Push Segue" sender:nil];
        
        return YES;
    } else {
        [GeneralUtils showMessage:@"Invalid code, please try again." withTitle:nil];
        self.codeTextField.text = @"";
        return NO;
    }
}

- (IBAction)nextButtonClicked:(id)sender {
    self.userCode = self.codeTextField.text;
    
    if (self.serverCode) {
        [self validateCode];
    } else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

@end
