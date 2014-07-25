//
//  TutorialViewController.m
//  Heard
//
//  Created by Bastien Beurier on 7/25/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *recordImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playImageView;
@property (weak, nonatomic) IBOutlet UIImageView *menuImageView;

@end

@implementation TutorialViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *recordImageArray  = [[NSArray alloc] initWithObjects:
                                [UIImage imageNamed:@"hold1.png"],
                                [UIImage imageNamed:@"hold2.png"],
                                [UIImage imageNamed:@"hold1.png"],
                                [UIImage imageNamed:@"hold2.png"],
                                [UIImage imageNamed:@"hold1.png"],
                                [UIImage imageNamed:@"hold2.png"],
                                [UIImage imageNamed:@"hold1.png"],
                                [UIImage imageNamed:@"hold2.png"],
                                nil];
    
    NSArray *playImageArray  = [[NSArray alloc] initWithObjects:
                                  [UIImage imageNamed:@"press1.png"],
                                  [UIImage imageNamed:@"press2.png"],
                                  [UIImage imageNamed:@"play1.png"],
                                  [UIImage imageNamed:@"play2.png"],
                                  [UIImage imageNamed:@"play1.png"],
                                  [UIImage imageNamed:@"play2.png"],
                                  [UIImage imageNamed:@"play1.png"],
                                  [UIImage imageNamed:@"play2.png"],
                                  nil];
    
    NSArray *menuImageArray  = [[NSArray alloc] initWithObjects:
                                [UIImage imageNamed:@"press1.png"],
                                [UIImage imageNamed:@"press2.png"],
                                [UIImage imageNamed:@"press1.png"],
                                [UIImage imageNamed:@"press2.png"],
                                [UIImage imageNamed:@"press1.png"],
                                [UIImage imageNamed:@"press1.png"],
                                [UIImage imageNamed:@"press1.png"],
                                [UIImage imageNamed:@"press1.png"],
                                nil];
    
    

	self.recordImageView.animationImages = recordImageArray;
    self.playImageView.animationImages = playImageArray;
    self.menuImageView.animationImages = menuImageArray;
    
	self.recordImageView.animationRepeatCount = 0;
    self.playImageView.animationRepeatCount = 0;
    self.menuImageView.animationRepeatCount = 0;
    
    self.recordImageView.animationDuration = 2;
    self.playImageView.animationDuration = 2;
    self.menuImageView.animationDuration = 2;
    
	[self.recordImageView startAnimating];
    [self.playImageView startAnimating];
    [self.menuImageView startAnimating];
}

- (IBAction)tutorialTapped:(id)sender {
    [self dismissViewControllerAnimated:NO completion:NO];
}

@end
