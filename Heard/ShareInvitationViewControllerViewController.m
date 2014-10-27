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
#import <FacebookSDK/FacebookSDK.h>
#import <MediaPlayer/MPMusicPlayerController.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioUtils.h"

@interface ShareInvitationViewControllerViewController ()
@property (weak, nonatomic) IBOutlet UILabel *toastLabel;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;

// Player
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic) BOOL isUsingHeadSet;

@property (nonatomic) BOOL firstOpening;

@end

@implementation ShareInvitationViewControllerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.firstOpening = YES;
    self.invitationLink = @"http://waved.io";
    self.toastLabel.alpha = 0;
    self.toastLabel.clipsToBounds = YES;
    self.toastLabel.layer.cornerRadius = 10;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.firstOpening) {
        self.firstOpening = NO;
        [self playPauseButtonClicked:nil];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

// ----------------------------------------------------------
#pragma mark Share options
// ----------------------------------------------------------

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

- (IBAction)copyLinkToClipboard:(id)sender {
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
    // Check if the Facebook app is installed and we can present
    // the message dialog
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
    params.link = [NSURL URLWithString:self.invitationLink];
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentMessageDialogWithParams:params]) {
        // Present message dialog
        [FBDialogs presentMessageDialogWithLink:[NSURL URLWithString:self.invitationLink]
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
                          self.invitationLink];
    
    whatsapp = [whatsapp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *whatsappURL = [NSURL URLWithString:whatsapp];
    if ([[UIApplication sharedApplication] canOpenURL: whatsappURL]) {
        [[UIApplication sharedApplication] openURL: whatsappURL];
    } else {
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"no_whatsapp_messenger",kStringFile,@"comment") withTitle:nil];
    }
}

// ----------------------------------------------------------
#pragma mark Player
// ----------------------------------------------------------

- (IBAction)playPauseButtonClicked:(id)sender {
    if (self.mainPlayer && [self.mainPlayer isPlaying]) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"invite-play"] forState:UIControlStateNormal];
        [self.mainPlayer pause];
    } else if (self.mainPlayer) {
        [self.playPauseButton setImage:[UIImage imageNamed:@"invite-pause"] forState:UIControlStateNormal];
        [self.mainPlayer play];
    } else {
        [self.playPauseButton setImage:[UIImage imageNamed:@"invite-pause"] forState:UIControlStateNormal];
        [self play];
    }
}

- (void)play
{
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:self.message error:nil];
    self.mainPlayer.delegate = self;
    [self.mainPlayer play];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag
{
    [self.playPauseButton setImage:[UIImage imageNamed:@"invite-play"] forState:UIControlStateNormal];
}

@end
