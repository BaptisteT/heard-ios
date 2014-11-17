//
//  PhotoView.m
//  Heard
//
//  Created by Baptiste Truchot on 11/14/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PhotoView.h"
#import "Constants.h"

@interface PhotoView()

@property (nonatomic) CGRect initialFrame;
@property (nonatomic, strong) UIPanGestureRecognizer *panningRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation PhotoView

- (id)initPhotoView
{
    self = [super init];
    self.contentMode = UIViewContentModeScaleAspectFill;
    // todo BT
    // round
    
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
    self.clipsToBounds = YES;
    self.hidden = YES;
    return self;
}

- (void)handleTapGesture
{
    [self.delegate tutoMessage:NSLocalizedStringFromTable(@"photo_tuto_message",kStringFile,nil) withDuration:3 priority:NO];
}


- (void)handlePanningGesture:(UIPanGestureRecognizer *)recognizer
{
    static CGPoint initialCenter;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // todo BT
        // delegate poubelle
        initialCenter = self.center;
    }
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.superview];
        CGPoint location = [recognizer locationInView:self.superview];
        [self.delegate updateEmojiOrPhotoLocation:location];
        CGPoint newCenterPoint = CGPointMake(initialCenter.x + translation.x,initialCenter.y + translation.y);
        self.center = newCenterPoint;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGPoint mainViewCoordinate = [recognizer locationInView:self.superview.superview];
        [self.delegate photoDropped:self atLocation:mainViewCoordinate];
    }
}


@end
