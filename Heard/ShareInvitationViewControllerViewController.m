//
//  ShareInvitationViewControllerViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ShareInvitationViewControllerViewController.h"
#import "Constants.h"
#import "GeneralUtils.h"

@interface ShareInvitationViewControllerViewController ()
@property (weak, nonatomic) IBOutlet UILabel *toastLabel;

@end

@implementation ShareInvitationViewControllerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.invitationLink = @"http://waved.io/hFhdfj";
    self.toastLabel.alpha = 0;
    self.toastLabel.clipsToBounds = YES;
    self.toastLabel.layer.cornerRadius = 10;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)smsShare:(id)sender {
    if ([MFMessageComposeViewController canSendText]) {
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"%@ %@.",
                               NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"), self.invitationLink];
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

- (IBAction)emailShare:(id)sender {
    NSString *email = [NSString stringWithFormat:@"mailto:?subject=%@&body=%@ %@.",
                       NSLocalizedStringFromTable(@"invite_mail_subject",kStringFile, @"comment"),
                       NSLocalizedStringFromTable(@"invite_message",kStringFile, @"comment"), self.invitationLink];
    
    email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}

- (IBAction)linkShare:(id)sender {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:self.invitationLink];
    
    [self.toastLabel.layer removeAllAnimations];
    self.toastLabel.alpha = 0;
    
    [UIView animateWithDuration:1.0 animations:^{
        self.toastLabel.alpha = 1;
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 delay:1.5 options:UIViewAnimationOptionCurveLinear animations:^{
            self.toastLabel.alpha = 0;
        }completion:nil];
    }];
}

- (IBAction)facebookShare:(id)sender {
}

- (IBAction)twitterShare:(id)sender {
}

- (IBAction)whatsappShare:(id)sender {
}

@end
