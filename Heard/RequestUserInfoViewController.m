//
//  RequestUserInfoViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "RequestUserInfoViewController.h"
#import "GeneralUtils.h"
#import "ImageUtils.h"
#import "MBProgressHUD.h"
#import "SessionUtils.h"
#import "ApiUtils.h"
#import "TrackingUtils.h"
#import "DashboardViewController.h"
#import "Constants.h"

@interface RequestUserInfoViewController ()

@property (weak, nonatomic) IBOutlet UITextField *fullNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation RequestUserInfoViewController


// ----------------------
// Life Cycle
// ----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Prefill if possible
    NSString *ownerName = [[UIDevice currentDevice] name];
    ownerName =[ownerName stringByReplacingOccurrencesOfString:@"’" withString:@"'"];
    NSRange t = [ownerName rangeOfString:@"'s"];
    if (t.location != NSNotFound) {
        self.fullNameTextField.text = [ownerName substringToIndex:t.location];
    }
    
    [self.fullNameTextField becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Dashboard Push Segue"]) {
        ((DashboardViewController *) [segue destinationViewController]).isSignUp = YES;
    }
}

// ----------------------
// Button Pressed
// ----------------------

- (IBAction)nextButtonPressed:(id)sender {
    
    if (![GeneralUtils validFullname:self.fullNameTextField.text]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"full_name_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    }
    
    [self signupUser];
}

- (void)signupUser
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    typedef void (^SuccessBlock)(NSString *authToken, Contact *contact);
    SuccessBlock successBlock = ^(NSString *authToken, Contact *contact) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [SessionUtils securelySaveCurrentUserToken:authToken];
        [SessionUtils saveUserInfo:contact];
        
        [TrackingUtils identifyWithMixpanel:contact signup:YES];

        [self performSegueWithIdentifier:@"Dashboard Push Segue" sender:nil];
    };
    
    typedef void (^FailureBlock)();
    FailureBlock failureBlock = ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"sign_up_error_message",kStringFile,@"comment") withTitle:nil];
    };
    
    NSString *firstName;
    NSString *lastName;
    
    NSArray *names = [self.fullNameTextField.text componentsSeparatedByString:@" "];
    
    firstName = names[0];
    
    lastName = @"";
    
    NSInteger i = 1;
    
    while (i < names.count) {
        if (i == 1) {
            lastName = names[i];
        } else {
            lastName = [NSString stringWithFormat:@"%@ %@", lastName, names[i]];
        }
        
        i++;
    }
    
    [ApiUtils createUserWithPhoneNumber:self.phoneNumber
                              firstName:firstName
                               lastName:lastName
                                picture:[ImageUtils encodeToBase64String:self.profilePicture]
                                   code:self.smsCode
                                success:successBlock failure:failureBlock];
}

@end
