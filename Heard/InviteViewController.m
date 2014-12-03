//
//  ShareInvitationViewControllerViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "InviteViewController.h"
#import "Constants.h"
#import "GeneralUtils.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AddContactViewController.h"
#import "TrackingUtils.h"
#import "SessionUtils.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "ImageUtils.h"
#import "ImageUtils.h"
#import "CameraUtils.h"
#import "EditContactsViewController.h"

#define NO_MESSAGE_VIEW_HEIGHT 40
#define NO_MESSAGE_VIEW_WIDTH 280

@interface InviteViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) UIView *tutoView;
@property (nonatomic, strong) UILabel *tutoViewLabel;

@end

@implementation InviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tutoView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - NO_MESSAGE_VIEW_WIDTH/2, self.view.bounds.size.height - 4 * NO_MESSAGE_VIEW_HEIGHT, NO_MESSAGE_VIEW_WIDTH, NO_MESSAGE_VIEW_HEIGHT)];
    
    self.tutoView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.tutoView.clipsToBounds = YES;
    self.tutoView.layer.cornerRadius = 5;
    
    self.tutoViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, NO_MESSAGE_VIEW_WIDTH, NO_MESSAGE_VIEW_HEIGHT)];
    self.tutoViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0];
    self.tutoViewLabel.textAlignment = NSTextAlignmentCenter;
    self.tutoViewLabel.textColor = [UIColor whiteColor];
    self.tutoViewLabel.backgroundColor = [UIColor clearColor];
    [self.tutoView addSubview:self.tutoViewLabel];
    [self.view addSubview:self.tutoView];
    self.tutoView.alpha = 0;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// ----------------------------------------------------------
#pragma mark Share options
// ----------------------------------------------------------

- (IBAction)smsShare:(id)sender {
    if ([MFMessageComposeViewController canSendText]) {
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"%@ %@.",
                               NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"), kProdAFHeardWebsite];
        viewController.messageComposeDelegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];

    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"text_access_error_message",kStringFile,@"comment") withTitle:nil];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackInvite:@"SMS" Success:@"True"];
    } else {
        [TrackingUtils trackInvite:@"SMS" Success:@"False"];
    }
}
- (IBAction)AddContactButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Add Contact Modal Segue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString:@"Add Contact Modal Segue"]) {
        ((AddContactViewController *) [segue destinationViewController]).contacts = self.contacts;
    }
}


- (IBAction)emailShare:(id)sender {
    NSString *email = [NSString stringWithFormat:@"mailto:?subject=%@&body=%@ %@.",
                       NSLocalizedStringFromTable(@"invite_mail_subject",kStringFile, @"comment"),
                       NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"), kProdAFHeardWebsite];
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    
    [TrackingUtils trackInvite:@"Email" Success:@""];
}

- (IBAction)facebookShare:(id)sender {
    // Check if the Facebook app is installed and we can present
    // the message dialog
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link = [NSURL URLWithString:kProdAFHeardWebsite];
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentMessageDialogWithParams:params]) {
        // Present message dialog
        [FBDialogs presentMessageDialogWithLink:[NSURL URLWithString:kProdAFHeardWebsite]
                                        handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                            if(error) {
                                                [GeneralUtils showMessage:NSLocalizedStringFromTable(@"fb_messenger_error",kStringFile,@"comment") withTitle:nil];
                                            }
                                        }];
        
        [TrackingUtils trackInvite:@"Facebook" Success:@""];
    }  else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"no_fb_messenger",kStringFile,@"comment") withTitle:nil];
    }
}

- (IBAction)whatsappShare:(id)sender {
    NSString *whatsapp = [NSString stringWithFormat:@"whatsapp://send?text=%@ %@.",
                       NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"),
                          kProdAFHeardWebsite];
    
    whatsapp = [whatsapp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *whatsappURL = [NSURL URLWithString:whatsapp];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
        
        [TrackingUtils trackInvite:@"Whatsapp" Success:@""];
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"no_whatsapp_messenger",kStringFile,@"comment") withTitle:nil];
    }
}

@end
