//
//  ShareInvitationViewControllerViewController.h
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "Contact.h"
#import "ContactView.h"
#import <AddressBookUI/AddressBookUI.h>
#import "EditContactsViewController.h"

@protocol InviteViewControllerProtocol;

@interface InviteViewController : UIViewController <MFMessageComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, weak) id <InviteViewControllerProtocol> delegate;

@end

@protocol InviteViewControllerProtocol <EditContactsVCDelegate>

- (void)updateCurrentUserFirstName:(NSString *)firstName lastName:(NSString *)lastName picture:(UIImage *)picture;

@end
