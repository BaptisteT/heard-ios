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
#import "RMPhoneFormat.h"
#import "RequestUserInfoViewController.h"
#import "SessionUtils.h"
#import "TrackingUtils.h"

#define CONFIMATION_CODE_DIGITS 4
#define BORDER_SIZE 0.5

@interface CodeConfirmationViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *textFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (nonatomic) BOOL existingUser;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic) NSTimeInterval countdownStart;
@property (weak, nonatomic) IBOutlet UILabel *resendLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainLabel;

@end

@implementation CodeConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.phoneNumberLabel.text = [[[RMPhoneFormat alloc] init] format:self.phoneNumber];
    
    self.codeTextField.delegate = self;
    
    //Weird bug on 3.5 screen screen
    if ([[UIScreen mainScreen] bounds].size.height>480.0f) {
        [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
    }
    [GeneralUtils addBottomBorder:self.textFieldContainer borderSize:BORDER_SIZE];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.countdownStart = CFAbsoluteTimeGetCurrent();
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCounter) userInfo:nil repeats:YES];
    
    [self.countdownTimer fire];
    
    [self.codeTextField becomeFirstResponder];
}

- (void)updateCounter
{
    NSInteger timeout = 2 * 60;
    
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval remainingTime = (self.countdownStart + timeout) - currentTime;
    
    if (remainingTime <= 0) {
        [self.countdownTimer invalidate];
        self.resendLabel.text = NSLocalizedStringFromTable(@"code_resent_label_text",@"strings",@"comment");
        self.timeRemainLabel.hidden = YES;
        
        [self.countdownTimer invalidate];
        
        [ApiUtils requestSmsCode:self.phoneNumber retry:YES success:nil failure:nil];
    } else {
        self.timeRemainLabel.text = [NSString stringWithFormat:@"%ld:%02ld", (NSInteger) floor(remainingTime/60), (NSInteger)remainingTime - (NSInteger) floor(remainingTime/60)*60];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    [self.countdownTimer invalidate];
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
                      success:^(NSString *authToken, Contact *contact) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
                          
        [self.countdownTimer invalidate];
                          
        if (authToken && contact != nil) {
            [SessionUtils securelySaveCurrentUserToken:authToken];
            [SessionUtils saveUserInfo:contact];
            
            [TrackingUtils identifyWithMixpanel:contact signup:NO];
            
            [self performSegueWithIdentifier:@"Dashboard Push Segue From Code Confirmation" sender:nil];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
        } else {
            [self performSegueWithIdentifier:@"Request User Info Push Segue" sender:nil];
        }
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"invalid_code_error_message",@"strings",@"comment") withTitle:nil];
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
