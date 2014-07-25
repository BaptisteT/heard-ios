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
@property (nonatomic) BOOL pendingContact;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic) NSInteger orderPosition;
@property (nonatomic) NSMutableArray *unreadMessages;
@property (nonatomic, strong) NSData *nextMessageAudioData;
@property (nonatomic) NSUInteger nextMessageId;


- (void)addUnreadMessage:(Message *)message;
- (void)resetUnreadMessages;
- (void)startRecordingUI;
- (void)endRecordingPlayingUI;
- (void)startPlayingUI;


@end

@protocol ContactBubbleViewDelegate

- (void)startedLongPressOnContactView:(ContactView *)contactView;

- (void)endedLongPressOnContactView:(ContactView *)contactView;

- (void)sendRecordtoContact:(Contact *)contact;

- (void)startedPlayingAudioFileByView:(ContactView *)view;

- (void)quitRecordingModeAnimated:(BOOL)animated;

- (void)pendingContactClicked:(Contact *)contact;

- (void)updateFrameOfContactView:(ContactView *)view;

- (void)endTutorialMode;

- (void)tutorialModeWithDuration:(NSTimeInterval)duration;

- (void)recordSound;

- (BOOL)isRecording;

- (NSTimeInterval)delayBeforeRecording;

- (void)doubleTappedOnContactView:(ContactView *)contactView;


@end
