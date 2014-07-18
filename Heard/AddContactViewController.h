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

@interface AddContactViewController : UIViewController <CountryCodeViewControllerDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate>

@end
