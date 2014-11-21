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
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    if (viewController.view.subviews.count > 1) { // bug fabrik
        UIView *plCropOverlay = [[[viewController.view.subviews objectAtIndex:1]subviews] objectAtIndex:0];
        plCropOverlay.hidden = YES;
        int position = (screenHeight - screenWidth + 10)/2;
        
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        UIBezierPath *path2 = [UIBezierPath bezierPathWithOvalInRect:
                               CGRectMake(0.0f, position, screenWidth, screenWidth)];
        [path2 setUsesEvenOddFillRule:YES];
        
        [circleLayer setPath:[path2 CGPath]];
        
        [circleLayer setFillColor:[[UIColor clearColor] CGColor]];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, screenWidth, screenHeight-72) cornerRadius:0];
        
        [path appendPath:path2];
        [path setUsesEvenOddFillRule:YES];
        
        CAShapeLayer *fillLayer = [CAShapeLayer layer];
        fillLayer.path = path.CGPath;
        fillLayer.fillRule = kCAFillRuleEvenOdd;
        fillLayer.fillColor = [UIColor blackColor].CGColor;
        fillLayer.opacity = 0.8;
        [viewController.view.layer addSublayer:fillLayer];
        
        UILabel *moveLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 10, screenWidth, 50)];
        [moveLabel setText:@"Move and Scale"];
        [moveLabel setTextAlignment:NSTextAlignmentCenter];
        [moveLabel setTextColor:[UIColor whiteColor]];
        [moveLabel setFont:[UIFont systemFontOfSize:18]];
        
        [viewController.view addSubview:moveLabel];
    }
}

@end
