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
#import <MediaPlayer/MPMusicPlayerController.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioUtils.h"
#import "AddContactViewController.h"

@interface InviteViewController ()

@end

@implementation InviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
        //TODO BB track
    } else {
        //TODO BB track
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
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"no_whatsapp_messenger",kStringFile,@"comment") withTitle:nil];
    }
}

@end
