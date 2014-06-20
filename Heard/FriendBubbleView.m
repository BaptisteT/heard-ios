//
//  FriendBubbleView.m
//  Heard
//
//  Created by Baptiste Truchot on 6/20/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "FriendBubbleView.h"
#import "UIImageView+AFNetworking.h"
#import "GeneralUtils.h"
#import "Constants.h"
#import "ApiUtils.h"
#import "SessionUtils.h"


@interface FriendBubbleView()

@property (nonatomic) NSInteger friendId;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationtimer;
@property (nonatomic, strong) NSTimer *minDurationtimer;
@property (nonatomic) BOOL minDurationReached;
@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation FriendBubbleView


- (id)initBubbleViewWithFriendId:(NSInteger)friendId
{
    // Set profile picture
    self.friendId = friendId;
    [self setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:friendId]];
    
    // Alloc and add gesture recognisers
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self addGestureRecognizer:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;
    self.longPressRecognizer.minimumPressDuration = 0.;

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
    [recordSetting setValue:[NSNumber numberWithFloat:16000] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:nil];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    
    return self;
}


// ----------------------------------------------------------
// Handle Gestures
// ----------------------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Create Timer
        self.maxDurationtimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(stopAndSendRecording) userInfo:nil repeats:NO];
        self.minDurationReached = NO;
        self.minDurationtimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minDurationReaching) userInfo:nil repeats:NO];
        
        // Record
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [self.recorder record];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Stop timer
        [self.maxDurationtimer invalidate];
        
        // Stop recording
        [self.recorder stop];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        
        // If we are above min message time, we send it
        if (self.minDurationReached) {
            NSData *audioData = [[NSData alloc] initWithContentsOfURL:self.recorder.url];
            [ApiUtils sendMessage:audioData fromUser:[SessionUtils getCurrentUserId] toUser:self.friendId success:nil failure:nil];
        } else {
            [GeneralUtils showMessage:@"Hold to record your message" withTitle:nil];
        }
    }
}


// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------

// Stop recording after kMaxAudioDuration
- (void)stopAndSendRecording {
    // todo BT (later)
}

// Stop recording after kMaxAudioDuration
- (void)minDurationReaching {
    self.minDurationReached = TRUE;
}

@end
