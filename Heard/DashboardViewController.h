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
#import "AddContactViewController.h"
#import <AddressBookUI/AddressBookUI.h>

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ContactBubbleViewDelegate, UIGestureRecognizerDelegate, EZMicrophoneDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AddContactViewControllerDelegate, AVAudioRecorderDelegate, ABPersonViewControllerDelegate>

- (BOOL)attributeMessageToExistingContacts:(Message *)message;
- (void) retrieveUnreadMessagesAndNewContacts;
- (void)distributeNonAttributedMessages;
- (void)endPlayerUIAnimated:(BOOL)animated;

@property (nonatomic) BOOL isSignUp;

@end
