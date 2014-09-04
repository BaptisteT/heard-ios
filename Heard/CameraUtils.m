//
//  CameraUtils.m
//  Heard
//
//  Created by Baptiste Truchot on 9/4/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CameraUtils.h"

@implementation CameraUtils

+ (UIImagePickerController *)allocCameraWithSourceType:(UIImagePickerControllerSourceType)sourceType delegate:(id<UINavigationControllerDelegate,UIImagePickerControllerDelegate>)delegate
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = delegate;
    imagePickerController.allowsEditing = YES;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    return imagePickerController;
}

+ (void)addCircleOverlayToEditView:(UIViewController *)viewController
{
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    UIView *plCropOverlay = [[[viewController.view.subviews objectAtIndex:1]subviews] objectAtIndex:0];
    plCropOverlay.hidden = YES;
    int position = 0;
    if (screenHeight == 568) {
        position = 124;
    } else {
        position = 80;
    }
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithOvalInRect:
                           CGRectMake(0.0f, position, 320.0f, 320.0f)];
    [path2 setUsesEvenOddFillRule:YES];
    
    [circleLayer setPath:[path2 CGPath]];
    
    [circleLayer setFillColor:[[UIColor clearColor] CGColor]];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 320, screenHeight-72) cornerRadius:0];
    
    [path appendPath:path2];
    [path setUsesEvenOddFillRule:YES];
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor blackColor].CGColor;
    fillLayer.opacity = 0.8;
    [viewController.view.layer addSublayer:fillLayer];
    
    UILabel *moveLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 10, 320, 50)];
    [moveLabel setText:@"Move and Scale"];
    [moveLabel setTextAlignment:NSTextAlignmentCenter];
    [moveLabel setTextColor:[UIColor whiteColor]];
    [moveLabel setFont:[UIFont systemFontOfSize:18]];
    
    [viewController.view addSubview:moveLabel];
}

@end
