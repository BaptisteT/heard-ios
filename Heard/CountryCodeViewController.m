//
//  CountryCodeViewController.m
//  Heard
//
//  Created by Bastien Beurier on 7/15/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "CountryCodeViewController.h"
#import "GeneralUtils.h"

#define BORDER_SIZE 0.5

@interface CountryCodeViewController ()

@property (weak, nonatomic) IBOutlet UIView *navigationContainer;

@end

@implementation CountryCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [GeneralUtils addBottomBorder:self.navigationContainer borderSize:BORDER_SIZE];
}

- (IBAction)cancelButtonClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
