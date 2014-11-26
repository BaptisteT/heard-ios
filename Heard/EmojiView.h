//
//  EmojiView.h
//  Heard
//
//  Created by Baptiste Truchot on 9/29/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmojiViewDelegateProtocol;

@interface EmojiView : UIImageView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<EmojiViewDelegateProtocol> delegate;
@property (nonatomic) NSString *identifier;

- (id)initWithIdentifier:(NSString *)identifier andFrame:(CGRect)frame;
- (CGRect)getInitialFrame;

@end

@protocol EmojiViewDelegateProtocol

- (void)updateEmojiOrPhotoLocation:(CGPoint)location;
- (void)emojiDropped:(EmojiView *)emojiView atLocation:(CGPoint)location;
- (void)playSound:(NSString *)sound ofType:(NSString *)type;
- (void)hideEmojiScrollViewAndDisplayEmoji:(EmojiView *)emojiView;

@end
