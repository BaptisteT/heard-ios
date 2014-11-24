//
//  PhotoView.h
//  Heard
//
//  Created by Baptiste Truchot on 11/14/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PhotoViewDelegateProtocol;

@interface PhotoView : UIImageView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<PhotoViewDelegateProtocol> delegate;
- (id)initPhotoView;

@end

@protocol PhotoViewDelegateProtocol

- (void)updateEmojiOrPhotoLocation:(CGPoint)location;
- (void)photoDropped:(PhotoView *)photoView atLocation:(CGPoint)location;
- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration priority:(BOOL)prority;
- (CGRect)getPhotoViewFrame;
- (void)startDisplayBin;
@end