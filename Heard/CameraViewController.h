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

@property (strong, nonatomic) id<CameraVCDelegate> delegate;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *text;
@property (nonatomic) float textPosition;

@end

@protocol CameraVCDelegate

- (void)savePhoto:(UIImage *)image text:(NSString *)text andTextPosition:(float)textPosition;

@end
