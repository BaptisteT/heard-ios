//
//  FriendBubbleView.m
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ContactView.h"
#import "UIImageView+AFNetworking.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "ApiUtils.h"
#import "SessionUtils.h"
#import "ImageUtils.h"
#import "TrackingUtils.h"
#import "DashboardViewController.h"
#import "AddressbookUtils.h"

#define ACTION_CIRCLE_BORDER 2.5
#define CONTACT_BORDER 0.5
#define DEGREES_TO_RADIANS(x) (x)/180.0*M_PI
#define RADIANS_TO_DEGREES(x) (x)/M_PI*180.0
#define UNREAD_LABEL_START_ANGLE 90

#define EMPTY_STATE 0
#define PENDING_STATE 1
#define RECORD_STATE 2
#define FAILED_STATE 3
#define PLAY_STATE 4
#define UNREAD_STATE 5
#define LOADING_STATE 6
#define SENDING_STATE 7
#define LAST_MESSAGE_NOT_READ_BY_CONTACT_STATE 8
#define LAST_MESSAGE_READ_BY_CONTACT_STATE 9
#define CURRENT_USER_DID_NOT_ANSWER_STATE 10
#define CONTACT_RECORDING_STATE 11


@interface ContactView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic, strong) NSTimer *minDurationTimer;

@property (nonatomic) BOOL contactIsRecording;
@property (nonatomic, strong) NSTimer *contactIsRecordingAnimationTimer;
@property (nonatomic, strong) NSTimer *contactIsRecordingMaxDelayTimer;

@property (nonatomic, strong) UIImageView *recordOverlay;
@property (nonatomic, strong) UIImageView *playOverlay;
@property (nonatomic, strong) UIImageView *pendingContactOverlay;
@property (nonatomic, strong) UIView *sentOverlay;

@property (nonatomic, strong) CAShapeLayer *circleShape;
@property (nonatomic, strong) CAShapeLayer *loadingCircleShape;
@property (nonatomic, strong) CAShapeLayer *unreadCircleShapeAudio;
@property (nonatomic, strong) CAShapeLayer *unreadCircleShapePhoto;
@property (nonatomic, strong) CAShapeLayer *unreadCircleStartMark;
@property (nonatomic, strong) CAShapeLayer *failedCircleShape;

@property (nonatomic, strong) UILabel *unreadMessagesLabel;
@property (nonatomic, strong) UILabel *failedMessageLabel;
@property (nonatomic, strong) UILabel *contactRecordingLabel;

@property (nonatomic, strong) UIImageView *readStateIcon;
@property (nonatomic, strong) UIImageView *readAnimationIcon;
@property (nonatomic, strong) UIImageView *unreadStateIcon;

@end

@implementation ContactView


// ----------------------------------------------------------
#pragma mark Initialization
// ----------------------------------------------------------
- (id)initWithContact:(Contact *)contact
{
    return [self initWithContact:contact andFrame:CGRectMake(0, 0, kContactSize, kContactSize)];
}

- (id)initWithContact:(Contact *)contact andFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self.clipsToBounds = NO;
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.pictureIsLoaded = NO;
    
    // Init variables
    self.contact = contact;
    self.failedMessages = [NSMutableArray new];
    self.unreadMessages = [NSMutableArray new];
    self.unreadMessagesCount = 0;
    self.isRecording = NO; self.isPlaying = NO; self.messageNotReadByContact = NO; self.contactIsRecording = NO;
    self.sendingMessageCount = 0; self.loadingMessageCount = 0;
    
    // Image view
    [self initImageView];
    
    // Gesture recognisers
    [self initTapAndLongPressGestureRecognisers];
    
    // Init Discussion UI elements
    [self initRecordOverlay];
    [self initPlayOverlay];
    [self initPendingContactOverlay];
    [self initSentOverlay];
    [self initFailedCircleShape];
    [self initUnreadCircleShapes];
    [self initLoadingCircleShape];
    [self initReadStateImageView];
    [self initReadAnimationImageView];
    [self initUnreadStateImageView];
    
    // Init labels
    self.unreadMessagesLabel = [self allocAndInitCornerLabelWithText:@"0" fontSize:18 andColor:[ImageUtils blue]];
    self.failedMessageLabel = [self allocAndInitCornerLabelWithText:@"!" fontSize:18 andColor:[ImageUtils red]];
    self.contactRecordingLabel = [self allocAndInitCornerLabelWithText:@"..." fontSize:20 andColor:[ImageUtils blue]];

    // Discussion state
    [self resetDiscussionStateAnimated:NO];
    
    return self;
}


- (void)setOrderPosition:(NSInteger)orderPosition
{
    if (_orderPosition != orderPosition) {
        _orderPosition = orderPosition;
        [self.delegate updateFrameOfContactView:self];
    }
}

- (BOOL)isGroupContactView {
    return NO;
}

- (BOOL)isFutureContact {
    return self.contact && self.contact.isFutureContact;
}

- (NSInteger)contactIdentifier {
    return self.contact.identifier;
}

// ----------------------------------------------------------
#pragma mark State
// ----------------------------------------------------------

- (void)resetDiscussionStateAnimated:(BOOL)animated
{
    // !! Order is key here !! (pressiooooon)
    
    if ([self viewIsPending]) {
        [self setDiscussionState:PENDING_STATE animated:animated];
    } else if ([self isRecording]){
        [self setDiscussionState:RECORD_STATE animated:animated];
    } else if ([self isPlaying]) {
        [self setDiscussionState:PLAY_STATE animated:animated];
    } else if ([self hasFailedMessages]) {
        [self setDiscussionState:FAILED_STATE animated:animated];
    } else if ([self hasUnreadMessages]) {
        [self setDiscussionState:UNREAD_STATE animated:animated];
    } else if ([self isloadingMessage]) {
        [self setDiscussionState:LOADING_STATE animated:animated];
    } else if ([self isSendingMessage]) {
        [self setDiscussionState:SENDING_STATE animated:animated];
    } else if ([self contactIsRecording]) {
        [self setDiscussionState:CONTACT_RECORDING_STATE animated:animated];
    } else if ([self currentUserDidNotAnswerLastMessage]) {
        [self setDiscussionState:CURRENT_USER_DID_NOT_ANSWER_STATE animated:animated];
    } else if ([self lastMessageSentReadByContact]) {
        [self setDiscussionState:LAST_MESSAGE_READ_BY_CONTACT_STATE animated:animated];
    } else if ([self messageNotReadByContact]) {
        [self setDiscussionState:LAST_MESSAGE_NOT_READ_BY_CONTACT_STATE animated:animated];
    }
    else {
        [self setDiscussionState:EMPTY_STATE animated:animated];
    }
    
    // Reset One tap mode
    [self resetOneTapMode];
}

- (void)setDiscussionState:(NSInteger)discussionState animated:(BOOL)animated
{
    if (_discussionState == discussionState && !(discussionState == UNREAD_STATE))
        return;

    _discussionState = discussionState;
    [self removeDiscussionUI];
    
    if (discussionState == PENDING_STATE) {
        self.imageView.alpha = 0.3;
        [self addSubview:self.pendingContactOverlay];
    }
    else if (discussionState == RECORD_STATE) {
        [self startSonarAnimationWithColor:[ImageUtils red]];
        [self addSubview:self.recordOverlay];
    }
    else if (discussionState == FAILED_STATE) {
        [self.layer addSublayer:self.failedCircleShape];
        self.failedMessageLabel.hidden = NO;
    }
    
    else if (discussionState == PLAY_STATE) {
        [self startSonarAnimationWithColor:[ImageUtils green]];
        [self addSubview:self.playOverlay];
    }
    
    else if (discussionState == UNREAD_STATE) {
        [self setUnreadStateUI];
    }
    
    else if (discussionState == LOADING_STATE) {
        [self startLoadingAnimation];
    }
    
    else if (discussionState == SENDING_STATE) {
        [self startLoadingAnimation];
    }
    
    else if (discussionState == CONTACT_RECORDING_STATE) {
        [self startContactIsRecordingAnimation];
    }
    
    else if (discussionState == CURRENT_USER_DID_NOT_ANSWER_STATE) {
        // do nothing
    }
    
    else if (discussionState == LAST_MESSAGE_READ_BY_CONTACT_STATE) {
        if (animated) {
            [self.delegate playSound:kListenedSound ofType:@"aif" completion:nil];
            self.readAnimationIcon.hidden = NO;
            self.readAnimationIcon.alpha = 1;
            self.readStateIcon.hidden = NO;
            [UIView animateWithDuration:0.5 animations:^{
                self.readAnimationIcon.alpha = 0;
            }completion:^(BOOL finished) {
                if (finished) {
                    self.readAnimationIcon.hidden = YES;
                    self.readAnimationIcon.alpha = 1;
                }
            }];
        } else {
            self.readStateIcon.hidden = NO;
        }
    }
    
    else if (discussionState == LAST_MESSAGE_NOT_READ_BY_CONTACT_STATE) {
        self.unreadStateIcon.hidden = NO;
    }
}

- (void)removeDiscussionUI
{
    //Pending
    self.imageView.alpha = 1;
    [self.pendingContactOverlay removeFromSuperview];
    
    //Record/Play
    [self endSonarAnimation];
    [self.recordOverlay removeFromSuperview];
    [self.playOverlay removeFromSuperview];
    
    //Failed
    self.failedMessageLabel.hidden = YES;
    [self.failedCircleShape removeFromSuperlayer];
    
    //Unread
    [self removeUnreadStateUI];
    
    //Read animation
    [self.readAnimationIcon.layer removeAllAnimations];
    self.readAnimationIcon.hidden = YES;
    
    //Loading/sending
    [self.loadingCircleShape removeAllAnimations];
    [self.loadingCircleShape removeFromSuperlayer];
    
    // Discussion state icons
    self.readStateIcon.hidden = YES;
    self.readAnimationIcon.hidden = YES;
    self.unreadStateIcon.hidden = YES;
    
    // contact is recording
    [self endContactIsRecordingAnimation];
}


// ----------------------------------------------------------
#pragma mark Gesture
// ----------------------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Case where long press comes to one tap
        if (! [self isOneTapMode]) {
            [self startRecording];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        
        // Case where long press comes to one tap
        if ([self isOneTapMode]) {
            [self handleSingleTapGesture];
        } else {
            // Stop timer if it did not fire yet
            if ([self.maxDurationTimer isValid]) {
                [self.maxDurationTimer invalidate];
                [self stopRecording];
                if ([self.minDurationTimer isValid]) {
                    if ([self.delegate displayOpeningTuto]) {
                        [self.delegate displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"hold_longer_tuto_action_label", kStringFile, @"comment") forOrigin:self.frame.origin.x + self.frame.size.width/2];
                    } else {
                        [self.delegate tutoMessage:NSLocalizedStringFromTable(@"audio_too_short_error",kStringFile, @"comment") withDuration:1 priority:YES bottom:YES];
                    }
                } else {
                    [self sendRecording];
                }
            }
        }
    }
}

- (void)handleSingleTapGesture {
    if (self.discussionState == PENDING_STATE) {
        [self handlePendingTapGesture];
    } else if (self.discussionState == UNREAD_STATE) {
        // Sort messages
        [self.unreadMessages sortUsingComparator:^(Message *message1, Message * message2) {
            if (message1.createdAt <= message2.createdAt) {
                return (NSComparisonResult)NSOrderedAscending;
            } else {
                return (NSComparisonResult)NSOrderedDescending;
            }
        }];
        [self.delegate resetLastMessagesPlayed];
        [self playNextMessage];
    } else if (self.discussionState == FAILED_STATE){
        [self handleFailedMessagesModeTapGesture];
    } else if (self.discussionState == PLAY_STATE) {
        [self handlePlayingTapGesture];
    }
}

- (BOOL)isOneTapMode
{
    return self.longPressRecognizer.minimumPressDuration == kLongPressMinDurationForOneTapMode;
}

- (void)resetOneTapMode
{
    if (self.discussionState == PENDING_STATE ||
        self.discussionState == UNREAD_STATE ||
        self.discussionState == PLAY_STATE ||
        self.discussionState == FAILED_STATE) {
        self.longPressRecognizer.minimumPressDuration = kLongPressMinDurationForOneTapMode;
    } else {
        self.longPressRecognizer.minimumPressDuration = kLongPressMinDuration;
    }
}


// ----------------------------------------------------------
#pragma mark Recording & sending
// ----------------------------------------------------------

- (void)startRecording
{
    // Set session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"micro_access_error_title",kStringFile,@"comment")
                                        message:NSLocalizedStringFromTable(@"micro_access_error_message",kStringFile,@"comment")
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        } else {
            if (![self isGroupContactView] && ![GeneralUtils isCurrentUser:self.contact] && !self.contact.isFutureContact && [self contactIdentifier] != 0) {
                [ApiUtils currentUserIsRecording:YES toUser:[self contactIdentifier] success:nil failure:nil];
            }
            self.isRecording = YES;
            // Create Timers
            self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
            self.minDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minRecordingDurationReached) userInfo:nil repeats:NO];
            
            [self resetDiscussionStateAnimated:NO];
            [self.delegate startedLongPressOnContactView:self];
        }
    }];
}

// Stop recording after kMaxAudioDuration
- (void)maxRecordingDurationReached {
    self.userInteractionEnabled = NO;
    [self stopRecording];
    [self sendRecording];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)minRecordingDurationReached {
    // do nothing
}

- (void)stopRecording
{
    if (![self isGroupContactView] && ![GeneralUtils isCurrentUser:self.contact] && !self.contact.isFutureContact && [self contactIdentifier] != 0) {
        [ApiUtils currentUserIsRecording:NO toUser:[self contactIdentifier] success:nil failure:nil];
    }
    self.isRecording = NO;
    [self resetDiscussionStateAnimated:NO];
    [self.delegate endedLongPressRecording];
}

- (void)sendRecording
{
    Message *messageToSend = [self.delegate messageToSend];
    if ([GeneralUtils isCurrentUser:self.contact]) {
        
        self.contact.lastMessageDate = messageToSend.createdAt;
        [self addUnreadMessage:messageToSend];
        [self resetDiscussionStateAnimated:NO];
        
        if ([self.delegate displayOpeningTuto]) {
            [self.delegate displayOpeningTutoWithActionLabel:NSLocalizedStringFromTable(@"tap_tuto_action_label", kStringFile, @"comment") forOrigin:self.frame.origin.x + self.frame.size.width/2];
        }
        [self.delegate resetApplicationBadgeNumber];
    } else {
        self.sendingMessageCount ++;
        [self resetDiscussionStateAnimated:NO];
        
        // Send
        [self.delegate sendMessageToContact:self];
    }
    if ([messageToSend.messageType isEqualToString:kAudioEmojiMessageType]) {
        [TrackingUtils trackRecord:messageToSend.messageType isGroup:NO emoji:messageToSend.messageText];
    } else {
        [TrackingUtils trackRecord:messageToSend.messageType isGroup:NO emoji:@""];
    }
}

- (void)message:(Message *)message sentWithError:(BOOL)error
{
    self.sendingMessageCount --;
    
    if (error) {
        [self.delegate playSound:kFailedSound ofType:@"aif" completion:nil];
        // Stock failed message
        [self.failedMessages addObject:message];
    } else {
        if (!self.isRecording && !self.isPlaying) {
            [self sentAnimation];
            [self.delegate playSound:kSentSound ofType:@"aif" completion:nil];
        }
        
        self.contact.currentUserDidNotAnswerLastMessage = NO;
        self.messageNotReadByContact = YES;
    }
    // Update last message date
    [self updateLastMessageDate:[[NSDate date] timeIntervalSince1970]];
    [self resetDiscussionStateAnimated:NO];
}

- (void)updateLastMessageDate:(NSInteger)date
{
    self.contact.lastMessageDate = date;
}

- (void)deleteFailedMessages {
    self.failedMessages = [NSMutableArray new];
    [self resetDiscussionStateAnimated:NO];
}

- (void)resendFailedMessages
{
    // Resend Messages
    for (Message *message in self.failedMessages) {
        self.sendingMessageCount ++;
        [ApiUtils sendMessage:message toContactView:self success:^{
            [self message:nil sentWithError:NO];
        } failure:^{
            [self message:message sentWithError:YES];
        }];
    }
    
    [self deleteFailedMessages];
}

- (void)sentAnimation
{
    self.sentOverlay.alpha = 0;
    
    [self addSubview:self.sentOverlay];
    
    [UIView animateWithDuration:0.15 animations:^{
        self.sentOverlay.alpha = 0.5;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.sentOverlay.alpha = 0;
        });
    }];
}

- (void)cancelRecording
{
    [self.maxDurationTimer invalidate];
    self.isRecording = NO;
    [self resetDiscussionStateAnimated:NO];
}


// ----------------------------------------------------------
#pragma mark Playing
// ----------------------------------------------------------

- (void)playNextMessage
{
    if (![self hasUnreadMessages])
        return;
    if (self.contact.lastMessageDate <= ((Message *)self.unreadMessages[0]).createdAt) {
        self.contact.currentUserDidNotAnswerLastMessage = YES;
    }
    [self.delegate startedPlayingMessagesOfView:self];
    self.isPlaying = YES;
    [self resetDiscussionStateAnimated:NO];
}

- (void)messageFinishPlaying:(BOOL)completed
{
    if ([self hasUnreadMessages]) {
        [self deleteMessage:self.unreadMessages[0]];
    }
    self.isPlaying = NO;
    [self resetDiscussionStateAnimated:NO];
    
    if (completed && [self hasUnreadMessages]) {
        [self playNextMessage];
    } else {
        if ([GeneralUtils displayReplayTuTo]) {
            [self.delegate tutoMessage:NSLocalizedStringFromTable(@"shake_to_replay_tuto",kStringFile, @"comment")  withDuration:3 priority:NO bottom:YES];
        }
    }
}

- (void)deleteMessage:(Message *)message
{
    // Mark as unread in DB
    if (![GeneralUtils isCurrentUser:self.contact]) {
        [ApiUtils markMessageAsOpened:message.identifier success:nil failure:nil];
    }
    
    // Delete & update counter
    [self.unreadMessages removeObject:message];
    [self setUnreadMessagesCount:self.unreadMessagesCount-1];
    [self.delegate resetApplicationBadgeNumber];
}

- (void)handlePlayingTapGesture {
    [self.delegate endPlayerAtCompletion:NO];
    [self.delegate tutoMessage:NSLocalizedStringFromTable(@"shake_to_replay_tuto",kStringFile, @"comment") withDuration:1 priority:NO bottom:YES];
    self.isPlaying = NO;
    [self resetDiscussionStateAnimated:NO];
}


// ----------------------------------------------------------
#pragma mark Pending Contact
// ----------------------------------------------------------

- (void)handlePendingTapGesture {
    [self.delegate pendingContactClicked:self];
}

- (void)handleFailedMessagesModeTapGesture
{
    [self.delegate failedMessagesModeTapGestureOnContact:self];
}


// ----------------------------------------------------------
#pragma mark Message utility
// ----------------------------------------------------------
- (void)downloadAudio:(Message *)message
{
    if (message.messageData) {
        return;
    }
    self.loadingMessageCount ++;
    [self resetDiscussionStateAnimated:NO];
    
    // Request data asynch
    [ApiUtils downloadAudioFileAtURL:[message getMessageURL] success:^void(NSData *data) {
        message.messageData = data;
        self.loadingMessageCount --;
        [self resetDiscussionStateAnimated:NO];
    } failure:^(){
        [self downloadAudio:message];
        self.loadingMessageCount --;
        [self resetDiscussionStateAnimated:NO];
    }];
}

- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    self.unreadMessagesLabel.text = [NSString stringWithFormat:@"%lu",(long)unreadMessagesCount];
}

- (void)addUnreadMessage:(Message *)message
{
    BOOL addMessage = YES;
    for (Message *unreadMessage in self.unreadMessages) {
        if (unreadMessage.identifier > 0 && unreadMessage.identifier == message.identifier) {
            addMessage = NO;
            break;
        }
    }
    if (addMessage) {
        [self downloadAudio:message];
        [self.unreadMessages addObject:message];
        [self setUnreadMessagesCount:self.unreadMessagesCount+1];
    }
}

- (void)resetUnreadMessages
{
    if ([GeneralUtils isCurrentUser:self.contact]) {
        return;
    }
    self.unreadMessages = [NSMutableArray new];
    self.unreadMessagesCount = 0;
    self.loadingMessageCount = 0;
    self.sendingMessageCount = 0;
    [self resetDiscussionStateAnimated:NO];
}

- (void)addPlayedMessages:(NSMutableArray *)messages
{
    if (![self hasUnreadMessages]) {
        self.unreadMessages = messages;
    } else {
        // Case where message was not finished playing (do not add it again)
        if (self.unreadMessages.count>0 && [messages lastObject]==self.unreadMessages[0]) {
            [messages removeLastObject];
        }
        NSRange range = NSMakeRange(0, [messages count]);
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.unreadMessages insertObjects:messages atIndexes:indexSet];
    }
    self.unreadMessagesCount = [self.unreadMessages count];
}

- (NSInteger)getLastMessageExchangedDate
{
    return self.contact.lastMessageDate;
}


// ----------------------------------------------------------
#pragma mark State belonging
// ----------------------------------------------------------
- (BOOL)viewIsPending {
    return self.contact.isPending;
}

- (BOOL)hasUnreadMessages {
    return self.unreadMessagesCount > 0 && self.unreadMessages && self.unreadMessages.count>0 && ((Message *)self.unreadMessages[0]).messageData;
}

- (BOOL)hasFailedMessages {
    return self.failedMessages && self.failedMessages.count > 0;
}

// not necessary (just for symmetry)
- (BOOL)isPlaying {
    return _isPlaying;
}

// not necessary (just for symmetry)
- (BOOL)isRecording {
    return _isRecording;
}

- (BOOL)isloadingMessage {
    return self.loadingMessageCount > 0;
}

- (BOOL)isSendingMessage {
    return self.sendingMessageCount > 0;
}

- (BOOL)lastMessageSentReadByContact {
    return self.contact.lastMessageDate != 0 && ![self currentUserDidNotAnswerLastMessage] && !self.messageNotReadByContact ;
}

- (BOOL)currentUserDidNotAnswerLastMessage {
    return self.contact.currentUserDidNotAnswerLastMessage;
}

// not necessary (just for symmetry)
- (BOOL)messageNotReadByContact {
    return _messageNotReadByContact ;
}

- (BOOL)contactIsRecording {
    return _contactIsRecording;
}

- (void)setContactIsRecordingProperty:(BOOL)flag {
    if (self.contactIsRecordingMaxDelayTimer) {
        [self.contactIsRecordingMaxDelayTimer invalidate];
    }
    self.contactIsRecording = flag;
    // security : avoid infinite is typing anim
    if (flag) {
        self.contactIsRecordingMaxDelayTimer = [NSTimer scheduledTimerWithTimeInterval:35.f target:self selector:@selector(endDelayContactIsRecordingTimer) userInfo:nil repeats:NO];
    }
    [self resetDiscussionStateAnimated:NO];
}

- (void)endDelayContactIsRecordingTimer {
    self.contactIsRecording = NO;
    [self resetDiscussionStateAnimated:NO];
}


// ----------------------------------------------------------
#pragma mark Design utility
// ----------------------------------------------------------

- (void)startSonarAnimationWithColor:(UIColor *)color
{
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(self.bounds), -CGRectGetMidY(self.bounds), self.bounds.size.width, self.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:self.bounds.size.height];
    
    CGPoint shapePosition = [self.superview convertPoint:self.center fromView:self.superview];
    
    self.circleShape = [CAShapeLayer layer];
    self.circleShape.path = path.CGPath;
    self.circleShape.position = shapePosition;
    self.circleShape.fillColor = [UIColor clearColor].CGColor;
    self.circleShape.opacity = 1;
    self.circleShape.strokeColor = color.CGColor;
    self.circleShape.lineWidth = 2.0;

    [self.superview.layer addSublayer:self.circleShape];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;
    
    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = 0.5f;
    animation.repeatCount = INFINITY;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [self.circleShape addAnimation:animation forKey:nil];
}

- (void)endSonarAnimation
{
    [self.circleShape removeAllAnimations];
    [self.circleShape removeFromSuperlayer];
}

- (void)startLoadingAnimation
{
    // Add to parent layer
    [self.layer addSublayer:self.loadingCircleShape];
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
    rotationAnimation.duration = 0.7;
    rotationAnimation.repeatCount = INFINITY;
    [self.loadingCircleShape addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
}

- (void)startContactIsRecordingAnimation {
    self.contactRecordingLabel.hidden = NO;
    [self.contactRecordingLabel setText:@"."];
    self.contactIsRecordingAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateContactRecordingLabel) userInfo:nil repeats:YES];
}

- (void)updateContactRecordingLabel {
    NSString *ellipses = @"...";
    if ([self.contactRecordingLabel.text rangeOfString:ellipses].location == NSNotFound) {
        [self.contactRecordingLabel setText:[NSString stringWithFormat:@"%@.",self.contactRecordingLabel.text]];
    } else {
        [self.contactRecordingLabel setText:@""];
    }
}

- (void)endContactIsRecordingAnimation {
    [self.contactIsRecordingAnimationTimer invalidate];
    self.contactIsRecordingAnimationTimer = nil;
    [self.contactRecordingLabel setHidden:YES];
}

- (void)addEmojiOverlay {
    [self addSubview:self.sentOverlay];
    self.sentOverlay.alpha = 0.8;
}

- (void)removeEmojiOverlay {
    self.sentOverlay.alpha = 0;
}

- (void)setUnreadStateUI {
    if (![self hasUnreadMessages]) {
        return;
    }
    UIColor *firstMessageColor = [(Message *)self.unreadMessages[0] isPhotoMessage]? [self photoMessageColor] : [self audioMessageColor];
    self.unreadMessagesLabel.textColor = firstMessageColor;
    self.unreadMessagesLabel.hidden = NO;
    self.unreadCircleStartMark.strokeColor = firstMessageColor.CGColor;
    
    CGPoint center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    float degreeStep = 360.f / self.unreadMessagesCount;
    float arcGap = 5 / MAX(1,self.unreadMessagesCount-5);
    UIBezierPath *audioPath = [UIBezierPath new];
    UIBezierPath *photoPath = [UIBezierPath new];
    CGFloat startDegree = - UNREAD_LABEL_START_ANGLE;
    for (Message *message in self.unreadMessages) {
        CGFloat endDegree = startDegree + degreeStep - arcGap / 2;
        if ([message isPhotoMessage]) {
            [photoPath appendPath:[UIBezierPath bezierPathWithArcCenter:center radius:self.frame.size.width/2 + 4 startAngle:DEGREES_TO_RADIANS(startDegree + arcGap / 2) endAngle:DEGREES_TO_RADIANS(endDegree) clockwise:YES]];
        } else {
            [audioPath appendPath:[UIBezierPath bezierPathWithArcCenter:center radius:self.frame.size.width/2 + 4 startAngle:DEGREES_TO_RADIANS(startDegree + arcGap / 2) endAngle:DEGREES_TO_RADIANS(endDegree) clockwise:YES]];
        }
        startDegree += degreeStep;
    }
    self.unreadCircleShapePhoto.path = photoPath.CGPath;
    self.unreadCircleShapeAudio.path = audioPath.CGPath;
    
    [self.layer addSublayer:self.unreadCircleShapeAudio];
    [self.layer addSublayer:self.unreadCircleShapePhoto];
    [self.layer addSublayer:self.unreadCircleStartMark];
}

- (void)removeUnreadStateUI {
    self.unreadMessagesLabel.hidden = YES;
    [self.unreadCircleShapePhoto removeFromSuperlayer];
    [self.unreadCircleShapeAudio removeFromSuperlayer];
    [self.unreadCircleStartMark removeFromSuperlayer];
}

// ----------------------------------------------------------
#pragma mark Init utility
// ----------------------------------------------------------

- (void) initImageView {
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self setContactPicture];
    [self addSubview:self.imageView];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.bounds.size.height/2;
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.borderWidth = CONTACT_BORDER;
}

- (void)setContactPicture
{
    if (self.contact.isFutureContact && self.contact.facebookId.length == 0) {
        UIImage *picture = [AddressbookUtils getPictureFromRecordId:self.contact.recordId andAddressBook:[self.delegate addressBook]];
        if (picture) {
            [UIView transitionWithView:self.imageView
                              duration:1.0f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[self.imageView setImage:picture];}
                            completion:nil];
            self.pictureIsLoaded = YES;
        }
    } else {
        NSURL *url;
        if (self.contact.isFutureContact) {
            url = [GeneralUtils getUserProfilePictureURLFromFacebookId:self.contact.facebookId];
        } else {
            url = [GeneralUtils getUserProfilePictureURLFromUserId:[self contactIdentifier]];
        }
        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:url];
        __weak __typeof(self)weakSelf = self;

        //Fade in profile picture
        [self.imageView setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            image = [ImageUtils cropBiggestCenteredSquareImageFromImage:image withSide:0];
            [UIView transitionWithView:weakSelf.imageView
                              duration:1.0f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[weakSelf.imageView setImage:image];}
                            completion:nil];
            weakSelf.pictureIsLoaded = YES;
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            weakSelf.pictureIsLoaded = NO;
        }];
    }
}

- (void)initPendingContactOverlay {
    self.pendingContactOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.pendingContactOverlay.clipsToBounds = YES;
    self.pendingContactOverlay.layer.cornerRadius = self.bounds.size.height/2;
    [self.pendingContactOverlay setBackgroundColor:[UIColor clearColor]];
    [self.pendingContactOverlay setImage:[UIImage imageNamed:@"unknown-user"]];
}

- (void)initSentOverlay
{
    self.sentOverlay = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.sentOverlay.clipsToBounds = YES;
    self.sentOverlay.layer.cornerRadius = self.bounds.size.height/2;
    [self.sentOverlay setBackgroundColor:[ImageUtils blue]];
}

- (UILabel *)allocAndInitCornerLabelWithText:(NSString *)text fontSize:(CGFloat)fontSize andColor:(UIColor *)color
{
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2 + 5, -20, kUnreadMessageSize, kUnreadMessageSize)];
    label.textColor = color;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:fontSize];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.2;
    label.text = text;
    label.hidden = YES;
    [self addSubview:label];
    return label;
}

- (void)initReadStateImageView
{
    self.readStateIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contact-eye"]];
    [self.readStateIcon setFrame:CGRectMake(kContactSize - 10, -10, 25, 25)];
    self.readStateIcon.hidden = YES;
    if (![GeneralUtils isCurrentUser:self.contact])
        [self addSubview:self.readStateIcon];
}

- (void)initReadAnimationImageView
{
    self.readAnimationIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contact-blue-eye"]];
    [self.readAnimationIcon setFrame:CGRectMake(kContactSize - 10, -10, 25, 25)];
    self.readAnimationIcon.hidden = YES;
    [self addSubview:self.readAnimationIcon];
}

- (void)initUnreadStateImageView
{
    self.unreadStateIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contact-sent"]];
    [self.unreadStateIcon setFrame:CGRectMake(kContactSize - 10, -10, 25, 25)];
    self.unreadStateIcon.hidden = YES;
    if (![GeneralUtils isCurrentUser:self.contact])
        [self addSubview:self.unreadStateIcon];
}
                            
- (void)initTapAndLongPressGestureRecognisers
{
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;
    self.longPressRecognizer.minimumPressDuration = kLongPressMinDuration;
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture)];
    [self addGestureRecognizer:self.singleTapRecognizer];
    self.singleTapRecognizer.delegate = self;
    self.singleTapRecognizer.numberOfTapsRequired = 1;
}

- (void)initRecordOverlay
{
    self.recordOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordOverlay.clipsToBounds = YES;
    self.recordOverlay.alpha = 0.7;
    self.recordOverlay.image = [UIImage imageNamed:@"record"];
}

- (void)initPlayOverlay
{
    self.playOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.playOverlay.clipsToBounds = YES;
    self.playOverlay.alpha = 0.7;
    self.playOverlay.image = [UIImage imageNamed:@"play"];
}

- (void)initFailedCircleShape
{
    CGPoint center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    self.failedCircleShape = [CAShapeLayer new];
    self.failedCircleShape.frame = self.frame;
    self.failedCircleShape.fillColor = [UIColor clearColor].CGColor;
    self.failedCircleShape.lineWidth = ACTION_CIRCLE_BORDER;
    self.failedCircleShape.strokeColor = [ImageUtils red].CGColor;
    self.failedCircleShape.path = [UIBezierPath bezierPathWithArcCenter:center
                                                                 radius:self.frame.size.width/2 + 4
                                                             startAngle:DEGREES_TO_RADIANS(0)
                                                               endAngle:DEGREES_TO_RADIANS(360)
                                                              clockwise:YES].CGPath;
}

- (void)initUnreadCircleShapes
{
    self.unreadCircleShapeAudio = [CAShapeLayer new];
    self.unreadCircleShapeAudio.frame = self.frame;
    self.unreadCircleShapeAudio.fillColor = [UIColor clearColor].CGColor;
    self.unreadCircleShapeAudio.lineWidth = ACTION_CIRCLE_BORDER;
    self.unreadCircleShapeAudio.strokeColor = [self audioMessageColor].CGColor;
    
    self.unreadCircleShapePhoto = [CAShapeLayer new];
    self.unreadCircleShapePhoto.frame = self.frame;
    self.unreadCircleShapePhoto.fillColor = [UIColor clearColor].CGColor;
    self.unreadCircleShapePhoto.lineWidth = ACTION_CIRCLE_BORDER;
    self.unreadCircleShapePhoto.strokeColor = [self photoMessageColor].CGColor;
    
    self.unreadCircleStartMark = [CAShapeLayer new];
    self.unreadCircleStartMark.frame = self.frame;
    self.unreadCircleStartMark.fillColor = [UIColor clearColor].CGColor;
    self.unreadCircleStartMark.lineWidth = ACTION_CIRCLE_BORDER + 3;
    CGPoint center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    self.unreadCircleStartMark.path = [UIBezierPath bezierPathWithArcCenter:center radius:self.frame.size.width/2 + 4 startAngle:DEGREES_TO_RADIANS(-UNREAD_LABEL_START_ANGLE-1) endAngle:DEGREES_TO_RADIANS(-UNREAD_LABEL_START_ANGLE+1) clockwise:YES].CGPath;
}

- (void)initLoadingCircleShape
{
    self.loadingCircleShape = [ImageUtils createGradientCircleLayerWithFrame:self.frame borderWidth:ACTION_CIRCLE_BORDER Color:[self audioMessageColor] subDivisions:100];
}

- (UIColor *)audioMessageColor {
    return [ImageUtils blue];
}

- (UIColor *)photoMessageColor {
    return [ImageUtils pink];
}

// ----------------------------------------------------------
#pragma mark Alert view delegate
// ----------------------------------------------------------

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:NSLocalizedStringFromTable(@"micro_access_error_title",kStringFile, @"comment")]) {
        [GeneralUtils openSettings];
    }
}

@end
