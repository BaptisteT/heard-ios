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
- (id)initWithIdentifier:(NSInteger)identifier;

@end

@protocol EmojiViewDelegateProtocol

- (void)updateEmojiLocation:(CGPoint)location;
- (void)emojiDropped:(NSInteger)emojiId atLocation:(CGPoint)location;
- (void)playSound:(NSString *)sound ofType:(NSString *)type;

@end
