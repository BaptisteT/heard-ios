//
//  CountryCodeViewController.h
//  Heard
//
//  Created by Bastien Beurier on 7/15/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CountryCodeTVCDelegate;

@interface CountryCodeViewTVC : UITableViewController

@property (weak, nonatomic) id <CountryCodeTVCDelegate> delegate;

@end

@protocol CountryCodeTVCDelegate

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode;

@end