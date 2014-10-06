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
    
    // User interaction
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.clipsToBounds = NO;
    self.layer.masksToBounds = NO;
    return self;
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
            initialCenter = self.center;
            initialCenter = recognizer.view.center;
            
            // play sound
            self.soundIndex ++;
            NSString *soundName = [NSString stringWithFormat:@"%@%lu.%lu",@"emoji-sound-",self.identifier,self.soundIndex];
            
            if(![[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"]) {
                self.soundIndex = 1;
                soundName = [NSString stringWithFormat:@"%@%lu.%lu",@"emoji-sound-",self.identifier,self.soundIndex];
            }
            
            [self.delegate playSound:soundName ofType:@"m4a"];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (isSlide) {
            CGPoint translation = [recognizer translationInView:recognizer.view.superview];
            newCenter = MIN( MAX(((UIScrollView *)self.superview).contentSize.width - self.window.frame.size.width,0),MAX(initialCenter.x - translation.x, 0));
            ((UIScrollView *)self.superview).contentOffset = CGPointMake(newCenter,0);
        } else {
            self.frame = CGRectMake(kEmojiSize * (self.identifier-1)+ kEmojiMargin * self.identifier, kEmojiMargin, kEmojiSize * 2, kEmojiSize * 2);

            
            CGPoint translation = [recognizer translationInView:recognizer.view.superview];
            recognizer.view.center = CGPointMake(initialCenter.x + translation.x,
                                                 initialCenter.y + translation.y);
            
            // Update contact views animations
            CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
            [self.delegate updateEmojiLocation:mainViewCoordinate];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (isSlide) {
            velocity = [recognizer velocityInView:self];
            if (fabs(velocity.x) > 100) {
                CGFloat finalCenter;
                int decelerationFactor = 3;
                
                if (velocity.x > 0) {
                    finalCenter = MAX(0, initialCenter.x - velocity.x /decelerationFactor);
                } else {
                    finalCenter = MIN(((UIScrollView *)self.superview).contentSize.width - self.window.frame.size.width, initialCenter.x - velocity.x /decelerationFactor);
                }

                NSTimeInterval duration = 0.5;
                [UIView animateWithDuration:duration delay:0
                                    options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState)
                                 animations:^ {
                                     ((UIScrollView *)self.superview).contentOffset = CGPointMake(finalCenter,0);
                                 }
                                 completion:NULL];
            }
        } else {
            CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
            [self.delegate emojiDropped:self atLocation:mainViewCoordinate];
        }
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
