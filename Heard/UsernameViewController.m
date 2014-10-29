//
//  UsernameViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/27/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "UsernameViewController.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "AddressbookUtils.h"
#import "TrackingUtils.h"

#define BORDER_SIZE 0.5

@interface UsernameViewController ()

@property (weak, nonatomic) IBOutlet UITextField *fullNameTextField;

@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.fullNameTextField becomeFirstResponder];
    
    NSLog(@"Formatted number %@", self.formattedNumber);
}
- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)nextButtonPressed:(id)sender {
    if (self.fullNameTextField.text.length == 0) {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"full_name_error_message",kStringFile,@"comment") withTitle:nil];
        return;
    }
    
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
    
    [AddressbookUtils createContactWithFormattedNumber:self.formattedNumber
                                             firstName:firstName
                                              lastName:lastName];
    
    [GeneralUtils showMessage:NSLocalizedStringFromTable(@"add_contact_success_message",kStringFile,@"comment") withTitle:@""];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [TrackingUtils trackAddContact];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}
@end
