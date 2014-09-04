//
//  CameraUtils.h
//  Heard
//
//  Created by Baptiste Truchot on 9/4/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraUtils : NSObject

+ (UIImagePickerController *)allocCameraWithSourceType:(UIImagePickerControllerSourceType)sourceType delegate:(id<UIImagePickerControllerDelegate>)delegate;

+ (void)addCircleOverlayToEditView:(UIViewController *)viewController;

@end
