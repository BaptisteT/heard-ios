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
#import "ProfilePicViewController.h"
#import "SessionUtils.h"
#import "TrackingUtils.h"
#import "Constants.h"
#import "HeardAppDelegate.h"

#define IS_IPHONE_4 ([UIScreen mainScreen].bounds.size.height < 568?YES:NO)

#define CONFIMATION_CODE_DIGITS 4
#define BORDER_SIZE 0.5

@interface CodeConfirmationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (weak, nonatomic) IBOutlet UITextView *smsInstructionLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (nonatomic) BOOL existingUser;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic) NSTimeInterval countdownStart;
@property (weak, nonatomic) IBOutlet UILabel *resendLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainLabel;
@property (weak, nonatomic) IBOutlet UIImageView *firstImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thirdImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fourthImageView;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdLabel;
@property (weak, nonatomic) IBOutlet UILabel *fourthLabel;
@property (strong, nonatomic) NSArray *labels;
@property (strong, nonatomic) NSArray *imageViews;

@end

@implementation CodeConfirmationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.phoneNumberLabel.text = [[[RMPhoneFormat alloc] init] format:self.phoneNumber];
    
    self.codeTextField.delegate = self;
    
    self.firstImageView.clipsToBounds = YES;
    self.secondImageView.clipsToBounds = YES;
    self.thirdImageView.clipsToBounds = YES;
    self.fourthImageView.clipsToBounds = YES;
    
    self.firstImageView.layer.cornerRadius = self.firstImageView.bounds.size.height/2;
    self.secondImageView.layer.cornerRadius = self.firstImageView.bounds.size.height/2;
    self.thirdImageView.layer.cornerRadius = self.firstImageView.bounds.size.height/2;
    self.fourthImageView.layer.cornerRadius = self.firstImageView.bounds.size.height/2;
    
    self.codeTextField.hidden = YES;
    
    self.labels = @[self.firstLabel, self.secondLabel, self.thirdLabel, self.fourthLabel];
    self.imageViews = @[self.firstImageView, self.secondImageView, self.thirdImageView, self.fourthImageView];
    
    self.firstLabel.text = @"";
    self.secondLabel.text = @"";
    self.thirdLabel.text = @"";
    self.fourthLabel.text = @"";
    
    if (IS_IPHONE_4) {
        self.phoneNumberLabel.hidden = YES;
        self.resendLabel.hidden = YES;
        self.timeRemainLabel.hidden = YES;
    }
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
        self.resendLabel.text = NSLocalizedStringFromTable(@"code_resent_label_text",kStringFile,@"comment");
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
    NSInteger nbrOfChar = 0;
    
    if (string.length < 1) {
        nbrOfChar = MAX(0, textField.text.length - 1);
    } else {
         nbrOfChar = textField.text.length + string.length;
    }
    
    for (NSInteger i = 0; i < CONFIMATION_CODE_DIGITS; i++) {
        if (i > nbrOfChar - 1) {
            ((UIImageView *)[self.imageViews objectAtIndex:i]).image = [UIImage imageNamed:@"light-blue-square"];
            ((UILabel *)[self.labels objectAtIndex:i]).text = @"";
        } else {
            ((UIImageView *)[self.imageViews objectAtIndex:i]).image = [UIImage imageNamed:@"dark-blue-square"];
            
            NSRange range;
            range.location = i;
            range.length = 1;
            
            ((UILabel *)[self.labels objectAtIndex:i]).text = [[textField.text stringByAppendingString:string] substringWithRange:range];
        }
    }
    
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
        } else {
            [self performSegueWithIdentifier:@"Profile Picture Push Segue" sender:nil];
        }
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"invalid_code_error_message",kStringFile,@"comment") withTitle:nil];
        self.codeTextField.text = @"";
        
        for (NSInteger i = 0; i < CONFIMATION_CODE_DIGITS; i++) {
            ((UIImageView *)[self.imageViews objectAtIndex:i]).image = [UIImage imageNamed:@"light-blue-square"];
            ((UILabel *)[self.labels objectAtIndex:i]).text = @"";
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Profile Picture Push Segue"]) {
        ((ProfilePicViewController *) [segue destinationViewController]).phoneNumber = self.phoneNumber;
        ((ProfilePicViewController *) [segue destinationViewController]).smsCode = self.codeTextField.text;
    }
}

@end
