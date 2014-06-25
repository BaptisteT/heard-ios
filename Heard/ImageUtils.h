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

+ (UIColor *)transparentRed;

+ (UIColor *)green;

+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side;

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

+ (NSString *)encodeToBase64String:(UIImage *)image;

@end
