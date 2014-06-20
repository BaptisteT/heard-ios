//
//  HeardViewController.m
//  Heard
//
//  Created by Bastien Beurier on 6/17/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "WelcomeViewController.h"

@interface WelcomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titbleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;
@property (strong, nonatomic) UIView *hiddingView;

@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titbleLabel.alpha = 0;
    self.subTitleLabel.alpha = 0;
    self.startButton.alpha = 0;
    
    self.hiddingView = [[UIView alloc] initWithFrame:self.logoImage.frame];
    self.hiddingView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.hiddingView];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:3.0 animations:^{
        
        self.hiddingView.frame = CGRectMake(self.hiddingView.frame.size.width,
                                            self.hiddingView.frame.origin.y,
                                            self.hiddingView.frame.size.width,
                                            self.hiddingView.frame.size.height);
    } completion:^(BOOL dummy){
        [UIView animateWithDuration:1.0 animations:^{
            
            self.titbleLabel.alpha = 1;
            self.subTitleLabel.alpha = 1;
            self.startButton.alpha = 1;
        }];
    }];
}

@end
