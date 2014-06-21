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

@interface DashboardViewController : UIViewController <UIAlertViewDelegate, UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate,MFMessageComposeViewControllerDelegate>

@end
