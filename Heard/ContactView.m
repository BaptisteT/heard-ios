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

@interface ContactView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic, strong) NSTimer *minDurationTimer;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) UILabel *unreadMessagesLabel;
@property (nonatomic, strong) UIImageView *recordPlayOverlay;
@property (nonatomic, strong) UIImageView *pendingContactOverlay;
@property (nonatomic, strong) CAShapeLayer *circleShape;
@property (nonatomic, strong) CAShapeLayer *loadingCircleShape;
@property (nonatomic, strong) CAShapeLayer *unreadCircleShape;
@property (nonatomic, strong) CAShapeLayer *failedCircleShape;
@property (nonatomic) BOOL cancelLongPress;
@property (nonatomic, strong) UILabel *failedMessageIcon;
@property (nonatomic, strong) UILabel *sentMessageIcon;
@property (nonatomic) NSInteger previousState;

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
    self.contact = contact;
    self.clipsToBounds = NO;
    self.previousState = 0;
    
    //Initialization
    self.nextMessageId = 0;
    self.cancelLongPress = NO;
    self.failedMessages = [NSMutableArray new];
    
    // Set image view
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self setContactPicture];
    [self addSubview:self.imageView];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.bounds.size.height/2;
    
    // Alloc and add gesture recognisers
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;
    self.longPressRecognizer.minimumPressDuration = kLongPressMinDuration;
    
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture)];
    [self addGestureRecognizer:self.singleTapRecognizer];
    self.singleTapRecognizer.delegate = self;
    self.singleTapRecognizer.numberOfTapsRequired = 1;
    
    // Init unread messages button
    [self initUnreadMessagesLabel];
    self.unreadMessagesCount = 0;
    
    // Set up the shape of the load messagecircle
    self.loadingCircleShape = [ImageUtils createGradientCircleLayerWithFrame:self.frame borderWidth:ACTION_CIRCLE_BORDER Color:[ImageUtils blue] subDivisions:100];
    // init send / fail images
    self.sentMessageIcon = [self allocAndInitCornerLabelWithText:@"\u2713" andColor:[ImageUtils green]];
    self.failedMessageIcon = [self allocAndInitCornerLabelWithText:@"!" andColor:[ImageUtils red]];
    
    // Set up the shape of the unread message circle
    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.unreadCircleShape = [CAShapeLayer new];
    self.unreadCircleShape.frame = frame;
    self.unreadCircleShape.fillColor = [UIColor clearColor].CGColor;
    self.unreadCircleShape.lineWidth = ACTION_CIRCLE_BORDER;
    self.unreadCircleShape.strokeColor = [ImageUtils blue].CGColor;
    self.unreadCircleShape.path = [UIBezierPath bezierPathWithArcCenter:center
                                                                 radius:frame.size.width/2 + 4
                                                             startAngle:DEGREES_TO_RADIANS(0)
                                                               endAngle:DEGREES_TO_RADIANS(360)
                                                              clockwise:YES].CGPath;
    
    // Set up the shape of the failed message circle
    self.failedCircleShape = [CAShapeLayer new];
    self.failedCircleShape.frame = frame;
    self.failedCircleShape.fillColor = [UIColor clearColor].CGColor;
    self.failedCircleShape.lineWidth = ACTION_CIRCLE_BORDER;
    self.failedCircleShape.strokeColor = [ImageUtils red].CGColor;
    self.failedCircleShape.path = [UIBezierPath bezierPathWithArcCenter:center
                                                                 radius:frame.size.width/2 + 4
                                                             startAngle:DEGREES_TO_RADIANS(0)
                                                               endAngle:DEGREES_TO_RADIANS(360)
                                                              clockwise:YES].CGPath;
    
    //Contact border
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.borderWidth = CONTACT_BORDER;
    
    [self setDiscussionState:EMPTY_STATE];
    
    return self;
}

- (void)removeDiscussionUI
{
    //Pending
    self.imageView.alpha = 1;
    [self.pendingContactOverlay removeFromSuperview];
    
    //Record/Play
    [self endSonarAnimation];
    [self.recordPlayOverlay removeFromSuperview];
    
    //Failed
    self.failedMessageIcon.hidden = YES;
    [self.failedCircleShape removeFromSuperlayer];
    
    //Unread
    self.unreadMessagesLabel.hidden = YES;
    [self.unreadCircleShape removeFromSuperlayer];
    
    //Loading/sending
    [self.loadingCircleShape removeAllAnimations];
    [self.loadingCircleShape removeFromSuperlayer];
    
    //Default tap mode: long tap
    [self setOneTapMode:NO];

}

- (void)setDiscussionState:(NSInteger)discussionState
{
    //Remove all discussion UI
    
    if (discussionState == PENDING_STATE) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self setOneTapMode:YES];
        self.imageView.alpha = 0.3;
        
        if (!self.pendingContactOverlay) {
            self.pendingContactOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
            [self.layer addSublayer:self.unreadCircleShape];
            self.pendingContactOverlay.clipsToBounds = YES;
            self.pendingContactOverlay.layer.cornerRadius = self.bounds.size.height/2;
            [self.pendingContactOverlay setBackgroundColor:[UIColor clearColor]];
            [self.pendingContactOverlay setImage:[UIImage imageNamed:@"unknown-user.png"]];
        }
        
        [self addSubview:self.pendingContactOverlay];
    }
    
    else if (discussionState == RECORD_STATE && !(
             self.discussionState == FAILED_STATE || self.discussionState == UNREAD_STATE || self.discussionState == PENDING_STATE)) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self.delegate endTutoMode];
        
        [self startSonarAnimationWithColor:[ImageUtils red]];
        
        self.recordPlayOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
        self.recordPlayOverlay.clipsToBounds = YES;
        self.recordPlayOverlay.alpha = 0.7;
        self.recordPlayOverlay.image = [UIImage imageNamed:@"record"];
        
        [self addSubview:self.recordPlayOverlay];
    }
    
    else if (discussionState == FAILED_STATE && !(self.discussionState == PENDING_STATE)) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self setOneTapMode:YES];
        [self.layer addSublayer:self.failedCircleShape];
        self.failedMessageIcon.hidden = NO;
    }
    
    else if (discussionState == PLAY_STATE && self.discussionState == UNREAD_STATE) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self.delegate endTutoMode];
        
        [self startSonarAnimationWithColor:[ImageUtils green]];
        
        self.recordPlayOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
        self.recordPlayOverlay.clipsToBounds = YES;
        self.recordPlayOverlay.alpha = 0.7;
        self.recordPlayOverlay.image = [UIImage imageNamed:@"play"];
        
        [self addSubview:self.recordPlayOverlay];
    }
    
    else if (discussionState == UNREAD_STATE && !(
        self.discussionState == FAILED_STATE || self.discussionState == RECORD_STATE || self.discussionState == PENDING_STATE || self.discussionState == PLAY_STATE || self.discussionState == SENDING_STATE)) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self setOneTapMode:YES];
        self.unreadMessagesLabel.hidden = NO;
        [self.layer addSublayer:self.unreadCircleShape];
    }
    
    else if (discussionState == LOADING_STATE && !(self.discussionState == FAILED_STATE || self.discussionState == RECORD_STATE || self.discussionState == PENDING_STATE || self.discussionState == PLAY_STATE || self.discussionState == SENDING_STATE || self.discussionState == UNREAD_STATE)) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self startLoadingAnimation];
    }
    
    else if (discussionState == SENDING_STATE || self.discussionState == RECORD_STATE) {
        _discussionState = discussionState;
        [self removeDiscussionUI];
        
        [self startLoadingAnimation];
    }
}

- (void)initUnreadMessagesLabel
{
    self.unreadMessagesLabel = [[UILabel alloc] init];
    [self.unreadMessagesLabel setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2 + 5, -20, kUnreadMessageSize, kUnreadMessageSize)];
    self.unreadMessagesLabel.textColor = [ImageUtils blue];
    self.unreadMessagesLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:18.0];
    self.unreadMessagesLabel.adjustsFontSizeToFitWidth = YES;
    self.unreadMessagesLabel.minimumScaleFactor = 0.2;
    self.unreadMessagesLabel.userInteractionEnabled = YES;
    [self addSubview:self.unreadMessagesLabel];
}

- (UILabel *)allocAndInitCornerLabelWithText:(NSString *)text andColor:(UIColor *)color
{
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2 + 5, -20, kUnreadMessageSize, kUnreadMessageSize)];
    label.textColor = color;
    label.font = [UIFont fontWithName:@"Avenir-Heavy" size:22];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.2;
    label.userInteractionEnabled = YES;
    label.text = text;
    label.alpha = 0;
    [self addSubview:label];
    return label;
}

- (void)setOrderPosition:(NSInteger)orderPosition
{
    if (_orderPosition != orderPosition) {
        _orderPosition = orderPosition;
        [self.delegate updateFrameOfContactView:self];
    }
}

// ----------------------------------------------------------
#pragma mark Handle Gestures
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
                    [TrackingUtils trackRecord];
                } else {
                    [self stopRecording];
                    [self setDiscussionState:EMPTY_STATE];
                    [self.delegate tutoMessage:@"Hold to record." withDuration:1];
                }
            };
        }
    }
}

- (void)startRecording
{
    // Set session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            [GeneralUtils showMessage:@"To activate it, go to Settings > Privacy > Micro" withTitle:@"Waved does not have access to your micro"];
            return;
        } else {
            [self setDiscussionState:RECORD_STATE];
            [session setActive:YES error:nil];
            // Create Timers
            self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
            self.minDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minRecordingDurationReached) userInfo:nil repeats:NO];
            
            [self.delegate startedLongPressOnContactView:self];
        }
    }];
}

- (void)handleSingleTapGesture {
    if (self.discussionState == PENDING_STATE) {
        [self handlePendingTapGesture];
    } else {
        if (self.discussionState == UNREAD_STATE) {
            [self playNextMessage];
        } else if (self.discussionState == FAILED_STATE){
            [self handleFailedMessagesModeTapGesture];
        }
    }
}

- (void)playNextMessage
{
    self.userInteractionEnabled = NO;
    if (!self.nextMessageAudioData) { // should not be possible
        return;
    }
    
    // Start playing
    [self.delegate startedPlayingAudioFileByView:self];
    [self setDiscussionState:PLAY_STATE];
    
    // Get data of next message (asynch) if any
    self.nextMessageAudioData = nil;
    if (self.unreadMessagesCount > 1) {
        [self downloadAudioAndAnimate:(Message *)self.unreadMessages[1]];
    }
    
    // Mark as opened on the database
    // todo bt (later) handle error
    [ApiUtils markMessageAsOpened:((Message *)self.unreadMessages[0]).identifier success:nil failure:nil];
    
    // Remove message
    [self.unreadMessages removeObjectAtIndex:0];
    [self setUnreadMessagesCount:self.unreadMessagesCount-1];
    
    // Update badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
    
    self.userInteractionEnabled = YES;
}

- (void)setOneTapMode:(BOOL)flag
{
    if (flag) {
        self.longPressRecognizer.minimumPressDuration = kLongPressMinDurationForOneTapMode;
    } else {
        self.longPressRecognizer.minimumPressDuration = kLongPressMinDuration;
    }
}

- (void)endRecordingPlayingUI
{
    //previousState not implemented
    [self setDiscussionState:self.previousState];
}


// ----------------------------------------------------------
#pragma mark Pending Contact
// ----------------------------------------------------------

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

- (void)handlePendingTapGesture {
    [self.delegate pendingContactClicked:self.contact];
}

- (void)handleFailedMessagesModeTapGesture
{
    [self.delegate failedMessagesModeTapGestureOnContact:self];
}


// ----------------------------------------------------------
#pragma mark Timer methods
// ----------------------------------------------------------

// Stop recording after kMaxAudioDuration
- (void)maxRecordingDurationReached {
    self.userInteractionEnabled = NO;
    [self endRecordingPlayingUI];
    [self sendRecording];
}

- (void)minRecordingDurationReached {
    // do nothing
}


// ----------------------------------------------------------
#pragma mark Recording utility
// ----------------------------------------------------------

- (void)stopRecording
{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.delegate endedLongPressRecording];
}

- (void)sendRecording
{
    // Update last message date
    self.contact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
    
    [self setDiscussionState:SENDING_STATE];
    
    // Send
    [self.delegate sendMessageToContact:self];
    [TrackingUtils trackRecord];
}

- (void)message:(NSData *)audioData sentWithError:(BOOL)error
{
    if (error) {
        // Stock failed message
        [self.failedMessages addObject:audioData];
        
        [self setDiscussionState:FAILED_STATE];
    } else {
        if (self.discussionState != FAILED_STATE) {
            [self setDiscussionState:EMPTY_STATE];
            
            // Sent message anim
            self.sentMessageIcon.alpha = 1;
            [UIView animateWithDuration:1
                                  delay:1
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.sentMessageIcon.alpha = 0;
                             } completion:nil];
        }
    }
}

- (void)deleteFailedMessages {
    self.failedMessages = [NSMutableArray new];
    [self setDiscussionState:EMPTY_STATE];
}

- (void)resendFailedMessages
{
    // Resend Messages
    for (NSData *audioData in self.failedMessages) {
        [ApiUtils sendMessage:audioData toUser:self.contact.identifier success:^{
            [self message:nil sentWithError:NO];
        } failure:^{
            [self message:audioData sentWithError:YES];
        }];
    }
    
    [self deleteFailedMessages];
    [self setDiscussionState:SENDING_STATE];
}


// ----------------------------------------------------------
#pragma mark Message utility
// ----------------------------------------------------------
- (void)downloadAudioAndAnimate:(Message *)message
{
    // Download animation
    [self setDiscussionState:LOADING_STATE];
    
    // Request data asynch
    [ApiUtils downloadAudioFileAtURL:[message getMessageURL] success:^void(NSData *data) {
        self.nextMessageAudioData = data;
        self.nextMessageId = message.identifier;
        [self setDiscussionState:UNREAD_STATE];
    } failure:^(){
        [self downloadAudioAndAnimate:message];
    }];
}

- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    self.unreadMessagesLabel.text = [NSString stringWithFormat:@"%lu",(long)unreadMessagesCount];
}

- (void)addUnreadMessage:(Message *)message
{
    if (!self.unreadMessages) { // 1st message
        self.unreadMessages = [[NSMutableArray alloc] init];
        self.unreadMessagesCount = 0;
    }
    
    if (self.unreadMessagesCount == 0) {
        [self downloadAudioAndAnimate:message];
    }
    
    [self.unreadMessages addObject:message];
    [self setUnreadMessagesCount:self.unreadMessagesCount+1];
}

- (void)resetUnreadMessages
{
    self.unreadMessages = nil;
    self.unreadMessagesCount = 0;
    self.nextMessageAudioData = nil;
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

- (BOOL)isOneTapMode
{
    return self.longPressRecognizer.minimumPressDuration == kLongPressMinDurationForOneTapMode;
}


@end
