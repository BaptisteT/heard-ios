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

@interface InviteContactsViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;
@property (weak, nonatomic) IBOutlet UIView *inviteButtonContainer;
@property (weak, nonatomic) IBOutlet UILabel *inviteButtonLabel;

@property (weak, nonatomic) InviteContactsTVC *inviteConctactsTVC;

@property (strong, nonatomic) NSMutableArray *selectedContacts;

@end

@implementation InviteContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:0.5];
    
    [GeneralUtils addTopBorder:self.inviteButtonContainer borderSize:0.5];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inviteButtonClicked)];
    [self.inviteButtonContainer addGestureRecognizer:tapRecognizer];
    tapRecognizer.delegate = self;
    tapRecognizer.numberOfTapsRequired = 1;
    
    self.inviteButtonContainer.hidden = YES;
    
    self.selectedContacts = [[NSMutableArray alloc] init];
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectAllButtonClicked:(id)sender {
    [self.inviteConctactsTVC selectAll];
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
    
    self.inviteButtonLabel.text = [NSString stringWithFormat:@"Invite to Waved (%ld)", [self.selectedContacts count]];
    
    if ([self.selectedContacts count] == 1) {
        [self.inviteButtonContainer.layer removeAllAnimations];
        
        self.inviteButtonContainer.frame = CGRectMake(self.inviteButtonContainer.frame.origin.x,
                                                      self.view.frame.size.height,
                                                      self.inviteButtonContainer.frame.size.width,
                                                      self.inviteButtonContainer.frame.size.height);
        self.inviteButtonContainer.hidden = NO;
        
        [UIView animateWithDuration:0.5 animations:^{
            self.inviteButtonContainer.frame = CGRectMake(self.inviteButtonContainer.frame.origin.x,
                                                          self.view.frame.size.height - self.inviteButtonContainer.frame.size.height,
                                                          self.inviteButtonContainer.frame.size.width,
                                                          self.inviteButtonContainer.frame.size.height);
        }];
    }
}

- (void)deselectContactWithPhoneNumber:(NSString *)phoneNumber
{
    [self.selectedContacts removeObject:phoneNumber];
    
    NSLog(@"COUNT: %ld", [self.selectedContacts count]);
    
    self.inviteButtonLabel.text = [NSString stringWithFormat:@"Invite to Waved (%ld)", [self.selectedContacts count]];
    
    if ([self.selectedContacts count] == 0) {
        [self.inviteButtonContainer.layer removeAllAnimations];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.inviteButtonContainer.frame = CGRectMake(self.inviteButtonContainer.frame.origin.x,
                                                          self.view.frame.size.height,
                                                          self.inviteButtonContainer.frame.size.width,
                                                          self.inviteButtonContainer.frame.size.height);
        }];
    }
}

- (void)inviteButtonClicked
{
    //Redirect to sms
    MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
    viewController.body = [NSString stringWithFormat:@"Let's start chatting on Waved! Download at %@", kProdAFHeardWebsite];
    viewController.recipients = self.selectedContacts;
    viewController.messageComposeDelegate = self;
    
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackInviteContacts:[self.selectedContacts count] successful:YES justAdded:NO];
        
        [self.inviteConctactsTVC deselectAll];
    } else {
        [TrackingUtils trackInviteContacts:[self.selectedContacts count] successful:NO justAdded:NO];
    }
}


@end
