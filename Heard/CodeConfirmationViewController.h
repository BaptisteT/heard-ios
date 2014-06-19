//
//  CodeConfirmationViewController.h
//  Heard
//
//  Created by Bastien Beurier on 6/18/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CodeConfirmationViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSString *phoneNumber;

@end
