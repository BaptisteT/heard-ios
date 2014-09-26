//
//  InviteContactsViewController.m
//  Heard
//
//  Created by Bastien Beurier on 7/16/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "InviteContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import "GeneralUtils.h"
#import "Constants.h"
#import "TrackingUtils.h"
#import <MediaPlayer/MPMusicPlayerController.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioUtils.h"
#import "MBProgressHUD.h"
#import "ApiUtils.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"

@interface InviteContactsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *playerButton;
@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *inviteButtonContainer;
@property (weak, nonatomic) IBOutlet UILabel *inviteButtonLabel;

@property (weak, nonatomic) InviteContactsTVC *inviteConctactsTVC;

@property (strong, nonatomic) NSMutableArray *selectedContacts;

// Player
@property (nonatomic, strong) AVAudioPlayer *mainPlayer;
@property (nonatomic) BOOL disableProximityObserver;
@property (nonatomic) BOOL isUsingHeadSet;

@property (nonatomic, strong) UIAlertView *inviteSuccessAlertView;

@property (nonatomic) BOOL firstOpening;

@end

@implementation InviteContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.firstOpening = YES;
    
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    self.backButton.titleLabel.text = NSLocalizedStringFromTable(@"back_button_title",kStringFile,@"comment");
    
    [self.playerButton setTitle:NSLocalizedStringFromTable(@"invite_play_button_title",kStringFile,@"comment") forState:UIControlStateNormal];
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:0.5];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inviteButtonClicked)];
    [self.inviteButtonContainer addGestureRecognizer:tapRecognizer];
    tapRecognizer.delegate = self;
    tapRecognizer.numberOfTapsRequired = 1;
    
    self.inviteButtonContainer.hidden = YES;
    
    self.selectedContacts = [[NSMutableArray alloc] init];
    
    // Add observers
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(routeChangeCallback:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(proximityStateDidChangeCallback)
                                                 name: UIDeviceProximityStateDidChangeNotification
                                               object: nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.firstOpening) {
        self.firstOpening = NO;
        [self playerButtonClicked:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove proximity state
    if ([UIDevice currentDevice].proximityState) {
        self.disableProximityObserver = YES;
    } else {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playerButtonClicked:(id)sender {
    if (self.mainPlayer && [self.mainPlayer isPlaying]) {
        [self.playerButton setTitle:NSLocalizedStringFromTable(@"invite_play_button_title",kStringFile,@"comment") forState:UIControlStateNormal];
        [self.mainPlayer pause];
    } else if (self.mainPlayer) {
        [self.playerButton setTitle:NSLocalizedStringFromTable(@"invite_pause_button_title",kStringFile,@"comment") forState:UIControlStateNormal];
        [self.mainPlayer play];
    } else {
        [self.playerButton setTitle:NSLocalizedStringFromTable(@"invite_pause_button_title",kStringFile,@"comment") forState:UIControlStateNormal];
        [self play];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Invite Contacts TVC Segue"]) {
        self.inviteConctactsTVC = [segue destinationViewController];
        self.inviteConctactsTVC.delegate = self;
    }
}

- (void)selectContactWithPhoneNumber:(NSString *)phoneNumber
{
    if (![self.selectedContacts containsObject:phoneNumber]) {
        [self.selectedContacts addObject:phoneNumber];
    }
    
    self.inviteButtonLabel.text = [NSString stringWithFormat:@"%@ (%ld)",NSLocalizedStringFromTable(@"invite_label_text",kStringFile,@"comment"), [self.selectedContacts count]];
    
    if ([self.selectedContacts count] == 1) {
        [self showInviteButton];
    }
}

- (void)deselectContactWithPhoneNumber:(NSString *)phoneNumber
{
    [self.selectedContacts removeObject:phoneNumber];
    
    self.inviteButtonLabel.text = [NSString stringWithFormat:@"%@ (%ld)",NSLocalizedStringFromTable(@"invite_label_text",kStringFile,@"comment"), [self.selectedContacts count]];
    
    if ([self.selectedContacts count] == 0) {
        [self hideInviteButton];
    }
}

- (void)showInviteButton
{
    [self.inviteButtonContainer.layer removeAllAnimations];
    
    self.inviteButtonContainer.frame = CGRectMake(self.inviteButtonContainer.frame.origin.x,
                                                  self.view.frame.size.height,
                                                  self.inviteButtonContainer.frame.size.width,
                                                  self.inviteButtonContainer.frame.size.height);
    self.inviteButtonContainer.hidden = NO;
    self.inviteButtonContainer.alpha = 1;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.inviteButtonContainer.frame = CGRectMake(self.inviteButtonContainer.frame.origin.x,
                                                      self.view.frame.size.height - self.inviteButtonContainer.frame.size.height,
                                                      self.inviteButtonContainer.frame.size.width,
                                                      self.inviteButtonContainer.frame.size.height);
    }];
}

- (void)hideInviteButton
{
    [self.inviteButtonContainer.layer removeAllAnimations];
    
    self.inviteButtonContainer.frame = CGRectMake(self.inviteButtonContainer.frame.origin.x,
                                                  self.view.frame.size.height - self.inviteButtonContainer.frame.size.height,
                                                  self.inviteButtonContainer.frame.size.width,
                                                  self.inviteButtonContainer.frame.size.height);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.inviteButtonContainer.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.inviteButtonContainer.hidden = YES;
        }
    }];
}

- (void)inviteButtonClicked
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSMutableArray *formattedContactPhoneNumbers = [NSMutableArray new];
    
    for (NSString *phoneNumber in self.selectedContacts) {
        NSError *aError = nil;
        
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        NBPhoneNumber *nbPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phoneNumber error:&aError];
        
        if (aError == nil && [phoneUtil isValidNumber:nbPhoneNumber]) {
            [formattedContactPhoneNumbers addObject:[NSString stringWithFormat:@"+%@%@", nbPhoneNumber.countryCode, nbPhoneNumber.nationalNumber]];
        }
    }
    
    [ApiUtils sendFutureMessage:self.message.audioData toFutureUsers:formattedContactPhoneNumbers success:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        if ([MFMessageComposeViewController canSendText]) {
            self.inviteSuccessAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"invite_messages_success_title",kStringFile,@"comment")
                                                                     message:NSLocalizedStringFromTable(@"invite_messages_success_message",kStringFile,@"comment")
                                                                    delegate:self
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
            
            [self.inviteSuccessAlertView show];
        } else {
            [GeneralUtils showMessage:NSLocalizedStringFromTable(@"text_access_error_message",kStringFile,@"comment") withTitle:nil];
        }
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        [GeneralUtils showMessage:NSLocalizedStringFromTable(@"send_invite_message_error_message",kStringFile,@"comment") withTitle:nil];
    }];
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (alertView == self.inviteSuccessAlertView) {
        //Redirect to sms
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = [NSString stringWithFormat:@"%@ %@ %@",NSLocalizedStringFromTable(@"invite_text_message_one",kStringFile,@"comment"),kProdAFHeardWebsite,NSLocalizedStringFromTable(@"invite_text_message_two",kStringFile,@"comment")];
        viewController.recipients = self.selectedContacts;
        viewController.messageComposeDelegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];

    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.inviteConctactsTVC dismissSearch];
    [self.inviteConctactsTVC deselectAll];
    
    self.inviteButtonContainer.hidden = YES;
    
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackInviteContacts:[self.selectedContacts count] successful:YES justAdded:NO];
    } else {
        [TrackingUtils trackInviteContacts:[self.selectedContacts count] successful:NO justAdded:NO];
    }
}

- (void)play
{
    // Min volume (legal / deprecated ?)
    MPMusicPlayerController *appPlayer = [MPMusicPlayerController applicationMusicPlayer];
    if (appPlayer.volume < 0.5) {
        [appPlayer setVolume:0.5];
    }
    
    // Set loud speaker and proximity check
    self.disableProximityObserver = NO;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    self.mainPlayer = [[AVAudioPlayer alloc] initWithData:self.message.audioData error:nil];
    self.mainPlayer.delegate = self;
    [self.mainPlayer play];
}

// ----------------------------------------------------------
#pragma mark Observer callback
// ----------------------------------------------------------

-(void)routeChangeCallback:(NSNotification*)notification {
    self.isUsingHeadSet = [AudioUtils usingHeadsetInAudioSession:[AVAudioSession sharedInstance]];
}

- (void)setIsUsingHeadSet:(BOOL)isUsingHeadSet {
    _isUsingHeadSet = isUsingHeadSet;
    [self proximityStateDidChangeCallback];
}

- (void)proximityStateDidChangeCallback {
    BOOL success; NSError* error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (self.isUsingHeadSet || [UIDevice currentDevice].proximityState ) {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    } else {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (self.disableProximityObserver) {
            [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        }
    }
    if (!success)
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag
{
    [self.playerButton setTitle:NSLocalizedStringFromTable(@"invite_play_button_title",kStringFile,@"comment") forState:UIControlStateNormal];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
