//
//  NewInviteContactsViewController.m
//  Heard
//
//  Created by Bastien Beurier on 10/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "NewInviteContactsViewController.h"
#import "Constants.h"
#import <AVFoundation/AVFoundation.h>
#import "ImageUtils.h"

@interface NewInviteContactsViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *microView;
@property (weak, nonatomic) IBOutlet UITextView *tutoLabelView;
@property (weak, nonatomic) IBOutlet UIButton *addContactButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic, strong) NSTimer *minDurationTimer;
@property (nonatomic, strong) CAShapeLayer *circleShape;

@property (nonatomic, strong) AVAudioPlayer *soundPlayer;
@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation NewInviteContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.microView setMultipleTouchEnabled:NO];
    self.microView.userInteractionEnabled = YES;
    self.microView.exclusiveTouch = YES;
    
    [self initTapAndLongPressGestureRecognisers];
    
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"audio.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:kAVSampleRateKey] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: kAVNumberOfChannelsKey] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addContactButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"Add Contact Segue" sender:nil];
}


- (void)initTapAndLongPressGestureRecognisers
{
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.microView addGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self startRecording];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        
        if ([self.maxDurationTimer isValid]) {
            [self.maxDurationTimer invalidate];
            
            [self stopRecording];
            
            if ([self.minDurationTimer isValid]) {
                //BB TODO: Tuto TOO SHORT
            } else {
                [self goToShareContoller];
            }
        }
    }
}

- (void)startRecording
{
    //TODO BB: hide too short tuto
    //TODO BB: hide all views
    
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
            // Create Timers
            self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
            self.minDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minRecordingDurationReached) userInfo:nil repeats:NO];
            
            [self startRecordingAnimation];
            
            [self playSound:kStartRecordSound];
            
            [self.recorder record];
        }
    }];
}

- (void)stopRecording
{
    [self endRecordingAnimation];
    [self.recorder stop];
    [self playSound:kEndRecordSound];
}

// Stop recording after kMaxAudioDuration
- (void)maxRecordingDurationReached {
    self.microView.userInteractionEnabled = NO;
    [self stopRecording];
    [self goToShareContoller];
}

- (void)minRecordingDurationReached {
    //Do nothing
}

- (void)goToShareContoller
{
    [self performSegueWithIdentifier:@"Share Invitation Segue" sender:nil];
}

- (void)playSound:(NSString *)sound
{
    if ([self.soundPlayer isPlaying]) {
        [self.soundPlayer stop];
    }
    
    NSError* error;
    if ([sound isEqualToString:kStartRecordSound]) {
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tink.caf"] error:&error];
    } else if ([sound isEqualToString:kEndRecordSound]) {
        self.soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:@"/System/Library/Audio/UISounds/Tock.caf"] error:&error];
    }
    
    if (error || ![self.soundPlayer prepareToPlay]) {
        NSLog(@"%@",error);
    } else {
        [self.soundPlayer play];
    }
}

// ----------------------------------------------------------
#pragma mark Animation
// ----------------------------------------------------------

- (void)startRecordingAnimation
{
    self.microView.image = [UIImage imageNamed:@"invite-record-button-pressed"];
    self.backButton.hidden = YES;
    self.tutoLabelView.hidden = YES;
    self.addContactButton.hidden = YES;
    [self startSonarAnimationWithColor:[ImageUtils red]];
}

- (void)endRecordingAnimation
{
    self.microView.image = [UIImage imageNamed:@"invite-record-button"];
    self.backButton.hidden = NO;
    self.tutoLabelView.hidden = NO;
    self.addContactButton.hidden = NO;
    [self endSonarAnimation];
}

- (void)startSonarAnimationWithColor:(UIColor *)color
{
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(self.microView.bounds) + 10, -CGRectGetMidY(self.microView.bounds) + 10, self.microView.bounds.size.width - 20, self.microView.bounds.size.height - 20);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:self.microView.bounds.size.height];
    
    CGPoint shapePosition = [self.microView.superview convertPoint:self.microView.center fromView:self.microView.superview];
    
    self.circleShape = [CAShapeLayer layer];
    self.circleShape.path = path.CGPath;
    self.circleShape.position = shapePosition;
    self.circleShape.fillColor = [UIColor clearColor].CGColor;
    self.circleShape.opacity = 1;
    self.circleShape.strokeColor = color.CGColor;
    self.circleShape.lineWidth = 2.0;
    
    [self.microView.superview.layer addSublayer:self.circleShape];
    
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


@end
