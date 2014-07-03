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

@interface ContactView : UIView <UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

- (id)initWithContact:(Contact *)contact andFrame:(CGRect)frame;
- (id)initWithContact:(Contact *)contact;

@property (strong, nonatomic) Contact *contact;
@property (weak, nonatomic) id <ContactBubbleViewDelegate> delegate;
@property (nonatomic) BOOL pendingContact;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic) NSInteger orderPosition;
@property (nonatomic) NSMutableArray *unreadMessages;

- (void)addUnreadMessage:(Message *)message;
- (void)resetUnreadMessages;
- (void)recordingUI;
- (void)endRecordingUI;
- (void)playingUI;
- (void)endPlayingUI;

@end

@protocol ContactBubbleViewDelegate

- (void)longPressOnContactBubbleViewStarted:(NSUInteger)contactId FromView:(ContactView *)view;

- (void)longPressOnContactBubbleViewEnded:(NSUInteger)contactId;

- (void)notifiedNewMeters:(float)meters;

- (void)messageSentWithError:(BOOL)error;

- (void)startedPlayingAudioFileByView:(ContactView *)view;

- (void)quitRecordingModeAnimated:(BOOL)animated;

- (void)endPlayerUI;

- (void)pendingContactClicked:(Contact *)contact;

- (void)enableAllContactViews;

- (void)updateFrameOfContactView:(ContactView *)view;

@property (nonatomic, strong) AVAudioPlayer *mainPlayer;


@end
