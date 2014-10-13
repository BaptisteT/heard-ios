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
@property (weak, nonatomic) IBOutlet UIView *hiddingView;
@property (weak, nonatomic) IBOutlet UITextView *subtitleTextView;

@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.startButton.titleLabel sizeToFit];
    self.startButton.titleLabel.text = NSLocalizedStringFromTable(@"start_button_text",kStringFile, @"comment");
    
    self.titleLabel.alpha = 0;
    self.subtitleTextView.alpha = 0;
    self.startButton.alpha = 0;
    self.hiddingView.hidden = NO;
    
    self.hiddingView.backgroundColor = [UIColor whiteColor];
    [self.logoImage addSubview:self.hiddingView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:3.0 animations:^{
        
        self.hiddingView.frame = CGRectMake(self.logoImage.bounds.size.width,
                                            0,
                                            self.hiddingView.bounds.size.width,
                                            self.hiddingView.bounds.size.height);
    } completion:^(BOOL dummy){
        [UIView animateWithDuration:1.0 animations:^{
            
            self.titleLabel.alpha = 1;
            self.subtitleTextView.alpha = 1;
            self.startButton.alpha = 1;
        }];
    }];
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
