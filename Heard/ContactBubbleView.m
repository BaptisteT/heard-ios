//
//  FriendBubbleView.m
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "ContactBubbleView.h"
#import "UIImageView+AFNetworking.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "ApiUtils.h"
#import "SessionUtils.h"
#import "ImageUtils.h"


@interface ContactBubbleView()

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

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation ContactBubbleView


- (id)initWithContactBubble:(Contact *)contact andFrame:(CGRect)frame;
{
    self  = [self initWithFrame:frame];
    self.contact = contact;
    
    self.clipsToBounds = NO;
    
    // Set image view
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kContactSize, kContactSize)];
    [self.imageView setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:contact.identifier]];
    [self addSubview:self.imageView];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.bounds.size.height/2;
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.borderWidth = 0.5;
    
    // Alloc and add gesture recognisers
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.imageView addGestureRecognizer:self.longPressRecognizer];
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


// ----------------------------------------------------------
// Handle Gestures
// ----------------------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    // todo BT (later)
    // check micro is available, else warm user
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Create Timer
        self.maxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(maxRecordingDurationReached) userInfo:nil repeats:NO];
        self.minDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minRecordingDurationReached) userInfo:nil repeats:NO];
        
        // Record
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [self.recorder record];
        
        [self.delegate longPressOnContactBubbleViewStarted:self.contact.identifier];
        
        self.metersTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                           target:self
                                                         selector:@selector(notifyNewMeters)
                                                         userInfo:nil
                                                          repeats:YES];
        
        [self.metersTimer fire];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Stop timer if it did not fire yet
        if ([self.maxDurationTimer isValid]) {
            [self.maxDurationTimer invalidate];
            if ([self.minDurationTimer isValid]) {
                [self stopRecording];
                [self.delegate quitRecodingModeAnimated:NO];
            } else {
                [self stopAndSendRecording];
            }
        }
    }
}

- (void)notifyNewMeters
{
    [self.recorder updateMeters];
    [self.delegate notifiedNewMeters:[self.recorder averagePowerForChannel:0]];
    
}

- (void)handleTapGesture
{
    if (self.unreadMessagesCount > 0) {
        [self.delegate startedPlayingAudioFileWithDuration:self.player.duration data:self.player.data andView:self];
        [self.player play];
    } else {
        [GeneralUtils showMessage:@"Hold to record." withTitle:nil];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        // Mark as opened on the database
        [ApiUtils markMessageAsOpened:((Message *)self.unreadMessages[0]).identifier success:nil failure:nil];
        
        // Remove message
        [self.unreadMessages removeObjectAtIndex:0];
        [self setUnreadMessagesCount:self.unreadMessagesCount-1];
        
        // Update badge
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
        
        // prepare player for next song
        if (self.unreadMessagesCount > 0) {
            NSData* data = [NSData dataWithContentsOfURL:[self.unreadMessages[0] getMessageURL]] ;
            self.player = [[AVAudioPlayer alloc] initWithData:data error:nil];
            [self.player setVolume:2];
            [self.player setDelegate:self];
        }
    }
}

// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------

// Stop and send recording
- (void)stopAndSendRecording
{
    [self stopRecording];
    
    // Send
    NSData *audioData = [[NSData alloc] initWithContentsOfURL:self.recorder.url];
    [ApiUtils sendMessage:audioData toUser:self.contact.identifier success:^{
        [self.delegate messageSentWithError:NO];
    } failure:^{
        [self.delegate messageSentWithError:YES];
    }];
}

// stop recording
- (void)stopRecording
{
    [self.metersTimer invalidate];
    [self.recorder stop];
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    [self.delegate longPressOnContactBubbleViewEnded:self.contact.identifier];
    [self.longPressRecognizer addTarget:self action:@selector(handleLongPressGesture:)];
}

// Stop recording after kMaxAudioDuration
- (void)maxRecordingDurationReached {
    [self.longPressRecognizer removeTarget:self action:@selector(handleLongPressGesture:)];
    [self stopAndSendRecording];
}

- (void)minRecordingDurationReached {
    // do nothing
}

- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    self.unreadMessagesLabel.text = [NSString stringWithFormat:@"%lu",(long)unreadMessagesCount];
    if (unreadMessagesCount>0) {
        [self.unreadMessagesLabel setHidden:NO];
        self.imageView.layer.borderColor = [ImageUtils blue].CGColor;
        self.imageView.layer.borderWidth = 3;
    } else {
        [self.unreadMessagesLabel setHidden:YES];
        self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.imageView.layer.borderWidth = 0.5;
    }
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
    [self.unreadMessagesLabel setHidden:YES];
}

- (void)addUnreadMessage:(Message *)message
{
    if (!self.unreadMessages) { // 1st message
        self.unreadMessages = [[NSMutableArray alloc] init];
    }
    [self.unreadMessages addObject:message];
    [self setUnreadMessagesCount:self.unreadMessagesCount+1];
    
    if (self.unreadMessagesCount == 1) {
        // Init player with this message if this is the only one
        NSData* data = [NSData dataWithContentsOfURL:[message getMessageURL]] ;
        self.player = [[AVAudioPlayer alloc] initWithData:data error:nil];
        [self.player setVolume:2];
        [self.player setDelegate:self];
    }
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

@end
