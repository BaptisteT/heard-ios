//
//  ContactRequestViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 9/13/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ContactRequestViewController.h"
#import "Constants.h"
#import "GeneralUtils.h"
#import "PushRequestViewController.h"

@interface ContactRequestViewController ()
@property (weak, nonatomic) IBOutlet UIButton *contactAccessButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@end

@implementation ContactRequestViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.skipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    [self.contactAccessButton setTitle:NSLocalizedStringFromTable(@"contact_access_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
}

- (IBAction)skipButtonClicked:(id)sender {
    [self quitController];
}

- (IBAction)contactAccessButtonClicked:(id)sender {
    ABAddressBookRequestAccessWithCompletion([self.delegate addressBook], ^(bool granted, CFErrorRef error) {
        [self.delegate removeAllowContactButton];
        [self quitController];
    });
}

- (void)quitController
{
    if ([GeneralUtils pushNotifRequestSeen]) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self performSegueWithIdentifier:@"Push Request From Contact Request" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Push Request From Contact Request"]) {
        ((PushRequestViewController *) [segue destinationViewController]).dashboardViewController = (UIViewController *)self.delegate;
    }
}

@end
