//
//  TrackingUtils.h
//  Heard
//
//  Created by Bastien Beurier on 6/25/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface TrackingUtils : NSObject

+ (void)identifyWithMixpanel:(Contact *)contact signup:(BOOL)isSigningUp;

+ (void)trackRecord;

+ (void)trackPlayWithDuration:(NSTimeInterval)duration;

+ (void)trackReplay;

+ (void)trackShareSuccessful:(BOOL)success;

+ (void)trackAddContactSuccessful:(BOOL)success;

+ (void)trackOpenApp;

+ (void)trackNumberOfContacts:(NSInteger)nbrOfContacts;

+ (void)trackInviteContacts:(NSInteger)nbrOfInvites successful:(BOOL)success;

@end
