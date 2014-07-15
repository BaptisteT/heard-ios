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
#import "EZAudioPlotGL.h"
#import "EZMicrophone.h"

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate,MFMessageComposeViewControllerDelegate, ContactBubbleViewDelegate, ABNewPersonViewControllerDelegate, UIGestureRecognizerDelegate, EZMicrophoneDelegate>

- (BOOL)addUnreadMessageToExistingContacts:(Message *)message;
- (void) retrieveUnreadMessagesAndNewContacts;
- (void)displayContacts;
- (void)distributeNonAttributedMessages;
- (NSTimeInterval)delayBeforeRecording;

@property (nonatomic) BOOL isSignUp;

@end
