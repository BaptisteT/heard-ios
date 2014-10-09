//
//  ProfilePicViewController.h
//  Heard
//
//  Created by Bastien Beurier on 10/8/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfilePicViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *smsCode;

@end
