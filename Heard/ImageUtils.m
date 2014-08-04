//
//  ImageUtils.m
//  Heard
//
//  Created by Bastien Beurier on 6/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ImageUtils.h"
#import "UIImageView+AFNetworking.h"

#define DEGREES_TO_RADIANS(x) (x)/180.0*M_PI
#define RADIANS_TO_DEGREES(x) (x)/M_PI*180.0

@implementation ImageUtils

+ (UIColor *)blue
{
    return [UIColor colorWithRed:14/256.0 green:78/256.0 blue:173/256.0 alpha:1];
}

+ (UIColor *)transparentBlue
{
    return [UIColor colorWithRed:14/256.0 green:78/256.0 blue:173/256.0 alpha:0.25];
}

+ (UIColor *)red
{
    return [UIColor colorWithRed:231/256.0 green:29/256.0 blue:37/256.0 alpha:1.0];
}

+ (UIColor *)transparentRed
{
    return [UIColor colorWithRed:231/256.0 green:29/256.0 blue:37/256.0 alpha:0.25];
}


+ (UIColor *)green
{
    return [UIColor colorWithRed:52/256.0 green:180/256.0 blue:74/256.0 alpha:1.0];
}

+ (UIColor *)lightGreen
{
    return [UIColor colorWithRed:152/256.0 green:251/256.0 blue:152/256.0 alpha:1];
}

+ (UIColor *)transparentGreen
{
    return [UIColor colorWithRed:52/256.0 green:180/256.0 blue:74/256.0 alpha:0.25];
}

+ (UIColor *)transparentWhite
{
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
}

+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side
{
    // Get size of current image
    CGSize size = [image size];
    if( size.width == size.height && size.width == side){
        return image;
    }
    
    CGSize newSize = CGSizeMake(side, side);
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.height / image.size.height;
        delta = ratio*(image.size.width - image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.width;
        delta = ratio*(image.size.height - image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width),
                                 (ratio * image.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImageJPEGRepresentation(image,0.9) base64EncodedStringWithOptions:0];
}

+ (void)setWithoutCachingImageView:(UIImageView *)imageView withURL:(NSURL *)url
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    request.cachePolicy=NSURLRequestReloadIgnoringCacheData;
    [imageView setImageWithURLRequest:request placeholderImage:nil success:nil failure:nil];
}

+ (CAShapeLayer *)createGradientCircleLayerWithFrame:(CGRect)frame
                                         borderWidth:(NSInteger)borderWidth
                                               Color:(UIColor *)color
                                        subDivisions:(NSInteger)nbSubDivisions
{
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    CGFloat red, green, blue, alpha, subAlpha = 0, startAngle = 0, endAngle = DEGREES_TO_RADIANS(360)/nbSubDivisions;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CAShapeLayer *containingLayer = [CAShapeLayer new];
    containingLayer.frame = frame;
    
    for (int i=0; i<nbSubDivisions; i++) {
        CAShapeLayer *subLayer = [CAShapeLayer new];
        subLayer.frame = frame;
        subLayer.fillColor = [UIColor clearColor].CGColor;
        subLayer.lineWidth = borderWidth;
        subLayer.strokeColor = [UIColor colorWithRed:red green:green blue:blue alpha:subAlpha].CGColor;

        subLayer.path = [UIBezierPath bezierPathWithArcCenter:center
                                                                      radius:frame.size.width/2
                                                                  startAngle:startAngle
                                                                    endAngle:endAngle
                                                                   clockwise:YES].CGPath;
        [containingLayer addSublayer:subLayer];
                                
        // Prepare next subdiv
        subAlpha += alpha / nbSubDivisions;
        startAngle = endAngle;
        endAngle += DEGREES_TO_RADIANS(360)/nbSubDivisions;
    }
    return containingLayer;
}

@end
