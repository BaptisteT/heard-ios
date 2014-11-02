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

@interface ContactView : UIView <UIGestureRecognizerDelegate, UIAlertViewDelegate>

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
@property (nonatomic) BOOL pictureIsLoaded;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL messageNotReadByContact;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) NSInteger sendingMessageCount;
@property (nonatomic) NSInteger loadingMessageCount;

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer;
- (void)addUnreadMessage:(Message *)message;
- (void)resetUnreadMessages;
- (void)message:(NSData *)audioData sentWithError:(BOOL)error;
- (void)deleteFailedMessages;
- (void)resendFailedMessages;
- (void)messageFinishPlaying:(BOOL)completed;
- (void)resetDiscussionStateAnimated:(BOOL)animated;
- (void)setContactPicture;
- (void)playNextMessage;
- (void)addPlayedMessages:(NSMutableArray *)messages;
- (void)cancelRecording;
- (void) initImageView;
- (void)initTapAndLongPressGestureRecognisers;
- (void)initRecordOverlay;
- (void)addEmojiOverlay;
- (void)removeEmojiOverlay;
- (void)sendRecording;
- (void)setContactIsRecordingProperty:(BOOL)flag;
- (NSInteger)getLastMessageExchangedDate;
- (void)updateLastMessageDate:(NSInteger)date;
- (BOOL)isGroupContactView;
- (BOOL)isFutureContact ;
- (NSInteger)contactIdentifier;

@end

@protocol ContactBubbleViewDelegate

- (void)startedLongPressOnContactView:(ContactView *)contactView;

- (void)endedLongPressRecording;

- (void)sendMessageToContact:(ContactView *)contactView;

- (void)startedPlayingAudioMessagesOfView:(ContactView *)view;

- (void)pendingContactClicked:(ContactView *)contactView;

- (void)updateFrameOfContactView:(ContactView *)view;

- (void)tutoMessage:(NSString *)message withDuration:(NSTimeInterval)duration priority:(BOOL)prority;

- (BOOL)isRecording;

- (void)failedMessagesModeTapGestureOnContact:(ContactView *)contactView;

- (void)endPlayerAtCompletion:(BOOL)completed;

- (void)playSound:(NSString *)sound ofType:(NSString *)type;

- (void)resetLastMessagesPlayed;

- (NSData *)getLastRecordedData;

- (BOOL) displayOpeningTuto;

- (void)displayOpeningTutoWithActionLabel:(NSString *)actionLabel forOrigin:(float)x;

- (ABAddressBookRef) addressBook;

- (void)resetApplicationBadgeNumber;

- (NSData *)emojiData;

- (BOOL) isFirstOpening;

@end
