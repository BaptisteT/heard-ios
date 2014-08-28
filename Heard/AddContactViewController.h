//
//  AddContactViewController.h
//  Heard
//
//  Created by Bastien Beurier on 7/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CountryCodeViewController.h"
#import <MessageUI/MessageUI.h>

@protocol AddContactViewControllerDelegate;

@interface AddContactViewController : UIViewController <CountryCodeViewControllerDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id <AddContactViewControllerDelegate> delegate;

@end

@protocol AddContactViewControllerDelegate

- (void)didFinishedAddingContact:(NSString *)contactName;

@end