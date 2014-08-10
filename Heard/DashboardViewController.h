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

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ContactBubbleViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AddContactViewControllerDelegate, AVAudioRecorderDelegate, ABPersonViewControllerDelegate, EditContactsVCDelegate>

- (BOOL)attributeMessageToExistingContacts:(Message *)message;
- (void)retrieveUnreadMessagesAndNewContacts;
- (void)distributeNonAttributedMessages;
- (void)endPlayerAtCompletion:(BOOL)completed;
- (void)removeViewOfHiddenContacts;
- (void)playSound:(NSString *)sound;

@property (nonatomic) BOOL isSignUp;

@end
