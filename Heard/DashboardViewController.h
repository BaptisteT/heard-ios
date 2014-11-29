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
#import <AddressBookUI/AddressBookUI.h>
#import "EmojiView.h"
#import "CreateGroupsViewController.h"
#import "InviteViewController.h"
#import "ManageGroupsViewController.h"
#import "PhotoView.h"
#import "CameraViewController.h"

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ContactBubbleViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, ABPersonViewControllerDelegate, EmojiViewDelegateProtocol, CreateGroupsVCDelegate, ManageGroupsVCDelegateProtocol, InviteViewControllerProtocol, PhotoViewDelegateProtocol,CameraVCDelegate, UIScrollViewDelegate>

- (BOOL)attributeMessageToExistingContacts:(Message *)message;
- (void)retrieveUnreadMessagesAndNewContacts;
- (void)endPlayerAtCompletion:(BOOL)completed;
- (void)removeViewOfHiddenContacts;
- (void)playSound:(NSString *)sound ofType:(NSString *)type completion:(void (^)(BOOL finished))completion;
- (void)message:(NSUInteger)messageId listenedByContact:(NSUInteger)contactId;
- (void)contact:(NSUInteger)contactId isRecording:(BOOL)flag;

@property (nonatomic) BOOL isSignUp;

@end
