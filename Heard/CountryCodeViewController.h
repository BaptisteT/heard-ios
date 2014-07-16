//
//  CountryCodeViewController.h
//  Heard
//
//  Created by Bastien Beurier on 7/15/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CountryCodeViewTVC.h"

@protocol CountryCodeViewControllerDelegate;

@interface CountryCodeViewController : UIViewController <CountryCodeTVCDelegate>

@property (weak, nonatomic) id <CountryCodeViewControllerDelegate> delegate;

@end

@protocol CountryCodeViewControllerDelegate

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode;

@end