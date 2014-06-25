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

#define UNREAD_MESSAGES_BORDER 3
#define NO_UNREAD_MESSAGES_BORDER 0.5

@interface ContactView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *oneTapRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationTimer;
@property (nonatomic, strong) NSTimer *minDurationTimer;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) UILabel *unreadMessagesLabel;
@property (nonatomic) NSMutableArray *unreadMessages;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) NSTimer *metersTimer;
@property (nonatomic, strong) UIImageView *recordingOverlay;
@property (nonatomic, strong) NSData *nextMessageAudioData;
@property (nonatomic, strong) UIImageView *pendingContactOverlay;

@end

@implementation ContactView


// ----------------------------------------------------------
// Initialization
// ----------------------------------------------------------

- (id)initWithContactBubble:(Contact *)contact andFrame:(CGRect)frame;
{
    self  = [self initWithFrame:frame];
    self.contact = contact;
    _pendingContact = NO;
    self.clipsToBounds = NO;
    
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
    
    self.oneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture)];
    [self addGestureRecognizer:self.oneTapRecognizer];
    self.oneTapRecognizer.delegate = self;
    self.oneTapRecognizer.numberOfTapsRequired = 1;

    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"audio.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:kAVSampleRateKey] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: kAVNumberOfChannelsKey] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    
    // Init unread messages button
    [self initUnreadMessagesButton];
    self.unreadMessagesCount = 0;
    
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


// ----------------------------------------------------------
// Handle Gestures
// ----------------------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    // todo BT (later)
    // check micro is available, else warm user
    
    if ([self.delegate.mainPlayer isPlaying]) {
        [self.delegate endPlayerUI];
    }
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self recordingUI];
        
        // Create Timer
        self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
        self.minDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minRecordingDurationReached) userInfo:nil repeats:NO];
        
        // Record
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [self.recorder record];
        
        [self.delegate longPressOnContactBubbleViewStarted:self.contact.identifier FromView:self];
        
        self.metersTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                           target:self
                                                         selector:@selector(notifyNewMeters)
                                                         userInfo:nil
                                                          repeats:YES];
        
        [self.metersTimer fire];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        [self endRecordingUI];
        
        // Stop timer if it did not fire yet
        if ([self.maxDurationTimer isValid]) {
            [self.maxDurationTimer invalidate];
            if ([self.minDurationTimer isValid]) {
                [self.minDurationTimer invalidate];
                [self stopRecording];
                [self.delegate quitRecodingModeAnimated:NO];
                [GeneralUtils showMessage:@"Hold to record." withTitle:nil];
            } else {
                [self sendRecording];
            }
        }
    }
}

- (void)handleTapGesture {
    if (self.pendingContact) {
        [self handlePendingTapGesture];
    } else {
        [self handleNonPendingTapGesture];
    }
}

- (void)handleNonPendingTapGesture
{
    //BB: weird condition?
    if (!self.unreadMessagesLabel.isHidden) { // ie. self.unreadMessageCount > 0 && self.nextMessageAudioData !=nil
        self.userInteractionEnabled = NO;
        
        if ([self.delegate.mainPlayer isPlaying]) {
            [self.delegate endPlayerUI];
        }
        
        if (!self.nextMessageAudioData) {
            // should not be possible
            return;
        }
        self.delegate.mainPlayer = [[AVAudioPlayer alloc] initWithData:self.nextMessageAudioData error:nil];
        [self.delegate.mainPlayer setVolume:kAudioPlayerVolume];
        
        // Get data of next message (asynch) if any
        [self hideMessageCountLabel:YES];
        self.nextMessageAudioData = nil;
        if (self.unreadMessagesCount > 1) {
            [ApiUtils downloadAudioFileAtURL:[self.unreadMessages[1] getMessageURL] success:^void(NSData *data) {
                self.nextMessageAudioData = data;
                [self hideMessageCountLabel:NO];
            } failure:nil];
        }
        
        // Mark as opened on the database
        [ApiUtils markMessageAsOpened:((Message *)self.unreadMessages[0]).identifier success:nil failure:nil];
        
        // Remove message
        [self.unreadMessages removeObjectAtIndex:0];
        [self setUnreadMessagesCount:self.unreadMessagesCount-1];
        
        // Update badge
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
        
        [self.delegate startedPlayingAudioFileByView:self];
        [self.delegate.mainPlayer play];
        self.userInteractionEnabled = YES;
    } else {
        [GeneralUtils showMessage:@"Hold to record." withTitle:nil];
    }
}


// ----------------------------------------------------------
// Pending Contact
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
            [self.pendingContactOverlay setBackgroundColor:[UIColor whiteColor]];
            [self.pendingContactOverlay setImage:[UIImage imageNamed:@"unknown-user.png"]];
        }
        [self addSubview:self.pendingContactOverlay];
     } else {
         [self addGestureRecognizer:self.longPressRecognizer];
         if (self.pendingContactOverlay) {
             [self.pendingContactOverlay removeFromSuperview];
         }
     }
}

- (void)setContactPicture
{
    
    [self.imageView setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:self.contact.identifier] placeholderImage:[UIImage imageNamed:@"contact-placeholder.png"]];
}

- (void)handlePendingTapGesture {
    [self.delegate pendingContactClicked:self.contact];
}

// ----------------------------------------------------------
// Timer methods
// ----------------------------------------------------------

// Stop recording after kMaxAudioDuration
- (void)maxRecordingDurationReached {
    self.userInteractionEnabled = NO;
    [self sendRecording];
}

- (void)minRecordingDurationReached {
    // do nothing
}

//TODO: Should be in DashBoard
- (void)notifyNewMeters
{
    [self.recorder updateMeters];
    [self.delegate notifiedNewMeters:[self.recorder averagePowerForChannel:0]];
}


// ----------------------------------------------------------
// Recording utility
// ----------------------------------------------------------

- (void)sendRecording
{
    [self stopRecording];
    
    NSData *audioData = [[NSData alloc] initWithContentsOfURL:self.recorder.url];
    [ApiUtils sendMessage:audioData toUser:self.contact.identifier success:^{
        [self.delegate messageSentWithError:NO];
    } failure:^{
        [self.delegate messageSentWithError:YES];
    }];
}

- (void)stopRecording
{
    [self.metersTimer invalidate];
    [self.recorder stop];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    [self.delegate longPressOnContactBubbleViewEnded:self.contact.identifier];
    // For the max duration case
    self.userInteractionEnabled = YES;
}


// ----------------------------------------------------------
// Message utility
// ----------------------------------------------------------
- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    self.unreadMessagesLabel.text = [NSString stringWithFormat:@"%lu",(long)unreadMessagesCount];
    if (unreadMessagesCount == 0) {
        self.longPressRecognizer.minimumPressDuration = 0;
    } else {
        self.longPressRecognizer.minimumPressDuration = kLongPressMinDuration;
    }
}

- (void)addUnreadMessage:(Message *)message
{
    if (!self.unreadMessages) { // 1st message
        self.unreadMessages = [[NSMutableArray alloc] init];
        self.unreadMessagesCount = 0;
    }
    if (self.unreadMessagesCount == 0) {
        // Request data asynch 
        [ApiUtils downloadAudioFileAtURL:[message getMessageURL] success:^void(NSData *data) {
            self.nextMessageAudioData = data;
            [self hideMessageCountLabel:NO];
        } failure:nil];
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
// Design utility
// ----------------------------------------------------------
- (void)recordingUI
{
    [self endRecordingUI];
    
    self.recordingOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordingOverlay.clipsToBounds = YES;
    self.recordingOverlay.alpha = 0.7;
    self.recordingOverlay.image = [UIImage imageNamed:@"record"];
    
    [self addSubview:self.recordingOverlay];
}

- (void)endRecordingUI
{
    [self.recordingOverlay removeFromSuperview];
    self.recordingOverlay = nil;
}

- (void)playingUI
{
    [self endRecordingUI];
    
    self.recordingOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height)];
    self.recordingOverlay.clipsToBounds = YES;
    self.recordingOverlay.alpha = 0.7;
    self.recordingOverlay.image = [UIImage imageNamed:@"play"];
    
    [self addSubview:self.recordingOverlay];
}

- (void)endPlayingUI
{
    [self.recordingOverlay removeFromSuperview];
    self.recordingOverlay = nil;
}

@end
