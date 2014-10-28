//
//  RequestUserInfoViewController.h
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RequestUserInfoViewController : UIViewController

@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *smsCode;
@property (strong, nonatomic) UIImage *profilePicture;

@end
