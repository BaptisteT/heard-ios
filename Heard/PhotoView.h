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
- (void)initPhotoView;


@end

@protocol PhotoViewDelegateProtocol

- (void)updateEmojiLocation:(CGPoint)location;
//- (void)emojiDropped:(EmojiView *)emojiView atLocation:(CGPoint)location;

@end