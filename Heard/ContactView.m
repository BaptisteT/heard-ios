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
#define DELAY_BEFORE_RECORDING 0.5
#define DELAY_FOR_SECOND_TAP 0.5
#define TAP_OVERLAY_LENGTH 0.1

@interface ContactView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) UILabel *unreadMessagesLabel;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *recordPlayOverlay;
@property (nonatomic, strong) UIView *tapOverlay;
@property (nonatomic, strong) UIImageView *pendingContactOverlay;
@property (nonatomic, strong) CAShapeLayer *circleShape;
@property (nonatomic, strong) CAShapeLayer *loadingCircleShape;

@property (nonatomic) BOOL cancelLongPress;
@property (nonatomic) BOOL cancelSingleTap;

@property (nonatomic) BOOL firstTap;
@property (nonatomic) BOOL maxDurationTimerReached;

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
    self  = [super initWithFrame:frame];
    self.contact = contact;
    _pendingContact = NO;
    self.clipsToBounds = NO;
    
    //Initialization
    self.nextMessageId = 0;
    self.cancelLongPress = NO;
    self.firstTap = YES;
    self.maxDurationTimerReached = NO;
    
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
    self.longPressRecognizer.minimumPressDuration = 0;
    
    //Init tap overlay
    self.tapOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.tapOverlay.clipsToBounds = YES;
    self.tapOverlay.layer.cornerRadius = self.bounds.size.width/2;
    self.tapOverlay.alpha = 0.4;
    self.tapOverlay.backgroundColor = [ImageUtils blue];
    
    // Init unread messages button
    [self initUnreadMessagesButton];
    self.unreadMessagesCount = 0;
    
    // Set up the shape of the load messagecircle
    self.loadingCircleShape = [CAShapeLayer layer];
    self.loadingCircleShape.path = [UIBezierPath bezierPathWithRoundedRect:self.imageView.frame
                                                              cornerRadius:self.bounds.size.height/2].CGPath;
    
    return self;
}

- (void)initUnreadMessagesButton
{
    self.unreadMessagesLabel = [[UILabel alloc] init];
    [self.unreadMessagesLabel setFrame:CGRectMake(kContactSize - kUnreadMessageSize/2, -15, kUnreadMessageSize, kUnreadMessageSize)];
    self.unreadMessagesLabel.textColor = [ImageUtils blue];
    self.unreadMessagesLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:16.0];
    self.unreadMessagesLabel.adjustsFontSizeToFitWidth = YES;
    self.unreadMessagesLabel.minimumScaleFactor = 0.2;
    self.unreadMessagesLabel.userInteractionEnabled = YES;
    [self addSubview:self.unreadMessagesLabel];
    [self hideMessageCountLabel:YES];
}

- (void)setOrderPosition:(NSInteger)orderPosition
{
    _orderPosition = orderPosition;
    [self.delegate updateFrameOfContactView:self];
}

// ----------------------------------------------------------
#pragma mark Handle Gestures
// ----------------------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self showTapOverlay];
        
        if (self.firstTap) {
            [self performSelector:@selector(startRecording) withObject:self afterDelay:DELAY_BEFORE_RECORDING];
        }
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        [self hideTapOverlay];
        [self endRecordingPlayingUI];
        
        if ([self.delegate isRecording]) {
            if ([self.maxDurationTimer isValid]) {
                [self.maxDurationTimer invalidate];
            }
            
            [self sendRecording];
        } else {
            if (self.firstTap) {
                
                //If view released after max duration time reached, consume event
                if (self.maxDurationTimerReached) {
                    self.maxDurationTimerReached = NO;
                    return;
                }
                
                self.cancelLongPress = YES;
                
                [self performSelector:@selector(handleSingleTapGesture) withObject:self afterDelay:DELAY_FOR_SECOND_TAP];
                self.firstTap = NO;
            } else {
                self.cancelSingleTap = YES;
                [self handleDoubleTapGesture];
            }
        }
    }
}

- (void)startRecording
{
    self.firstTap = YES;
    
    if (self.cancelLongPress) {
        self.cancelLongPress = NO;
    } else {
        self.cancelLongPress = NO;
        
        [self startRecordingUI];
        
        // Set session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                [GeneralUtils showMessage:@"To activate it, go to Settings > Privacy > Micro" withTitle:@"Waved does not have access to your micro"];
                return;
            } else {
                [session setActive:YES error:nil];
                
                // Create Timer
                self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
                
                //TODO Vibrate
                
                [self.delegate startedLongPressOnContactView:self];
            }
        }];
    }
}

- (void)handleSingleTapGesture {
    self.firstTap = YES;
    
    if (self.cancelSingleTap) {
        self.cancelSingleTap = NO;
    } else {
        if (self.pendingContact) {
            [self handlePendingTapGesture];
        } else {
            [self handleNonPendingTapGesture];
        }
    }
}

- (void)handleDoubleTapGesture {
    if (self.pendingContact) {
        [self handlePendingTapGesture];
    } else {
        [self.delegate doubleTappedOnContactView:self];
    }
}

- (void)handleNonPendingTapGesture
{
    if ([self hasMessagesToPlay]) {
        self.userInteractionEnabled = NO;
        if (!self.nextMessageAudioData) { // should not be possible
            return;
        }
        
        // Save data to file (for FDWaveFormView)
        if (![self.nextMessageAudioData writeToURL:[GeneralUtils getPlayedAudioURL] atomically:NO]) {
            NSLog(@"saving failure");
        }
        
        // Stat playing
        [self.delegate startedPlayingAudioFileByView:self];
        
        // Get data of next message (asynch) if any
        [self hideMessageCountLabel:YES];
        self.nextMessageAudioData = nil;
        if (self.unreadMessagesCount > 1) {
            // Download animation
            [self startLoadingMessageAnimation];
            
            [ApiUtils downloadAudioFileAtURL:[self.unreadMessages[1] getMessageURL] success:^void(NSData *data) {
                self.nextMessageAudioData = data;
                [self hideMessageCountLabel:NO];
                [self endLoadingMessageAnimation];
            } failure:^(){
                [self endLoadingMessageAnimation];
            }];
        }
        
        // Mark as opened on the database
        // todo bt handle error
        [ApiUtils markMessageAsOpened:((Message *)self.unreadMessages[0]).identifier success:nil failure:nil];
        
        // Remove message
        [self.unreadMessages removeObjectAtIndex:0];
        [self setUnreadMessagesCount:self.unreadMessagesCount-1];
        
        // Update badge
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
        
        self.userInteractionEnabled = YES;
    } else {
        [self.delegate noMessageModeWithDuration:3];
    }
}


// ----------------------------------------------------------
#pragma mark Pending Contact
// ----------------------------------------------------------
- (void)setPendingContact:(BOOL)pendingContact
{
    _pendingContact = pendingContact;
    if (pendingContact) {
        [self removeGestureRecognizer:self.longPressRecognizer];
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
         [self addGestureRecognizer:self.longPressRecognizer];
         self.imageView.alpha = 1;
         if (self.pendingContactOverlay) {
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


// ----------------------------------------------------------
#pragma mark Timer methods
// ----------------------------------------------------------

// Stop recording after kMaxAudioDuration
- (void)maxRecordingDurationReached {
    self.maxDurationTimerReached = YES;
    self.userInteractionEnabled = NO;
    
    [self endRecordingPlayingUI];
    [self sendRecording];
}


// ----------------------------------------------------------
#pragma mark Recording utility
// ----------------------------------------------------------

- (void)sendRecording
{
    //TODO Vibrate
    
    [self stopRecording];
    
    [self.delegate sendRecordtoContact:self.contact];
    
    [TrackingUtils trackRecord];
}

- (void)stopRecording
{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    [self.delegate endedLongPressOnContactView:self];
}


// ----------------------------------------------------------
#pragma mark Message utility
// ----------------------------------------------------------
- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    self.unreadMessagesLabel.text = [NSString stringWithFormat:@"%lu",(long)unreadMessagesCount];
    if (unreadMessagesCount == 0) {
        [self hideMessageCountLabel:YES];
    }
}

- (void)addUnreadMessage:(Message *)message
{
    if (!self.unreadMessages) { // 1st message
        self.unreadMessages = [[NSMutableArray alloc] init];
        self.unreadMessagesCount = 0;
    }
    if (self.unreadMessagesCount == 0) {
        // Download animation
        [self startLoadingMessageAnimation];
        
        // Request data asynch 
        [ApiUtils downloadAudioFileAtURL:[message getMessageURL] success:^void(NSData *data) {
            self.nextMessageAudioData = data;
            self.nextMessageId = message.identifier;
            [self hideMessageCountLabel:NO];
            [self endLoadingMessageAnimation];
        } failure:^(){
            [self endLoadingMessageAnimation];
        }];
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
        self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.imageView.layer.borderWidth = NO_UNREAD_MESSAGES_BORDER;
    } else {
        self.unreadMessagesLabel.hidden = NO;
        self.imageView.layer.borderColor = [ImageUtils blue].CGColor;
        self.imageView.layer.borderWidth = UNREAD_MESSAGES_BORDER;
    }
}


// ----------------------------------------------------------
#pragma mark Design utility
// ----------------------------------------------------------
- (void)startRecordingUI
{
    [self hideTapOverlay];
    [self endRecordingPlayingUI];
    
    [self startSonarAnimationWithColor:[ImageUtils red]];
    
    self.recordPlayOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordPlayOverlay.clipsToBounds = YES;
    self.recordPlayOverlay.alpha = 0.7;
    self.recordPlayOverlay.image = [UIImage imageNamed:@"record"];
    
    [self addSubview:self.recordPlayOverlay];
}

- (void)startPlayingUI
{
    [self hideTapOverlay];
    [self endRecordingPlayingUI];
    
    [self startSonarAnimationWithColor:[ImageUtils green]];
    
    self.recordPlayOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordPlayOverlay.clipsToBounds = YES;
    self.recordPlayOverlay.alpha = 0.7;
    self.recordPlayOverlay.image = [UIImage imageNamed:@"play"];
    
    [self addSubview:self.recordPlayOverlay];
}

- (void)startSonarAnimationWithColor:(UIColor *)color
{
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(self.bounds), -CGRectGetMidY(self.bounds), self.bounds.size.width, self.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:self.bounds.size.height];
    
    // accounts for left/right offset and contentOffset of scroll view
    //    CGPoint shapePosition = [self.superview.superview convertPoint:self.center fromView:self.superview.superview];
    CGPoint shapePosition = [self.superview convertPoint:self.center fromView:self.superview];
    
    self.circleShape = [CAShapeLayer layer];
    self.circleShape.path = path.CGPath;
    self.circleShape.position = shapePosition;
    self.circleShape.fillColor = [UIColor clearColor].CGColor;
    self.circleShape.opacity = 1;
    self.circleShape.strokeColor = color.CGColor;
    self.circleShape.lineWidth = 2.0;
    
    //    [self.superview.superview.layer addSublayer:circleShape];
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

- (void)endRecordingPlayingUI
{
    [self endSonarAnimation];
    
    [self.recordPlayOverlay removeFromSuperview];
    self.recordPlayOverlay = nil;
    
    [self.delegate noMessageMode];
}

- (void)showTapOverlay
{
    [self addSubview:self.tapOverlay];
}

- (void)hideTapOverlay
{
    [self.tapOverlay removeFromSuperview];
}

- (void)startLoadingMessageAnimation
{
    // Configure the apperence of the circle
    self.loadingCircleShape.fillColor = [UIColor clearColor].CGColor;
    self.loadingCircleShape.strokeColor = [ImageUtils blue].CGColor;
    self.loadingCircleShape.lineWidth = UNREAD_MESSAGES_BORDER;
    
    // Add to parent layer
    [self.imageView.layer addSublayer:self.loadingCircleShape];
    
    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.beginTime            = 0.0;
    drawAnimation.duration            = 2.0;
    drawAnimation.repeatCount         = INFINITY;
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0];
    drawAnimation.removedOnCompletion = YES;
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    // Add the animation to the circle
    [self.loadingCircleShape addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
}

- (void)endLoadingMessageAnimation
{
    [self.loadingCircleShape removeAllAnimations];
    [self.loadingCircleShape removeFromSuperlayer];
}

- (BOOL)hasMessagesToPlay
{
    return self.unreadMessagesCount > 0 && self.nextMessageAudioData;
}

@end
