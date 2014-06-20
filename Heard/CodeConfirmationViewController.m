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
#import "RequestUserInfoViewController.h"
#import "SessionUtils.h"

#define CONFIMATION_CODE_DIGITS 5
#define BORDER_SIZE 0.5

@interface CodeConfirmationViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (nonatomic) BOOL existingUser;

@end

@implementation CodeConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    if (textField.text.length + string.length == CONFIMATION_CODE_DIGITS && string.length > 0) {
        [self validateCode:[textField.text stringByAppendingString:string]];
    }
    
    return YES;
}

- (void)validateCode:(NSString *)code
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [ApiUtils validateSmsCode:code
                         phoneNumber:self.phoneNumber
                      success:^(NSString *authToken) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
                          
        if (authToken) {
            [SessionUtils securelySaveCurrentUserToken:authToken];
            [self performSegueWithIdentifier:@"Dashboard Push Segue From Code Confirmation" sender:nil];
        } else {
            [self performSegueWithIdentifier:@"Request User Info Push Segue" sender:nil];
        }
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:@"Invalid code, please try again." withTitle:nil];
        self.codeTextField.text = @"";
    }];
}

- (IBAction)nextButtonClicked:(id)sender {
    [self validateCode:self.codeTextField.text];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Request User Info Push Segue"]) {
        ((RequestUserInfoViewController *) [segue destinationViewController]).phoneNumber = self.phoneNumber;
        ((RequestUserInfoViewController *) [segue destinationViewController]).smsCode = self.codeTextField.text;
    }
}

@end
