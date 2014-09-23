//
//  HeardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "WelcomeViewController.h"
#import "Constants.h"

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;
@property (nonatomic) BOOL animating;

@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.animating = NO;
    
    self.subTitleLabel.text = NSLocalizedStringFromTable(@"subtitle_label",kStringFile, @"comment");
    [self.startButton.titleLabel sizeToFit];
    self.startButton.titleLabel.text = NSLocalizedStringFromTable(@"start_button_text",kStringFile, @"comment");
    
    self.titleLabel.alpha = 0;
    self.subTitleLabel.alpha = 0;
    self.startButton.alpha = 0;
    self.logoImage.alpha = 0;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.0 animations:^{
        
        self.titleLabel.alpha = 1;
        self.subTitleLabel.alpha = 1;
        self.startButton.alpha = 1;
        self.logoImage.alpha = 1;
    }];
}

@end
