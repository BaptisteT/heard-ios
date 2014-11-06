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
@property (nonatomic) NSInteger identifier;
@property (nonatomic) NSInteger soundIndex;

- (id)initWithIdentifier:(NSInteger)identifier;
- (CGRect)getInitialFrame;

@end

@protocol EmojiViewDelegateProtocol

- (void)updateEmojiLocation:(CGPoint)location;
- (void)emojiDropped:(EmojiView *)emojiView atLocation:(CGPoint)location;
- (void)playSound:(NSString *)sound ofType:(NSString *)type;
- (void)hideEmojiScrollView;

@end
