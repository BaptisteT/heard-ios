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

@interface ContactView : UIView <UIGestureRecognizerDelegate>

- (id)initWithContact:(Contact *)contact andFrame:(CGRect)frame;
- (id)initWithContact:(Contact *)contact;

@property (strong, nonatomic) Contact *contact;
@property (weak, nonatomic) id <ContactBubbleViewDelegate> delegate;
@property (nonatomic) NSInteger discussionState;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic) NSInteger orderPosition;
@property (nonatomic) NSMutableArray *unreadMessages;
@property (nonatomic, strong) NSMutableArray *failedMessages;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL messageNotReadByContact;

- (void)addUnreadMessage:(Message *)message;
- (void)resetUnreadMessages;
- (void)message:(NSData *)audioData sentWithError:(BOOL)error;
- (void)deleteFailedMessages;
- (void)resendFailedMessages;
- (void)messageFinishPlaying;
- (void)resetDiscussionStateAnimated:(BOOL)animated;



@end

@protocol ContactBubbleViewDelegate

- (void)startedLongPressOnContactView:(ContactView *)contactView;

- (void)endedLongPressRecording;

- (void)sendMessageToContact:(ContactView *)contactView;

- (void)startedPlayingAudioMessagesOfView:(ContactView *)view;

- (void)pendingContactClicked:(Contact *)contact;

- (void)updateFrameOfContactView:(ContactView *)view;

- (void)endTutoMode;

- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration;

- (BOOL)isRecording;

- (void)failedMessagesModeTapGestureOnContact:(ContactView *)contactView;

- (void)endPlayerAtCompletion:(BOOL)completed;

- (void)playSound:(NSString *)sound;


@end
