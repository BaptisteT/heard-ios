//
//  EmojiView.m
//  Heard
//
//  Created by Baptiste Truchot on 9/29/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "EmojiView.h"
#import "Constants.h"

@interface EmojiView()

@property (nonatomic, strong) UIPanGestureRecognizer *panningRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation EmojiView

- (id)initWithIdentifier:(NSInteger)identifier
{
    self.identifier = identifier;
    self.soundIndex = 0;
    self = [super initWithFrame:[self getInitialFrame]];
    self.identifier = identifier;
    [self addEmojiImage];
    
    self.panningRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanningGesture:)];
    [self addGestureRecognizer:self.panningRecognizer];
    self.panningRecognizer.delegate = self;
    
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanningGesture:)];
    [self addGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;
    self.longPressRecognizer.minimumPressDuration = 0.5;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    [self addGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer.delegate = self;
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    
    // User interaction
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.clipsToBounds = NO;
    self.layer.masksToBounds = NO;
    return self;
}

- (void)handleTapGesture
{
    // play sound
    self.soundIndex ++;
    NSString *soundName = [NSString stringWithFormat:@"%@%lu.%lu",@"emoji-sound-",(long)self.identifier,(long)self.soundIndex];
    
    if(![[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"]) {
        self.soundIndex = 1;
        soundName = [NSString stringWithFormat:@"%@%lu.%lu",@"emoji-sound-",(long)self.identifier,(long)self.soundIndex];
    }
    [self.delegate playSound:soundName ofType:@"m4a"];
}

- (void)handlePanningGesture:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.frame = CGRectMake(self.superview.frame.origin.x + self.frame.origin.x - kEmojiSize/2, self.superview.frame.origin.y + self.frame.origin.y - kEmojiSize/2, kEmojiSize * 2, kEmojiSize * 2);
        [self.delegate hideEmojiScrollViewAndDisplayEmoji:self];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [recognizer locationInView:recognizer.view.superview];
        recognizer.view.center = location;
        // Update contact views animations
        CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview.superview];
        [self.delegate updateEmojiOrPhotoLocation:mainViewCoordinate];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
        [self.delegate emojiDropped:self atLocation:mainViewCoordinate];
    }
}

- (void)addEmojiImage
{
    self.image = [UIImage imageNamed:[@"emoji-image-" stringByAppendingFormat:@"%lu",self.identifier]];
}

- (CGRect)getInitialFrame {
    return CGRectMake(kEmojiSize * (self.identifier-1)+ kEmojiMargin * self.identifier, kEmojiMargin, kEmojiSize, kEmojiSize);
}

@end
