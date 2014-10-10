//
//  HeardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "WelcomeViewController.h"
#import "Constants.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;

@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.startButton.titleLabel sizeToFit];
    self.startButton.titleLabel.text = NSLocalizedStringFromTable(@"start_button_text",kStringFile, @"comment");
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)startButtonClicked:(id)sender {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [self performSelectorOnMainThread:@selector(startSegue) withObject:nil waitUntilDone:YES];
    }];
}
     
- (void)startSegue
{
    [self performSegueWithIdentifier:@"Phone Push Segue" sender:nil];
}

@end
