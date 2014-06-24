//
//  FriendBubbleView.h
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Contact.h"
#import "Message.h"

@protocol ContactBubbleViewDelegate;

@interface ContactBubbleView : UIView <UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

- (id)initWithContactBubble:(Contact *)contact andFrame:(CGRect)frame;

@property (strong, nonatomic) Contact *contact;
@property (weak, nonatomic) id <ContactBubbleViewDelegate> delegate;
@property (nonatomic) BOOL pendingContact;

- (void)addUnreadMessage:(Message *)message;
- (void)resetUnreadMessages;

- (void)addActiveOverlay;
- (void)removeActiveOverlay;

@end

@protocol ContactBubbleViewDelegate

- (void)longPressOnContactBubbleViewStarted:(NSUInteger)contactId FromView:(ContactBubbleView *)view;

- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId;

- (void)notifiedNewMeters:(float)meters;

- (void)messageSentWithError:(BOOL)error;

- (void)startedPlayingAudioFileByView:(ContactBubbleView *)view;

- (void)quitRecodingModeAnimated:(BOOL)animated;

- (void)quitPlayerMode;

- (void)pendingContactClicked:(Contact *)contact;

@property (nonatomic, strong) AVAudioPlayer *mainPlayer;


@end
