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


@interface ContactBubbleView()

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *oneTapRecognizer;
@property (nonatomic, strong) NSTimer *maxDurationtimer;
@property (nonatomic, strong) NSTimer *minDurationtimer;
@property (nonatomic) BOOL minDurationReached;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic) NSInteger unreadMessagesCount;
@property (nonatomic) UIButton *unreadMessagesButton;
@property (nonatomic) NSMutableArray *unreadMessages;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) NSTimer *metersTimer;
@property (nonatomic) float averagePower;
@property (nonatomic) float elapsedTime;

// temp bt ?
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation ContactBubbleView


- (id)initWithContactBubble:(Contact *)contact andFrame:(CGRect)frame;
{
    self  = [self initWithFrame:frame];
    self.contact = contact;
    
    // Set image view
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kContactSize, kContactSize)];
    [self.imageView setImageWithURL:[GeneralUtils getUserProfilePictureURLFromUserId:contact.identifier]];
    [self addSubview:self.imageView];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = self.bounds.size.height/2;
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.borderWidth = 2.0;
    
    // Alloc and add gesture recognisers
    [self setMultipleTouchEnabled:NO];
    self.userInteractionEnabled = YES;
    self.exclusiveTouch = YES;
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [self.imageView addGestureRecognizer:self.longPressRecognizer];
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
    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
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
        self.maxDurationtimer = [NSTimer scheduledTimerWithTimeInterval:kMaxAudioDuration target:self selector:@selector(stopAndSendRecording) userInfo:nil repeats:NO];
        self.minDurationReached = NO;
        self.minDurationtimer = [NSTimer scheduledTimerWithTimeInterval:kMinAudioDuration target:self selector:@selector(minDurationReaching) userInfo:nil repeats:NO];
        
        // Record
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        self.elapsedTime = 0;
        self.averagePower = 0;
        
        // Start recording
        [self.recorder record];
        
        [self.delegate longPressOnContactBubbleViewStarted:self.contact.identifier];
        
        self.metersTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                           target:self
                                                         selector:@selector(notifyNewMeters)
                                                         userInfo:nil
                                                          repeats:YES];
        [self.metersTimer fire];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.metersTimer invalidate];
        // Stop timer
        [self.maxDurationtimer invalidate];
        
        // Stop recording
        [self.recorder stop];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];
        
        // If we are above min message time, we send it
        if (self.minDurationReached) {
            NSData *audioData = [[NSData alloc] initWithContentsOfURL:self.recorder.url];
            [ApiUtils sendMessage:audioData toUser:self.contact.identifier success:^{
                [self.delegate messageSentWithError:NO];
            } failure:^{
                [self.delegate messageSentWithError:YES];
            }];
            
            [self.delegate longPressOnContactBubbleViewEnded:self.contact.identifier longEnough:YES];
        } else {
            [self.delegate longPressOnContactBubbleViewEnded:self.contact.identifier longEnough:NO];
        }
    }
}

- (void)notifyNewMeters
{
    [self.recorder updateMeters];
    
    
    float power;
    
    if (self.averagePower == 0) {
        power = [self.recorder averagePowerForChannel:0];
    } else {
        power = ([self.recorder averagePowerForChannel:0] - self.averagePower * (self.elapsedTime / (self.elapsedTime + 0.1))) * ((self.elapsedTime + 0.1)/0.1);
    }
    
    self.averagePower = [self.recorder averagePowerForChannel:0];
    
    NSLog(@"POWER: %f", power);
    
    [self.delegate notifiedNewMeters:power];
    
}

- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
    [self.player play];
}

// temp bt
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        // Mark as opened on the database
        [ApiUtils markMessageAsOpened:((Message *)self.unreadMessages[0]).identifier success:nil failure:nil];
        
        
        [self.unreadMessages removeObjectAtIndex:0];
        [self setUnreadMessagesCount:self.unreadMessagesCount-1];
        
        if (self.unreadMessagesCount > 0) {
            NSData* data = [NSData dataWithContentsOfURL:[self.unreadMessages[0] getMessageURL]] ;
            self.player = [[AVAudioPlayer alloc] initWithData:data error:nil];
            [self.player setDelegate:self];
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

- (void)setUnreadMessagesCount:(NSInteger)unreadMessagesCount
{
    _unreadMessagesCount = unreadMessagesCount;
    [self.unreadMessagesButton setTitle:[NSString stringWithFormat:@"%lu",(long)unreadMessagesCount] forState:UIControlStateNormal];
    if (unreadMessagesCount>0) {
        [self.unreadMessagesButton setHidden:NO];
    } else {
        [self.unreadMessagesButton setHidden:YES];
    }
}

- (void)initUnreadMessagesButton
{
    self.unreadMessagesButton = [[UIButton alloc] init];
    [self.unreadMessagesButton setFrame:CGRectMake(kContactSize - kUnreadMessagesButtonSize, 0, kUnreadMessagesButtonSize, kUnreadMessagesButtonSize)];
    [self.unreadMessagesButton setBackgroundColor:[UIColor redColor]];
    [self.unreadMessagesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.unreadMessagesButton.layer.cornerRadius = self.unreadMessagesButton.bounds.size.height/2;
    
    self.oneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.unreadMessagesButton addGestureRecognizer:self.oneTapRecognizer];
    self.oneTapRecognizer.delegate = self;
    self.oneTapRecognizer.numberOfTapsRequired = 1;

    
    [self addSubview:self.unreadMessagesButton];
    [self.unreadMessagesButton setHidden:YES];
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
        [self.player setDelegate:self];
    }
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
}

@end
