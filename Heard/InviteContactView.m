//
//  InviteContactView.m
//  Heard
//
//  Created by Bastien Beurier on 9/19/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "InviteContactView.h"
#import "Constants.h"

@implementation InviteContactView

- (id)init
{
    self = [super initWithFrame:CGRectMake(kContactMargin, kContactMargin, kContactSize, kContactSize)];
    self.clipsToBounds = NO;
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.pictureIsLoaded = NO;
    
    // Init variables
    self.failedMessages = [NSMutableArray new];
    self.unreadMessages = [NSMutableArray new];
    self.isRecording = NO; self.isPlaying = NO; self.messageNotReadByContact = NO;
    self.sendingMessageCount = 0; self.loadingMessageCount = 0;
    
    // Image view
    [self initImageView];
    
    // Gesture recognisers
    [self initTapAndLongPressGestureRecognisers];
    
    // Init Discussion UI elements
    [self initRecordOverlay];
    
    return self;
}

- (void)setContactPicture
{
    self.imageView.image = [UIImage imageNamed:@"invite-button.png"];
}

- (void) initImageView {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self setContactPicture];
    [self addSubview:self.imageView];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.bounds.size.height/2;
}

- (void)sendRecording
{
    Message *message = [Message new];
    message.senderId = self.contact.identifier;
    message.audioData = [self.delegate getLastRecordedData];
    
    [self.delegate inviteContactsWithMessage:message];
}

@end