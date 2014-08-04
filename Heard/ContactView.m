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

#define UNREAD_MESSAGES_BORDER 2.5
#define NO_UNREAD_MESSAGES_BORDER 0.5
#define LOADING_BORDER 2
#define DEGREES_TO_RADIANS(x) (x)/180.0*M_PI
#define RADIANS_TO_DEGREES(x) (x)/M_PI*180.0

@interface ContactView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic, strong) NSTimer *minDurationTimer;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) UILabel *unreadMessagesLabel;
@property (nonatomic, strong) UIImageView *recordPlayOverlay;
@property (nonatomic, strong) UIImageView *pendingContactOverlay;
@property (nonatomic, strong) UIView *contactOverlay;
@property (nonatomic, strong) CAShapeLayer *circleShape;
@property (nonatomic, strong) CAShapeLayer *loadingCircleShape;
@property (nonatomic) BOOL cancelLongPress;
@property (nonatomic) BOOL failedMessagesMode;
@property (nonatomic, strong) UILabel *failedMessageIcon;
@property (nonatomic, strong) UILabel *sentMessageIcon;

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
    _failedMessagesMode = NO; // custom setter
    _pendingContact = NO; // custom setter
    self.clipsToBounds = NO;
    
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
    self.loadingCircleShape = [ImageUtils createGradientCircleLayerWithFrame:self.frame borderWidth:LOADING_BORDER Color:[ImageUtils blue] subDivisions:100];
    // init send / fail images
    self.sentMessageIcon = [self allocAndInitCornerLabelWithText:@"\u2713" andColor:[ImageUtils green]];
    self.failedMessageIcon = [self allocAndInitCornerLabelWithText:@"!" andColor:[ImageUtils red]];
    
    return self;
}

- (void)initUnreadMessagesLabel
{
    self.unreadMessagesLabel = [[UILabel alloc] init];
    [self.unreadMessagesLabel setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2, -15, kUnreadMessageSize, kUnreadMessageSize)];
    self.unreadMessagesLabel.textColor = [ImageUtils blue];
    self.unreadMessagesLabel.font = [UIFont fontWithName:@"Avenir" size:16.0];
    self.unreadMessagesLabel.adjustsFontSizeToFitWidth = YES;
    self.unreadMessagesLabel.minimumScaleFactor = 0.2;
    self.unreadMessagesLabel.userInteractionEnabled = YES;
    [self addSubview:self.unreadMessagesLabel];
    [self hideMessageCountLabel:YES];
}

- (UILabel *)allocAndInitCornerLabelWithText:(NSString *)text andColor:(UIColor *)color
{
    UILabel *label = [[UILabel alloc] init];
    [label setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2, -15, kUnreadMessageSize, kUnreadMessageSize)];
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
    // Safety: Case where long press should be disabled
    if (self.pendingContact || self.failedMessagesMode || [self hasMessagesToPlay]) {
        [self.longPressRecognizer setEnabled:NO];
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self startRecording];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        
        [self endRecordingPlayingUI];
        
        // Stop timer if it did not fire yet
        if ([self.maxDurationTimer isValid]) {
            [self.maxDurationTimer invalidate];
            
            if([self.delegate isRecording] && ![self.minDurationTimer isValid]) {
                [self sendRecording];
                [TrackingUtils trackRecord];
            } else {
                [self stopRecording];
                [self.delegate tutoMessage:@"Hold to record." withDuration:1];
            }
        };
    }
}

- (void)startRecording
{
    [self startRecordingUI];
    
    // Set session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session requestRecordPermission:^(BOOL granted) {
        if (!granted) {
            [GeneralUtils showMessage:@"To activate it, go to Settings > Privacy > Micro" withTitle:@"Waved does not have access to your micro"];
            return;
        } else {
            [session setActive:YES error:nil];
            // Create Timers
            self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
            self.minDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minRecordingDurationReached) userInfo:nil repeats:NO];
            
            [self.delegate startedLongPressOnContactView:self];
        }
    }];
}

- (void)handleSingleTapGesture {
    if (self.pendingContact) {
        [self handlePendingTapGesture];
    } else {
        if ([self hasMessagesToPlay]) {
            [self playNextMessage];
        } else if (self.failedMessagesMode){
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
    
    // Stat playing
    [self.delegate startedPlayingAudioFileByView:self];
    
    // Get data of next message (asynch) if any
    [self hideMessageCountLabel:YES];
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


// ----------------------------------------------------------
#pragma mark Pending Contact
// ----------------------------------------------------------
- (void)setPendingContact:(BOOL)pendingContact
{
    _pendingContact = pendingContact;
    if (pendingContact) {
        [self.longPressRecognizer setEnabled:NO];
        if (!self.pendingContactOverlay) {
            self.pendingContactOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
            self.pendingContactOverlay.layer.borderColor = [ImageUtils blue].CGColor;
            self.pendingContactOverlay.layer.borderWidth = UNREAD_MESSAGES_BORDER;
            self.pendingContactOverlay.clipsToBounds = YES;
            self.pendingContactOverlay.layer.cornerRadius = self.bounds.size.height/2;
            [self.pendingContactOverlay setBackgroundColor:[UIColor clearColor]];
            self.imageView.alpha = 0.3;
            [self.pendingContactOverlay setImage:[UIImage imageNamed:@"unknown-user.png"]];
        }
        [self addSubview:self.pendingContactOverlay];
     } else {
         self.imageView.alpha = 1;
         if (self.pendingContactOverlay) {
             [self.longPressRecognizer setEnabled:YES];
             [self.pendingContactOverlay removeFromSuperview];
         }
     }
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

- (void)sendRecording
{
    [self stopRecording];
    // Send
    [self.delegate sendMessageToContact:self];
    [TrackingUtils trackRecord];
    
    // Sending animation
    [self startLoadingAnimationWithStrokeColor:[ImageUtils blue]];
}

- (void)stopRecording
{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.delegate endedLongPressRecording];
}

- (void)message:(NSData *)audioData sentWithError:(BOOL)error
{
    // Update last message date
    self.contact.lastMessageDate = [[NSDate date] timeIntervalSince1970];
    
    // stop sending anim
    [self endLoadingAnimation];
    
    if (error) {
        // Stock failed message
        [self.failedMessages addObject:audioData];
        self.failedMessagesMode = YES;
    } else {
        if (!self.failedMessagesMode) {
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
    self.failedMessagesMode = NO;
}

- (void)setFailedMessagesMode:(BOOL)failedMessagesMode
{
    if (failedMessagesMode) {
        _failedMessagesMode = YES;
        [self.longPressRecognizer setEnabled:NO];
        [self startFailedMessagesUI];
    } else {
        _failedMessagesMode = NO;
        [self.longPressRecognizer setEnabled:YES];
        [self endFailedMessagesUI];
    }
}


// ----------------------------------------------------------
#pragma mark Message utility
// ----------------------------------------------------------
- (void)downloadAudioAndAnimate:(Message *)message
{
    // Download animation
    [self startLoadingAnimationWithStrokeColor:[ImageUtils blue]];
    
    // Request data asynch
    [ApiUtils downloadAudioFileAtURL:[message getMessageURL] success:^void(NSData *data) {
        self.nextMessageAudioData = data;
        self.nextMessageId = message.identifier;
        [self hideMessageCountLabel:NO];
        [self endLoadingAnimation];
    } failure:^(){
        [self endLoadingAnimation];
    }];
}

- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    self.unreadMessagesLabel.text = [NSString stringWithFormat:@"%lu",(long)unreadMessagesCount];
    if (unreadMessagesCount == 0) {
        [self hideMessageCountLabel:YES];
        [self.longPressRecognizer setEnabled:YES];
    } else {
        [self.longPressRecognizer setEnabled:NO];
    }
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

- (void)hideMessageCountLabel:(BOOL)flag {
    if (flag) {
        self.unreadMessagesLabel.hidden = YES;
        [self hideContactOverlay];
    } else {
        self.unreadMessagesLabel.hidden = NO;
        [self showContactOverlayOfColor:[ImageUtils blue]];
    }
}


// ----------------------------------------------------------
#pragma mark Design utility
// ----------------------------------------------------------
- (void)startRecordingUI
{
    [self endRecordingPlayingUI];
    [self.delegate endTutoMode];
    
    [self startSonarAnimationWithColor:[ImageUtils red]];
    
    self.recordPlayOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordPlayOverlay.clipsToBounds = YES;
    self.recordPlayOverlay.alpha = 0.7;
    self.recordPlayOverlay.image = [UIImage imageNamed:@"record"];
    
    [self addSubview:self.recordPlayOverlay];
}

- (void)startPlayingUI
{
    [self endRecordingPlayingUI];
    [self.delegate endTutoMode];
    
    [self startSonarAnimationWithColor:[ImageUtils green]];
    
    self.recordPlayOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordPlayOverlay.clipsToBounds = YES;
    self.recordPlayOverlay.alpha = 0.7;
    self.recordPlayOverlay.image = [UIImage imageNamed:@"play"];
    
    [self addSubview:self.recordPlayOverlay];
    [self.loadingCircleShape setHidden:YES];
}

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
    [self.loadingCircleShape setHidden:NO];
}

- (void)endRecordingPlayingUI
{
    [self endSonarAnimation];
    
    [self.recordPlayOverlay removeFromSuperview];
    self.recordPlayOverlay = nil;
    [self.contactOverlay removeFromSuperview];
}

- (void)startLoadingAnimationWithStrokeColor:(UIColor *)color
{
    // Add to parent layer
    [self.layer addSublayer:self.loadingCircleShape];
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
    rotationAnimation.duration = 1.0;
    rotationAnimation.repeatCount = INFINITY;
    
    [self.loadingCircleShape addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
}

- (void)endLoadingAnimation
{
    [self.loadingCircleShape removeAllAnimations];
    [self.loadingCircleShape removeFromSuperlayer];
}

- (BOOL)hasMessagesToPlay
{
    return self.unreadMessagesCount > 0 && self.nextMessageAudioData;
}

- (void)hideContactOverlay
{
    // if unread messages, blue
    if ([self hasMessagesToPlay]) {
        [self showContactOverlayOfColor:[ImageUtils blue]];
    // if failed, red
    } else if (self.failedMessagesMode) {
        [self showContactOverlayOfColor:[ImageUtils red]];
    } else {
        // standard border
        self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.imageView.layer.borderWidth = NO_UNREAD_MESSAGES_BORDER;
        // remove overlay
        [self.contactOverlay removeFromSuperview];
    }
}

- (void)showContactOverlayOfColor:(UIColor *)color
{
    if (!self.contactOverlay) {
        self.contactOverlay = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
        self.contactOverlay.clipsToBounds = YES;
        self.contactOverlay.alpha = 0.25;
    }
    
    // Blue if unread messages, red otherwise
    UIColor *dominantColor = [self hasMessagesToPlay] ? [ImageUtils blue] : color;
    self.contactOverlay.backgroundColor = dominantColor;
    [self.imageView addSubview:self.contactOverlay];
    
    // Border Color
    self.imageView.layer.borderColor = dominantColor.CGColor;
    self.imageView.layer.borderWidth = UNREAD_MESSAGES_BORDER;

}

- (void)startFailedMessagesUI
{
    // start by hiding success
    [self.sentMessageIcon.layer removeAllAnimations];
    self.sentMessageIcon.alpha = 0;
    
    [self showContactOverlayOfColor:[ImageUtils red]];
    self.failedMessageIcon.alpha = 1;
}

- (void)endFailedMessagesUI
{
    [self hideContactOverlay];
    self.failedMessageIcon.alpha = 0;
}


@end
