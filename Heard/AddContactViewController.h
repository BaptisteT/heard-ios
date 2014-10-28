//
//  AddContactViewController.h
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CountryCodeViewController.h"

@interface AddContactViewController : UIViewController <UITextFieldDelegate, CountryCodeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *contacts;

@end
