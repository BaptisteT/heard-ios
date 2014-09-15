//
//  PushRequestViewController.m
//  Heard
//
//  Created by Baptiste Truchot on 9/14/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PushRequestViewController.h"
#import "GeneralUtils.h"
#import "Constants.h"

@interface PushRequestViewController ()
@property (weak, nonatomic) IBOutlet UIButton *notifyMeButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@end

@implementation PushRequestViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.skipButton setTitle:NSLocalizedStringFromTable(@"skip_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
    [self.notifyMeButton setTitle:NSLocalizedStringFromTable(@"notify_me_button_title", kStringFile, @"comment") forState:UIControlStateNormal];
}

- (IBAction)skipButtonClicked:(id)sender {
    [self.navigationController popToViewController:self.dashboardViewController animated:YES];
}

- (IBAction)notifyMeButtonClicked:(id)sender {
    [GeneralUtils registerForRemoteNotif];
    [self.navigationController popToViewController:self.dashboardViewController animated:YES];
}

@end
