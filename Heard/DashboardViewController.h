//
//  DashboardViewController.h
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import "Message.h"
#import "ContactView.h"

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate,MFMessageComposeViewControllerDelegate, ContactBubbleViewDelegate, ABNewPersonViewControllerDelegate>

- (void)addUnreadMessage:(Message *)message;
- (void) retrieveAndDisplayUnreadMessages;
- (void)requestAddressBookAccessAndRetrieveFriends;
- (void)displayContacts;
- (void)distributeNonAttributedMessages;

@property (nonatomic, strong) AVAudioPlayer *mainPlayer;

@end
