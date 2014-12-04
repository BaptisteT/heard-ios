//
//  ImageUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

+ (UIColor *)blue;

+ (UIColor *)transparentBlue;

+ (UIColor *)slightlyTransparentBlue;

+ (UIColor *)red;

+ (UIColor *)transparentRed;

+ (UIColor *)green;

+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side;

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

+ (NSString *)encodeToBase64String:(UIImage *)image;

+ (UIColor *)lightGreen;

+ (UIColor *)transparentGreen;

+ (UIColor *)transparentWhite;

+ (UIColor *)transparentBlack;

+ (void)setWithoutCachingImageView:(UIImageView *)imageView withURL:(NSURL *)url;

+ (CAShapeLayer *)createGradientCircleLayerWithFrame:(CGRect)frame
                                         borderWidth:(NSInteger)borderWidth
                                               Color:(UIColor *)color
                                        subDivisions:(NSInteger)nbSubDivisions;

+ (void)outerGlow:(UIView *)view;

@end
