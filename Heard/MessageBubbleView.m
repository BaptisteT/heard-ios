//
//  MessageBubbleView.m
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "MessageBubbleView.h"
#import "Message.h"
#import "GeneralUtils.h"
#import "UIImageView+AFNetworking.h"
#import "ApiUtils.h"

@interface MessageBubbleView()

@property (nonatomic) NSInteger senderId;
@property (nonatomic) NSInteger messageId;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation MessageBubbleView

- (id)initWithMessage:(Message *)message
{
    // Set profile picture
    self.senderId = message.senderId;
    self.messageId = message.identifier;
    [self setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:message.senderId]];
    
    // Alloc and add gesture recognisers
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;
    self.longPressRecognizer.minimumPressDuration = 0.;
    
    // Init player
    NSData* data = [NSData dataWithContentsOfURL:[message getMessageURL]] ;
    self.player = [[AVAudioPlayer alloc] initWithData:data error:nil];
    [self.player setDelegate:self];
    
    return self;
}


// ----------------------------------------------------------
// Handle Gestures
// ----------------------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.player play];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.player pause];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        // Mark as opened on the database
        [ApiUtils markMessageAsOpened:self.messageId success:nil failure:nil];
        
        // Remove from view
        [self removeFromSuperview];
        
        // todo BT
        // release
    }
}




@end
