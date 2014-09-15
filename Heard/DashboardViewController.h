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
#import "AddContactViewController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "EditContactsViewController.h"
#import "ContactRequestViewController.h"

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ContactBubbleViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AddContactViewControllerDelegate, AVAudioRecorderDelegate, ABPersonViewControllerDelegate, EditContactsVCDelegate, ContactRequestVCDelegate>

- (BOOL)attributeMessageToExistingContacts:(Message *)message;
- (void)retrieveUnreadMessagesAndNewContacts;
- (void)distributeNonAttributedMessages;
- (void)endPlayerAtCompletion:(BOOL)completed;
- (void)removeViewOfHiddenContacts;
- (void)playSound:(NSString *)sound;
- (void)message:(NSUInteger)messageId listenedByContact:(NSUInteger)contactId;

@property (nonatomic) BOOL isSignUp;

@end
