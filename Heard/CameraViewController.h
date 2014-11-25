//
//  CameraViewController.h
//  Heard
//
//  Created by Baptiste Truchot on 11/24/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CameraVCDelegate;

@interface CameraViewController : UIViewController <UINavigationControllerDelegate,UIImagePickerControllerDelegate,UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) id<CameraVCDelegate> delegate;
@property (strong, nonatomic) UITextView *photoDescriptionField;

@end

@protocol CameraVCDelegate

- (void)savePhoto:(UIImage *)image andText:(NSString *)text;

@end
