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

#define ACTION_CIRCLE_BORDER 2.5
#define CONTACT_BORDER 0.5
#define DEGREES_TO_RADIANS(x) (x)/180.0*M_PI
#define RADIANS_TO_DEGREES(x) (x)/M_PI*180.0

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

@interface ContactView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic, strong) NSTimer *minDurationTimer;

@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) NSInteger sendingMessageCount;
@property (nonatomic) NSInteger loadingMessageCount;

@property (nonatomic, strong) UIImageView *recordOverlay;
@property (nonatomic, strong) UIImageView *playOverlay;
@property (nonatomic, strong) UIImageView *pendingContactOverlay;
@property (nonatomic, strong) UIView *sentOverlay;

@property (nonatomic, strong) CAShapeLayer *circleShape;
@property (nonatomic, strong) CAShapeLayer *loadingCircleShape;
@property (nonatomic, strong) CAShapeLayer *unreadCircleShape;
@property (nonatomic, strong) CAShapeLayer *failedCircleShape;

@property (nonatomic) UILabel *unreadMessagesLabel;
@property (nonatomic, strong) UILabel *failedMessageLabel;

@property (nonatomic, strong) UIImageView *readStateIcon;
@property (nonatomic, strong) UIImageView *readAnimationIcon;
@property (nonatomic, strong) UIImageView *unreadStateIcon;
@property (nonatomic, strong) UIImageView *unrespondedStateIcon;

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
    
    // Init variables
    self.contact = contact;
    self.failedMessages = [NSMutableArray new];
    self.unreadMessages = [NSMutableArray new];
    self.unreadMessagesCount = 0;
    self.isRecording = NO; self.isPlaying = NO; self.messageNotReadByContact = NO;
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
    [self initUnreadCircleShape];
    [self initLoadingCircleShape];
    [self initReadStateImageView];
    [self initReadAnimationImageView];
    [self initUnreadStateImageView];
    [self initUnrespondedStateImageView];
    
    // Init labels
    self.unreadMessagesLabel = [self allocAndInitCornerLabelWithText:@"0" andColor:[ImageUtils blue]];
    self.failedMessageLabel = [self allocAndInitCornerLabelWithText:@"!" andColor:[ImageUtils red]];

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
    if (_discussionState == discussionState)
        return;

    _discussionState = discussionState;
    [self removeDiscussionUI];
    
    if (discussionState == PENDING_STATE) {
        self.imageView.alpha = 0.3;
        [self addSubview:self.pendingContactOverlay];
    }
    else if (discussionState == RECORD_STATE) {
        [self.delegate endTutoMode];
        [self startSonarAnimationWithColor:[ImageUtils red]];
        [self addSubview:self.recordOverlay];
    }
    else if (discussionState == FAILED_STATE) {
        [self.layer addSublayer:self.failedCircleShape];
        self.failedMessageLabel.hidden = NO;
    }
    
    else if (discussionState == PLAY_STATE) {
        [self.delegate endTutoMode];
        [self startSonarAnimationWithColor:[ImageUtils green]];
        [self addSubview:self.playOverlay];
    }
    
    else if (discussionState == UNREAD_STATE) {
        self.unreadMessagesLabel.hidden = NO;
        [self.layer addSublayer:self.unreadCircleShape];
    }
    
    else if (discussionState == LOADING_STATE) {
        [self startLoadingAnimation];
    }
    
    else if (discussionState == SENDING_STATE) {
        [self startLoadingAnimation];
    }
    
    else if (discussionState == CURRENT_USER_DID_NOT_ANSWER_STATE) {
        self.unrespondedStateIcon.hidden = NO;
    }
    
    else if (discussionState == LAST_MESSAGE_READ_BY_CONTACT_STATE) {
        if (animated) {
            [self.delegate playSound:kListenedSound];
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
    self.unreadMessagesLabel.hidden = YES;
    [self.unreadCircleShape removeFromSuperlayer];
    
    //Read animation
    [self.readAnimationIcon.layer removeAllAnimations];
    self.readAnimationIcon.hidden = YES;
    
    //Loading/sending
    [self.loadingCircleShape removeAllAnimations];
    [self.loadingCircleShape removeFromSuperlayer];
    
    // Discussion state icons
    self.unrespondedStateIcon.hidden = YES;
    self.readStateIcon.hidden = YES;
    self.readAnimationIcon.hidden = YES;
    self.unreadStateIcon.hidden = YES;
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
                
                if([self.delegate isRecording] && ![self.minDurationTimer isValid]) {
                    [self stopRecording];
                    [self sendRecording];
                } else {
                    [self stopRecording];
                    [self resetDiscussionStateAnimated:NO];
                    [self.delegate tutoMessage:@"Hold to record." withDuration:1];
                }
            };
        }
    }
}

- (void)handleSingleTapGesture {
    if (self.discussionState == PENDING_STATE) {
        [self handlePendingTapGesture];
    } else if (self.discussionState == UNREAD_STATE) {
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
            [GeneralUtils showMessage:@"To activate it, go to Settings > Privacy > Micro" withTitle:@"Waved does not have access to your micro"];
            return;
        } else {
            self.isRecording = YES;
            [session setActive:YES error:nil];
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
}

- (void)minRecordingDurationReached {
    // do nothing
}

- (void)stopRecording
{
    self.isRecording = NO;
    [self resetDiscussionStateAnimated:NO];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.delegate endedLongPressRecording];
}

- (void)sendRecording
{
    // Update last message date
    self.contact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
    
    self.sendingMessageCount ++;
    [self resetDiscussionStateAnimated:NO];
    
    // Send
    [self.delegate sendMessageToContact:self];
    [TrackingUtils trackRecord];
}

- (void)message:(NSData *)audioData sentWithError:(BOOL)error
{
    self.sendingMessageCount --;
    
    if (error) {
        [self.delegate playSound:kFailedSound];
        // Stock failed message
        [self.failedMessages addObject:audioData];
    } else {
        if (!self.isRecording && !self.isPlaying) {
            [self sentAnimation];
            [self.delegate playSound:kSentSound];
        }
        
        self.contact.currentUserDidNotAnswerLastMessage = NO;
        self.messageNotReadByContact = YES;
    }
    [self resetDiscussionStateAnimated:NO];
}

- (void)deleteFailedMessages {
    self.failedMessages = [NSMutableArray new];
    [self resetDiscussionStateAnimated:NO];
}

- (void)resendFailedMessages
{
    // Resend Messages
    for (NSData *audioData in self.failedMessages) {
        self.sendingMessageCount ++;
        [ApiUtils sendMessage:audioData toUser:self.contact.identifier success:^{
            [self message:nil sentWithError:NO];
        } failure:^{
            [self message:audioData sentWithError:YES];
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


// ----------------------------------------------------------
#pragma mark Playing
// ----------------------------------------------------------

- (void)playNextMessage
{
    self.isPlaying = YES;
    self.contact.currentUserDidNotAnswerLastMessage = YES;
    [self.delegate startedPlayingAudioMessagesOfView:self];
    [self resetDiscussionStateAnimated:NO];
}

- (void)messageFinishPlaying
{
    [self deleteMessage:self.unreadMessages[0]];
    self.isPlaying = NO;
    [self resetDiscussionStateAnimated:NO];
    
    if ([self hasUnreadMessages])
        [self playNextMessage];
}

- (void)deleteMessage:(Message *)message
{
    // Mark as unread in DB
    [ApiUtils markMessageAsOpened:message.identifier success:nil failure:nil];
    
    // Delete & update counter
    [self.unreadMessages removeObject:message];
    [self setUnreadMessagesCount:self.unreadMessagesCount-1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
}

- (void)handlePlayingTapGesture {
    // unread state
    [self.delegate endPlayerAtCompletion:NO];
    self.isPlaying = NO;
    [self resetDiscussionStateAnimated:NO];
}


// ----------------------------------------------------------
#pragma mark Pending Contact
// ----------------------------------------------------------

- (void)handlePendingTapGesture {
    [self.delegate pendingContactClicked:self.contact];
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
    if (message.audioData)
        return;
    self.loadingMessageCount ++;
    [self resetDiscussionStateAnimated:NO];
    
    // Request data asynch
    [ApiUtils downloadAudioFileAtURL:[message getMessageURL] success:^void(NSData *data) {
        message.audioData = data;
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
    [self downloadAudio:message];
    [self.unreadMessages addObject:message];
    [self setUnreadMessagesCount:self.unreadMessagesCount+1];
}

- (void)resetUnreadMessages
{
    self.unreadMessages = [NSMutableArray new];
    self.unreadMessagesCount = 0;
    self.loadingMessageCount = 0;
    self.sendingMessageCount = 0;
    [self resetDiscussionStateAnimated:NO];
}


// ----------------------------------------------------------
#pragma mark State belonging
// ----------------------------------------------------------
- (BOOL)viewIsPending {
    return self.contact.isPending;
}

- (BOOL)hasUnreadMessages {
    return self.unreadMessagesCount > 0 && self.unreadMessages && ((Message *)self.unreadMessages[0]).audioData;
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
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:self.contact.identifier]];
    
    UIImageView *imageView = self.imageView;
    
    //Fade in profile picture
    [self.imageView setImageWithURLRequest:imageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [UIView transitionWithView:imageView
                          duration:1.0f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{[imageView setImage:image];}
                        completion:nil];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [UIView transitionWithView:imageView
                          duration:1.0f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{[imageView setImage:[UIImage imageNamed:@"contact-placeholder.png"]];}
                        completion:nil];
    }];
    
}

- (void)initPendingContactOverlay {
    self.pendingContactOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    [self.layer addSublayer:self.unreadCircleShape];
    self.pendingContactOverlay.clipsToBounds = YES;
    self.pendingContactOverlay.layer.cornerRadius = self.bounds.size.height/2;
    [self.pendingContactOverlay setBackgroundColor:[UIColor clearColor]];
    [self.pendingContactOverlay setImage:[UIImage imageNamed:@"unknown-user.png"]];
}

- (void)initSentOverlay
{
    self.sentOverlay = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.sentOverlay.clipsToBounds = YES;
    self.sentOverlay.layer.cornerRadius = self.bounds.size.height/2;
    [self.sentOverlay setBackgroundColor:[ImageUtils blue]];
}

- (UILabel *)allocAndInitCornerLabelWithText:(NSString *)text andColor:(UIColor *)color
{
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2 + 5, -20, kUnreadMessageSize, kUnreadMessageSize)];
    label.textColor = color;
    label.font = [UIFont fontWithName:@"Avenir-Heavy" size:18];
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
    [self addSubview:self.unreadStateIcon];
}
                            
- (void)initUnrespondedStateImageView
{
    self.unrespondedStateIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"contact-suspension.png"]];
    [self.unrespondedStateIcon setFrame:CGRectMake(kContactSize - 10, -10, 25, 25)];
    self.unrespondedStateIcon.hidden = YES;
    [self addSubview:self.unrespondedStateIcon];
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
    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
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

- (void)initUnreadCircleShape
{
    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.unreadCircleShape = [CAShapeLayer new];
    self.unreadCircleShape.frame = self.frame;
    self.unreadCircleShape.fillColor = [UIColor clearColor].CGColor;
    self.unreadCircleShape.lineWidth = ACTION_CIRCLE_BORDER;
    self.unreadCircleShape.strokeColor = [ImageUtils blue].CGColor;
    self.unreadCircleShape.path = [UIBezierPath bezierPathWithArcCenter:center
                                                                 radius:self.frame.size.width/2 + 4
                                                             startAngle:DEGREES_TO_RADIANS(0)
                                                               endAngle:DEGREES_TO_RADIANS(360)
                                                              clockwise:YES].CGPath;
}

- (void)initLoadingCircleShape
{
    self.loadingCircleShape = [ImageUtils createGradientCircleLayerWithFrame:self.frame borderWidth:ACTION_CIRCLE_BORDER Color:[ImageUtils blue] subDivisions:100];
}

@end
