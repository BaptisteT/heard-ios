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
@property (nonatomic) NSInteger identifier;

@end

@implementation EmojiView

- (id)initWithIdentifier:(NSInteger)identifier
{
    CGRect frame = CGRectMake(kEmojiSize * (identifier-1)+ kEmojiMargin * identifier, kEmojiMargin, kEmojiSize, kEmojiSize);
    self = [super initWithFrame:frame];
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
            NSString *soundName = [NSString stringWithFormat:@"%@%lu",@"emoji-sound-",self.identifier];
            [self.delegate playSound:soundName ofType:@"m4a"];
        }
    }
    if (isSlide) {
        CGPoint translation = [recognizer translationInView:recognizer.view.superview];
        newCenter = MIN( MAX(((UIScrollView *)self.superview).contentSize.width - self.window.frame.size.width,0),MAX(initialCenter.x - translation.x, 0));
        ((UIScrollView *)self.superview).contentOffset = CGPointMake(newCenter,0);
    } else {
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [recognizer translationInView:recognizer.view.superview];
            recognizer.view.center = CGPointMake(initialCenter.x + translation.x,
                                                 initialCenter.y + translation.y);
            
            // Update contact views animations
            CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
            [self.delegate updateEmojiLocation:mainViewCoordinate];
        }
        else if (recognizer.state == UIGestureRecognizerStateEnded) {
            recognizer.view.center = initialCenter;
            CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
            [self.delegate emojiDropped:self.identifier atLocation:mainViewCoordinate];
        }
    }
}

- (void)addEmojiImage
{
    self.image = [UIImage imageNamed:[@"emoji-image-" stringByAppendingFormat:@"%lu",self.identifier]];
}

@end
