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

#define BORDER_SIZE 0.5

@interface RequestUserInfoViewController ()

@property (weak, nonatomic) IBOutlet UIView *firstNameTextFieldContainer;
@property (weak, nonatomic) IBOutlet UIView *lastNameTextFieldContainer;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (strong, nonatomic) UIActionSheet *pictureActionSheet;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation RequestUserInfoViewController


// ----------------------
// Life Cycle
// ----------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f,
                                    self.firstNameTextFieldContainer.frame.size.height - BORDER_SIZE,
                                    self.firstNameTextFieldContainer.frame.size.width,
                                    BORDER_SIZE);
    
    bottomBorder.backgroundColor = [ImageUtils blue].CGColor;
    [self.firstNameTextFieldContainer.layer addSublayer:bottomBorder];
    
    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f,
                                    self.lastNameTextFieldContainer.frame.size.height - BORDER_SIZE,
                                    self.lastNameTextFieldContainer.frame.size.width,
                                    BORDER_SIZE);
    
    bottomBorder.backgroundColor = [ImageUtils blue].CGColor;
    [self.lastNameTextFieldContainer.layer addSublayer:bottomBorder];
    
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;
    
    // Prefill if possible
    NSString *ownerName = [[UIDevice currentDevice] name];
    ownerName =[ownerName stringByReplacingOccurrencesOfString:@"’" withString:@"'"];
    NSRange t = [ownerName rangeOfString:@"'s"];
    if (t.location != NSNotFound) {
        ownerName = [ownerName substringToIndex:t.location];
        NSArray *ownerNames = [ownerName componentsSeparatedByString:@" "];
        if (ownerNames.count == 1) {
            self.firstNameTextField.text = ownerNames[0];
            [self.lastNameTextField becomeFirstResponder];
        } else if (ownerNames.count == 2) {
            self.firstNameTextField.text = ownerNames[0];
            self.lastNameTextField.text = ownerNames[1];
        } else {
            [self.firstNameTextField becomeFirstResponder];
        }
    } else {
        [self.firstNameTextField becomeFirstResponder];
    }
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
    
    if (![GeneralUtils validName:self.firstNameTextField.text]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"first_name_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    } else if (![GeneralUtils validName:self.lastNameTextField.text]) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"last_name_error_message",kStringFile,@"comment") withTitle:nil];
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
    
    [ApiUtils createUserWithPhoneNumber:self.phoneNumber
                              firstName:self.firstNameTextField.text
                               lastName:self.lastNameTextField.text
                                picture:[ImageUtils encodeToBase64String:self.profilePicture]
                                   code:self.smsCode
                                success:successBlock failure:failureBlock];
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.firstNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
    } else if (theTextField == self.lastNameTextFieldContainer) {
        [self.lastNameTextField resignFirstResponder];
    }
    
    return YES;
}

@end
