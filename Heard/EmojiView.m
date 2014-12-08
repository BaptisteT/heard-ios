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
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) CGRect initialFrame;

@end

@implementation EmojiView

- (id)initWithIdentifier:(NSString *)identifier andFrame:(CGRect)frame
{
    self.initialFrame = frame;

    self.identifier = identifier;
    self = [super initWithFrame:frame];
    [self addEmojiImage];
    
    self.panningRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanningGesture:)];
    [self addGestureRecognizer:self.panningRecognizer];
    self.panningRecognizer.delegate = self;
    
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
    NSString *soundName = [NSString stringWithFormat:@"emoji-%@",self.identifier];
    
    if(![[NSBundle mainBundle] pathForResource:soundName ofType:@"mp3"]) {
        soundName = @"emoji-1f60a";
    }
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.05];
    [animation setRepeatCount:INFINITY];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint: CGPointMake([self center].x - 2.0f, [self center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint: CGPointMake([self center].x + 2.0f, [self center].y)]];
    
    [self.delegate playSound:soundName ofType:@"mp3" completion:^(BOOL completed){
        [self.layer removeAllAnimations];
    }];
    
    [self.delegate tutoMessage:@"Drag emoji to send." withDuration:1 priority:YES bottom:NO];
    
    [[self layer] addAnimation:animation forKey:@"position"];
}

- (void)handlePanningGesture:(UIPanGestureRecognizer *)recognizer
{
    static CGPoint initialCenter;
    static BOOL isSlide = FALSE;
    CGPoint velocity; CGFloat newCenter = 0;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        velocity = [recognizer velocityInView:self];
        if (- velocity.y < fabs(velocity.x) / 2 ) {
            isSlide = TRUE;
            initialCenter = ((UIScrollView *)self.superview).contentOffset;
        } else {
            isSlide = FALSE;
            [self.delegate hideEmojiScrollViewAndDisplayEmoji:self];
        }
    }
    
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (isSlide) {
            CGPoint translation = [recognizer translationInView:recognizer.view.superview];
            newCenter = MIN( MAX(((UIScrollView *)self.superview).contentSize.width - self.window.frame.size.width,0),MAX(initialCenter.x - translation.x, 0));
            ((UIScrollView *)self.superview).contentOffset = CGPointMake(newCenter,0);
        } else {
            CGPoint location = [recognizer locationInView:recognizer.view.superview];
            recognizer.view.center = location;
            // Update contact views animations
            CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview.superview];
            [self.delegate updateEmojiLocation:mainViewCoordinate];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (isSlide) {
            velocity = [recognizer velocityInView:self];
            CGFloat finalOffset;
            
            if (fabs(velocity.x) > 100) {
                if (velocity.x > 0) {
                    finalOffset = 0;
                } else {
                    finalOffset = self.superview.frame.size.width;
                }
            } else {
                if (((UIScrollView *)self.superview).contentOffset.x > self.superview.frame.size.width/2) {
                    finalOffset = self.superview.frame.size.width;
                } else {
                    finalOffset = 0;
                }
            }
            
            CGRect frame = ((UIScrollView *)self.superview).frame;
            frame.origin.x = finalOffset;
            frame.origin.y = 0;
            [((UIScrollView *)self.superview) scrollRectToVisible:frame animated:YES];
            
        } else {
            CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
            [self.delegate emojiDropped:self atLocation:mainViewCoordinate];
        }
    }
}

- (void)addEmojiImage
{
    self.image = [UIImage imageNamed:self.identifier];
}

- (CGRect)getInitialFrame {
    return self.initialFrame;
}

@end
