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
@property (nonatomic, strong) NSMutableArray *failedMessages;


- (void)addUnreadMessage:(Message *)message;
- (void)resetUnreadMessages;
- (void)startRecordingUI;
- (void)endRecordingPlayingUI;
- (void)startPlayingUI;
- (void)message:(NSData *)audioData sentWithError:(BOOL)error;
- (void)deleteFailedMessages;
- (void)startLoadingAnimationWithStrokeColor:(UIColor *)color;



@end

@protocol ContactBubbleViewDelegate

- (void)startedLongPressOnContactView:(ContactView *)contactView;

- (void)endedLongPressOnContactView:(ContactView *)contactView;

- (void)sendMessageToContact:(ContactView *)contactView;

- (void)startedPlayingAudioFileByView:(ContactView *)view;

- (void)pendingContactClicked:(Contact *)contact;

- (void)updateFrameOfContactView:(ContactView *)view;

- (void)endTutoMode;

- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration;

- (BOOL)isRecording;

- (void)failedMessagesModeTapGestureOnContact:(ContactView *)contactView;

@end
